function [config, store, obs] = aev13clustering(config, setting, data)      
% aev13convolution CONVOLUTION step of the expLanes experiment aed_v1        
%    [config, store, obs] = aev13convolution(config, setting, data)          
%      - config : expLanes configuration state                               
%      - setting   : set of factors to be evaluated                          
%      - data   : processing data stored during the previous step            
%      -- store  : processing data to be saved for the other steps           
%      -- obs    : observations to be saved for analysis                     
                                                                             
% Copyright: <userName>                                                      
% Date: 10-Apr-2016                                                          
                                                                             
% Set behavior for debug mode                                                
if nargin==0, aed_v1('do', 3, 'mask', {0 0 1 0 [1 4] 0 0 0 0}); return; else store=[]; obs=[]; end

if setting.convLength~=0
    [ K ] = manualSmoothing(full(data.simMat),setting.convLength,setting.convLength,data.xp_settings.hoptime);
else
   K= full(data.simMat);
end

[ clustering ] = getKnKmeans(K,2);

%% store

store.xp_settings=data.xp_settings;
store.bgDetection=clustering.prediction;
