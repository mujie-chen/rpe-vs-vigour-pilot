function fh = revlPlotData(subj_data,dopa_state,sID)
% FUNCTION revlPlotdata(subjects, dataPath)
% 
% Plot the raw behavioural data and smoothed response function for the the
% reversal learning task. 
% 
% subjects = subject ID vector, e.g. [1:2:10] 
% dataPath = full path to directoroy that contains the data
% 
% Hanneke den Ouden 
% Donders Institute for Brain, Cognition and Behaviour
% h.denouden@gmail.com
% 
% version 11-08-2015
%==========================================================================


dopamine  = {'on','off'};


% taskVersion = 2-mod(sID,2); % determine which version of the task they did

% define paths and filenames
% subTag      = sprintf('tutorialRevLearn_%s_s%03.0f',volatility{taskVersion},sID);
% dataFile = fullfile(dataPath,sprintf('%s_data.mat', subTag));
% load(dataFile) % get data

% recode choices so they're 0/1 where 1 is the initially correct
% stimulus
choice = 2-subj_data.chosenDice(:)'; 
smoothingkernel = 6; % average across 7 trials

% blue's schedule, two names
if isfield(subj_data,'diceWin')
    sched = squeeze(subj_data.diceWin);
    if size(sched,1) == 2, sched = sched.'; end % force nTrials x2
else
    g = squeeze(subj_data.diceGood);
    if size(g,1) == 2, g=g.'; end
    sched = 0.3 + 0.4*g;        
end
bluePr = sched(:,1);
redPr = sched(:,2);

% plot everything
fh = figure; box off; hold on;
set(fh,'position', [10 60 700 400],'paperunits','centimeters','paperposition',[0 0 6 6],'Color','w');
title(sprintf('subject %02.0f, %s dopamine',sID,dopamine{dopa_state}));
plot(bluePr,'k-','linewidth',2);
plot(redPr,'r-','linewidth',2);
plot(choice,'k*','markersize',10);
plot(mySmooth(choice,smoothingkernel,[],'backward'),'r:','linewidth',2)
ylabel('probability');
ylim([-0.1 1.1]);
xlabel('trial');
legend({'p(win|blue)','p(win|red)','choice (1=blue)','smoothed choice'},'location','northeastoutside')
legend boxoff

