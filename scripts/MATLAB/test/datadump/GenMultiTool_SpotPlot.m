%
%%

%Colors:
%   HB: #aa3838 [0.667 0.220 0.220]

function fig_handle = GenMultiTool_SpotPlot(img_summary, figno)

if nargin < 2
    figno = round(rand() * 10000);
end

COLOR_HB = [0.667 0.220 0.220];
COLOR_BF = [0.000 0.000 1.000];
COLOR_RS = [0.000 0.800 0.000];
COLOR_DB = [0.700 0.700 0.000];
LINE_WIDTH = 2;
LINE_STYLE = '-';

fig_handle = figure(figno);
subplot(2,2,1);
if isfield(img_summary, 'results_hb')
    thval = 0;
    if isfield(img_summary.results_hb, 'threshold')
        thval = img_summary.results_hb.threshold;
    end
    fig_handle_temp = PlotIndivSpotCurve(img_summary.results_hb, thval, COLOR_HB, LINE_WIDTH, LINE_STYLE, fig_handle);
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderSpotCountPlot('homebrew', [1.0 0.0 0.0], figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('Neuert Lab');

subplot(2,2,2);
if isfield(img_summary, 'results_bf')
    thval = 0;
    if isfield(img_summary.results_bf, 'threshold')
        thval = img_summary.results_bf.threshold;
    end
    fig_handle_temp = PlotIndivSpotCurve(img_summary.results_bf, thval, COLOR_BF, LINE_WIDTH, LINE_STYLE, fig_handle);
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderSpotCountPlot('bigfish', [0.0 0.0 1.0], figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('BigFISH');

subplot(2,2,3);
if isfield(img_summary, 'results_rs')
    fig_handle_temp = PlotIndivSpotCurve(img_summary.results_rs, 0, COLOR_RS, LINE_WIDTH, LINE_STYLE, fig_handle);
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderSpotCountPlot('rsfish', [0.0 0.8 0.0], figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('RS-FISH');

subplot(2,2,4);
if isfield(img_summary, 'results_db')
    fig_handle_temp = PlotIndivSpotCurve(img_summary.results_db, 0, COLOR_DB, LINE_WIDTH, LINE_STYLE, fig_handle);
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderSpotCountPlot('deepblink', [0.7 0.7 0.0], figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('DeepBlink');


end

function fighandle_out = handleReturnHandle(fighandle_og, fighandle_ret)
    if isempty(fighandle_ret)
        fighandle_out = fighandle_og;
    else
        fighandle_out = fighandle_ret;
    end
end
