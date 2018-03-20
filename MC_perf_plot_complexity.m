function [] = MC_perf_plot_complexity(SNR,control,N,outpath,ifXlab,ifYlab)
%% Input params
% N: number of trials (to choose statfile)
% ifGaps: whether to draw upper bounds
% ifConf: whether to draw confidence bounds
close all
clearvars -except SNR control N outpath ifXlab ifYlab
ifGaps = 0;
format short
if isfield(control,'alg')
    algos = control.alg;
else
    if control.p == 2
        algos = {'nes'};
    else
        algos = {'mp'};
    end
end
if control.l2_prox == 0 || control.l2_prox == 1
    prxs = control.l2_prox;
else
    prxs = [0 1];
end
iters = control.iters;

%% Common line specs
% markerSize = 18;
lineWidthAcc = [8];
lineWidthAccUb = [8];
lineWidthTrueErr = [8];
axisLabelFontSize = [60];
axisMarksFontSize = [48];
legendFontSize = [48];
transp = 0.2;

xticks = logspace(-2,2,5);
xlabels = {'10^{-2}','', '10^0', '', '10^2'};
yticks = logspace(0,2,5);
ylabels = {'10^0','','10^1', '', '10^2'};


%% Variable line specs
myColor = {'b','r'};
lineSpec = repmat({{}},2,2,2);
%%%% colors code T_* or T_min %%% DEPRECATED
lineSpec(1,:,:) = repmat({myColor{1}},1,2,2);
lineSpec(2,:,:) = repmat({myColor{2}},1,2,2);
% error is solid for Euclidean prox & dashed for non-Euclidean one
lineSpec(:,1,1) = strcat(lineSpec(:,1,1),'--');
lineSpec(:,1,2) = strcat(lineSpec(:,1,2),'-');
% gap is dotted for Euclidean prox & dash-dotted for non-Euclidean
lineSpec(:,2,1) = strcat(lineSpec(:,2,1),'-.');
lineSpec(:,2,2) = strcat(lineSpec(:,2,2),':');


%% T(SNR)
figure
for a=1:length(algos)
    alg=algos{a};
    if strcmp(alg,'mp'), aIdx = 1; else aIdx = 2; end
    for pr = prxs,
        % find out T(SNR)
        for snrIdx = 1:numel(SNR),
            snr = SNR(snrIdx);
            control.snr = snr;
            respath = [MC_perf_construct_name('./MC_perf_sims/',control) '/'];
            statfile = [respath 'stats-N-' num2str(N) '.mat'];
            load(statfile)
            if aIdx == 1, % MP, acc of the residual
                T_fix(snrIdx) = squeeze(mean_stats.threshold_iter(1,1,a,pr+1));
                T_fix_err(snrIdx) = 2*squeeze(stdev_stats.threshold_iter(1,1,a,pr+1))./sqrt(N);
%                 [~,T_min(snrIdx)] = min(squeeze(mean_stats.true_err_lInf(:,1,a,pr+1)));
            else % FGM, acc of the squared residual
                T_fix(snrIdx) = squeeze(mean_stats.threshold_iter_sq(1,1,a,pr+1));
                T_fix_err(snrIdx) = 2*squeeze(stdev_stats.threshold_iter_sq(1,1,a,pr+1))./sqrt(N);
%                 [~,T_min(snrIdx)] = min(squeeze(mean_stats.true_err_l2(:,1,a,pr+1)));
            end
        end
        % plot T(SNR)
        hl(aIdx,pr+1,1) = boundedline_up(SNR,T_fix,T_fix_err,lineSpec{aIdx,1,pr+1},'transparency',transp);
        hl(aIdx,pr+1,1).LineWidth = lineWidthTrueErr;
        hold on;
%         hl(aIdx,pr+1,1) = plot(SNR,T_min,lineSpec{aIdx,1,pr+1}(2:end),'Linewidth',lineWidthTrueErr);
%         %...'Marker',marker{pr+1},'MarkerFaceColor','w','MarkerSize',markerSize)
%         hold on;
    end
end
alpha 0.6
set(gca,'XScale','log');
set(gca,'YScale','log');
if ifXlab,
    xlabel('SNR','interpreter','latex','fontsize',axisLabelFontSize);
end
if ifYlab,
    ylabel('T$_*$','interpreter','latex','fontsize',axisLabelFontSize);
end
% ylim(rel_acc_ylim);
% ylim([1e0, 1e3]);
% xlim([0 min(1e3,control.iters)]);
ylim([1e0, 1e2]);
set(gca,'FontSize',axisMarksFontSize);
set(gca,'XTick',xticks);
set(gca,'XTickLabel',xlabels);
set(gca,'YTick',yticks);
set(gca,'YTickLabel',ylabels);
set(gca,'XMinorTick','off')
set(gca,'XMinorGrid','off')
set(gca,'YMinorTick','off')
set(gca,'YMinorGrid','off')
grid on
%set(gca,'YTick',[1e-2 1e-1 1 1e1 1e2]);
allLines = flipud(findobj(gca,'Type','line'));
allPossibleLabels = perf_algoLegendNames(algos);
allLabels = allPossibleLabels(1:(ifGaps+1),prxs+1,:);
allLabels = allLabels(:);
l = legend(allLines,allLabels,'Location','southwest');
set(l,'Interpreter','latex','fontsize',legendFontSize);
treat_gcf_complexity(gcf,respath,'complexity',control,outpath);
end

function [] = treat_gcf_complexity(gcf,~,title,control,outpath)
%set(gcf,'PaperPositionMode','Auto');
set(gcf,'defaulttextinterpreter','latex');
set(gcf, 'PaperSize', [11.69 8.27]); % paper size (A4), landscape
% Extend the plot to fill entire paper.
set(gcf, 'PaperPosition', [0 0 11.69 8.27]);
% print('-depsc',[respath title '.eps']);
% Save directly in '../MC_perf_plots/' or control.path
if ~exist('outpath','var'),
    outpath = './MC_perf_plots/';
end
if ~exist(outpath, 'dir'),
  mkdir(outpath);
end
filename = [outpath title '_' 'sce=' control.sce '_p=' num2str(control.p) '_ada=' num2str(control.ada)];
saveas(gcf,[filename '.pdf'],'pdf');
end