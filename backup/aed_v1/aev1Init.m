function [config, store] = aev1Init(config)                        
% aev1Init INITIALIZATION of the expLanes experiment aed_v1        
%    [config, store] = aev1Init(config)                            
%      - config : expLanes configuration state                     
%      -- store  : processing data to be saved for the other steps 
                                                                   
% Copyright: <userName>                                            
% Date: 10-Apr-2016                                                
                                                                   
if nargin==0, aed_v1(); return; else store=[];  end                
