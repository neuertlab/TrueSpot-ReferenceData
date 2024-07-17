%
%%  !! UPDATE TO YOUR BASE DIR
%BaseDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
BaseDir = 'D:\usr\bghos\labdat\imgproc';

%ImgProcDir = 'D:\Users\hospelb\labdata\imgproc';
ImgProcDir = 'D:\usr\bghos\labdat\imgproc';

%ImgDir = 'C:\Users\hospelb\labdata\imgproc';
ImgDir = 'D:\usr\bghos\labdat\imgproc';

addpath('./core');
addpath('./test');

% ========================== Constants ==========================

SimResCSVPath = [BaseDir filesep 'sim_results_240426.csv'];

DateDir = '20240527';
DateSuffix = '240527';
OutDir = [ImgProcDir filesep 'figures' filesep DateDir];

% ========================== Parameters ==========================

DO_HB = true;
DO_BF = true;
DO_RS = true;
DO_DB = true;

HB_TRIMMED = true;
MAX_ZEROPROP = 0.70;

DO_PRAUC = false;
DO_FSCORE = false;
DO_SPOTSVS = true;

% ========================== Read Table ==========================

fmt_string = ['%s' repmat('%f', 1, 6) '%s' repmat('%f', 1, 47) '%s%s'];
simres_table = readtable(SimResCSVPath,'Delimiter',',','ReadVariableNames',true,'Format',...
    fmt_string);

% ========================== Do plot ==========================

%Filter..
if MAX_ZEROPROP > 0.0
    keeprows = find(~isnan(simres_table{:, 'FILT_PROP_ZERO'}));
    simres_table = simres_table(keeprows,:);
    keeprows = find(simres_table{:, 'FILT_PROP_ZERO'} <= MAX_ZEROPROP);
    simres_table = simres_table(keeprows,:);
    zpstr = sprintf('%02d', uint16(MAX_ZEROPROP * 100));
else
    zpstr = 'n';
end

bkg_lvl = simres_table{:, 'BKG_LVL'};
amp_lvl = simres_table{:, 'AMP_LVL'};
%snr = amp_lvl ./ bkg_lvl;

actual_spots = simres_table{:, 'SPOTS_ACTUAL_XYTRIM'};
fzprop = simres_table{:, 'FILT_PROP_ZERO'};
bkg_var = simres_table{:, 'BKG_VAR'};
amp_var = simres_table{:, 'AMP_VAR'};
snr = amp_lvl ./ (bkg_lvl .* bkg_var);

if DO_HB
    if HB_TRIMMED
        pr_auc = simres_table{:, 'PRAUC_HBTr'};
        f_scores = simres_table{:, 'HBTr_FSCORE'};
        spot_det = simres_table{:, 'HBTr_SPOTS'};
    else
        pr_auc = simres_table{:, 'PRAUC_HB'};
        f_scores = simres_table{:, 'HB_FSCORE'};
        spot_det = simres_table{:, 'HB_SPOTS'};
    end

    if DO_PRAUC
        %MakeRedBlueScatterplot(snr, pr_auc, amp_var, bkg_var, 'SNR', 'PR-AUC', 1);
        fig = makeScatterplot(snr, pr_auc, 'SNR', 'PR-AUC', 1);
        ylim([0 1]);
        title('Simulated Image PR-AUC (Homebrew)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_hb_scatterb_' DateSuffix '.svg']);
    end

    if DO_FSCORE
        %MakeRedBlueScatterplot(snr, f_scores, amp_var, bkg_var, 'SNR', 'F-Score', 2);
        fig = makeScatterplot(snr, f_scores, 'SNR', 'F-Score', 2);
        %MakeRedBlueScatterplot(snr, f_scores, actual_spots, fzprop, 'SNR', 'F-Score', 2);
        ylim([0 1]);
        title('Simulated Image F-Score (Homebrew)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_fscore_hb_scatterb_' DateSuffix '.svg']);
    end

    if DO_SPOTSVS
        fig = makeScatterplot(actual_spots, spot_det, 'Actual Spots', 'Detected Spots', 3);
        maxval = max(actual_spots, [], 'all', 'omitnan');
        maxval = max(maxval, max(spot_det, [], 'all', 'omitnan'));
        ylim([0 maxval]);
        xlim([0 maxval]);
        drawXeqYLine();
        title('Detected vs. Simulated Spots (Homebrew)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_spots_hb_scatterb_' DateSuffix '.svg']);
    end

end

if DO_BF
    pr_auc = simres_table{:, 'PRAUC_BFTr'};
    f_scores = simres_table{:, 'BFTr_FSCORE'};
    spot_det = simres_table{:, 'BFTr_SPOTS'};

    if DO_PRAUC
        %MakeRedBlueScatterplot(snr, pr_auc, amp_var, bkg_var, 'SNR', 'PR-AUC', 4);
        fig = makeScatterplot(snr, pr_auc, 'SNR', 'PR-AUC', 4);
        ylim([0 1]);
        title('Simulated Image PR-AUC (Big-FISH)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_bf_scatterb_' DateSuffix '.svg']);
    end

    if DO_FSCORE
        %MakeRedBlueScatterplot(snr, f_scores, amp_var, bkg_var, 'SNR', 'F-Score', 5);
        fig = makeScatterplot(snr, f_scores, 'SNR', 'F-Score', 5);
        %MakeRedBlueScatterplot(snr, f_scores, actual_spots, fzprop, 'SNR', 'F-Score', 5);
        ylim([0 1]);
        title('Simulated Image F-Score (Big-FISH)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_fscore_bf_scatterb_' DateSuffix '.svg']);
    end

    if DO_SPOTSVS
        fig = makeScatterplot(actual_spots, spot_det, 'Actual Spots', 'Detected Spots', 6);
        maxval = max(actual_spots, [], 'all', 'omitnan');
        maxval = max(maxval, max(spot_det, [], 'all', 'omitnan'));
        ylim([0 maxval]);
        xlim([0 maxval]);
        drawXeqYLine();
        title('Detected vs. Simulated Spots (Big-FISH)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_spots_bf_scatterb_' DateSuffix '.svg']);
    end

end

if DO_RS
    pr_auc = simres_table{:, 'PRAUC_RS'};

    if DO_PRAUC
        %MakeRedBlueScatterplot(snr, pr_auc, amp_var, bkg_var, 'SNR', 'PR-AUC', 7);
        fig = makeScatterplot(snr, pr_auc, 'SNR', 'PR-AUC', 7);
        ylim([0 1]);
        title('Simulated Image PR-AUC (RS-FISH)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_rs_scatterb_' DateSuffix '.svg']);
    end
end

if DO_DB
    pr_auc = simres_table{:, 'PRAUC_DB'};

    if DO_PRAUC
        %MakeRedBlueScatterplot(snr, pr_auc, amp_var, bkg_var, 'SNR', 'PR-AUC', 10);
        fig = makeScatterplot(snr, pr_auc, 'SNR', 'PR-AUC', 10);
        ylim([0 1]);
        title('Simulated Image PR-AUC (DeepBlink)');
        cleanupFormatting();
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_db_scatterb_' DateSuffix '.svg']);
    end
end

if DO_HB & DO_BF & DO_FSCORE
    fs_hb = simres_table{:, 'HB_FSCORE'};
    fs_bf = simres_table{:, 'BF_FSCORE'};
    fig = makeScatterplot(fs_bf, fs_hb, 'F-Score (BF)', 'F-Score (HB)', 11);
    ylim([0 1]);
    xlim([0 1]);
    drawXeqYLine();
    title('F-Scores Homebrew vs. Big-FISH');
    cleanupFormatting();
    saveas(fig, [OutDir filesep 'zp' zpstr '_fscore_hbvbf_scatterb_' DateSuffix '.svg']);
end

% ========================== Helper functions ==========================

function fig_handle = makeScatterplot(x_data, y_data, xlbl, ylbl, figno)
    is_bad = ~isfinite(x_data) | ~isfinite(y_data);
    keepidx = find(~is_bad);
    x_data = x_data(keepidx);
    y_data = y_data(keepidx);

    rdim = size(x_data, 1);
    cdim = size(x_data, 2);
    if rdim > cdim
        x_data = x_data.';
        y_data = y_data.';
    end

    fig_handle = figure(figno);
    clf;
    hold on;
    plot(x_data, y_data, 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'none',...
            'MarkerFaceColor', 'black', 'MarkerSize', 3);

    %Labels
    xlabel(xlbl);
    ylabel(ylbl);
end

function cleanupFormatting()
    set(gca,'FontSize',12);
end

function drawXeqYLine()
    ax = gca;
    xmax = ax.XLim(2);
    ymax = ax.YLim(2);
    xymax = max(xmax, ymax);
    plot([0 xymax], [0 xymax], 'LineStyle', '-', 'LineWidth', 1, 'Color', 'black');
    hold on;
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end