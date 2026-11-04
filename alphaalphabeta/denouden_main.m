function fitted = denouden_main

% Adapted for two dopamine states by Levi

% ------------------------------------------------------------------------
%
% Tutorial to do simple modelling, associated with the online tutorial and
% dataset for a simple reversal learning tasks with 2 levels of volatility.
%
% Using this code, you can factorially vary whether to
% - simulate data or use real data
% - just visualise the (simulated or real) data or estimate the model
% - plot individual data or data aggregated over subjects
%
% The learning model used is a simple Rescorla-Wagner (Rescorla & Wagner
% 1972) function, using a softmax choice/link/observation function:
%   learning model (RW):     vA <- vA + alpha*(r-vA)
%   choice function (softmax):    p(A) = exp(beta*vA)/(exp(beta*vA)+exp(beta*vB))
%
% The parameter estimation is performed using a grid search. The function
% returns both expected value and maximum likelihood paramer estimates.
%
% Any parameters in the 'modify' section can be altered.
%
%
% Code by Hanneke den Ouden <h.denouden@gmail.com>
% Donders Center for Cognitive Neuroimaging
% Donders Center for Brain, Cognition and Behavior
% Radboud University Nijmegen
%
% version: 11 August 2015
% ------------------------------------------------------------------------


%==========================================================================
%% Section 1: Preparation
%==========================================================================
close all;
load('sanjayLearningBetting_11_PD_onoff.mat');
alldata = sp;

%%%%%%%%%%%%    MODIFY      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subjects        = 1:width(sp);
simulate        = false;    % true if simulate, false if using real data
fitData         = true; 	% if false, we only simulate / plot data
plotIndividual  = false;     % only set to to true if running a small number of individuals!

% If simulating data, specify the parameters you want to use for fitting
if simulate
    simpars.alphaPos = [0.2 0.4 0.6];
    simpars.alphaNeg = [0.2 0.4 0.6];
    simpars.beta  = 1.5;
end

% If fitting data, specify the bounds of the grid, and the number of bins
% that we want to compute.
if fitData
    bounds      = [0 1; % alphaPos
                   0 1; % alphaNeg
                 0 15]; % beta
    nBin        = [20 20 25] ;
end

%%%%%%%%%%%%    MODIFY      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set paths for code we need
tmp = fileparts(which('denouden_main'));
rootdir = tmp(1:end-15); % directory in which you put RL_tutorial_main
addpath(fullfile(rootdir,'alphaalphabeta')); % modelling code
addpath(fullfile(rootdir,'util')); % some helper functions
addpath(fullfile(rootdir,'taskReversalLearn')); % to get the feedback code
% dataPath = fullfile(rootdir,'taskReversalLearn','odata'); % where our data comes from

% set labels that we'll need later on.
% volatility  = {'high','low'};
dopamine = {'on','off'};
paramLabel  = {'alphaPos','alphaNeg','beta'};
nParam      = length(paramLabel);

% if using all subjects
% if strcmp(subjects,'all')
%     subFind = dir(fullfile(dataPath,'*_data*')); % select proper files
%     subFind = {subFind.name};
%     for iSub = 1:numel(subFind)
%         idx = regexp(subFind{iSub},'\d'); % recognise numbers.
%         if idx>0
%             subNr = subFind{iSub}(idx); % select the number
%             subNr = str2double(subNr);
%             subList(iSub) = subNr;
%         end
%     end
%     subjects = sort(subList); % create a final subjectlist
% end

% sort subjects by task condition (high or low volatility);
% highVol = mod(subjects,2)==1;
% sortedsubs{1} = subjects(highVol); % odd
% sortedsubs{2} = subjects(~highVol); % even
% nsubTask = max(sum(highVol),length(subjects)-sum(highVol));
% nTrial = 135;

% sort subjects by dopamine condition;
sortedsubs{1} = subjects; % on
sortedsubs{2} = subjects; % off
nsubTask = width(sp);
nTrial = 257; % accommodate sub 10 who has the max trial no.

%==================================================================
%% Section 2: Simulate data or plot real data
%==================================================================

% initialise variables
score           = nan(2,nsubTask); % top for dopa on, bottom for dopa off
if ~plotIndividual
    fhData = figure('Name','Data');
    set(fhData,'position',[10 60 900 650],'paperunits','centimeters','Color','w');
else
    trialfh = nan(2,nsubTask); % figure handle for individual trialwise plots
end

for dopa_state = 1:2 % we'll do the subjects separately by dopamine
    subj      = 0; % reset subject counter
    choice  = nan(nsubTask,nTrial);
    VV      = nan(nsubTask,nTrial,2); % empty containers for plotting?
    PP      = nan(nsubTask,nTrial);
    
    for sID = sortedsubs{dopa_state}
        subj = subj+1;

        subj_data = alldata{dopa_state,subj};

        % Simulate data
        %==================================================================
        if simulate % TODO
            % Simulate & store data
            [data pout{dopa_state,subj}] = denouden_simulate([simpars.alphaPos simpars.alphaNeg simpars.beta],sID);
            data{dopa_state,sID} = data;
            VV(subj,:,:) = pout{dopa_state,subj}.VV;
            PP(subj,:) = pout{dopa_state,subj}.PP(:,1);

            % Everything below if for plotting only
            choice(subj,:) = 2-alldata{dopa_state,sID}.chosenDice; % convert to 0/1 for plotting
            if plotIndividual
                trialfh(dopa_state,subj) = figure; box off; hold on;
                set(trialfh(dopa_state,subj),'position', [10 60 700 400],'paperunits','centimeters','paperposition',[0 0 6 6],'Color','w');
                plot(data.prep.feedbackprob,'k','linewidth',2)
                plot(pout{dopa_state,subj}.PP(:,1),'b-','linewidth',2)
                plot(pout{dopa_state,subj}.VV(:,1),':','color',[.4 0.4 1],'linewidth',2)
                plot(pout{dopa_state,subj}.VV(:,2),':','color',[1 .35 0.1],'linewidth',2)
                plot(2-pout{dopa_state,subj}.data.choice,'k*')
                legend({'p(reward|blue)','p(choose blue)','value(blue)','value(orange)',...
                    'choice'},'location','northeastoutside');
                legend boxoff
                ylabel('probability');
                ylim([-0.1 1.1]);
                xlabel('trial');
                title(sprintf('simulated data, alphaPos = %0.02f, alphaNeg = %0.02f, beta = %02.01f',...
                    simpars.alphaPos, simpars.alphaNeg, simpars.beta));
            end

            % ... or load and plot real data
            %==============================================================
        else
            if plotIndividual
                trialfh(dopa_state,subj)= revlPlotData(subj_data,dopa_state,sID);
            end
            
            % skip scoring for now
            % % locate index per subject, they have unequal trials in dopa on and off
            % numsubTrials = width(subj_data.trialIndex);
            % 
            % % convert to 0/1 for plotting (den ouden)
            % % before: 1: blue, 2: red (sanjay); after: 1: blue, 0: red
            % choice(subj,1:numsubTrials) = 2-alldata{dopa_state,sID}.chosenDice;
            % 
            % % accuracy
            % % score(dopa_state,subj) = (sum(choice(subj,data.prep.feedbackprob==data.prep.prob)==1)... % blue when blue is correct
            % %    +sum(choice(subj,data.prep.feedbackprob==(1-data.prep.prob))==0))/data.prep.nt; % orange when orange is correct
            % 
            % dw = squeeze(alldata{dopa_state,sID}.diceWin); % !! DOESNT WORK sID 2 onward changes diceWin's fieldname
            % strictly_has_better = dw(:,1) ~= dw(:,2); % ignore equal probability cases
            % 
            % correctChoice = strictly_has_better & alldata{dopa_state,sID}.chosenWinProb(:) == 0.7; % selecting high option when 1 is strictly higher
            % score(dopa_state,subj) = sum(correctChoice) / sum(strictly_has_better);
            % 
            % % !! TODO: what is a good bet?
            % rich = ~strictly_has_better & dw(1,:) == 0.7; % 70/70
            % lean = ~strictly_has_better & dw(1,:) == 0.3; % 30/30
            % 
            % % betting high when rich, and low when lean
            % % bets are in chosenBet, 1/2/5/10/20 stored as 1-5
        end

    end % individual subject
    
    % plot the data averaged across all subjects, for each dopa_state separately if not plotting
    % individuals
    %==============================================================
    if ~plotIndividual
        figure(fhData)
        subplot(2,1,dopa_state);hold on
        plot(dw(1,:),'k:','linewidth',2)
        plot(nanmean(choice,1),'k-','linewidth',1)
        if simulate
            plot(mean(PP,1),'b-','linewidth',2)
            plot(mean(squeeze(VV(:,:,1)),1),':','color',[.4 0.4 1],'linewidth',2)
            plot(mean(squeeze(VV(:,:,2)),1),':','color',[1 .35 0.1],'linewidth',2)
            legend({'p(reward|blue)','mean choice (blue)','p(choose blue)','value(blue)','value(orange)',...
                },'location','northeastoutside');
            title(sprintf('MEAN data, %s dopamine, alphaPos = %0.02f, alphaNeg = %0.02f beta = %02.01f',...
                dopamine{dopa_state},simpars.alphaPos,simpars.alphaNeg,simpars.beta));
        else
            legend({'p(reward|blue)','mean choice (blue)'},'location','northeastoutside');
            title(sprintf('MEAN data, %s dopamine',dopamine{dopa_state}));
        end
        legend boxoff
        ylabel('probability');
        ylim([0 1]);
        xlabel('trial');
        ylabel('probability');
    end % if plotting group
end % dopa_state

% % plot the scores
% % if run to error, run internal block for dopa_state = 2, sID = 1, subj = 1, gives single plot of subject 1 on and off dopamine
% if ~plotIndividual
%     fhScore = figure('Name','score');set(fhScore,'position',[10 60 250 400],'paperunits','centimeters',...
%         'paperposition',[0 0 6 6],'Color','w');
%     barScatter(score,[],dopamine,true);
%     set(gca,'xtick',1:2,'xticklabel',dopamine);
%     xlabel('dopamine');
%     ylabel('p(correct)');
%     title('correct choice')
%     hline(.5,'w:');
%     ylim([0 1])
%     box off
% end

%==========================================================================
%% Section 3.
% Do a grid search to compute the likelihood functions of the
% parameters, within prespecified bounds
%==========================================================================
if fitData
    if size(bounds,1)~=nParam
        error('number of bounds and parameters don''t match')
    end
    
    % Initialise the output matrices for the fitted parameters.
    fitted.alphaPos.pdf    = nan(2,nsubTask,nBin(1)); % expand alpha, ml and ev
    fitted.alphaNeg.pdf    = nan(2,nsubTask,nBin(2));
    fitted.beta.pdf        = nan(2,nsubTask,nBin(3));
    fitted.alphaPos.ml     = nan(2,nsubTask);
    fitted.alphaNeg.ml     = nan(2,nsubTask);
    fitted.beta.ml         = nan(2,nsubTask);
    fitted.alphaPos.ev     = nan(2,nsubTask);
    fitted.alphaNeg.ev     = nan(2,nsubTask);
    fitted.beta.ev         = nan(2,nsubTask);
    
    % open some figures
    fhParamPDF = figure('Name','parameter PDF');
    set(fhParamPDF,'position',[10 60 650 650],'paperunits','centimeters','Color','w');
    if plotIndividual
        fhGrid{1} = figure('Name','Likelihoods dopamine on');
        set(fhGrid{1},'position',[10 60 650 650],'paperunits','centimeters','Color','w');
        fhGrid{2} = figure('Name','Likelihoods dopamine off');
        set(fhGrid{2},'position',[10 60 650 650],'paperunits','centimeters','Color','w');
        
    else
        fhParBar = figure('Name','Parameter estimates');
        set(fhParBar,'position',[10 60 650 650],'paperunits','centimeters','Color','w');
    end
    
    % Do the actual grid search
    % =========================================================================
    if simulate % compute where the stimulated alpha and beta are in binspace
        simAlphaPos_bin = simpars.alphaPos/bounds(1,2)*nBin(1);
        simAlphaNeg_bin = simpars.alphaNeg/bounds(2,2)*nBin(2);
        simBeta_bin = simpars.beta/bounds(3,2)*nBin(3);
    end
    
    for dopa_state = 1:2
        subj = 0; % subject x dopa_state counter
        for sID = sortedsubs{dopa_state}
            subj = subj+1;
            subj_data = alldata{dopa_state,sID};
            
            % range
            for iParam = 1:nParam
                range = linspace(bounds(iParam,1),bounds(iParam,2),nBin(iParam)+1); % e.g. start, stop, step
                p{iParam} = range(2:end); % stay just off the zero bounds
            end
            
            % params = nan(1,2);
            % for t = 1:nBin(1)
            %     params(1) = p{1}(t);
            %     for tt = 1:nBin(2)
            %         params(2) = p{2}(tt);
            %         [loglik(t,tt), foo]= denouden_fitmodel(params,data);
            %     end
            % end
            
            % fitting
            loglik = nan(nBin(1),nBin(2),nBin(3));
            for t = 1:nBin(1)
                for tt = 1:nBin(2)
                    for ttt = 1:nBin(3)
                        loglik(t,tt,ttt) = denouden_fitmodel([p{1}(t) p{2}(tt) p{3}(ttt)], subj_data);
                    end
                end
            end

            % log p is negative, bigger is better
            % max(loglik(:)) - min(loglik(:))
            
            lik = exp(loglik - max(loglik(:))); % remove max, compute likelihood

            % compute the marginal likelihoods for each parameter: for
            % alpha, sum the likelihoods across all bins of beta, and  for
            % beta, sum the likelihoods across all bins of alpha. Then to
            % compute the probability density, normalise by dividing by the sum
            % of the likelihoods for each parameter.

            % for x = 1:nParam
            %     tmp = sum(lik,3-x);
            %     marglik{x} = tmp/sum(tmp);
            % end

            for x = 1:nParam
                tmp = lik;
                % if x = 2, sum dimensions 1 and 3 of tmp, etc.
                for d = setdiff(1:nParam, x), tmp = sum(tmp, d); end 
                tmp = tmp(:);
                marglik{x} = tmp/sum(tmp); % normalise
            end
            
            % plot the likelihood landscape with the maximum and true
            % value (latter for simulations only), for each individual
            % =============================================================
            
            ML(1) = myvect(p{1}(max(marglik{1})==marglik{1})); % largest parameter value
            ML(2) = myvect(p{2}(max(marglik{2})==marglik{2}));
            ML(3) = myvect(p{3}(max(marglik{3})==marglik{3}));
            EV(1) = sum(p{1}(:).*marglik{1}(:)); % weighted mean
            EV(2) = sum(p{2}(:).*marglik{2}(:));
            EV(3) = sum(p{3}(:).*marglik{3}(:));

            % trial-wise VV (value estimate) and PP (predicted choice probability) based on ML and EV
            [~, poutEst{dopa_state,subj,1}]= denouden_fitmodel(ML,subj_data); 
            [~, poutEst{dopa_state,subj,2}]= denouden_fitmodel(EV,subj_data);
            
            if plotIndividual
                % plot the grid
                figure(fhGrid{dopa_state});
                dims = ceil(sqrt(length(sortedsubs{dopa_state})));
                subplot(dims, dims,subj);
                imagesc(lik); hold on;
                
                [maxalpha maxbeta] = find(lik==max(lik(:)));
                hline(maxalpha, {'w-', 'LineWidth', 2});
                vline(maxbeta, {'w-', 'LineWidth', 2});
                
                if simulate
                    plot(simBeta_bin*ones(1,2),[simAlpha_bin-.75 simAlpha_bin+.75],'-','color',[0.4 0.4 0.4],'linewidth',3);
                    plot([simBeta_bin-.75 simBeta_bin+.75],simAlpha_bin*ones(1,2),'-','color',[0.4 0.4 0.4],'linewidth',3);
                end
                hold off
                
                title(sprintf('p(data|model), sub %03.0f, %s vol.',sID,dopamine{dopa_state}));
                ytick = 0:nBin(1)/5:nBin(1);
                xtick = 0:nBin(2)/5:nBin(2);
                yticklabel = num2cell(bounds(1,1):diff(bounds(1,:)/5):bounds(1,2));
                xticklabel = num2cell(bounds(2,1):diff(bounds(2,:)/5):bounds(2,2));
                set(gca,'ytick',ytick,'yticklabel',yticklabel,'xtick',xtick,'xticklabel',xticklabel)
                ylabel(paramLabel{1}); xlabel(paramLabel{2})
                
                % add the estimated choice probability to the plot
                figure(trialfh(dopa_state,subj)); hold on;
                plot(poutEst{dopa_state,subj,2}.PP(:,1),'color',[0 .55 .55],'linewidth',2);
                leg{end+1} = 'est. p(choose blue)';
                legend(leg,'location','northeastoutside');
                
                % If simulating data, plot the correlation the recovered choice probabilities
                % and the actual choice probabilities
                if simulate;
                    psim = pout{dopa_state,subj}.PP(:,1);
                    hfig = figure;set(hfig,'position',[10 60 500 500],'Color','w'); box off;
                    [foo,foo,h(1)] = myScatter(psim,poutEst{dopa_state,subj,1}.PP(:,1),false,[0 0 1],'x');
                    [foo,foo,h(2)] = myScatter(psim,poutEst{dopa_state,subj,2}.PP(:,1),false,[1 0 0],'o');
                    h(3) = plot([0 1],[0 1],'k:','linewidth',2);
                    legend(h(1:2),{'Maximum Likelihood','Expected Value'},'location','best');legend boxoff
                    xlim([0 1]); ylim([0 1]);
                    xlabel('p(blue) - true'); ylabel ('p(blue) - estimated');
                    title('true vs. estimated choice probability');
                end
                
            end
            % - store the marginal likelihoods across subjects, sorted by dopa_state
            % - for each parameter, compute the peak (= maximum likelihood) and
            % the mean ('expected value', i.e. sum over all bins of (value(bin)
            % * likelihood(bin))
            
            fitted.alphaPos.pdf(dopa_state,subj,:) = marglik{1};
            fitted.alphaNeg.pdf(dopa_state,subj,:) = marglik{2};
            fitted.beta.pdf(dopa_state,subj,:)     = marglik{3};
            fitted.alphaPos.ml(dopa_state,subj) = ML(1);
            fitted.alphaNeg.ml(dopa_state,subj) = ML(2);
            fitted.beta.ml(dopa_state,subj)     = ML(3);
            fitted.alphaPos.ev(dopa_state,subj) = EV(1);
            fitted.alphaNeg.ev(dopa_state,subj) = EV(2);
            fitted.beta.ev(dopa_state,subj)     = EV(3);
        end % subject

        fitted(dopa_state,:) = fitted;
        
        % PLOT posterior densities
        % parameter grids, matching p{1} and p{2} in the search above
        % aGrid = linspace(bounds(1,1),bounds(1,2),nBin(1)+1); aGrid = aGrid(2:end);
        % bGrid = linspace(bounds(2,1),bounds(2,2),nBin(2)+1); bGrid = bGrid(2:end);
        
        aPosGrid = linspace(bounds(1,1),bounds(1,2),nBin(1)+1); aPosGrid = aPosGrid(2:end);
        aNegGrid = linspace(bounds(2,1),bounds(2,2),nBin(2)+1); aNegGrid = aNegGrid(2:end);
        bGrid    = linspace(bounds(3,1),bounds(3,2),nBin(3)+1); bGrid    = bGrid(2:end);

        figure(fhParamPDF);

        % plot posterior density of alphaPos across all subjects
        subplot(3,2,dopa_state); hold on;
        plot(aPosGrid, squeeze(fitted.alphaPos.pdf(dopa_state,:,:))');
        title(sprintf('%s dopamine, alphaPos PDF',dopamine{dopa_state}))
        xlabel(paramLabel{1}); ylabel('p(data|m)');
        xlim(bounds(1,:)); box off;
        if simulate; vline(simpars.alphaPos,'k:'); end

        % plot posterior density of alphaNeg across all subjects
        subplot(3,2,dopa_state+2); hold on;
        plot(aNegGrid, squeeze(fitted.alphaNeg.pdf(dopa_state,:,:))');
        title(sprintf('%s dopamine, alphaNeg PDF',dopamine{dopa_state}))
        xlabel(paramLabel{2}); ylabel('p(data|m)');
        xlim(bounds(2,:)); box off;
        if simulate; vline(simpars.alphaNeg,'k:'); end

        % plot posterior density of beta across all subjects
        subplot(3,2,dopa_state+4); hold on;
        plot(bGrid, squeeze(fitted.beta.pdf(dopa_state,:,:))');
        title(sprintf('%s dopamine, beta PDF',dopamine{dopa_state}))
        xlabel(paramLabel{3}); ylabel('p(data|m)');
        xlim(bounds(3,:)); box off;
        if simulate; vline(simpars.beta,'k:'); end
        
    end % dopa_state
    
    if ~plotIndividual
        
        figure(fhParBar);
        
        % plot barplots of the max and EV for alphaPos
        subplot(3,2,1); barScatter(fitted.alphaPos.ml,[],dopamine,true); box off;
        if simulate; hold on; scatter(1:2,simpars.alphaPos*ones(1,2),'go','filled');hold off; end
        xlabel('dopamine');
        ylabel('alphaPos (max. likelihood)');
        title('alphaPos - max likelihood');
        ylim([bounds(1,1) bounds(1,2)])
        
        subplot(3,2,2); barScatter(fitted.alphaPos.ev,[],dopamine,true); box off;
        if simulate; hold on; scatter(1:2,simpars.alphaPos*ones(1,2),'go','filled');hold off; end
        xlabel('dopamine');
        ylabel('alphaPos (expected value)');
        title('alphaPos - expected value');
        ylim([bounds(1,1) bounds(1,2)])

        % plot barplots of the max and EV for alphaNeg
        subplot(3,2,3); barScatter(fitted.alphaNeg.ml,[],dopamine,true); box off;
        if simulate; hold on; scatter(1:2,simpars.alphaNeg*ones(1,2),'go','filled');hold off; end
        xlabel('dopamine');
        ylabel('alphaNeg (max. likelihood)');
        title('alphaNeg - max likelihood');
        ylim([bounds(2,1) bounds(2,2)])

        subplot(3,2,4); barScatter(fitted.alphaNeg.ev,[],dopamine,true); box off;
        if simulate; hold on; scatter(1:2,simpars.alphaNeg*ones(1,2),'go','filled');hold off; end
        xlabel('dopamine');
        ylabel('alphaNeg (expected value)');
        title('alphaNeg - expected value');
        ylim([bounds(2,1) bounds(2,2)])
        
        % plot barplots of the max and EV for beta
        subplot(3,2,5); barScatter(fitted.beta.ml,[],dopamine,true); box off;
        if simulate; hold on; scatter(1:2,simpars.beta*ones(1,2),'go','filled');hold off; end
        xlabel('dopamine');
        ylabel('beta (max. likelihood)');
        title('beta - max likelihood');
        ylim([bounds(3,1) bounds(3,2)])
        
        subplot(3,2,6); barScatter(fitted.beta.ev,[],dopamine,true); box off;
        if simulate; hold on; scatter(1:2,simpars.beta*ones(1,2),'go','filled');hold off; end
        xlabel('dopamine');
        ylabel('beta (expected value)');
        title('beta - expected value');
        ylim([bounds(3,1) bounds(3,2)])
        
        % add the trial-wise choice probabilities across subjects to the probability plots
        if ~simulate
            figure(fhData)
            for dopa_state = 1:2
                nsub = length(sortedsubs{dopa_state});
                tmp = nan(nsub,nTrial);
                for isub = 1:nsub
                    tmp(isub,:)= poutEst{dopa_state,isub,2}.PP(:,1);
                end
                mu = mean(tmp,1);
                b = nan(nTrial,1,1);
                b(:,1,1) = std(tmp,[],1);
                subplot(2,1,dopa_state);hold on
                boundedline(1:nTrial,mu,b,'alpha','cmap',[0 .55 .55])
                leg{end+1} = 'estimated p(choice)';
                legend(leg,'location','northeastoutside');
                legend boxoff
            end
        end
    end
end

asym = log(fitted.alphaPos.ev./(1-fitted.alphaPos.ev)) - log(fitted.alphaNeg.ev./(1-fitted.alphaNeg.ev)); % logit difference
[h, pval, ~, stats] = ttest(asym(1,:), asym(2,:));

%==========================================================================
%% Section 4. Will be implemented in future versions
% Compute how good the model is: compute the likelihood, perhaps even plot
% trial-by-trial likelihood: what sort of trials can we explain well vs
% not? Can you think of other models and do model comparison?
%==========================================================================


diffs = fitted.alphaPos



