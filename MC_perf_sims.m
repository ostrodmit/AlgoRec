function [] = MC_perf_sims(control,N)
clearvars -except control N
rng(2,'twister'); % initialize random number generator
wb = waitbar(0,'Processing...','WindowStyle','modal','Position',control.wb_pos);
stats = test_performance(control);
fields = fieldnames(stats);
% all_stats = repmat(stats, [1 1 1 N]);
for trial = 1:N,
    stats = test_performance(control);
%     size(stats.abs_err)
    for i = 1:numel(fields),
        all_stats.(fields{i})(:,:,:,:,trial) = stats.(fields{i});
    end
    waitbar(trial/N);
end
close(wb);
%% Compute averages and stdevs
mean_stats = stats;
stdev_stats = stats;
for i = 1:numel(fields)
    mean_stats.(fields{i}) = mean(all_stats.(fields{i}),5);
	stdev_stats.(fields{i}) = std(all_stats.(fields{i}),1,5);
end

%% Save results in a file
respath = [MC_perf_construct_name('./sims-perf/',control) '/'];
if ~exist(respath, 'dir'),
  mkdir(respath);
end
addpath(respath);
statfile = [respath 'stats-N-' num2str(N) '.mat'];
% if exist(statfile, 'file')==2, delete(statfile); end
save(statfile,'all_stats','mean_stats','stdev_stats','-v7.3');
end