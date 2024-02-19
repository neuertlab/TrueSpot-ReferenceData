function fighandle = PlotIndivSpotCurve(rstruct, thval, color, linewidth, linetype, fighandle)

if isfield(rstruct, 'performance_trimmed')
    x = rstruct.performance_trimmed{:, 'thresholdValue'};
    y = rstruct.performance_trimmed{:, 'spotCount'};
elseif isfield(rstruct, 'performance')
    x = rstruct.performance{:, 'thresholdValue'};
    y = rstruct.performance{:, 'spotCount'};
elseif isfield(rstruct, 'benchmarks')
    if isfield(rstruct.benchmarks, 'BH')
        bstruct = rstruct.benchmarks.BH;
    elseif isfield(rstruct.benchmarks, 'BHImaris')
        bstruct = rstruct.benchmarks.BHImaris;
    end
    if isfield(bstruct, 'performance_trimmed')
        x = bstruct.performance_trimmed{:, 'thresholdValue'};
        y = bstruct.performance_trimmed{:, 'spotCount'};
    elseif isfield(bstruct, 'performance')
        x = bstruct.performance{:, 'thresholdValue'};
        y = bstruct.performance{:, 'spotCount'};
    end
else
    return;
end

y = double(y);
y = log10(y);
ymax = max(y, [], 'all', 'omitnan');

hold on;
if isfield(rstruct, 'threshold_details')
    score_list = RNAThreshold.getAllThresholdSuggestions(rstruct.threshold_details);
    score_mean = mean(score_list, 'all', 'omitnan');
    score_std = std(score_list, 0, 'all', 'omitnan');
    xmin = score_mean - score_std;
    xmax = score_mean + score_std;
    if xmin < 0; xmin = 0; end

    cdiff = [1 1 1] - color;
    cdiff = cdiff ./ 2;
    boxcolor = color + cdiff;

    rectangle('Position', [xmin 0 (xmax - xmin) ymax],...
                'FaceColor', boxcolor, 'LineStyle', 'none');
end

plot(x, y, 'LineStyle', linetype, 'LineWidth', linewidth, 'Color', color);

if thval > 0
    xline(thval, 'LineStyle', '--', 'LineWidth', 1.5);
end

if isfield(rstruct, 'threshold_details')
    score_min = min(score_list, [], 'all', 'omitnan');
    score_max = max(score_list, [], 'all', 'omitnan');
    if(score_min < 0); score_min = 0; end
    xline(score_min, 'LineStyle', ':', 'LineWidth', 1);
    xline(score_max, 'LineStyle', ':', 'LineWidth', 1);
end


end