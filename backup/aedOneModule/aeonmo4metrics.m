function [config, store, obs] = aeonmo4metrics(config, setting, data)
% aeonmo4metrics METRICS step of the expLanes experiment aedOneModule
%    [config, store, obs] = aeonmo4metrics(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 15-Apr-2016

% Set behavior for debug mode
if nargin==0, aedOneModule('do', 4, 'mask', {0 1 0 0 2 2 [4] 2 3 1}); return; else store=[]; obs=[]; end

annotators={'bdm','sid'};
disp('')
xx=1;

for jj=1:length(data)
    
    for pp=1:length(annotators)
        %% load annotation
        GTFile=[config.inputPath data(jj).xp_settings.dataset 'annotation/' data(jj).xp_settings.sounds{data(jj).xp_settings.soundIndex} '_' annotators{pp} '.txt'];
        [target.onsets,target.offsets,target.classNames] = loadEventsList(GTFile);
        
        prediction.onsets=data(jj).nmat(:,1);
        prediction.offsets=data(jj).nmat(:,2);
        prediction.classNames=arrayfun(@(x) data(jj).classes{x},data(jj).nmat(:,3),'uniformoutput',false);
        
        [resultsEB] = eventDetectionMetrics_eventBased(prediction,target);
        [resultsCWEB] = eventDetectionMetrics_classWiseEventBased(prediction,target,data(jj).classes);
        [resultsFB,eventRoll,eventRollGT] = eventDetectionMetrics_frameBased(prediction,target,data(jj).classes);
        
        figure(1)
        subplot 211
        imagesc(eventRoll')
        set(gca,'ytick',1:length(data(jj).classes),'yticklabel',data(jj).classes)
        subplot 212
        imagesc(eventRollGT')
        set(gca,'ytick',1:length(data(jj).classes),'yticklabel',data(jj).classes)
        disp('')
        
        obs.F_fb(xx)=resultsFB.F;
        obs.F_cweb(xx)=resultsCWEB.F;
        obs.F_eb(xx)=resultsEB.F;
        xx=xx+1;
    end
    
end