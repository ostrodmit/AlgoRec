function [] = MC_perf_plot(control,N,ifGaps,ifConf,ifTrueErr,outpath,exp,ifXlab,ifYlab,ifSq)
%% Input params
% N: number of trials (to choose statfile)
% ifGaps: whether to draw upper bounds
% ifConf: whether to draw confidence bounds
close all
clearvars -except control N ifGaps ifConf ifTrueErr outpath exp ifXlab ifYlab ifSq
format short
respath = [MC_perf_construct_name('./sims-perf/',control) '/'];
statfile = [respath 'stats-N-' num2str(N) '.mat'];
load(statfile)
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
lineWidthAcc = [8 8 8];
lineWidthAccUb = [8 8 8];
lineWidthTrueErr = [8 8 8];
axisLabelFontSize = [60 60 60];
axisMarksFontSize = [48 48 48];
legendFontSize = [48 48 48];
transp = 0.2;

xticks = logspace(0,3,10);
xlabels = {'1','', '', '10^1', '', '', '10^2', '', '', '10^3'};
yticks = logspace(-4,3,8);
ylabels = {'10^{-4}','10^{-3}','10^{-2}','10^{-1}','10^{0}','10^{1}','10^{2}','10^{3}'};

%% Variable line specs
myColor = {'b','r'};
lineSpec = repmat({{}},2,2,2);
for alg = algos
    if strcmp(alg,'mp'), aIdx = 1; else aIdx = 2; end
    lineSpec(aIdx,:,:) = repmat({myColor{aIdx}},1,2,2);
end
% error is solid for Euclidean prox & dashed for non-Euclidean one
lineSpec(:,1,1) = strcat(lineSpec(:,1,1),'--');
lineSpec(:,1,2) = strcat(lineSpec(:,1,2),'-');
% gap is dotted for Euclidean prox & dash-dotted for non-Euclidean
lineSpec(:,2,1) = strcat(lineSpec(:,2,1),'-.');
lineSpec(:,2,2) = strcat(lineSpec(:,2,2),':');

% % 'diamond for Non-Euclidean prox, 'o' for Euclidean one
% marker = repmat({{}},2,1);
% marker{1} = 'diamond';
% marker{2} = 'o';

%% Absolute accuracy
figure
A = 1:length(algos);
if ifSq,
    A = 2; % only 'nes'
end
for a = A,
    alg = algos{a};
    if strcmp(alg,'mp'), aIdx = 1; else aIdx = 2; end
    for pr = prxs,
        % error
        if ~ifSq,
            fun = squeeze(mean_stats.abs_acc(1:iters,1,a,pr+1));
            bnd = 2*squeeze(stdev_stats.abs_acc(1:iters,1,a,pr+1))./sqrt(N);
        else
            fun = squeeze(mean_stats.abs_acc_sq(1:iters,1,a,pr+1));
            bnd = 2*squeeze(stdev_stats.abs_acc_sq(1:iters,1,a,pr+1))./sqrt(N);
        end
        if ifConf,
            hl(aIdx,pr+1,1) = boundedline_up(1:iters,fun,bnd,lineSpec{aIdx,1,pr+1},'transparency',transp); 
            hl(aIdx,pr+1,1).LineWidth = lineWidthAcc(exp);
        else
            hl(aIdx,pr+1,1) = plot(1:iters,fun,lineSpec{aIdx,1,pr+1},'Linewidth',lineWidthAcc(exp));
            %...'Marker',marker{pr+1},'MarkerFaceColor','w','MarkerSize',markerSize)
        end
        hold on;
        if ifGaps,
            % gap
            if ~ifSq,
                fun = squeeze(mean_stats.abs_acc_ub(1:iters,1,a,pr+1));
            else
                fun = squeeze(mean_stats.abs_acc_sq_ub(1:iters,1,a,pr+1));
            end
            hl(aIdx,pr+1,2) = plot(1:iters,fun,lineSpec{aIdx,2,pr+1},'Linewidth',lineWidthAccUb(exp));
            %...'Marker',marker{pr+1},'MarkerFaceColor','w','MarkerSize',markerSize)
            hold on;
        end
    end
end
alpha 0.6
set(gca,'XScale','log');
set(gca,'YScale','log');
if ifXlab,
    xlabel('Iteration','interpreter','latex','fontsize',axisLabelFontSize(exp));
end
if ifYlab,
    ylabel('Absolute accuracy','interpreter','latex','fontsize',axisLabelFontSize(exp));
end
%axis([0 1e4 1e-2 1e2]);
abs_acc_ylim = ylim;
xlim([0 min(1e3,control.iters)]);
set(gca,'FontSize',axisMarksFontSize(exp));
set(gca,'XTick',xticks);
set(gca,'XTickLabel',xlabels);
set(gca,'YTick',yticks);
set(gca,'YTickLabel',ylabels);
set(gca,'XMinorTick','off');
set(gca,'XMinorGrid','off');
set(gca,'YMinorTick','off');
set(gca,'YMinorGrid','off');
%set(gca,'YTick',[1e-2 1e-1 1 1e1 1e2]);
grid on
allLines = flipud(findobj(gca,'Type','line'));
if ~ifSq
    allPossibleLabels = perf_algoLegendNames(algos);
else
    allPossibleLabels = perf_algoLegendNames({'nes'});
end
allLabels = allPossibleLabels(1:(ifGaps+1),prxs+1,:);
% allLabels = allPossibleLabels(1,prxs+1,:); % no gaps
allLabels = allLabels(:);
l = legend(allLines,allLabels,'Location','southwest');
if length(allLines) == 4,
    l=legend([allLines(1) allLines(3)],[allLabels(1) allLabels(3)],'Location','southwest');
end
set(l,'Interpreter','latex','fontsize',legendFontSize(exp));
if ~ifSq,
    treat_gcf(gcf,respath,'abs_acc',control,outpath);
else
    treat_gcf(gcf,respath,'abs_acc_sq',control,outpath);
end

%% Relative accuracy
figure
for a = A,
    alg = algos{a};
    if strcmp(alg,'mp'), aIdx = 1; else aIdx = 2; end
    for pr = prxs,
        % error
        if ~ifSq,
            fun = squeeze(mean_stats.rel_acc(1:iters,1,a,pr+1));
            bnd = 2*squeeze(stdev_stats.rel_acc(1:iters,1,a,pr+1))./sqrt(N);
        else
            fun = squeeze(mean_stats.rel_acc_sq(1:iters,1,a,pr+1));
            bnd = 2*squeeze(stdev_stats.rel_acc_sq(1:iters,1,a,pr+1))./sqrt(N);
        end
        if ifConf,
            hl(aIdx,pr+1,1) = boundedline_up(1:iters,fun,bnd,lineSpec{aIdx,1,pr+1},'transparency',transp);
            hl(aIdx,pr+1,1).LineWidth = lineWidthAcc(exp);
        else
            hl(aIdx,pr+1,1) = plot(1:iters,fun,lineSpec{aIdx,1,pr+1},'Linewidth',lineWidthAcc(exp));
                %...'Marker',marker{pr+1},'MarkerFaceColor','w','MarkerSize',markerSize)
        end
        hold on;
        if ifGaps,
            % gap
            if ~ifSq,
                fun = squeeze(mean_stats.rel_acc_ub(1:iters,1,a,pr+1));
            else
                fun = squeeze(mean_stats.rel_acc_sq_ub(1:iters,1,a,pr+1));
            end
            hl(aIdx,pr+1,2) = plot(1:iters,fun,lineSpec{aIdx,2,pr+1},'Linewidth',lineWidthAccUb(exp));
                %...'Marker',marker{pr+1},'MarkerFaceColor','w','MarkerSize',markerSize)
            hold on;
        end
    end
end
alpha 0.6
set(gca,'XScale','log');
set(gca,'YScale','log');
if ifXlab,
    xlabel('Iteration','interpreter','latex','fontsize',axisLabelFontSize(exp)); 
end
if ifYlab,
    ylabel('Relative accuracy','interpreter','latex','fontsize',axisLabelFontSize(exp));
end
% Rel_err_ub = mean_stats.rel_err_ub(:,:,:,:);
rel_acc_ylim = ylim;
xlim([0 min(1e3,control.iters)]);
set(gca,'FontSize',axisMarksFontSize(exp));
set(gca,'XTick',xticks);
set(gca,'XTickLabel',xlabels);
set(gca,'XMinorTick','off');
set(gca,'XMinorGrid','off');
set(gca,'YMinorTick','off');
set(gca,'YMinorGrid','off');
if (exp == 1 || exp == 2),
    ylim([1e-4 1e2]);
    yticksHere = logspace(-4,2,7);
    ylabelsHere = {'10^{-4}','','10^{-2}','','10^{0}','','10^{2}'};
    set(gca,'YTick',yticksHere);
    set(gca,'YTickLabel',ylabelsHere);
end
% set(gca,'YTick',[1e-2 1e-1 1 1e1 1e2]);
grid on
allLines = flipud(findobj(gca,'Type','line'));
l=legend(allLines,allLabels,'Location','southwest');
if length(allLines) == 4,
    l=legend([allLines(1) allLines(3)],[allLabels(1) allLabels(3)],'Location','southwest');
end
set(l,'Interpreter','latex','fontsize',legendFontSize(exp));
if ~ifSq,
    treat_gcf(gcf,respath,'rel_acc',control,outpath);
else
    treat_gcf(gcf,respath,'rel_acc_sq',control,outpath);
end

if ~ifTrueErr,
    return
end

%% True error
figure
for a = A,
    alg = algos{a};
    if strcmp(alg,'mp'), aIdx = 1; else aIdx = 2; end
    for pr = prxs,
        % error
        if ifConf,
            hl(aIdx,pr+1,1) = boundedline_up(1:iters,...
                squeeze(mean_stats.true_err(1:iters,1,a,pr+1)),...
                2*squeeze(stdev_stats.true_err(1:iters,1,a,pr+1))./sqrt(N),...
                lineSpec{aIdx,1,pr+1}(2:end),'transparency',transp); 
            hl(aIdx,pr+1,1).LineWidth = lineWidthTrueErr(exp);
        else
            hl(aIdx,pr+1,1) = plot(1:iters,...
                squeeze(mean_stats.true_err(1:iters,1,a,pr+1)),...
                lineSpec{aIdx,1,pr+1}(2:end),'Linewidth',lineWidthTrueErr(exp));
            %...'Marker',marker{pr+1},'MarkerFaceColor','w','MarkerSize',markerSize)
        end
        hold on;
    end
end
alpha 0.6
set(gca,'XScale','log');
set(gca,'YScale','log');
if ifXlab,
    xlabel('Iteration','interpreter','latex','fontsize',axisLabelFontSize(exp));
end
if ifYlab,
    ylabel('True error','interpreter','latex','fontsize',axisLabelFontSize(exp));
end
% ylim(rel_acc_ylim);
ylim([1e0, 1e3]);
xlim([0 min(1e3,control.iters)]);
set(gca,'FontSize',axisMarksFontSize(exp));
set(gca,'XTick',xticks);
set(gca,'XTickLabel',xlabels);
set(gca,'YTick',yticks);
set(gca,'YTickLabel',ylabels);
set(gca,'XMinorTick','off');
set(gca,'XMinorGrid','off');
set(gca,'YMinorTick','off');
set(gca,'YMinorGrid','off');
%set(gca,'YTick',[1e-2 1e-1 1 1e1 1e2]);
grid on
allLines = flipud(findobj(gca,'Type','line'));
allPossibleLabels = perf_algoLegendNames(algos);
allLabels = allPossibleLabels(1:(ifGaps+1),prxs+1,:);
allLabels = allLabels(:);
l = legend(allLines,allLabels,'Location','southwest');
set(l,'Interpreter','latex','fontsize',legendFontSize(exp));
treat_gcf(gcf,respath,'true_err',control,outpath);
end

function [] = treat_gcf(gcf,respath,title,control,outpath)
%set(gcf,'PaperPositionMode','Auto');
set(gcf,'defaulttextinterpreter','latex');
set(gcf, 'PaperSize', [11.69 8.27]); % paper size (A4), landscape
savefig(gcf,[respath title '.fig']);
% Extend the plot to fill entire paper.
set(gcf, 'PaperPosition', [0 0 11.69 8.27]);
print('-depsc',[respath title '.eps']);
saveas(gcf,[respath title '.pdf'],'pdf');
% Also save directly in '../MC_perf_plots/' or control.path
if ~exist('outpath','var'),
    outpath = './MC_perf_plots/';
end
if ~exist(outpath, 'dir'),
  mkdir(outpath);
end
filename = MC_perf_construct_name([outpath title '_'],control);
saveas(gcf,[filename '.pdf'],'pdf');
end