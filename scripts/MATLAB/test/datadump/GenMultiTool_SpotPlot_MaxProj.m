%
%%

%Colors:
%   HB: #aa3838 [0.667 0.220 0.220]

function fig_handle = GenMultiTool_SpotPlot_MaxProj(img_summary, zMin, zMax, figno)

if nargin < 4
    figno = round(rand() * 10000);
end

COLOR_HB = [0.667 0.220 0.220];
COLOR_BF = [0.000 0.000 1.000];
LINE_WIDTH = 2;
LINE_STYLE = '-';

fig_handle = figure(figno);
subplot(2,2,1);
if isfield(img_summary, 'results_hb')
    fig_handle_temp = PlotIndivSpotCurve_MaxProj(img_summary.results_hb, COLOR_HB, LINE_WIDTH, LINE_STYLE, zMin, zMax, fig_handle);
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderSpotCountPlot('homebrew', [1.0 0.0 0.0], figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('Neuert Lab');

subplot(2,2,2);
if isfield(img_summary, 'results_bf')
    fig_handle_temp = PlotIndivSpotCurve_MaxProj(img_summary.results_bf, COLOR_BF, LINE_WIDTH, LINE_STYLE, zMin, zMax, fig_handle);
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderSpotCountPlot('bigfish', [0.0 0.0 1.0], figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('BigFISH');

end

function fighandle_out = handleReturnHandle(fighandle_og, fighandle_ret)
    if isempty(fighandle_ret)
        fighandle_out = fighandle_og;
    else
        fighandle_out = fighandle_ret;
    end
end
