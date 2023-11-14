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

SimResCSVPath = [BaseDir filesep 'sim_results.csv'];

DateDir = '20230606';
DateSuffix = '230606';
OutDir = [ImgProcDir filesep 'figures' filesep DateDir];

% ========================== Parameters ==========================

DO_HB = true;
DO_BF = true;
DO_RS = true;
DO_DB = true;

HB_TRIMMED = true;
MAX_ZEROPROP = 0.0;
SNR_MAX = 240;
EXP_MAX = 5000; %Max spots generated
NORM_TO = 0;

DO_PRAUC = true;
DO_FSCORE = true;
DO_SPOTSVS = true;
DO_RECALL = true;

% ========================== Read Table ==========================

fmt_string = ['%s' repmat('%f', 1, 5) '%s' repmat('%f', 1, 22) '%s%s'];
simres_table = readtable(SimResCSVPath,'Delimiter',',','ReadVariableNames',true,'Format',...
    fmt_string);

% ========================== Do plot ==========================


%Filter..
if MAX_ZEROPROP > 0
    keeprows = find(~isnan(simres_table{:, 'FILT_PROP_ZERO'}));
    simres_table = simres_table(keeprows,:);
    keeprows = find(simres_table{:, 'FILT_PROP_ZERO'} <= MAX_ZEROPROP);
    simres_table = simres_table(keeprows,:);
    zpstr = sprintf('%02d', MAX_ZEROPROP * 100);
else
    zpstr = 'n';
end

bkg_lvl = simres_table{:, 'BKG_LVL'};
amp_lvl = simres_table{:, 'AMP_LVL'};
%snr = amp_lvl ./ bkg_lvl;

actual_spots = simres_table{:, 'SPOTS_ACTUAL'};
actual_spots_log = log10(double(actual_spots));
fzprop = simres_table{:, 'FILT_PROP_ZERO'};
bkg_var = simres_table{:, 'BKG_VAR'};
amp_var = simres_table{:, 'AMP_VAR'};
snr = amp_lvl ./ (bkg_lvl .* bkg_var);

%snr_unit = max(snr, [], 'all', 'omitnan') / 20;
snr_unit = SNR_MAX / 20;
f = 1;

maxcounts = NaN(1,6);

%Zeroprop vs. SNR
[fig, ~] = doHeatmap(f, snr, fzprop, snr_unit, 0.05, 0.5, NORM_TO);
f = f + 1;
title('Zero Voxel Proportion vs. SNR');
ylabel('Zero Voxel Proportion');
saveas(fig, [OutDir filesep 'zp' zpstr '_zvp_heatmap_' DateSuffix '.svg']);

if DO_HB
    if HB_TRIMMED
        pr_auc = simres_table{:, 'PRAUC_HBTr'};
        f_scores = simres_table{:, 'HBTr_FSCORE'};
        spot_det = simres_table{:, 'HBTr_SPOTS'};
        recall = simres_table{:, 'HBTr_MAXREC'};
    else
        pr_auc = simres_table{:, 'PRAUC_HB'};
        f_scores = simres_table{:, 'HB_FSCORE'};
        spot_det = simres_table{:, 'HB_SPOTS'};
        recall = simres_table{:, 'HB_MAXREC'};
    end

    if DO_PRAUC
        [fig, maxcounts(1)] = doHeatmap(f, snr, pr_auc, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC (Homebrew)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_hb_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, actual_spots_log, pr_auc, 0.2, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC vs. Expression (Homebrew)');
        xlabel('log10(Actual Spots)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_aucvexp_hb_heatmap_' DateSuffix '.svg']);
    end

    if DO_FSCORE
        [fig, maxcounts(2)] = doHeatmap(f, snr, f_scores, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image F-Scores (Homebrew)');
        ylabel('F-Score');
        saveas(fig, [OutDir filesep 'zp' zpstr '_fscore_hb_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, fzprop, f_scores, 0.05, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image F-Scores vs. zvp (Homebrew)');
        xlabel('Zero Voxel Proportion');
        ylabel('F-Score');
        saveas(fig, [OutDir filesep 'zp' zpstr '_fsvzvp_hb_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, actual_spots_log, f_scores, 0.2, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image F-Scores vs. Expression (Homebrew)');
        xlabel('log10(Actual Spots)');
        ylabel('F-Score');
        saveas(fig, [OutDir filesep 'zp' zpstr '_fsvexp_hb_heatmap_' DateSuffix '.svg']);
    end

    if DO_RECALL
        [fig, ~] = doHeatmap(f, snr, recall, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image Recall (Homebrew)');
        ylabel('Recall');
        saveas(fig, [OutDir filesep 'zp' zpstr '_recall_hb_heatmap_' DateSuffix '.svg']);
    end

end

if DO_BF
    pr_auc = simres_table{:, 'PRAUC_BF'};
    f_scores = simres_table{:, 'BF_FSCORE'};
    spot_det = simres_table{:, 'BF_SPOTS'};
    recall = simres_table{:, 'BF_MAXREC'};

    if DO_PRAUC
        [fig, maxcounts(3)] = doHeatmap(f, snr, pr_auc, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC (BigFISH)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_bf_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, actual_spots_log, pr_auc, 0.2, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC vs. Expression (BigFISH)');
        xlabel('log10(Actual Spots)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_aucvexp_bf_heatmap_' DateSuffix '.svg']);
    end

    if DO_FSCORE
        [fig, maxcounts(4)] = doHeatmap(f, snr, f_scores, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image F-Scores (BigFISH)');
        ylabel('F-Score');
        saveas(fig, [OutDir filesep 'zp' zpstr '_fscore_bf_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, fzprop, f_scores, 0.05, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image F-Scores vs. zvp (BigFISH)');
        xlabel('Zero Voxel Proportion');
        ylabel('F-Score');
        saveas(fig, [OutDir filesep 'zp' zpstr '_fsvzvp_bf_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, actual_spots_log, f_scores, 0.2, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image F-Scores vs. Expression (BigFISH)');
        xlabel('log10(Actual Spots)');
        ylabel('F-Score');
        saveas(fig, [OutDir filesep 'zp' zpstr '_fsvexp_bf_heatmap_' DateSuffix '.svg']);
    end

    if DO_RECALL
        [fig, ~] = doHeatmap(f, snr, recall, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image Recall (Big-FISH)');
        ylabel('Recall');
        saveas(fig, [OutDir filesep 'zp' zpstr '_recall_bf_heatmap_' DateSuffix '.svg']);
    end
    
end

if DO_RS
    pr_auc = simres_table{:, 'PRAUC_RS'};
    recall = simres_table{:, 'RS_MAXREC'};

    if DO_PRAUC
        [fig, maxcounts(5)] = doHeatmap(f, snr, pr_auc, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC (RS-FISH)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_rs_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, actual_spots_log, pr_auc, 0.2, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC vs. Expression (RS-FISH)');
        xlabel('log10(Actual Spots)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_aucvexp_rs_heatmap_' DateSuffix '.svg']);
    end

    if DO_RECALL
        [fig, ~] = doHeatmap(f, snr, recall, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image Recall (RS-FISH)');
        ylabel('Recall');
        saveas(fig, [OutDir filesep 'zp' zpstr '_recall_rs_heatmap_' DateSuffix '.svg']);
    end
end

if DO_DB
    pr_auc = simres_table{:, 'PRAUC_DB'};
    recall = simres_table{:, 'DB_MAXREC'};

    if DO_PRAUC
        [fig, maxcounts(6)] = doHeatmap(f, snr, pr_auc, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC (DeepBlink)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_prauc_db_heatmap_' DateSuffix '.svg']);

        [fig, ~] = doHeatmap(f, actual_spots_log, pr_auc, 0.2, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image PR-AUC vs. Expression (DeepBlink)');
        xlabel('log10(Actual Spots)');
        ylabel('PR-AUC');
        saveas(fig, [OutDir filesep 'zp' zpstr '_aucvexp_db_heatmap_' DateSuffix '.svg']);
    end

    if DO_RECALL
        [fig, ~] = doHeatmap(f, snr, recall, snr_unit, 0.05, 0.5, NORM_TO);
        f = f + 1;
        title('Simulated Image Recall (DeepBlink)');
        ylabel('Recall');
        saveas(fig, [OutDir filesep 'zp' zpstr '_recall_db_heatmap_' DateSuffix '.svg']);
    end
end

% ========================== Helper functions ==========================

function [fig_handle, max_count] = doHeatmap(figno, x, y, x_unit, y_unit, color_lim, norm, x_boxes, y_boxes)

    if nargin < 6; color_lim = 0.5; end
    if nargin < 7; norm = 0; end
    if nargin < 8; x_boxes = 20; end
    if nargin < 9; y_boxes = 20; end
    
    x_max = x_boxes * x_unit;
    y_max = y_boxes * y_unit;

    x_bounds = [0:x_unit:x_max];
    y_bounds = [0:y_unit:y_max];

    countmtx = NaN(y_boxes, x_boxes);
    for i = 1:x_boxes
        x_lo = x_bounds(i);
        x_hi = x_bounds(i+1);
        boolx_lo = (x >= x_lo);
        if i == x_boxes
            boolx_hi = (x <= x_hi);
        else
            boolx_hi = (x < x_hi);
        end
        boolx = boolx_hi & boolx_lo;

        for j = 1:y_boxes
            y_lo = y_bounds(j);
            y_hi = y_bounds(j+1);
            booly_lo = (y >= y_lo);
            if i == y_boxes
                booly_hi = (y <= y_hi);
            else
                booly_hi = (y < y_hi);
            end
            booly = booly_hi & booly_lo;
            boolxy = boolx & booly;
            countmtx(j,i) = nnz(boolxy);
        end
    end

    xlbl = x_bounds(1:x_boxes);
    ylbl = y_bounds(1:y_boxes);
    max_count = max(countmtx, [], 'all', 'omitnan');
    total = size(x,1);
    if norm > 0
        countmtx = countmtx ./ norm;
    else
        countmtx = countmtx ./ total;
    end

    %Invert y
    ylbl = flip(ylbl);
    countmtx = flip(countmtx, 1);

    fig_handle = figure(figno);
    clf;
    hm = heatmap(xlbl, ylbl, countmtx);
    hm.Colormap = turbo;
    hm.ColorLimits = [0.0 color_lim];
    hm.CellLabelColor = 'none';
    xlabel('SNR');
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end