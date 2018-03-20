function [] = exp_certificates(N, reproduce)
clearvars -except N reproduce
% reproduce = 0: only draw plots
% reproduce = 1: first reproduce the experiments
if nargin < 2, 
    reproduce = 0;
end
if nargin < 1,
    N = 10; % number of Monte-Carlo trials
end
ifGaps = 1; % accuracy upper bounds
ifConf = 1; 
ifTrueErr = 0;
%% EXP: Mirror Prox for Con-UF; FGM for Con-LS, with accuracy certificates
% N = 10;
SNR = [4];
base_sce = 'CohSin-';
S = [4];
outpath = './plots-certificates/';
control = struct('w',100,'n',100,'verb',0,'iters',1000,'ada',1,'constr',1);
nsim = 0;
wb1 = waitbar(0,'E3: overall progress','WindowStyle','modal');
pos_wb1=get(wb1,'position');
pos_wb2=[pos_wb1(1) pos_wb1(2)+pos_wb1(4) pos_wb1(3) pos_wb1(4)];
control.wb_pos = pos_wb2;

%% p == Inf, Mirror Prox
control.l2_prox = 2; % mandatory for indexing
control.p = Inf;
control.alg = {'mp'};
for s = S,
    spikes = 2*s;
    sce = [base_sce num2str(spikes)];
    control.sce = sce;
    control.rho = 2*spikes;
    for snr = SNR,
        nsim = nsim+1;
        control.snr = snr;
        if reproduce,
            MC_perf_sims(control,N);
        end
        waitbar(nsim/(2*length(S)*length(SNR)));
    end
end
control.l2_prox = 1; % plot only l2-setup
control.iters = 100; % plot only 100 iters
for s = S,
    spikes = 2*s;
    sce = [base_sce num2str(spikes)];
    control.sce = sce;
    control.rho = 2*spikes;
%     sce = [base_sce num2str(s)];
%     control.sce = sce;
%     control.rho = 4*s; % coherent!
    for snr = SNR,
        control.snr = snr;
        ifXlab = 0;
        ifYlab = 1;
        ifSq = 0;
        MC_perf_plot(control,N,ifGaps,ifConf,ifTrueErr,outpath,3,ifXlab,ifYlab,ifSq);
    end
end

%% p == 2, Fast Gradient Method
control.l2_prox = 2; % mandatory for indexing
control.iters = 1000;
control.p = 2;
control.alg = {'mp','nes'};
for s = S,
    spikes = 2*s;
    sce = [base_sce num2str(spikes)];
    control.sce = sce;
    control.rho = 2*spikes;
%     sce = [base_sce num2str(s)];
%     control.sce = sce;
%     control.rho = sqrt(2)*s;
    for snr = SNR,
        nsim = nsim+1;
        control.snr = snr;
        if reproduce,
            MC_perf_sims(control,N);
        end
        waitbar(nsim/(2*length(S)*length(SNR)));
    end
end
control.l2_prox = 1;
control.iters = 100;
for s = S,
%     sce = [base_sce num2str(s)];
%     control.sce = sce;
%     control.rho = 2*s;
    spikes = 2*s;
    sce = [base_sce num2str(spikes)];
    control.sce = sce;
    control.rho = 2*spikes;
    for snr = SNR,
        control.snr = snr;
        ifXlab = 0;
        ifYlab = 0;
        ifSq = 0;
        MC_perf_plot(control,N,ifGaps,ifConf,ifTrueErr,outpath,3,ifXlab,ifYlab,ifSq);
%         ifSq = 1;
%         MC_perf_plot(control,N,ifGaps,ifConf,ifTrueErr,outpath,3,ifXlab,ifYlab,ifSq);
    end
end
close(wb1);
end