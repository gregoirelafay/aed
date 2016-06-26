function [config, store, obs] = ae2trainFtrsSegmentation(config, setting, data)
% ae2features FEATURES step of the expLanes experiment aed
%    [config, store, obs] = ae2features(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 20-Apr-2016

% Set behavior for debug mode
hoptime=1;
rmSilence=2;

segmentation_train=1;
segmentation_obs=2;
segmentation_ftrs2use=2;

features=5;
norm=4;
classif_method=2;

nbKnn=2;
dist=2;

setting_soundIndex=6;
setting_bgDetection=1;

rmBg=1;

if nargin==0, aed('do',3, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm classif_method ...
        nbKnn dist ...
        setting_soundIndex setting_bgDetection rmBg}); return; else store=[]; obs=[]; end

store.xp_settings=data.xp_settings;
store.classeId=data.classeId;
store.sampleId=data.sampleId;

%% get segmentation

if ~setting.segmentation_train
    
    store.segmentId=data.segmentId;
    store.segmentStatus=cellfun(@(x) ones(1,length(x)),data.segmentId,'UniformOutput',false);
    
else
    
    store.segmentId=cell(1,length(store.xp_settings.classes));
    
    % segment per class
    for jj=1:length(store.xp_settings.classes)
        eval(['features_train=data.ftrs_' setting.segmentation_ftrs2use '{jj};']);
   
    
    dimSOM=[12 8];
    
    net = selforgmap(dimSOM,50,20,'gridtop','dist');
    net.trainParam.showWindow = 0;
    net.trainParam.epochs=1000;
    net = train(net,features_train);
    
    figure(1)
    subplot 311
    imagesc(features_train)
    subplot 312
    imagesc(store.sampleId{jj})
    subplot 313
    imagesc(vec2ind(net(features_train)));
    disp('')
    
     end
end

disp('')


