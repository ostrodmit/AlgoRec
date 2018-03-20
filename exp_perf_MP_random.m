function [] = exp_perf_MP_random(N, reproduce)
clearvars -except N reproduce
% reproduce = 0: only draw plots
% reproduce = 1: first reproduce the experiments
if nargin < 2, 
    reproduce = 0;
end
if nargin < 1,
    N = 10; % number of Monte-Carlo trials
end
%% EXP: Mirror Prox for Constrained UFR in Random scenario
% SNR = [1, 4, 16];
SNR = [1,16];
base_sce = 'RanSin-';
% S = [4,8,16];
S = [16];
outpath = './plots-perf-MP-random/';
control = struct('w',100,'n',100,'p',Inf,'alg',{{'mp'}},'verb',0,...
    'iters',1000,'ada',1,'constr',1,'l2_prox',2);
nsim = 0;
wb1 = waitbar(0,'EXP: overall progress','WindowStyle','modal');
pos_wb1=get(wb1,'position');
pos_wb2=[pos_wb1(1) pos_wb1(2)+pos_wb1(4) pos_wb1(3) pos_wb1(4)];
control.wb_pos = pos_wb2;
for s = S,
    sce = [base_sce num2str(s)];
    control.sce = sce;
    control.rho = 2*s;
    for snr = SNR,
        nsim = nsim+1;
        control.snr = snr;
        if reproduce,
            MC_perf_sims(control,N);
        end
        waitbar(nsim/(length(S)*length(SNR)));
    end
end
ifGaps = 0; % accuracy upper bounds
ifConf = 1; % confidence tubes
ifTrueErr = 1; % plot with true error
for s = S,
    sce = [base_sce num2str(s)];
    control.sce = sce;
    control.rho = 2*s;
    for snr = SNR,
        control.snr = snr;
        ifXlab = 0;
        ifYlab = (snr == SNR(1));
        MC_perf_plot(control,N,ifGaps,ifConf,ifTrueErr,outpath,1,ifXlab,ifYlab,0);
    end
end
close(wb1);
end