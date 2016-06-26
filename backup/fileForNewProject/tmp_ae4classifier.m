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
hoptime=1;
rmSilence=2;

segmentation_train=1;
segmentation_obs=2;
segmentation_ftrs2use=2;

features=1;
norm=1;
classif_method=3;
classif_seed=0;

hmm_settings=2;

randomForest_nbTree=0;

setting_soundIndex=4;
setting_bgDetection=1;

rmBg=1;

if nargin==0, aed('do',4, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm classif_method classif_seed ...
        hmm_settings ...
        randomForest_nbTree ...
        setting_soundIndex setting_bgDetection rmBg}); return; else store=[]; obs=[]; end


store.xp_settings=data(1).xp_settings;
store.xp_settings.soundIndex=setting.soundIndex;
store.xp_settings.dataset = 'environment/dcase/QMUL_dev-test/events_OL_test/';
store.xp_settings.bgDetectionPath='~/Dropbox/projets/aed/bgDetection/';

%% get best Model

switch setting.classif_method
    
    case 'hmm'
        
        store.model={data.hmm_settings};
        
        modelPerf=zeros(length(data),length(store.xp_settings.classes));
        
        for jj=1:length(data)
            for ii=1:length(store.xp_settings.classes)
                if isempty(data(jj).train.LL{ii})
                    modelPerf(jj,ii)=-inf;
                else
                    modelPerf(jj,ii)=data(jj).train.LL{ii}(end);
                end
            end
        end
        
        [~,indBestModel]=max(modelPerf,[],1);
        
        store.modelPerf=modelPerf;
        store.indBestModel=indBestModel;
        
    case 'randomForest'
        
        modelPerf=[data.error];
        [~,store.indBestModel]=min(modelPerf);
        data=data(store.indBestModel);
        
end

%% get sound
% select sound

fileId = fopen([config.inputPath store.xp_settings.dataset 'sampleList.txt']);
store.xp_settings.sounds=textscan(fileId,'%s');store.xp_settings.sounds=store.xp_settings.sounds{1};
fclose(fileId);

% load sound
[signal,store.xp_settings.sr]=audioread([config.inputPath store.xp_settings.dataset '/sound/' store.xp_settings.sounds{setting.soundIndex}  '.wav']);
if min(size(signal)) > 1
    signal=mean(signal,2);
end

audio = miraudio(signal(:));
maxFeaturesLength = size(mirgetdata(mirframe(audio,'length',store.xp_settings.wintime,'s','hop',store.xp_settings.hoptime,'s')),2);

%% get test segment



switch setting.bgDetection
    case {'null'}
        
        bgDetection=load([store.xp_settings.bgDetectionPath store.xp_settings.sounds{setting.soundIndex} '.mat']);
        
        [bgDetection.onsets,bgDetection.offsets]=getOnsetsOffsets(bgDetection.event);
        bgDetection.onsets=bgDetection.onsets(bgDetection.event(bgDetection.onsets)~=0);
        bgDetection.offsets=bgDetection.offsets(bgDetection.event(bgDetection.offsets)~=0);
        
        bgDetection.onsets_time=bgDetection.onsets*bgDetection.hoptime;
        bgDetection.offsets_time=bgDetection.offsets*bgDetection.hoptime;
        
        bgDetection.onsets=max(1,round(bgDetection.onsets_time/store.xp_settings.hoptime));
        bgDetection.offsets=min(maxFeaturesLength,round(bgDetection.offsets_time/store.xp_settings.hoptime));
        
    case {'bdm','sid'}
        
        [bgDetection] = getAnnotation([config.inputPath store.xp_settings.dataset],setting.bgDetection,store.xp_settings.sounds{store.xp_settings.soundIndex},store.xp_settings.hoptime,maxFeaturesLength,store.xp_settings.classes,'mono');
        bgDetection.onsets_time=bgDetection.time.onsets;
        bgDetection.offsets_time=bgDetection.time.offsets;
        bgDetection.onsets=bgDetection.frame.onsets;
        bgDetection.offsets=bgDetection.frame.offsets;
        disp('')
end


disp('')
%% get features
beg_seg=max(1,round(bgDetection.onsets_time*store.xp_settings.sr));
end_seg=min(length(signal),round(bgDetection.offsets_time*store.xp_settings.sr));

[ftrs2use,uselog] = getFeatures2use(setting.features);

ftrs_spec=[];
ftrs_mel=[];
ftrs_mfcc=[];
ftrs_gbfb=[];
sampleId_test=[];

for jj=1:length(beg_seg)
    
    signalSeg=signal(beg_seg(jj):end_seg(jj));
    signalSeg=signalSeg-mean(signalSeg);
    signalSeg=signalSeg/max(abs(signalSeg));
    
    if store.xp_settings.preemph > 0
        signalSeg = filter([1 -store.xp_settings.preemph], 1, signalSeg);
    end
    
    mirverbose(0);
    audio = miraudio(signalSeg(:));
    frame = mirframe(audio,'length',store.xp_settings.wintime,'s','hop',store.xp_settings.hoptime,'s');
    
    sampleId_test=[sampleId_test ones(1,size(mirgetdata(frame),2))*jj];
    
    if any(strcmp('spec',ftrs2use));
        spec=mirspectrum(frame,'min',store.xp_settings.minFreq,'max',store.xp_settings.maxFreq);
        ftrs_spec=[ftrs_spec mirgetdata(spec)];
    end
    
    if any(strcmp('mel',ftrs2use));
        mel=mirspectrum(frame,'mel','min',store.xp_settings.minFreq,'max',store.xp_settings.maxFreq,'bands',store.xp_settings.melBand);
        ftrs_mel=[ftrs_mel (squeeze(mirgetdata(mel)))'];
    end
    
    if any(strcmp('mfcc',ftrs2use));
        mel=mirspectrum(frame,'mel','min',store.xp_settings.minFreq,'max',store.xp_settings.maxFreq,'bands',store.xp_settings.melBand);
        ftrs_mfcc=[ftrs_mfcc mirgetdata(mirmfcc(mel,'rank',2:13))];
    end
    
    if any(strcmp('gbfb',ftrs2use))
        
        logMel=log_mel_spectrogram(signalSeg, store.xp_settings.sr, store.xp_settings.hoptime*1000,...
            store.xp_settings.wintime*1000, [store.xp_settings.minFreq store.xp_settings.maxFreq], store.xp_settings.melBand);
        
        ftrs_gbfb =[ftrs_gbfb gbfb(logMel,[pi/2 pi/2],[69 40],[3.5 3.5],[0.3 0.2])];
        
    end
    
end

%% select Features

features_test=[];
ftrs_id=[];
for pp=1:length(ftrs2use)
    ftrsTmp=eval(['ftrs_' ftrs2use{pp} ';']);
    if uselog(pp)==0
        features_test=[features_test;ftrsTmp];
    else
        features_test=[features_test;log(ftrsTmp)];
    end
    ftrs_id=[ftrs_id ones(1,size(ftrsTmp,1))*pp];
end

[onsets_seg,offsets_seg]=getOnsetsOffsets(sampleId_test);

%% norm
if ~strcmp(setting.norm,'null')
    
    switch setting.norm
        case 'pca_95'
            features_test= (features_test'/data.coeff')';
            features_test=features_test(1:data.pc2use,:);
        case {'L1','L2'}
            features_test= normalizeFeature(features_test,str2double(setting.norm(2)), 10^-6);
        otherwise
            error('wrong norm argument')
    end
end
disp('');

%% classify segment
switch setting.classif_method
    case 'hmm'
        
        offsetsTime=0;
        
        store.loglik=zeros(length(store.xp_settings.classes),length(onsets));
        store.prediction=zeros(1,size(features_test,2))+length(store.xp_settings.classes)+1; % class 17: 'bg';
        
        for ii=1:length(onsets)
            for jj=1:length(store.xp_settings.classes)
                store.loglik(jj,ii) = mhmm_logprob(features_test(:,max(1,onsets(ii)-round(offsetsTime/store.xp_settings.hoptime)):min(size(features_test,2),offsets(ii)+round(offsetsTime/store.xp_settings.hoptime))),...
                    data(indBestModel(jj)).train.prior1{jj}, data(indBestModel(jj)).train.transmat1{jj}, data(indBestModel(jj)).train.mu1{jj}, data(indBestModel(jj)).train.Sigma1{jj}, data(indBestModel(jj)).train.mixmat1{jj});
            end
        end
        
        [loglik,store.classId]=max(store.loglik,[],1);
        for ii=1:length(onsets)
            store.prediction(onsets(ii):offsets(ii))=store.classId(ii);
        end
        
    case 'randomForest'
        
        ftrs=[];
        eventPred=[];
        for jj=1:length(onsets)
            ftrs=[ftrs features_test(:,onsets(jj):offsets(jj))];
            eventPred=[eventPred ones(1,offsets(jj)-onsets(jj)+1)*jj];
        end
        
        Yfit = cellfun(@(x) str2double(x),predict(data.treeBagger,ftrs'));
        store.prediction=zeros(1,size(features_test,2))+length(store.xp_settings.classes)+1; % class 17: 'bg';
        
        [onsets_min,offsets_min] = getOnsetsOffsets_min(onsets,offsets);
        predMin=zeros(1,offsets_min(end));
        for ii=1:length(onsets_min)
            [~,classTmp]=max(histc(Yfit(onsets_min(ii):offsets_min(ii)),1:length(store.xp_settings.classes)));
            predMin(onsets_min(ii):offsets_min(ii))=classTmp;
            store.prediction(onsets(ii):offsets(ii))=classTmp;
        end
        
    case 'knn'
        
        
        [onsets_train,offsets_train]=getOnsetsOffsets(cell2mat(data.segmentId));
        classId=cell2mat(arrayfun(@(x) ones(1,length(unique(data.segmentId{x})))*x,1:length(data.segmentId),'UniformOutput',false));
        ftrs_train_all=cell2mat(data.features);
        
        labelsFeatures=unique(ftrs_id);
        probClassFound=cell(1,length(labelsFeatures));
        store.prediction{jj}=cell(1,length(labelsFeatures));
        dist='euc';
        nbKnn=1;

        for jj=1:length(labelsFeatures)
            
            
            %% pooling
            % [features_train,classId_pool ] = featuresPooling(ftrsTmp,onsets_train,offsets_train,round(0.2/store.xp_settings.hoptime),round(0.1/store.xp_settings.hoptime),'mean',classId);
            [features_train,classId_pool ] = featuresPooling(ftrs_train_all(ftrs_id==labelsFeatures(jj),:),onsets_train,offsets_train,0,0,'mean',classId);
            
            
            net = selforgmap([4 4],50,10,'gridtop','dist');           
            net.trainParam.showWindow = 0;
            net.trainParam.epochs=1000;
            net = train(net,features_train);
            
            classes = vec2ind(net(features_test(ftrs_id==labelsFeatures(jj),:)));
            
%             perf = perform(net,net(features_train),classes);
            disp('')
            
            %% sample pooling
            
            
            
            D=pdist2(features_train',features_train',dist);
            SM=1-D/max(D(:));
            
            nbc=4*16;
            [clustering]=getKnKmeans(SM,nbc);
            probClass=samplePooling(clustering.prediction,classId_pool,nbc);
%             probClass(probClass<0.25)=0;
            figure(1)
            subplot 411
            imagesc(SM)
            subplot 412
            imagesc(classId_pool)
            subplot 413
            imagesc(clustering.prediction)
            subplot 414
            imagesc(probClass)
            disp('')
            
            %% Knn
            [ind_knn,dist_knn]=knnsearch(features_train',features_test(ftrs_id==labelsFeatures(jj),:)','K',nbKnn,'distance',dist);
            labels=classId_pool(ind_knn(:)');

             %% votMaj Seg
            nbClass2keep=1;
%             [newOnsets_seg,new_Offsets_eg]=getUnderSeg(onsets_seg,offsets_seg,6*store.xp_settings.hoptime,3*store.xp_settings.hoptime)
%             [ newClus,newProblabels ] = majVote(labels,onsets_seg,offsets_seg,store.xp_settings.classes,problabels);
%             probClassFound{jj}=newProblabels;
            
             [ newClus{jj},probClassFound{jj} ] = majVoteProb(ind_knn(:)',onsets_seg,offsets_seg,probClass,clustering.prediction,labels,nbClass2keep);

            
            store.prediction{jj}=zeros(nbClass2keep,maxFeaturesLength);
            for ii=1:length(bgDetection.onsets)
                store.prediction{jj}(:,bgDetection.onsets(ii):bgDetection.offsets(ii))=repmat(newClus{jj}(:,ii),1,length(bgDetection.onsets(ii):bgDetection.offsets(ii)));
            end
            
        end
        
        % best clustering
        
        candidate=[];
        prob=[];
        
       for jj=1:length(labelsFeatures)
            candidate=[candidate;newClus{jj}];
            prob=[prob;probClassFound{jj}];
       end
       
       disp('')
        
        store.BestPrediction=zeros(1,maxFeaturesLength);
        for hh=1:length(bgDetection.onsets)
            [~,indBest]=max(prob(:,hh));
            store.BestPrediction(bgDetection.onsets(hh):bgDetection.offsets(hh))=candidate(indBest,hh);
        end
        
        [target] = getAnnotation([config.inputPath store.xp_settings.dataset],'sid',store.xp_settings.sounds{store.xp_settings.soundIndex},store.xp_settings.hoptime,length(store.prediction{1}),store.xp_settings.classes,'mono');
        
        figure(2)
        subplot 511
        imagesc(target.clus)
        title('target')
        
        subplot 512
        imagesc(store.BestPrediction)
        title('Best Pred')
        
        subplot 513
        imagesc(store.prediction{1})
        title('Target')
        set(gca,'xtick',bgDetection.onsets+round((bgDetection.offsets-bgDetection.onsets)/2),'xticklabel',round(probClassFound{1}*100)/100)
        rotateXLabels(gca,45)

        subplot 514
        imagesc(store.prediction{2})
        title('Target')
        set(gca,'xtick',bgDetection.onsets+round((bgDetection.offsets-bgDetection.onsets)/2),'xticklabel',round(probClassFound{2}*100)/100)
        rotateXLabels(gca,45)

        subplot 515
        imagesc(store.prediction{3})
        title('Target')
        set(gca,'xtick',bgDetection.onsets+round((bgDetection.offsets-bgDetection.onsets)/2),'xticklabel',round(probClassFound{3}*100)/100)
        rotateXLabels(gca,45)

        disp('')
end




