%
%%
function analysis = plotbug_correct_240214(analysis)
    
    if startsWith(analysis.imgname, 'simneg_')
        analysis = correctSimneg(analysis);
    elseif startsWith(analysis.imgname, 'simerly_')
        analysis = correctExpSimerly(analysis);
    end

end

function analysis = correctExpSimerly(analysis)
    if ~isfield(analysis, 'results_hb'); return; end
    rstruct = analysis.results_hb;

    if isfield(rstruct, 'benchmarks')
        bstruct = rstruct.benchmarks.BHImaris;
        T = size(bstruct.performance, 1);
        spot_table = NaN(T,2);
        spot_table(:,1) = bstruct.performance{:,'thresholdValue'};
        spot_table(:,2) = bstruct.performance{:,'spotCount'};

        th_res = RNAThreshold.runWithPreset(spot_table, [], 1);
        rstruct.threshold_details = th_res;
        rstruct.threshold = th_res.threshold;

        if rstruct.threshold > 0
            thidx = RNAUtils.findThresholdIndex(rstruct.threshold, spot_table(:,1)');
            bstruct.fscore_autoth = bstruct.performance{thidx, 'fScore'};
            if isfield(bstruct, 'performance_trimmed')
                bstruct.fscore_autoth_trimmed = bstruct.performance_trimmed{thidx, 'fScore'};
            end
        else
            bstruct.fscore_autoth = NaN;
            if isfield(bstruct, 'performance_trimmed')
                bstruct.fscore_autoth_trimmed = NaN;
            end
        end

        rstruct.benchmarks.BHImaris = bstruct;
    else
        thall = rstruct.callset{:,'dropout_thresh'};
        thall(thall == 0) = NaN;
        minth = min(thall, [], 'all', 'omitnan');
        maxth = max(thall, [], 'all', 'omitnan');

        T = maxth - minth + 1;
        spot_table = NaN(T,2);
        for t = 1:T
            thval = t + minth - 1;
            spot_table(t,1) = thval;
            spot_table(t,2) = nnz(rstruct.callset{:,'dropout_thresh'} >= thval);
        end

        th_res = RNAThreshold.runWithPreset(spot_table, [], 1);
        rstruct.threshold_details = th_res;
        rstruct.threshold = th_res.threshold;
    end

    
    analysis.results_hb = rstruct;
end

function analysis = correctSimneg(analysis)
    if ~isfield(analysis, 'results_hb'); return; end
    rstruct = analysis.results_hb;

    T = size(rstruct.performance, 1);
    spot_table = NaN(T,2);
    spot_table(:,1) = rstruct.performance{:,'thresholdValue'};
    spot_table(:,2) = rstruct.performance{:,'spotCount'};

    th_res = RNAThreshold.runWithPreset(spot_table, [], 5);
    rstruct.threshold_details = th_res;
    rstruct.threshold = th_res.threshold;

    if rstruct.threshold > 0
        thidx = RNAUtils.findThresholdIndex(rstruct.threshold, spot_table(:,1)');
        rstruct.fscore_autoth = rstruct.performance{thidx, 'fScore'};
        if isfield(rstruct, 'performance_trimmed')
            rstruct.fscore_autoth_trimmed = rstruct.performance_trimmed{thidx, 'fScore'};
        end
    else
        rstruct.fscore_autoth = NaN;
        if isfield(rstruct, 'performance_trimmed')
            rstruct.fscore_autoth_trimmed = NaN;
        end
    end

    analysis.results_hb = rstruct;
end