function fighandle = PlotIndivFScoreCurve_MaxProj(rstruct, color, linewidth, linetype, zMin, zMax, fighandle)

if zMin < 1
    minZstr = '1';
else
    minZstr = num2str(zMin);
end

if zMax < 1
    maxZstr = 'Z';
else
    maxZstr = num2str(zMax);
end
mipFieldName = ['mip_' minZstr '_' maxZstr];

if isfield(rstruct, mipFieldName)
    mipStruct = rstruct.(mipFieldName);
else
    return;
end

if isfield(mipStruct, 'performance_trimmed')
    x = mipStruct.performance_trimmed{:, 'thresholdValue'};
    y = mipStruct.performance_trimmed{:, 'fScore'};
elseif isfield(mipStruct, 'performance')
    x = mipStruct.performance{:, 'thresholdValue'};
    y = mipStruct.performance{:, 'fScore'};
elseif isfield(mipStruct, 'benchmarks')
    if isfield(mipStruct.benchmarks, 'BH')
        bstruct = mipStruct.benchmarks.BH;
    elseif isfield(mipStruct.benchmarks, 'BHImaris')
        bstruct = mipStruct.benchmarks.BHImaris;
    end
    if isfield(bstruct, 'performance_trimmed')
        x = bstruct.performance_trimmed{:, 'thresholdValue'};
        y = bstruct.performance_trimmed{:, 'fScore'};
    elseif isfield(bstruct, 'performance')
        x = bstruct.performance{:, 'thresholdValue'};
        y = bstruct.performance{:, 'fScore'};
    end
else
    return;
end

thval = 0;
if isfield(mipStruct, 'threshold')
    thval = mipStruct.threshold;
end

hold on;
if isfield(mipStruct, 'threshold_details')
    score_list = RNAThreshold.getAllThresholdSuggestions(mipStruct.threshold_details);
    score_mean = mean(score_list, 'all', 'omitnan');
    score_std = std(score_list, 0, 'all', 'omitnan');
    xmin = score_mean - score_std;
    xmax = score_mean + score_std;
    if xmin < 0; xmin = 0; end

    cdiff = [1 1 1] - color;
    cdiff = cdiff ./ 2;
    boxcolor = color + cdiff;

    rectangle('Position', [xmin 0.0 (xmax - xmin) 1.0],...
                'FaceColor', boxcolor, 'LineStyle', 'none');
end

plot(x, y, 'LineStyle', linetype, 'LineWidth', linewidth, 'Color', color);

if thval > 0
    xline(thval, 'LineStyle', '--', 'LineWidth', 1.5);
end

if isfield(mipStruct, 'threshold_details')
    score_min = min(score_list, [], 'all', 'omitnan');
    score_max = max(score_list, [], 'all', 'omitnan');
    if(score_min < 0); score_min = 0; end
    xline(score_min, 'LineStyle', ':', 'LineWidth', 1);
    xline(score_max, 'LineStyle', ':', 'LineWidth', 1);
end

ylim([0 1]);

end