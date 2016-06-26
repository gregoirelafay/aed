function [config, store, obs] = ae4classifier(config, setting, data)
% ae4classifier CLASSIFIER step of the expLanes experiment aed
%    [config, store, obs] = ae4classifier(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 20-Apr-2016
% Date: 20-Apr-2016
hoptime=1;
rmSilence=2;

segmentation_train=1;
segmentation_obs=2;
segmentation_ftrs2use=2;

features=0;
norm_1=0;
ftrsSel=0;

classif_method=2;

gamma=0;

nbKnn=2;
dist=2;

setting_soundIndex=0;
setting_bgDetection=1;

rmBg=1;

if nargin==0, aed('do',3:5, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm_1 [1 2] classif_method ...
        gamma nbKnn dist ...
        setting_soundIndex setting_bgDetection rmBg},'parallel',3); return; else store=[]; obs=[]; end

% if nargin==0, aed('do',4, 'mask', {1 2 1 0 0 2 1 2 1 1 3 10 1 1}); return; else store=[]; obs=[]; end


store.xp_settings=data.xp_settings;
store.xp_settings.soundIndex=setting.soundIndex;
store.xp_settings.bgDetectionPath='~/Dropbox/projets/aed/bgDetection/';


%% norm || PCA

param=store.xp_settings.norm_1;
[features_test,~] = normFtrs(features_test,param);

%% features selection (LDA)

param=store.xp_settings.ftrsSel;
[features_test ,~] = featuresSelection(features_test,param);

figure(1)
subplot 211
imagesc(features_test)
subplot 212
imagesc(data.features)
disp('')
%% classify segment
rng(0)

[onsets_seg,offsets_seg]=getOnsetsOffsets(sampleId_test,[]);
[onsets_train,offsets_train]=getOnsetsOffsets(data.segmentId,[]);

[target] = getAnnotation([config.inputPath store.xp_settings.dataset],'sid',store.xp_settings.sounds{store.xp_settings.soundIndex},store.xp_settings.hoptime,maxFeaturesLength,store.xp_settings.classes,'mono');

switch setting.classif_method
    
    case 'knn'
        
        [ind_knn,dist_knn]=knnsearch(data.features',features_test','K',setting.nbKnn,'distance',setting.dist);
        
        %% get best nn (votMaj_knn)
        prediction=votMaj_knn(ind_knn,dist_knn,data.classeId);
        
        %% integration 1
        [onsets,offsets] = overSeg(onsets_seg,offsets_seg,round(0.2/store.xp_settings.hoptime),round(0.2/store.xp_settings.hoptime));
        [prediction] = votMaj_seg(prediction,onsets,offsets,data.classeId,[]);
        
        %% integration 2
        [prediction] = votMaj_seg(prediction,onsets_seg,offsets_seg,data.classeId,onsets);
        
        store.prediction=resizedPrediction(prediction,bgDetection.onsets,bgDetection.offsets,'point2seg',maxFeaturesLength);
        
        figure(2)
        subplot 211
        imagesc(target.clus)
        subplot 212
        imagesc(resizedPrediction(prediction,bgDetection.onsets,bgDetection.offsets,'point2seg',maxFeaturesLength))
        disp('')
        
    case {'lda_lin','lda_quad'}
        
        prediction = predict(data.L,features_test');
        
         %% integration 1
        [onsets,offsets] = overSeg(onsets_seg,offsets_seg,round(0.2/store.xp_settings.hoptime),round(0.2/store.xp_settings.hoptime));
        [prediction] = votMaj_seg(prediction,onsets,offsets,data.classeId,[]);
        
        %% integration 2
        [prediction] = votMaj_seg(prediction,onsets_seg,offsets_seg,data.classeId,onsets); 
        
        store.prediction=resizedPrediction(prediction,bgDetection.onsets,bgDetection.offsets,'point2seg',maxFeaturesLength);
        disp('')
    
        
end



