function config = aeReport(config)                 
% aeReport REPORTING of the expLanes experiment aed
%    config = aeInitReport(config)                 
%       config : expLanes configuration state      
                                                   
% Copyright: <userName>                            
% Date: 20-Apr-2016                                
                                                   
if nargin==0, aed('report', 'r'); return; end      

hoptime=1;
rmSilence=2;

segmentation_train=1;
segmentation_obs=2;
segmentation_ftrs2use=2;

features=0;
norm_1=0;
ftrsSel=0;

classif_method=2;
gamma=0;

nbKnn=2;
dist=2;

setting_soundIndex=1;
setting_bgDetection=1;

rmBg=1;

config = expExpose(config, 't','fontSize','scriptsize','step', 5, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm_1 [1 2] [2 3] gamma ...
        nbKnn dist ...
        setting_soundIndex setting_bgDetection rmBg},'precision', 2);
