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
segmentation_ftrs2use=3;

features=3;
norm=1;
classif_method=3;
classif_seed=0;

hmm_settings=2;

randomForest_nbTree=0;

setting_soundIndex=0;
rmBg=1;

if nargin==0, aed('do',4, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm classif_method classif_seed ...
        hmm_settings ...
        randomForest_nbTree ...
        setting_soundIndex rmBg},'parallel',2); return; else store=[]; obs=[]; end

store.xp_settings=data.xp_settings;

if isnan(setting.classif_seed)
    store.classif_seed=0;
else
    store.classif_seed=setting.classif_seed;
end

%% load train
[dataSetp_1, ~, ~,~] = expLoad(config, [], 1, 'data', [], 'data');

%% select Features
features=cell(1,length(store.xp_settings.classes));

for jj=1:length(store.xp_settings.classes)
    
    sampleId{jj}=data.sampleId{jj};
    segmentStatus{jj}=data.segmentStatus{jj};
    segmentId{jj}=data.segmentId{jj};
    
    [ftrs2use,uselog] = getFeatures2use(setting.features);

    features{jj}=[];
    
    for pp=1:length(ftrs2use)
        if uselog(pp)==0
            eval(['features{jj}=[features{jj};dataSetp_1.ftrs_' ftrs2use{pp} '{jj}];'])
        else
            eval(['features{jj}=[features{jj};log(dataSetp_1.ftrs_' ftrs2use{pp} '{jj})];'])
        end
    end

    if setting.segmentation_train
        
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

clearvars data dataSetp_1

%% Norm

if ~strcmp(setting.norm,'null')
    
    ftrsTmp=cell2mat(features);
    
    switch setting.norm
        
        case {'pca_95'}
            % coef*score'=features; to project new data use features/score'
            % don't forget to center the features: features-repmat(mean(features,2),1,size(features,2))
            
            treshVar=str2double(setting.norm(strfind(setting.norm,'_')+1:end));
            
            [store.coeff,store.score,~,~,explained,~] = pca(ftrsTmp');
            store.pc2use=find(cumsum(explained)>=treshVar,1,'first'); 
            
            features=mat2cell(store.score(:,1:store.pc2use)',store.pc2use,cellfun(@(x) size(x,2),features));
            
        case {'L1','L2'}
            
            ftrsTmp= normalizeFeature(ftrsTmp,str2double(setting.norm(2)), 10^-6);
            features=mat2cell(ftrsTmp,size(ftrsTmp,1),cellfun(@(x) size(x,2),features));
            
        otherwise
            error('not done')
    end
end

%% train

rng(store.classif_seed);

switch setting.classif_method
    
    case 'hmm'
        
        store.train.nbGauss=8; % M: Number of mixtures
        store.train.method='hmm';
        store.train.maxIter=10;
        store.hmm_settings=setting.hmm_settings;
        store.kmeansRep=1; %% nb Rep to init Gmm
        
        % get nbstate
        hmmSettings=strsplit(store.hmm_settings,'_');
        store.train.nbState=str2double(hmmSettings{2});
        store.train.type=hmmSettings{1};
        
        for jj=1:length(store.xp_settings.classes)
            
            disp(store.xp_settings.classes{jj})
            
            if setting.segmentation_train
                segmentLabels=unique(segmentId{jj});
                segments=segmentId{jj};
            else
                segmentLabels=unique(sampleId{jj});
                segments=sampleId{jj};
            end
            
            varNb=size(features{jj},1); % O: Number of coefficients in a vector
            
            cov_type = 'diag';
            
            % initial guess of parameters
            if store.classif_seed==0
                prior0 = ones(store.train.nbState,1)/store.train.nbState;
            else
                prior0 = normalise(rand(store.train.nbState,1));
            end
            
            switch store.train.type
                case 'full'
                    if store.classif_seed==0
                        transmat0 = mk_stochastic(ones(store.train.nbState,store.train.nbState));
                    else
                        transmat0 = mk_stochastic(rand(store.train.nbState,store.train.nbState));
                    end
                    
                case 'L2R'
                    if store.classif_seed==0
                        transmat0 = mk_leftright_transmat(store.train.nbState, 0.5);
                    else
                        transmat0 = mk_stochastic((mk_leftright_transmat(store.train.nbState, 0.5)>0).*rand(store.train.nbState,store.train.nbState));
                    end
                    
                case 'fullInt'
                    transmat0 = zeros(store.train.nbState,store.train.nbState);
                    transmat0(end,end)=1;
                    if store.classif_seed==0
                        transmat0(1,1:2)=0.5;
                        transmat0(2:store.train.nbState-1,2:store.train.nbState-1)=mk_stochastic(ones(store.train.nbState-2,store.train.nbState-2));
                    else
                        transmat0(1,1:2)=normalize(rand(1,2));
                        transmat0(2:store.train.nbState-1,2:store.train.nbState-1)=mk_stochastic(rand(store.train.nbState-2,store.train.nbState-2));
                    end
                    
                    
            end
            
            % init gmm
            [mu0, Sigma0] = mixgauss_init(store.train.nbState*store.train.nbGauss, features{jj}, cov_type,'kmeans',store.kmeansRep);
            mu0 = reshape(mu0, [varNb store.train.nbState store.train.nbGauss]);
            Sigma0 = reshape(Sigma0, [varNb varNb store.train.nbState store.train.nbGauss]);
            mixmat0 = mk_stochastic(rand(store.train.nbState,store.train.nbGauss));
            
            
            ftrsPerSample=arrayfun(@(x) features{jj}(:,segments==x),segmentLabels,'UniformOutput',false);
            
            % learn parameters
            [store.train.LL{jj}, store.train.prior1{jj}, store.train.transmat1{jj}, store.train.mu1{jj}, store.train.Sigma1{jj}, store.train.mixmat1{jj}] = mhmm_em(ftrsPerSample, prior0, transmat0, mu0, Sigma0, mixmat0, 'max_iter', store.train.maxIter,'verbose',0,'cov_type',cov_type);
            
            store.train.loglik{jj} = mhmm_logprob(ftrsPerSample, store.train.prior1{jj}, store.train.transmat1{jj}, store.train.mu1{jj}, store.train.Sigma1{jj}, store.train.mixmat1{jj});
            
            disp('')
            
        end
        
    case 'randomForest'
        
        classes=cell2mat(arrayfun(@(x) ones(1,size(features{x},2))*x,1:length(features),'UniformOutput',false))';
        ftrsTmp=cell2mat(features)';
        treeBagger= TreeBagger(setting.randomForest_nbTree,ftrsTmp,classes,'Method', 'classification','Prior','Uniform','OOBPred','on');
        store.error=oobError(treeBagger,'mode','ensemble');
        store.treeBagger=compact(treeBagger);
        
    case 'knn'
        
        store.features=features;
        store.sampleId=sampleId;
        store.segmentStatus=segmentStatus;
        store.segmentId=segmentId;
        
    otherwise
        error('wrong train_method setting')
        
end
disp('')

