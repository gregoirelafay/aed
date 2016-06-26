function [config, store] = aeonmoInit(config)                      
% aeonmoInit INITIALIZATION of the expLanes experiment aedOneModule
%    [config, store] = aeonmoInit(config)                          
%      - config : expLanes configuration state                     
%      -- store  : processing data to be saved for the other steps 
                                                                   
% Copyright: <userName>                                            
% Date: 15-Apr-2016                                                
                                                                   
if nargin==0, aedOneModule(); return; else store=[];  end          
