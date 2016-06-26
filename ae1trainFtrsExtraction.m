function [config, store, obs] = ae1trainFtrsExtraction(config, setting, data)
% ae1train TRAIN step of the expLanes experiment aed
%    [config, store, obs] = ae1train(config, setting, data)
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

if nargin==0, aed('do',1, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm classif_method ...
        nbKnn dist ...
        setting_soundIndex setting_bgDetection rmBg}); return; else store=[]; obs=[]; end


%% init

store.xp_settings.hoptime = setting.hoptime;
store.xp_settings.wintime = setting.hoptime;
store.xp_settings.sr=44100;
store.xp_settings.mfccDeltaRadius=1;
store.xp_settings.minFreq=27.5;
store.xp_settings.maxFreq=8000;
store.xp_settings.preemph=1;
store.xp_settings.melBand=31;
store.xp_settings.train_features={'mel','logmel','mfcc','mfccD1','mfccD2','gbfb'};
store.xp_settings.classes = {'alert','clearthroat','cough','doorslam','drawer','keyboard','keys','knock',...
    'laughter','mouse','pageturn','pendrop','phone','printer','speech','switch'};
store.xp_settings.trainSetPath='~/Dropbox/databases/environment/dcase/QMUL_train/';


%% compute features (ftrs x time)
store.classeId=cell(1,length(store.xp_settings.classes));
store.sampleId=cell(1,length(store.xp_settings.classes));
store.segmentId=cell(1,length(store.xp_settings.classes)); 

for ii=1:length(store.xp_settings.train_features)
    eval(['store.ftrs_' store.xp_settings.train_features{ii} '=cell(1,length(store.xp_settings.classes));'])
end

for jj=1:length(store.xp_settings.classes)
    
    disp(store.xp_settings.classes{jj});
    
    store.classeId{jj}=[];
    store.sampleId{jj}=[];
    store.segmentId{jj}=[];
    
    for ii=1:length(store.xp_settings.train_features)
        eval(['store.ftrs_' store.xp_settings.train_features{ii} '{jj}=[];'])
    end
    
    [trainSignal,eventLoc,bgLoc] = getSamplesInfos(setting.rmSilence,store.xp_settings.classes{jj},store.xp_settings.trainSetPath,store.xp_settings.sr);
    
    currentSegmentId=1;
    
    for rr=1:length(trainSignal)
        
        disp(['sample: ' num2str(rr)]);
        
        % get segments
        [onsets,offsets]=getOnsetsOffsets(eventLoc{rr},1);
        
        if length(onsets)>1
            error('multiple events in one sample')
        end
        
        signal=trainSignal{rr}(onsets:offsets);
        signal = signal/max(abs(signal(:)));
        
        % pre emph
        if store.xp_settings.preemph > 0
            signal = filter([1 -store.xp_settings.preemph], 1, signal);
        end
        
        features = getFeatures(signal,store.xp_settings.train_features,store.xp_settings);
        
        % store
        for ii=1:length(store.xp_settings.train_features)
            eval(['store.ftrs_' store.xp_settings.train_features{ii} '{jj}=[store.ftrs_' store.xp_settings.train_features{ii} '{jj} features.' store.xp_settings.train_features{ii}  '];']);
        end
        
        store.classeId{jj}=[store.classeId{jj} ones(1,features.size)*jj];
        store.sampleId{jj}=[store.sampleId{jj} ones(1,features.size)*rr];
        store.segmentId{jj}=[store.segmentId{jj} ones(1,features.size)*currentSegmentId];
        
        currentSegmentId=currentSegmentId+1;
        
    end
    
end

