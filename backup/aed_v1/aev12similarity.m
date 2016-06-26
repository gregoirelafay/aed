function [config, store, obs] = aev12similarity(config, setting, data)
% aev12similarity SIMILARITY step of the expLanes experiment aed_v1
%    [config, store, obs] = aev12similarity(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 10-Apr-2016

% Set behavior for debug mode
if nargin==0, aed_v1('do', 3, 'mask', {0 1 1 1 1 2 0 0 2},'parallel',4); return; else store=[]; obs=[]; end
%% Get Similarity

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
simMat=getSim(data.features,param);
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
        
    case 2
        
        simMatTmp=distanceWiseStructFeat(full(simMat));
        simMat2=getSim(full(simMatTmp),param);
        simMat2=simMat2+triu(simMat2,1)';
        simMat2=simMat2/max(simMat2(:));
end

% figure(1)
% subplot 311
% imagesc(simMat)
% subplot 312
% imagesc(simMat2)
% subplot 313
% imagesc(simMat3)
% disp('')
%% Store

store.xp_settings=data.xp_settings;
store.simMat_origin=simMat;
store.simMat=simMat2;
