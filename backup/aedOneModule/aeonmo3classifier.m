function [config, store, obs] = aeonmo3classifier(config, setting, data)
% aeonmo3classifier CLASSIFIER step of the expLanes experiment aedOneModule
%    [config, store, obs] = aeonmo3classifier(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 15-Apr-2016

% Set behavior for debug mode
if nargin==0, aedOneModule('do',3, 'mask', {0 2 1 1 1 1 1 1 0 2}); return; else store=[]; obs=[]; end

%% load features
[dataStep_1, ~, ~,~] = expLoad(config, [], 1, 'data', [], 'data');

% figure(1)
% subplot 211
% imagesc(dataStep_1.features)
% subplot 212
% imagesc(data.bgDetection')


for ii=1:length(data.onsets)
    
    indEvents=ii;
    
    switch setting.distance
        case 'kernel-rbf'
            param.kernelSig_nei=setting.kernelRbf_nei;
        case 'kernel-st'
            param.kernelSig_m=round(setting.kernelSt_m*size(features,2));
        case 'dtw'
            param.onsets=data(k).seg.onsets;
            param.offsets=data(k).seg.offsets;
            param.sim_dtw='euc';
    end
    param.type = setting.distance;
    simMat=getSim(dataStep_1.features(:,data.onsets(indEvents):data.offsets(indEvents)),param);
    simMat=simMat+triu(simMat,1)';
    simMat=simMat/max(simMat(:));
    
    switch setting.structFeat
        
        case 0
            
            simMat2=simMat;
            
        case 1
            
            simMatTmp=simMat;
            
            for jj=1:size( simMatTmp,2)
                simMatTmp(:,jj)=circshift( simMatTmp(:,jj),-jj+1);
            end
            
            
            simMat2=getSim(full(simMatTmp),param);
            simMat2=simMat2+triu(simMat2,1)';
            simMat2=simMat2/max(simMat2(:));
            
            simMatTmp2=full(simMatTmp.*simMatTmp');
            
            simMat3=getSim(full(simMatTmp2),param);
            simMat3=simMat3+triu(simMat3,1)';
            simMat3=simMat3/max(simMat3(:));
            
        case 2
            
            simMatTmp=distanceWiseStructFeat(full(simMat));
            simMat2=getSim(full(simMatTmp),param);
            simMat2=simMat2+triu(simMat2,1)';
            simMat2=simMat2/max(simMat2(:));
    end
    
    flag=1;
    nbcF=2;
    nbcSF=2;
    
    cont=arrayfun(@(x) pdist2(simMatTmp(:,x)',simMatTmp(:,x-1)') ,2:size(simMatTmp,2));
    
    while flag
        
        [ clusteringOutput ] = doubleSim({simMat,simMat2,simMat3},data.xp_settings.hoptime*4,data.xp_settings.hoptime,nbcF,nbcSF);
        
        [onsets,offsets]=getOnsetsOffsets(clusteringOutput{2}.prediction);
%         for oo=1:length(onsets)
%             clusteringOutput{2}.prediction(onsets(oo):offsets(oo))=oo;
%         end
        
        metrics= clusteringMetrics(clusteringOutput{2}.prediction,clusteringOutput{1}.prediction,0,0,0,1,1);
        
        figure(2)
        subplot 311
        imagesc(dataStep_1.features(:,data.onsets(indEvents):data.offsets(indEvents)))
        title([num2str(data.onsets(indEvents)*data.xp_settings.hoptime) ' -- ' num2str(data.offsets(indEvents)*data.xp_settings.hoptime) ])
        subplot 312
        imagesc(simMat)
        subplot 313
        imagesc(clusteringOutput{1}.prediction)
        
        figure(3)
        subplot 511
        imagesc(dataStep_1.features(:,data.onsets(indEvents):data.offsets(indEvents)))
        subplot 512
        imagesc(simMatTmp)
        subplot 513
        imagesc(simMat2)
        subplot 514
        imagesc(clusteringOutput{2}.prediction)
        subplot 515
        plot([0 arrayfun(@(x) pdist2(simMatTmp(:,x)',simMatTmp(:,x-1)'),2:size(simMatTmp,2))])
        axis tight
        
        figure(4)
        subplot 311
        imagesc(dataStep_1.features(:,data.onsets(indEvents):data.offsets(indEvents)))
        subplot 312
        imagesc(simMat3)
        subplot 313
        imagesc(clusteringOutput{3}.prediction)
        
        figure(5)
        subplot 311
        imagesc(clusteringOutput{1}.prediction)
        subplot 312
        imagesc(clusteringOutput{2}.prediction)
        title(['pred=' num2str(metrics.pairwisePrecision) '; rec=' num2str(metrics.pairwiseRecall)])
        subplot 313
        imagesc(clusteringOutput{3}.prediction)
        
        
        if  nbcF>1
            flag=0;
        else
%             nbc=nbc+1;
        end
        disp('')
    end
    
end

