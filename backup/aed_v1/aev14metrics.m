function [config, store, obs] = aev14metrics(config, setting, data)
% aev14rectification RECTIFICATION step of the expLanes experiment aed_v1
%    [config, store, obs] = aev14rectification(config, setting, data)
%      - config : expLanes configuration state
%      - setting   : set of factors to be evaluated
%      - data   : processing data stored during the previous step
%      -- store  : processing data to be saved for the other steps
%      -- obs    : observations to be saved for analysis

% Copyright: <userName>
% Date: 10-Apr-2016

% Set behavior for debug mode
if nargin==0, aed_v1('do', 4, 'mask', {0 1 1 1 1 2 0 2 2}); return; else store=[]; obs=[]; end

saveFlag=1;

%% metrics
xx=1;
annotators={'bdm','sid'};

% [dataStep_2, ~, ~,~] = expLoad(config, [], 2, 'data', [], 'data');

for jj=1:length(data)
    
    simMat=full(dataStep_2(jj).simMat_origin);
    simMat(logical(eye(size(simMat)))) = 0;
    
    for hh=1:2
        val(hh)= mean(squareform(simMat(data(jj).bgDetection==hh,data(jj).bgDetection==hh)));
    end
    
    %% set bg to 1 and events to 2
    
    if val(1)<val(2)
        data(jj).bgDetection(data(jj).bgDetection==2)=3;
        data(jj).bgDetection(data(jj).bgDetection==1)=2;
        data(jj).bgDetection(data(jj).bgDetection==3)=1;
    end
    
    for ii=1:length(annotators)
        
        [gt_clustering,~,labels,~]=getAnnotation([config.inputPath data(jj).xp_settings.dataset],annotators{ii},data(jj).xp_settings.sounds{data(jj).info.setting.soundIndex},data(jj).xp_settings.hoptime,length(data(jj).bgDetection));
        
        indBg=find(strcmp('bg',labels));
        gt_bg=gt_clustering;gt_bg(gt_bg==indBg)=0;gt_bg=gt_bg>0;gt_bg=gt_bg+1;
        
        metrics= clusteringMetrics(gt_bg,data(jj).bgDetection,1,0,0,1,1);
        obs.acc(xx)=metrics.accuracy;
        obs.F(xx)=metrics.pairwiseFmeasure;
        obs.R(xx)=metrics.pairwiseRecall;
        obs.P(xx)=metrics.pairwisePrecision;
        xx=xx+1;
        
        %% save for classifier
        
        if saveFlag
            data_bgDetection=data(jj);
            save(['~/Dropbox/projets/aed/bgDetection/' data(jj).xp_settings.sounds{data(jj).xp_settings.soundIndex}],'data_bgDetection');
        end
        
        %% visu
        %         figure(1)
        %         subplot 211
        %         imagesc(gt_bg')
        %         title('Gt')
        %         subplot 212
        %         imagesc(data(jj).bgDetection)
        %         title(['pred: F=' num2str(metrics.pairwiseFmeasure) '; acc=' num2str(metrics.accuracy)])
        %         disp('')
    end
end



disp('')