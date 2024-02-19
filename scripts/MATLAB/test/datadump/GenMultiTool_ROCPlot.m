%
%%

%Colors:
%   HB: #aa3838 [0.667 0.220 0.220]

function fig_handle = GenMultiTool_ROCPlot(img_summary, figno)

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
    PlotIndivPRCurve(img_summary.results_hb, COLOR_HB, LINE_WIDTH, LINE_STYLE);
    xlim([0.0 1.0]);
    ylim([0.0 1.0]);
    fig_handle_temp = fig_handle;
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderROCPlot('homebrew', [1.0 0.0 0.0], 1, figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('Neuert Lab');

subplot(2,2,2);
if isfield(img_summary, 'results_bf')
    PlotIndivPRCurve(img_summary.results_bf, COLOR_BF, LINE_WIDTH, LINE_STYLE);
    xlim([0.0 1.0]);
    ylim([0.0 1.0]);
    fig_handle_temp = fig_handle;
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderROCPlot('bigfish', [0.0 0.0 1.0], 1, figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('BigFISH');

subplot(2,2,3);
if isfield(img_summary, 'results_rs')
    PlotIndivPRCurve(img_summary.results_rs, COLOR_RS, LINE_WIDTH, LINE_STYLE);
    xlim([0.0 1.0]);
    ylim([0.0 1.0]);
    fig_handle_temp = fig_handle;
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderROCPlot('rsfish', [0.0 0.8 0.0], 1, figno, fig_handle);
fig_handle = handleReturnHandle(fig_handle, fig_handle_temp);
title('RS-FISH');

subplot(2,2,4);
if isfield(img_summary, 'results_db')
    PlotIndivPRCurve(img_summary.results_db, COLOR_DB, LINE_WIDTH, LINE_STYLE);
    xlim([0.0 1.0]);
    ylim([0.0 1.0]);
    fig_handle_temp = fig_handle;
else
    fig_handle_temp = [];
end
%fig_handle_temp = img_results_obj.renderROCPlot('deepblink', [0.7 0.7 0.0], 1, figno, fig_handle);
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