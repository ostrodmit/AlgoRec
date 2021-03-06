function stats =  test_performance(input_control)
%
% TEST_PERFORMANCE Test the performance of proximal first-order algorithms 
% for filtering: Composite Mirror Prox and Fast Gradient Method.
%
% Input params
%   input_control : structure with the following fields (all optional) :
%       sce [{'RanSin-<k>','CohSin-<k>','Speech','1'-'8'},'RanSin-2'] :
%           ground truth signal scenario. Here, <k> is the number of
%           harmonics. Random Sines, Coherent Sines, Speech (file
%           'mtlb.mat'), or an artificial signal generated by YSIM.
%       snr [{[double1,double2,...]},[100]] : signal-to-noise ratio (*not*
%           in dBs!).
%       w [{int > 0},100] : filter bandwidth.
%       n [{int > 0},100] : remaining signal length.
%       p [{2,inf},2] : l_2 or l_inf minimization. If constrained=0
%           and solver='nes', penalized l_2^2 objective will be minimized.
%           See FIT_FILTER.
%       constr [{1,0},1] : contrained or unconstrained formulation
%       *rho [{>0}] : filter norm constraint, see FIT_FILTER. Mandatory if
%           constr=1.
%       *lambda [{>0}] : penalty, see FIT_FILTER. Mandatory if contsr=0.
%       alg : cell array, in {{}}, with the names of algorithms to compare.
%           'mp', 'nes', 'sub'. By default, {{'nes'}} if p=2, and {{'mp'}}
%           if p=inf.
%       l2_prox [{0,1,2},0] : whether to force l2 prox; l2_prox=2 to 
%           compare both.
%       ada [{0,1},0] : whether to use the adaptive stepsize.
%       iters [int,1000] : how many iterations.
%       verb [int, 0] : verbose level. verb=0 for no output.
% 
% Example :
%   input_control = struct('sce','RanSin-2','snr',[5],'w',100,'n',100,...
%       'rho',3,'alg',{{'mp','nes'}},'p',2,'l2_prox',2,'ada',1,'verb',0);
%   test_performance(input_control);
%
% See also : test_dialog, test_auto.
%
% Copyright : Dmitry Ostrovsky, 2016.

%%
format long
respath = '../test/perf_test/';
if ~exist(respath, 'dir')
  mkdir(respath);
end
addpath(respath);
if input_control.verb,
    fprintf('Generating data...\n');
end
if isfield(input_control,'sce')
    sce = input_control.sce;
else
    sce = 'RanSin-2';
end
if isfield(input_control,'snr'), snr = input_control.snr; else snr = [100]; end
if isfield(input_control,'w'), w = input_control.w; else w = 100; end
if isfield(input_control,'n'), n = input_control.n; else n = 100; end
if isfield(input_control,'p'), p = input_control.p; else p = 2; end
if isfield(input_control,'constr')
    constr = input_control.constr;
else
    constr = 1;
end
if isfield(input_control,'rho'), rho = input_control.rho;
else
    if constr, error('constrained, hence rho must be specified.'); end
end
if isfield(input_control,'lambda'),
    lambda = input_control.lambda; % lambda * sqrt(n) will be used
else
    if ~constr, error('constr=0, lambda must be specified.'); end
end
if isfield(input_control,'alg')
    algos = input_control.alg;
else
    if p==2
        algos = {'nes'};
    else
        algos = {'mp'};
    end
end
if ~constr && p==2 && ~isempty(strmatch('nes',algos)) % for cvx baseline
    squared = 1;
else
    squared = 0;
end
if isfield(input_control,'l2_prox'), l2_prox = input_control.l2_prox; 
else l2_prox = 0; end
if isfield(input_control,'ada'), online = input_control.ada; else online = 0; end
if isfield(input_control,'iters')
    iters = input_control.iters-1;
else
    iters = 999;
end
if isfield(input_control,'verb'), verb = input_control.verb; else verb = 0; end

%% Generate data
if length(sce)>=7 && (strcmp(sce(1:7),'RanSin-') || strcmp(sce(1:7),'CohSin-'))
    k = str2num(sce(8:end));
    if strcmp(sce(1:7),'RanSin-')
        freqs = rand(k,1);
        amps = randn(k,1);
        numfreqs = k;
    else
        spikes = rand(floor(k/2),1);
        amps = randn(floor(k/2),1);
        delta = 0.1;
        freqs = [spikes,spikes+delta/(n+w)]; % close random spikes
        amps = [amps;amps];
        numfreqs = k;
    end
    x = zeros(n+w,1);
    for j = 1:numfreqs
        x = x+amps(j)*exp(2*pi*1i*freqs(j)*(0:n+w-1))';
    end
    x = real(x);
elseif strcmp(sce,'Speech')
    speech = open('mtlb.mat');
    x = speech.mtlb(1:n+w);
elseif ismember(str2num(sce),1:8) % artificial signal
    [y,x]=ysim(n,100,str2num(sce));
else
    error('Incorrect scenario');
end
for i = 1:length(snr)
    sigm(i) = norm(x)/sqrt(n+w)/snr(i);
    %% Dima's change
    y(:,i) = x + sigm(i) * randn(n+w,1);
    % y(:,i) = x + sigm(i) * ones(n+w,1);
    %%
end

%% Set common params
tol = 1e-12;
max_cpu = inf;
y1 = y;
y2 = y(w+1:n+w,:);
eps = 0;
verbose = verb;
init_verbose = verb;
init_solver = 'cvx';
%phi0 = ones(101,1);

control = struct('p',p,'constrained',constr,'squared',squared,...
    'solver',init_solver,'accuracy','abs','eps',0,'tol',tol,...
    'max_iter',iters,'max_cpu',max_cpu,'l2_prox',l2_prox,'warm_start',0,...
    'online',online,'last_part',0,'verbose',init_verbose,...
    'if_trace_filter',1);%,...
    %'phi0', phi0);

%% Obtain the optimal values
control.max_iter = 2*iters;
if constr, control.rho = rho; end
% clear opt_sol;
% clear opt_val;
for i = 1:length(snr)
    if ~constr, 
        if squared,
            control.lambda = lambda * sigm(i)^2 * log(n+w);
        else
            control.lambda = lambda * sigm(i) * log(n+w) / sqrt(n+w);
        end
    end
    opt_sol(i) = fit_filter(y1(:,i), y2(:,i), control);
    opt_val(i) = opt_sol(i).pobj;
    % to debug
    %opt_val(i) = 0;
    %
end
control.verbose = verbose;
control.max_iter = iters;

%% Collect stats
if verb,
    fprintf('Running simulations...\n');
end
if l2_prox == 0 || l2_prox == 1
    prxs = l2_prox;
else
    prxs = [0 1];
end
obj = zeros(iters+1,length(snr),length(algos),length(prxs));
abs_acc = zeros(iters+1,length(snr),length(algos),length(prxs));
abs_acc_sq = zeros(iters+1,length(snr),length(algos),length(prxs));
abs_acc_sq_ub = zeros(iters+1,length(snr),length(algos),length(prxs));
abs_acc_ub = zeros(iters+1,length(snr),length(algos),length(prxs));
threshold_iter = zeros(1,length(snr),length(algos),length(prxs)); % dummy 1st idx for consistency when averaging
threshold_iter_sq = zeros(1,length(snr),length(algos),length(prxs));  % dummy 1st idx for consistency when averaging
rel_acc = zeros(iters+1,length(snr),length(algos),length(prxs));
rel_acc_sq = zeros(iters+1,length(snr),length(algos),length(prxs));
rel_acc_ub = zeros(iters+1,length(snr),length(algos),length(prxs));
rel_acc_sq_ub = zeros(iters+1,length(snr),length(algos),length(prxs));
cpu = zeros(iters+1,length(snr),length(algos),length(prxs));
int_iter = zeros(iters+1,length(snr),length(algos),length(prxs));
phi = zeros(w+1,length(snr),length(algos),length(prxs));
true_err_lInf = zeros(iters+1,length(snr),length(algos),length(prxs));
true_err_l2 = zeros(iters+1,length(snr),length(algos),length(prxs));
true_err = zeros(iters+1,length(snr),length(algos),length(prxs));
for a = 1:length(algos) % run algorithms
    if ~sum(ismember({'mp','nes','sub'},algos{a}))
        error('Unknown algorithm.');
    end
    control.solver = algos{a};
    for i = 1:length(snr)
        if ~constr,
            if squared,
                control.lambda = lambda * sigm(i)^2 * log(n+w);
            else
                control.lambda = lambda * sigm(i) * log(n+w) / sqrt(n+w);
            end
        end
        for pr = prxs
            control.l2_prox = pr;
            sol = fit_filter(y1(:,i), y2(:,i), control);
            obj(:,i,a,pr+1) = sol.Pobj;
            abs_acc(:,i,a,pr+1) = sol.Pobj-opt_val(i)*ones(iters+1,1);
            threshold_iter(1,i,a,pr+1) = find(squeeze(abs_acc(:,i,a,pr+1)) < sigm(i)*rho,1);
            abs_acc_sq(:,i,a,pr+1) = abs_acc(:,i,a,pr+1) .* (sol.Pobj+opt_val(i));
            findIter = find(squeeze(abs_acc_sq(:,i,a,pr+1)) < ((sigm(i)*rho)^2),1);
            if isempty(findIter), % happens for MP since there we need not to have quadratic error small
                threshold_iter_sq(1,i,a,pr+1) = Inf;
            else
                threshold_iter_sq(1,i,a,pr+1) = findIter;
            end
            abs_acc_ub(:,i,a,pr+1) = sol.Gap;
            abs_acc_sq_ub(:,i,a,pr+1) = abs_acc_ub(:,i,a,pr+1) .* (2*sol.Pobj);
            rel_acc(:,i,a,pr+1) = abs_acc(:,i,a,pr+1) / opt_val(i);
            rel_acc_sq(:,i,a,pr+1) = abs_acc_sq(:,i,a,pr+1) / (opt_val(i))^2;
            rel_acc_ub(:,i,a,pr+1) = sol.RelErrUb;
            rel_acc_sq_ub(:,i,a,pr+1) = rel_acc_ub(:,i,a,pr+1).*(rel_acc_ub(:,i,a,pr+1)+2);
            cpu(:,i,a,pr+1) = sol.Cpu;
            phi(:,i,a,pr+1) = sol.phi;
            int_iter(:,i,a,pr+1) = sol.Int_iter;
            % true error -- norm of the residual x - y * phi
            for it = 1:size(sol.Filter,2),
                true_err_lInf(it,i,a,pr+1) = norm(fft(x(w+1:w+n)-conv(y(:,i),sol.Filter(:,it),'valid')),Inf);
                true_err_l2(it,i,a,pr+1) = norm(fft(x(w+1:w+n)-conv(y(:,i),sol.Filter(:,it),'valid')),2);
                true_err = true_err_lInf;
                %true_err(it,i,a,pr+1) = true_err(it,i,a,pr+1)./(sigm(i)*sqrt(n));
            end
        end
    end
end
%% Save stats
stats = struct('int_iter',int_iter,...
    'cpu',cpu,...
    'abs_acc',abs_acc,'abs_acc_sq',abs_acc_sq,'abs_acc_ub',abs_acc_ub,'abs_acc_sq_ub',abs_acc_sq_ub,...
    'rel_acc',rel_acc,'rel_acc_sq',rel_acc_sq,'rel_acc_ub',rel_acc_ub,'rel_acc_sq_ub',rel_acc_sq_ub,...
    'threshold_iter',threshold_iter,'threshold_iter_sq',threshold_iter_sq,...
    'true_err_lInf',true_err_lInf,'true_err_l2',true_err_l2,'true_err',true_err);
end
% %% Plot results
% if ~plot,
%     return
% end
% snr_string = sprintf('%g-',snr);
% param_string = ['sce-' sce '_snr-[' snr_string(1:end-1)...
%     ']_n-' num2str(n) '_w-' num2str(w) '_p-' num2str(p)];
% if constr, param_string = [param_string '_rho-' num2str(rho)];
% else param_string = [param_string '_lambda-' num2str(lambda)]; end
% param_string = [param_string '_l2_prox-' num2str(l2_prox)...
%     '_ada-' num2str(online) '_it-' num2str(iters+1)];
% param_string = strrep(param_string, '.', 'p');
% param_string = strrep(param_string, '/', ':');
% set(gcf,'name', param_string)
% % Line styles
% myColor = {'b','r'};
% lineSpec = repmat({{}},2,2,2);
% for a = 1:length(algos)
%     lineSpec(a,:,:) = repmat({strcat(myColor{a},'-')},1,2,2);
% end
% % gap curves are dashed
% lineSpec(:,2,:) = strcat(lineSpec(:,2,:),'-');
% % Non-Euclidean Prox
% %lineSpec(:,:,1) = strcat(lineSpec(:,:,1),'.');
% for i = 1:length(snr)
%     % absolute error
%     subplot(length(snr),2,(i-1)*2+1);
%     for pr = prxs
%         for a = 1:length(algos)
%             % true
%             loglog(int_iter(:,i,a,pr+1)+1,abs_err(:,i,a,pr+1),...
%                 lineSpec{a,1,pr+1},'Linewidth',pr+1,'MarkerSize',3)
%             hold on;
%         end
%         for a = 1:length(algos)
%             % gap
%             loglog(int_iter(:,i,a,pr+1)+1,gap(:,i,a,pr+1),...
%                 lineSpec{a,2,pr+1},'Linewidth',pr+1,'MarkerSize',3)
%             hold on;
%         end
%     end
%     title(['Absolute error, ' 'SNR=' num2str(snr(i))...
%         ', optval=' num2str(opt_val(i))])
%     legend(perf_algoLegendNames(algos),'Location','southwest')
%     %axis([0 1e4 1e-2 1e2]);
%     %set(gca,'YTick',[1e-2 1e-1 1 1e1 1e2]);
%     set(gca,'XTick',[0 1e1 1e2 1e3 1e4]);
%     grid on
%     grid minor
%     hold off
%     % relative error
%     subplot(length(snr),2,(i-1)*2+2);
%     for pr = prxs
%         for a = 1:length(algos)
%             % true
%             loglog(int_iter(:,i,a,pr+1)+1,rel_err(:,i,a,pr+1),...
%                 lineSpec{a,1,pr+1},'Linewidth',pr+1,'MarkerSize',3)
%             hold on;
%         end
%         for a = 1:length(algos)
%             % gap
%             loglog(int_iter(:,i,a,pr+1)+1,rel_err_ub(:,i,a,pr+1),...
%                 lineSpec{a,2,pr+1},'Linewidth',pr+1,'MarkerSize',3)
%             hold on;
%         end
%     end
%     title(['Relative error, ' 'SNR=' num2str(snr(i))])
%     legend(perf_algoLegendNames(algos),'Location','southwest');
%     Rel_err = rel_err(:,i,:,:);
%     axis([0 1e4 1e-2 2*max(Rel_err(:))]);
%     set(gca,'XTick',[0 1e1 1e2 1e3 1e4]);
%     set(gca,'YTick',[1e-2 1e-1 1 1e1 1e2]);
%     grid on
%     grid minor
%     hold off
% end
% savefig(gcf,[respath param_string '.fig']);
% set(gcf, 'PaperSize', [11.69 8.27]); % paper size (A4), landscape
% % Extend the plot to fill entire paper.
% set(gcf, 'PaperPosition', [0 0 11.69 8.27]);
% saveas(gcf,[respath param_string '.pdf'],'pdf');
% % for i = 1:length(snr)
% %     disp('snr');
% %     snr(i)
% %     b = dft(y2(:,i));
% %     disp('MP error:');
% %     norm(direct_operator(phi(:,i,1),rho,y1(:,i))-b,i)
% %     disp('Nesterov error:')
% %     norm(direct_operator(phi(:,i,2),rho,y1(:,i))-b,i)
% %     disp('Optimal value')
% %     opt_val(i)
% % end