function config = aev1Report(config)                    
% aev1Report REPORTING of the expLanes experiment aed_v1
%    config = aev1InitReport(config)                    
%       config : expLanes configuration state           
                                                        
% Copyright: <userName>                                 
% Date: 10-Apr-2016                                     
                                                        
if nargin==0, aed_v1('report', 'r'); return; end        
                                                        
config = expExpose(config, 't','fontSize','scriptsize','step', 4, 'mask',{0 1 1 0 [1 4] 0 0 0 0},'obs',[1 2 3],'precision', 2);  
                     
