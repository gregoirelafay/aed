function [config, store, obs] = ae3train(config, setting, data)
% ae4classifier CLASSIFIER step of the expLanes experiment aed
%    [config, store, obs] = ae4classifier(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
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

setting_soundIndex=1;
setting_bgDetection=1;

rmBg=1;

if nargin==0, aed('do',4:5, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm_1 [1 2] [2 3] gamma ...
        nbKnn dist ...
        setting_soundIndex setting_bgDetection rmBg},'parallel',3); return; else store=[]; obs=[]; end

store.xp_settings=data.xp_settings;

%% load train
[dataSetp_1, ~, ~,~] = expLoad(config, [], 1, 'data', [], 'data');

%% select Features
features=cell(1,length(store.xp_settings.classes));

for jj=1:length(store.xp_settings.classes)
    
    classeId{jj}=data.classeId{jj};
    sampleId{jj}=data.sampleId{jj};
    segmentStatus{jj}=data.segmentStatus{jj};
    segmentId{jj}=data.segmentId{jj};
    
    ftrs2use=strsplit(setting.features,'_');
    
    features{jj}=[];
    
    for pp=1:length(ftrs2use)
        eval(['features{jj}=[features{jj};dataSetp_1.ftrs_' ftrs2use{pp} '{jj}];'])
    end
end

clearvars data dataSetp_1

%% get segmentation Features
if setting.segmentation_train
    for jj=1:length(store.xp_settings.classes)
        
        
        ind2keep=zeros(1,size(features{jj},2));
        sampleLabels=unique(sampleId{jj});
        
        for oo=1:length(sampleLabels)
            ind2keep(sampleId{jj}==sampleLabels(oo) & segmentStatus{jj}==1)=1;
        end
        
        ind2keep=logical(ind2keep);
        
        features{jj}=features{jj}(:,ind2keep);
        sampleId{jj}=sampleId{jj}(ind2keep);
        segmentStatus{jj}=segmentStatus{jj}(ind2keep);
        segmentId{jj}=segmentId{jj}(ind2keep);
        
        
    end
end

classeId=cell2mat(classeId);
sampleId=cell2mat(sampleId);
segmentId=cell2mat(segmentId);
segmentStatus=cell2mat(segmentStatus);

%% summarization

[onsets_train,offsets_train]=getOnsetsOffsets(segmentId,[]);

% [features_train,classId_pool ] = featuresPooling(ftrs_train_all(ftrs_id==labelsFeatures(jj),:),onsets_train,offsets_train,round(0.2/store.xp_settings.hoptime),round(0.2/store.xp_settings.hoptime),'mean',classId);
[features,onsets,offsets] = featuresPooling(cell2mat(features),'mean',onsets_train,offsets_train,1,0.5,store.xp_settings.hoptime);

store.classeId=classeId(onsets);
store.sampleId=sampleId(onsets);
store.segmentId=segmentId(onsets);
store.segmentStatus=segmentStatus(onsets);

%% get norm

param.type=setting.norm_1;
[features,store.xp_settings.norm_1] = normFtrs(features,param);

%% features selection (LDA | LDA)

if ~isempty(strfind(setting.ftrsSel,'lda')) && ~isempty(strfind(setting.classif_method,'lda'))
    store.xp_settings.ftrsSel.type='null';
else
    param.type=setting.ftrsSel;
    param.classes=store.classeId;
    [ features ,store.xp_settings.ftrsSel] = featuresSelection(features,param);
end

%% train
rng(0);

switch setting.classif_method
    
    case {'knn'}
        
        store.features=features;
        
    case {'lda_lin','lda_quad'}
        
        store.features=features; % FiXME only for step 4 figures
        splitSet=strsplit(setting.classif_method,'_');
        
        switch splitSet{2}
            case 'lin'
                store.L = fitcdiscr(features',store.classeId','DiscrimType','linear','gamma',setting.gamma);
            case 'quad'
                store.L = fitcdiscr(features',store.classeId','DiscrimType','quadratic');
        end
        
        
        store.err = loss(store.L,features',store.classeId');

        
        %% lda regularization
%         [err,gamma,delta,numpred] = cvshrink(store.L,'NumGamma',24,'NumDelta',24,'Verbose',1);
%         figure;
%         plot(err,numpred,'k.')
%         xlabel('Error rate');
%         ylabel('Number of predictors');
%         [p q] = find(err < min(min(err)) + 0.001);
%         [gamma(p) delta(sub2ind(size(delta),p,q))]
    otherwise
        error('wrong train_method setting')
        
end
disp('')

