function name = MC_perf_construct_name(prefix,control)
base_sce = control.sce(1:6);
if strcmp(base_sce,'RanSin'),
    sce = 'Random';
    s = control.sce(8:end);
elseif strcmp(base_sce,'CohSin'),
    sce = 'Coherent';
    s = num2str(str2num(control.sce(8:end))/2);
end
name = [prefix ...
    'sce=' sce '_s=' s '_p=' num2str(control.p) ... 
    '_ada=' num2str(control.ada) '_snr=' num2str(control.snr)];
%     '/l2_prox-' num2str(control.l2_prox) ...
end
