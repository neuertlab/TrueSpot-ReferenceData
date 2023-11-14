%
function Dump_sctcSimCounts(outhandle, analysis, fixed_th_struct)

    fprintf(outhandle, analysis.imgname);

    if contains(analysis.imgname, 'CY5L')
        ch = 1;
    else
        ch = 2;
    end

    %Actual counts
    spot_count = size(analysis.simkey, 2);
    fprintf(outhandle, "\t%d", spot_count);

    x_okay = ([analysis.simkey.x] >= analysis.results_hb.x_min) & ([analysis.simkey.x] <= analysis.results_hb.x_max);
    y_okay = ([analysis.simkey.y] >= analysis.results_hb.y_min) & ([analysis.simkey.y] <= analysis.results_hb.y_max);
    xy_okay = and(x_okay, y_okay);
    okay_idx = find(xy_okay);
    if ~isempty(okay_idx)
        spot_count = size(okay_idx, 2);
    else
        spot_count = 0;
    end
    fprintf(outhandle, "\t%d", spot_count);

    perf = analysis.results_hb.performance;
    if isfield(analysis.results_hb, 'performance_trimmed')
        perf = analysis.results_hb.performance_trimmed;
    end
    fprintf(outhandle, "\t%d", analysis.results_hb.threshold);
    th_list = perf{:,'thresholdValue'};
    th_idx = RNAUtils.findThresholdIndex(analysis.results_hb.threshold, th_list');
    fprintf(outhandle, "\t%d", perf{th_idx,'spotCount'});
    th_idx = RNAUtils.findThresholdIndex(fixed_th_struct.exp_fixed_th_hb(3, ch), th_list');
    fprintf(outhandle, "\t%d", perf{th_idx,'spotCount'});

    perf = analysis.results_bf.performance;
    if isfield(analysis.results_bf, 'performance_trimmed')
        perf = analysis.results_bf.performance_trimmed;
    end
    fprintf(outhandle, "\t%d", analysis.results_bf.threshold);
    th_list = perf{:,'thresholdValue'};
    th_idx = RNAUtils.findThresholdIndex(analysis.results_bf.threshold, th_list');
    fprintf(outhandle, "\t%d", perf{th_idx,'spotCount'});
    th_idx = RNAUtils.findThresholdIndex(fixed_th_struct.exp_fixed_th_bf(3, ch), th_list');
    fprintf(outhandle, "\t%d", perf{th_idx,'spotCount'});
    
    fprintf(outhandle, '\n');
end