function [] = exp_complexity(N,reproduce)
clearvars -except N reproduce
% reproduce = 0: only draw plots
% reproduce = 1: first reproduce the experiments
if nargin < 2, 
    reproduce = 0;
end
if nargin < 1,
    N = 20; % number of Monte-Carlo trials
end
%% EXP: ``Statistical'' complexity of Mirror Prox for Con-UF, FGM for Con-LS
SNR = logspace(log10(1/10),log10(100),11);
base_sce = 'RanSin-';
S = [4];
outpath = './plots-complexity/';
control = struct('w',100,'n',100,'verb',0,'iters',1000,'ada',1,'constr',1);
nsim = 0;
wb1 = waitbar(0,'EXP: overall progress','WindowStyle','modal');
pos_wb1=get(wb1,'position');
pos_wb2=[pos_wb1(1) pos_wb1(2)+pos_wb1(4) pos_wb1(3) pos_wb1(4)];
control.wb_pos = pos_wb2;

%% p == Inf, Mirror Prox
control.l2_prox = 2; % mandatory for indexing
control.p = Inf;
control.alg = {'mp'};
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
        waitbar(nsim/(2*length(S)*length(SNR)));
    end
end
control.l2_prox = 1; % plot only l2-setup
for s = S,
    sce = [base_sce num2str(s)];
    control.sce = sce;
    control.rho = 2*s;
    for snr = SNR,
        control.snr = snr;
        ifXlab = 1;
        ifYlab = 1;
        MC_perf_plot_complexity(SNR,control,N,outpath,ifXlab,ifYlab);
    end
end

%% p == 2, Fast Gradient Method
control.l2_prox = 2; % mandatory for indexing
control.iters = 3000;
control.p = 2;
control.alg = {'nes'};
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
        waitbar(nsim/(2*length(S)*length(SNR)));
    end
end
control.l2_prox = 1;

control.iters = 1000;
for s = S,
    sce = [base_sce num2str(s)];
    control.sce = sce;
    control.rho = 2*s;
    for snr = SNR,
        control.snr = snr;
        ifXlab = 1;
        ifYlab = 1;
        MC_perf_plot_complexity(SNR,control,N,outpath,ifXlab,ifYlab);
    end
end
close(wb1);
end