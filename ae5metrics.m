function [config, store, obs] = ae5metrics(config, setting, data)
% ae5metrics METRICS step of the expLanes experiment aed
%    [config, store, obs] = ae5metrics(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 20-Apr-2016

% Set behavior for debug mode
hoptime=1;
rmSilence=2;

segmentation_train=1;
segmentation_obs=2;
segmentation_ftrs2use=3;

features=4;
norm=4;
classif_method=3;
classif_seed=0;

hmm_settings=2;

randomForest_nbTree=0;

setting_soundIndex=1;
rmBg=1;

if nargin==0, aed('do',5, 'mask', {...
        hoptime rmSilence ...
        segmentation_train segmentation_obs segmentation_ftrs2use...
        features norm classif_method classif_seed ...
        hmm_settings ...
        randomForest_nbTree ...
        setting_soundIndex rmBg}); return; else store=[]; obs=[]; end

annotatorGt={'sid','bdm'};

indMetrics=1;

for ii=1:length(data)
    for jj=1:length(annotatorGt)
        
        %% metrics
        
        target = getAnnotation([config.inputPath data(ii).xp_settings.dataset],'bdm',data(ii).xp_settings.sounds{data(ii).xp_settings.soundIndex},data(ii).xp_settings.hoptime,length(data(ii).prediction),data(ii).xp_settings.classes,'mono');
        prediction = getPredictionDcaseFormat(data(ii).prediction,data(ii).xp_settings.classes,data(ii).xp_settings.hoptime);
        
        [results_fb,e_pred,e_gt] = eventDetectionMetrics_frameBased(prediction.time,target.time,data(ii).xp_settings.classes);
        [results_eb] = eventDetectionMetrics_eventBased(prediction.time,target.time);
        [results_cweb] = eventDetectionMetrics_classWiseEventBased(prediction.time,target.time,data(ii).xp_settings.classes);
        
        obs.F_fb(indMetrics)=results_fb.F;
        obs.R_fb(indMetrics)=results_fb.Rec;
        obs.P_fb(indMetrics)=results_fb.Pre;
        
        obs.F_eb(indMetrics)=results_eb.F;
        obs.R_eb(indMetrics)=results_eb.Rec;
        obs.P_eb(indMetrics)=results_eb.Pre;
        
        obs.F_cweb(indMetrics)=results_cweb.F;
        obs.R_cweb(indMetrics)=results_cweb.Rec;
        obs.P_cweb(indMetrics)=results_cweb.Pre;
        
        
        figure(2)
        subplot 211
        imagesc(e_gt')
        set(gca,'ytick',1:length(data(ii).xp_settings.classes),'yticklabel',data(ii).xp_settings.classes)
        title('GT')
        subplot 212
        imagesc(e_pred')
        set(gca,'ytick',1:length(data(ii).xp_settings.classes),'yticklabel',data(ii).xp_settings.classes)
        title(['Pred, F=' num2str(results_fb.F)])
        disp('')
        
        indMetrics=indMetrics+1;
    end
end

disp('')