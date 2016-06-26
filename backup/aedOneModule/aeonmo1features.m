function [config, store, obs] = aeonmo1features(config, setting, data)             
% aeonmo1features FEATURES step of the expLanes experiment aedOneModule            
%    [config, store, obs] = aeonmo1features(config, setting, data)                 
%      - config : expLanes configuration state                                     
%      - setting   : set of factors to be evaluated                                
%      - data   : processing data stored during the previous step                  
%      -- store  : processing data to be saved for the other steps                 
%      -- obs    : observations to be saved for analysis                           
                                                                                   
% Copyright: <userName>                                                            
% Date: 15-Apr-2016                                                                
                                                                                   
% Set behavior for debug mode                                                      
if nargin==0, aedOneModule('do', 1, 'mask', {0 2 1 1 2 2 [2 3 4] 2 0 1}); return; else store=[]; obs=[]; end

store.xp_settings.hoptime = setting.hoptime;
store.xp_settings.wintime = setting.hoptime;
store.xp_settings.features = setting.features;
store.xp_settings.dataset = 'environment/dcase/QMUL_dev-test/events_OL_test/';
store.xp_settings.soundIndex = setting.soundIndex;

%% select sound

fileId = fopen([config.inputPath store.xp_settings.dataset 'sampleList.txt']);
store.xp_settings.sounds=textscan(fileId,'%s');store.xp_settings.sounds=store.xp_settings.sounds{1};
fclose(fileId);

%% load sound 

[y,store.xp_settings.sr]=audioread([config.inputPath store.xp_settings.dataset '/sound/' store.xp_settings.sounds{setting.soundIndex}  '.wav']);
if min(size(y)) > 1
    y=mean(y,2);
end
y=y/max(abs(y));
store.xp_settings.soundDuration = length(y)/store.xp_settings.sr;

%% compute features (ftrs x time)

switch setting.features
    case 'spec'
        [~,~,store.features] = melfcc(y,store.xp_settings.sr, 'wintime',store.xp_settings.wintime,'hoptime',store.xp_settings.hoptime,'nbands',40,'minfreq',0,'maxfreq',12000,'preemph',0,'useenergy',0,'lifterexp',0);
    case 'mel'
        [~,store.features,~] = melfcc(y,store.xp_settings.sr, 'wintime',store.xp_settings.wintime,'hoptime',store.xp_settings.hoptime,'nbands',40,'minfreq',0,'maxfreq',12000,'preemph',0,'useenergy',0,'lifterexp',0);
        store.features=log(store.features);
    case 'mfcc'
        [store.features,~,~] = melfcc(y,store.xp_settings.sr, 'wintime',store.xp_settings.wintime,'hoptime',store.xp_settings.hoptime,'nbands',40,'minfreq',0,'maxfreq',12000,'preemph',0,'useenergy',0,'lifterexp',0);
        store.features=store.features(2:end,:);      
end

if setting.norm
     store.features = normalizeFeature(store.features,2, 10^-6);
end
%% store

store.features=store.features-min(store.features(:));
store.features=store.features/max(store.features(:));

disp('')
