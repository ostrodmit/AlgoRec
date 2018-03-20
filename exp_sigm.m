function [] = exp_sigm(N,reproduce)
clearvars -except N reproduce
% reproduce = 0: only draw plots
% reproduce = 1: first reproduce the experiments
if nargin < 2, 
    reproduce = 0;
end
if nargin < 1,
    N = 10; % number of Monte-Carlo trials
end
s1 = 4;
s2 = 2;
r1 = 2;
r2 = 4;
noises = {'white'};
% noises = {'white','colored'};

if reproduce == 1,
    for i = 1:length(noises),
        noise = noises{i};
        MC_sigm_sims(N,1,0,'ModSin',s1,r1,noise);
        MC_sigm_sims(N,1,0,'ModSin',s1,r2,noise);
        MC_sigm_sims(N,1,0,'RanSin',s1,0,noise);
        MC_sigm_sims(N,1,0,'CohSin',s2,0,noise);
    end
end

for i = 1:length(noises),
    noise = noises{i};
    MC_sigm_plot(N,1,0,'ModSin',s1,r1,noise);
    MC_sigm_plot(N,1,0,'ModSin',s1,r2,noise);
    MC_sigm_plot(N,1,0,'RanSin',s1,0,noise);
    MC_sigm_plot(N,1,0,'CohSin',s2,0,noise);
end

end