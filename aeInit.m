function [config, store] = aeInit(config)                          
% aeInit INITIALIZATION of the expLanes experiment aed             
%    [config, store] = aeInit(config)                              
%      - config : expLanes configuration state                     
%      -- store  : processing data to be saved for the other steps 
                                                                   
% Copyright: <userName>                                            
% Date: 20-Apr-2016                                                
                                                                   
if nargin==0, aed(); return; else store=[];  end                   
