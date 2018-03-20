function names = perf_algoLegendNames(algos)
names = repmat({{}},2,2,length(algos));
for a = 1:length(algos)
    if strcmp(algos{a},'mp'),
        names(:,:,a) = repmat({'CMP'},2,2,1);
    else
        names(:,:,a) = repmat({'FGM'},2,2,1);
    end
    names(:,1,a) = strcat(names(:,1,a),'-$\ell_1$'); % Complex l1-setup
    names(:,2,a) = strcat(names(:,2,a),'-$\ell_2$'); % l2-setup
    names(2,:,a) = strcat(names(2,:,a),'-Gap');
end