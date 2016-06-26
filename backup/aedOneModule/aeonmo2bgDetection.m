function [config, store, obs] = aeonmo2bgDetection(config, setting, data)
% aeonmo2bgDetection BGDETECTION step of the expLanes experiment aedOneModule
%    [config, store, obs] = aeonmo2bgDetection(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 15-Apr-2016

% Set behavior for debug mode
if nargin==0, aedOneModule('do', 2, 'mask', {0 1 1 1 2 1}); return; else store=[]; obs=[]; end

%% store
store.xp_settings=data.xp_settings;
store.xp_settings.aedProjects='~/Dropbox/projets/aed/';

%% bg detection

if setting.oracle
    
    [gt_clustering,~,labels,~]=getAnnotation([config.inputPath data.xp_settings.dataset],setting.annotators,data.xp_settings.sounds{data.xp_settings.soundIndex},data.xp_settings.hoptime,size(data.features,2));
    indBg=find(strcmp('bg',labels));
    store.bgDetection=gt_clustering;store.bgDetection(store.bgDetection==indBg)=0;
    store.bgDetection=store.bgDetection>0;
    store.bgDetection=store.bgDetection+1;
    
else
    
    load([store.xp_settings.aedProjects 'bgDetection/' store.xp_settings.sounds{store.xp_settings.soundIndex}])
    store.bgDetection=data_bgDetection.bgDetection;
    
end

[onsets,offsets]=getOnsetsOffsets(store.bgDetection(:)');
store.offsets=offsets(store.bgDetection(onsets)==2);
store.onsets=onsets(store.bgDetection(onsets)==2);
disp('')
