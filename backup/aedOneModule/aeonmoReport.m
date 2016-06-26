function config = aeonmoReport(config)                          
% aeonmoReport REPORTING of the expLanes experiment aedOneModule
%    config = aeonmoInitReport(config)                          
%       config : expLanes configuration state                   
                                                                
% Copyright: <userName>                                         
% Date: 15-Apr-2016                                             
                                                                
if nargin==0, aedOneModule('report', 'r'); return; end          
                                                                
config = expExpose(config, 't');                                
