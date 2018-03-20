function [] = MC_sigm_sims(N,dim,~,sce,s,r,noise)
clearvars -except N dim ifPost sce s r noise
if nargin < 7,
    noise = 'white';
end
if nargin < 6,
    r = 0;
end
if nargin < 5,
    s = 4;
end
if nargin < 4, 
    sce='RanSin';
end
if strcmp(sce,'CohSin'),
    spikes = 2*s;
    sce = [sce '-' num2str(spikes)];
else
    sce = [sce '-' num2str(s)];
end
if r > 0, % only if ModSin
    sce = [sce '-' num2str(r)];
end
rng(2,'twister'); % initialize random number generator
logSNR = linspace(log(0.25), log(16), 7);
SNR = exp(logSNR);
if dim==1,
    n = 100;
    methodErr = zeros(9,1,1,length(SNR),N);
    methodCpu = zeros(9,1,1,length(SNR),N);
% elseif dim==2,
%     N=40;
%     n = 40;
%     methodErr = zeros(7+ifPost,1,length(K),length(SNR),N); % RanSin or SingleIdx
%     if strcmp(exper,'sin'), Sce = [0,1]; % RanSin, CohSin
%     elseif strcmp(exper,'SI'), Sce = [2]; % SI
%     else
%         error('Incorrect experiment');
%     end
else
    error('dim must be 1');
end

wb = waitbar(0,'Processing...','WindowStyle','modal');
for trial = 1:N,
    for snr=SNR,
            [x,y,sigm] = MC_sigm_generate_data(sce,noise,n,snr);
            Z  = norm(x(:));
            x = x ./ Z; y = y ./ Z; sigm = sigm / Z;
            % Denoise via Recht's oversampled Lasso.
            tic;
            recl = lasso_recovery(y,sigm);
            cpu_recl = toc;
            %%
            % Denoise via constrained l2-filtering.
            clear params
            if strcmp(sce(1:6),'CohSin'),
                params.rho=2*spikes;
            else
                params.rho=2*s*(r+1);
            end
            params.lep=0; % no bandwidth adaptation
            params.sigm=sigm; % won't be used
            %alpha = 0.1;
            %lambda = 2 * sigm^2 * log(42*n/alpha);
            params.verb=0;
            solver_control = struct('p',2,'constrained',1,...
                'solver','nes','tol',1e-8,'eps',(params.rho)^2*sigm^2,...
                'max_iter',10000,'max_cpu',1000,...
                'l2_prox',1,'online',1,'verbose',0);
            solver_control.sigm = sigm;
            tic;
            recf2conk = filter_recovery(y,params,solver_control);
            cpu_recf2conk = toc;
            solver_control.eps = 0.01*(params.rho)^2*sigm^2;
            tic;
            fine_recf2conk = filter_recovery(y,params,solver_control);
            cpu_fine_recf2conk = toc;
%                 params.rho=k^2;
%                 recf2conk2 = filter_recovery(y,params,solver_control);
%                 solver_control.p=inf;
%                 solver_control.solver='mp';
%                 params.rho=s;
%                 recf8conk = filter_recovery(y,params,solver_control);
%                 params.rho=s^2;
%                 recf8conk2 = filter_recovery(y,params,solver_control);
%                 solver_control.constrained=0;
%                 solver_control.p=2;
%                 solver_control.solver='nes';
%                 solver_control.max_iter=1000;
%                 solver_control.lambda=2*sigm^2*log(630*(n/2)^dim);
%                 recf2penpr = filter_recovery(y,params,solver_control);
%                 % post-denoising 
%                 if ifPost, 
%                     rec_post = music(recf2penpr,'root',k,n/2);
%                 end
%                 %
%                 solver_control.lambda=60*sigm^2*log(630*(n/2)^dim);
%                 recf2penth = filter_recovery(y,params,solver_control);
            % Save stats
            methodErr(1,1,1,find(SNR==snr),trial)...
                = norm(recl(:)-x(:));       % AST
            methodCpu(1,1,1,find(SNR==snr),trial)...
                = cpu_recl;       % AST
%                 methodErr(2,1,1,find(SNR==snr),trial)...
%                     = norm(recf8conk(:)-x(:));  % l8conk
%                 methodErr(3,1,1,find(SNR==snr),trial)...
%                     = norm(recf8conk2(:)-x(:)); % l8conk2
            methodErr(4,1,1,find(SNR==snr),trial)...
                = norm(recf2conk(:)-x(:));  % l2conk
            methodCpu(4,1,1,find(SNR==snr),trial)...
                = cpu_recf2conk;  % l2conk
%                 methodErr(5,1,1,find(SNR==snr),trial)...
%                     = norm(recf2conk2(:)-x(:)); % l2conk2
%                 methodErr(6,1,1,find(SNR==snr),trial)...
%                     = norm(recf2penpr(:)-x(:)); % l2penpr
%                 methodErr(7,1,1,find(SNR==snr),trial)...
%                     = norm(recf2penth(:)-x(:)); % l2penth
%                 if ifPost,
%                     methodErr(8,1,1,find(SNR==snr),trial)...
%                         = norm(rec_post(:)-x(:)); % post-denoising
%                 end
            methodErr(9,1,1,find(SNR==snr),trial)...
                = norm(fine_recf2conk(:)-x(:));  % fine acc l2conk
            methodCpu(9,1,1,find(SNR==snr),trial)...
                = cpu_fine_recf2conk;  % fine acc l2conk
    end
    waitbar(trial/N);
end
close(wb);
if strcmp(sce(1:6),'CohSin'),
    spikes = str2num(sce(8:end));
    s = spikes/2;
    sce(8:end) = num2str(s);
end
respath = ['./sims-sigm/' sce '_' noise '/'];
if ~exist(respath, 'dir')
  mkdir(respath);
end
addpath(respath);
statfile = [respath 'stats-N-' num2str(N) '.mat'];
% if exist(statfile, 'file')==2, delete(statfile); end
save(statfile,'SNR','methodErr','methodCpu','-v7.3');
end