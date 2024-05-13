function fighandle = PlotIndivSpotCurve_MaxProj(rstruct, color, linewidth, linetype, zMin, zMax, fighandle)

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

%Get x and y
if isfield(mipStruct, 'th_scan_min')
    [x, y] = RNAUtils.spotCountFromCallTable(mipStruct.callset, false, mipStruct.th_scan_min, mipStruct.th_scan_max);
else
    [x, y] = RNAUtils.spotCountFromCallTable(mipStruct.callset, false);
end

y = double(y);
y = log10(y);
ymax = max(y, [], 'all', 'omitnan');

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

    rectangle('Position', [xmin 0 (xmax - xmin) ymax],...
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


end