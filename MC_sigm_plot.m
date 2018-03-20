function [] = MC_sigm_plot(N,dim,~,sce,s,r,noise)
clearvars -except N dim ifPost sce s r noise
format short
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
sce = [sce '-' num2str(s)];
if r > 0,
    sce = [sce '-' num2str(r)];
end
if dim==1,
    respath = ['./sims-sigm/' sce '_' noise '/'];
% elseif dim==2,
%     N=40;
%     if strcmp(exper,'sin'),
%         respath = './sines_sigm-2d/';
%         Sce = [0,1];
%     else
%         respath = './SI_sigm-2d/';
%         Sce = [2];
%     end
else
    error('dim must be 1');
end
statfile = [respath 'stats-N-' num2str(N) '.mat'];
load(statfile)
markerSize = [24 24 18];
lineWidth = [8 8 6];
axisLabelFontSize = [64 64 48];
axisMarksFontSize = [42 42 36];
legendFontSize = [60 60 45];
transp = 0.2;
% figErr = figure;
% figCpu = figure;
% Fig = [figErr, figCpu];
for i = 1:2,
    figure
    if i == 1,
        bl = errorbar(1./SNR,squeeze(mean(methodErr(1,1,1,:,:),5)),...
            2*squeeze(std(methodErr(1,1,1,:,:),1,5))./sqrt(N),'b-'); % AST
    else
        bl = errorbar(1./SNR,squeeze(mean(methodCpu(1,1,1,:,:),5)),...
            2*squeeze(std(methodCpu(1,1,1,:,:),1,5))./sqrt(N),'b-'); % AST
    end
    bl.LineWidth = lineWidth(1);
    hold on
    %     loglog(1./SNR,squeeze(mean(methodErr(2,1,1,:,:),5)),'g-','Marker', 'square', ...
    %         'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'g', 'MarkerSize', 12,...
    %         'LineWidth',3); % l8conk    
    %     hold on
    %     loglog(1./SNR,squeeze(mean(methodErr(3,1,1,:,:),5)),'g-','Marker', 'square', ...
    %         'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'g', 'MarkerSize', 12,...
    %         'LineWidth',3); % l8conk2
    %     hold on
    %     loglog(1./SNR,squeeze(mean(methodErr(4,1,1,:,:),5)),'r-','Marker', 'diamond', ...
    %         'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'r', 'MarkerSize', 12,...
    %         'LineWidth',3); % l2conk
    %     hold on
    if i == 1,
        bl = errorbar(1./SNR,squeeze(mean(methodErr(4,1,1,:,:),5)),...
            2*squeeze(std(methodErr(4,1,1,:,:),1,5))./sqrt(N),'r-'); % fine acc l2conk
    else
        bl = errorbar(1./SNR,squeeze(mean(methodCpu(4,1,1,:,:),5)),...
            2*squeeze(std(methodCpu(4,1,1,:,:),1,5))./sqrt(N),'r-'); % fine acc l2conk
    end
    bl.LineWidth = lineWidth(1);
    hold on
    %     loglog(1./SNR,squeeze(mean(methodErr(5,1,1,:,:),5)),'r-','Marker', 'diamond', ...
    %         'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'r', 'MarkerSize', 12,...
    %         'LineWidth',3); % l2conk2
    %     hold on
    %         bl = errorbar(1./SNR,squeeze(mean(methodErr(6,1,1,:,:),5)),...
    %                 2*squeeze(std(methodErr(6,1,1,:,:),1,5))./sqrt(N),'r-'); % l2penpr
    %                 'Marker', 'diamond',... %'pentagram', ...
    %                 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'r', 'MarkerSize', markerSize(1),...
    %                 'LineWidth', lineWidth(1)); % 10,'LineWidth',3); % l2penpr
    if i == 1,
        bl = errorbar(1./SNR,squeeze(mean(methodErr(9,1,1,:,:),5)),...
            2*squeeze(std(methodErr(9,1,1,:,:),1,5))./sqrt(N),'m-'); % fine acc l2conk
    else
        bl = errorbar(1./SNR,squeeze(mean(methodCpu(9,1,1,:,:),5)),...
            2*squeeze(std(methodCpu(9,1,1,:,:),1,5))./sqrt(N),'m-'); % fine acc l2conk
    end
    bl.LineWidth = lineWidth(1);
    %     loglog(1./SNR,squeeze(mean(methodErr(7,1,1,:,:),5)),'m-.','Marker', 'diamond',... %'hexagram', ...
    %             'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'm', 'MarkerSize', 12, 'LineWidth', 4); % 10,'LineWidth',3); % l2penth
    %         if ifPost,
    %             loglog(1./SNR,squeeze(mean(methodErr(8,1,1,:,:),5)),'m-','Marker', '+',... %'pentagram', ...
    %                     'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'm', 'MarkerSize', markerSize(1),...
    %                     'LineWidth', lineWidth(1));
    %             loglog(1./SNR,squeeze(mean(methodErr(9,1,1,:,:),5)),'g-','Marker', 'o',... %'pentagram', ...
    %                     'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'g', 'MarkerSize', markerSize(1),...
    %                     'LineWidth', lineWidth(1));
    %         end
    alpha 0.6
    set(gca,'XScale','log');
    set(gca,'YScale','log');
    xlim([0.06,4]);
    if i == 1,
        ylim([0.025,1]);
    else
        ylim([1e-3,1e1]);
    end
    xlabel('SNR$^{-1}$','interpreter','latex','fontsize',axisLabelFontSize(1));
    if i == 1,
        yl = ylabel('$\ell_2$-error','interpreter','latex','fontsize',axisLabelFontSize(1));
    else
        yl = ylabel('CPU time (s)','interpreter','latex','fontsize',axisLabelFontSize(1));
    end
    % yl.Color = 'none';
    % if sc == 1 || dim == 2 && sc == 3 && kInd == 1,
    %     yl.Color = 'black';
    % end
    set(gca,'FontSize',axisMarksFontSize(1));
    %set(gca,'XTick', [0.1 0.25 0.5 1 2 4 10]);
    set(gca,'XTick', [0.0625 0.125 0.25 0.5 1 2 4]);
    set(gca,'xtickmode','manual');
    %set(gca,'xtick', [1/32 1/16 1/8 1/4 1/2 1 2 4 8 16]);
    set(gca,'xticklabels', {'0.06','0.12','0.25','0.5','1','2','4'});
    %set(gca,'YTick', [2.5 5 10 20]);
    if i == 1,
        set(gca,'YTick', [0.005 0.01 0.025 0.05 0.1 0.25 0.5 1 2 4]);
        set(gca,'XminorTick','off');
        set(gca,'XMinorGrid','off');
        set(gca,'YminorTick','off');
        set(gca,'YMinorGrid','off');
        l=legend('Lasso','LSR-Coarse','LSR-Fine','Location','southeast');
    else
        gca
        set(gca,'YTick', [1e-3 1e-2 1e-1 1 1e1]);
        set(gca,'XminorTick','off');
        set(gca,'XMinorGrid','off');
        set(gca,'YminorTick','off');
        set(gca,'YMinorGrid','off');
        l=legend('Lasso','LSR-Coarse','LSR-Fine','Location','northeast');
    end
    grid on
    %     if ifPost,
    %         l=legend('Lasso (AST)','Pen. LSR','post','esprit','Location','southeast');
    %     end
    %'Pen. $\ell_2$-recovery, $\lambda_{pract}$','Pen. $\ell_2$-recovery, $\lambda_{theor}$','Location','southeast');
        %'Constrained $\ell_\infty$-recovery','Constrained $\ell_2$-recovery',
    set(l,'Interpreter','latex','fontsize',legendFontSize(1));
    %set(gcf,'PaperPositionMode','Auto');
    set(gcf,'defaulttextinterpreter','latex');
    set(gcf, 'PaperSize', [11.69 8.27]); % paper size (A4), landscape
    % Extend the plot to fill entire paper.
    set(gcf, 'PaperPosition', [0 0 11.69 8.27]);
    respath = ['./plots-sigm/' sce '_' noise '/'];
    if i == 1,
        print('-depsc',[respath 'err_' sce '_' noise '.eps']);
        saveas(gcf,[respath 'err_' sce '_' noise '.pdf'],'pdf');
    else
        print('-depsc',[respath 'cpu_' sce '_' noise '.eps']);
        saveas(gcf,[respath 'cpu_' sce '_' noise '.pdf'],'pdf');
    end
    close(gcf);
end
end