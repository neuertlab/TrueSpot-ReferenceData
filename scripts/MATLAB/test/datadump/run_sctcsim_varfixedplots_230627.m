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

TMRL_FIXED_TH_HB = 137;
TMRL_FIXED_TH_BF = 403;

CY5L_FIXED_TH_HB = 187;
CY5L_FIXED_TH_BF = 186;

COLOR_HB = [0.667 0.220 0.220];
COLOR_HBT = [0.667 0.320 0.320];
COLOR_BF = [0.000 0.000 1.000];

ResultsDir = [BaseDir filesep 'data' filesep 'results'];

% ========================== Read Table ==========================

InputTablePath = [BaseDir filesep 'test_images_simytc.csv'];

image_table = testutil_opentable(InputTablePath);

% ========================== Import Values ==========================

row_count = size(image_table,1);

actual_counts = NaN(250, 2);
actual_counts_hbt = NaN(250, 2);
hb_counts_var = NaN(250, 2);
hbt_counts_var = NaN(250, 2);
bft_counts_var = NaN(250, 2);
hb_counts_fix = NaN(250, 2);
hbt_counts_fix = NaN(250, 2);
bft_counts_fix = NaN(250, 2);

i = 1;
j = 1;
for r = 1:row_count
    myname = getTableValue(image_table, r, 'IMGNAME');
    set_group_dir = getSetOutputDirName(myname);
    ResFilePath = [ResultsDir filesep set_group_dir filesep myname '_summary.mat'];

    fprintf('Now processing %s (%d of %d)...\n', myname, r, row_count);

    if ~isfile(ResFilePath); continue; end

    pos = i;
    ch = 1;
    th_fixed_hb = CY5L_FIXED_TH_HB;
    th_fixed_bf = CY5L_FIXED_TH_BF;
    if contains(myname, 'TMRL')
        ch = 2;
        pos = j;
        th_fixed_hb = TMRL_FIXED_TH_HB;
        th_fixed_bf = TMRL_FIXED_TH_BF;
    end

    load(ResFilePath, 'analysis');

    if ~isfield(analysis, 'simparam'); continue; end

    actual_counts(pos, ch) = analysis.simparam.spots_actual;

    if isfield(analysis, 'results_hb')
        th_var = analysis.results_hb.threshold;
       
        if isfield(analysis.results_hb, 'callset')
            if th_var > 0
                findres = find((analysis.results_hb.callset{:,'dropout_thresh'} >= th_var)...
                    & ~analysis.results_hb.callset{:,'is_trimmed_out'});
                if ~isempty(findres)
                    hbt_counts_var(pos, ch) = size(findres, 1);
                else
                    hbt_counts_var(pos, ch) = 0;
                end

                findres = find(analysis.results_hb.callset{:,'dropout_thresh'} >= th_var);
                if ~isempty(findres)
                    hb_counts_var(pos, ch) = size(findres, 1);
                else
                    hb_counts_var(pos, ch) = 0;
                end
                clear findres
            end

            findres = find((analysis.results_hb.callset{:,'dropout_thresh'} >= th_fixed_hb)...
                & ~analysis.results_hb.callset{:,'is_trimmed_out'});
            if ~isempty(findres)
                hbt_counts_fix(pos, ch) = size(findres, 1);
            else
                hbt_counts_fix(pos, ch) = 0;
            end

            findres = find(analysis.results_hb.callset{:,'dropout_thresh'} >= th_fixed_hb);
            if ~isempty(findres)
                hb_counts_fix(pos, ch) = size(findres, 1);
            else
                hb_counts_fix(pos, ch) = 0;
            end
            clear findres

            %Trim...
            findres = find((analysis.results_hb.callset{:,'is_true'})...
                & ~analysis.results_hb.callset{:,'is_trimmed_out'});
            if ~isempty(findres)
                actual_counts_hbt(pos, ch) = size(findres, 1);
            else
                actual_counts_hbt(pos, ch) = 0;
            end

            clear findres
        end
        clear th_var
    end

    if isfield(analysis, 'results_bf')
        th_var = analysis.results_bf.threshold;
       
        if isfield(analysis.results_bf, 'callset')
            if th_var > 0
                findres = find((analysis.results_bf.callset{:,'dropout_thresh'} >= th_var)...
                    & ~analysis.results_bf.callset{:,'is_trimmed_out'});
                if ~isempty(findres)
                    bft_counts_var(pos, ch) = size(findres, 1);
                else
                    bft_counts_var(pos, ch) = 0;
                end
                clear findres
            end

            findres = find((analysis.results_bf.callset{:,'dropout_thresh'} >= th_fixed_bf)...
                & ~analysis.results_bf.callset{:,'is_trimmed_out'});
            if ~isempty(findres)
                bft_counts_fix(pos, ch) = size(findres, 1);
            else
                bft_counts_fix(pos, ch) = 0;
            end
            clear findres
        end
        clear th_var
    end

    %Increment pos
    if ch == 1
        i = i + 1;
    else
        j = j + 1;
    end

    clear analysis myname set_group_dir ResFilePath ch pos th_fixed_hb th_fixed_bf
end

% ========================== Render Plots ==========================

%For channel...
%   HBVar   HBFixed
%   HBTVar   HBTFixed
%   BFTVar   BFTFixed

%CY5L
figure(1);
clf;
hold on;

genScatterCurrentFig(hb_counts_var(:,1), actual_counts(:,1), COLOR_HB, 1);
genScatterCurrentFig(hb_counts_fix(:,1), actual_counts(:,1), COLOR_HB, 2);
genScatterCurrentFig(hbt_counts_var(:,1), actual_counts_hbt(:,1), COLOR_HBT, 3);
genScatterCurrentFig(hbt_counts_fix(:,1), actual_counts_hbt(:,1), COLOR_HBT, 4);
genScatterCurrentFig(bft_counts_var(:,1), actual_counts_hbt(:,1), COLOR_BF, 5);
genScatterCurrentFig(bft_counts_fix(:,1), actual_counts_hbt(:,1), COLOR_BF, 6);

%TMRL
figure(2);
clf;
hold on;

genScatterCurrentFig(hb_counts_var(:,2), actual_counts(:,2), COLOR_HB, 1);
genScatterCurrentFig(hb_counts_fix(:,2), actual_counts(:,2), COLOR_HB, 2);
genScatterCurrentFig(hbt_counts_var(:,2), actual_counts_hbt(:,2), COLOR_HBT, 3);
genScatterCurrentFig(hbt_counts_fix(:,2), actual_counts_hbt(:,2), COLOR_HBT, 4);
genScatterCurrentFig(bft_counts_var(:,2), actual_counts_hbt(:,2), COLOR_BF, 5);
genScatterCurrentFig(bft_counts_fix(:,2), actual_counts_hbt(:,2), COLOR_BF, 6);

% ========================== Helper Functions ==========================

function genScatterCurrentFig(det_spots, actual_spots, color, subplot_no)

    %Remove NaNs...
    okay_idx = find(~isnan(det_spots) & ~isnan(actual_spots));
    det_spots = det_spots(okay_idx).';
    actual_spots = actual_spots(okay_idx).';

    %fighandle = figure(figno);
    %clf;
    subplot(3,2,subplot_no);
    plot(actual_spots, det_spots, 'LineStyle', 'none', ...
        'Marker', 'o', 'MarkerFaceColor', color, 'MarkerEdgeColor', 'none', 'MarkerSize', 3);
    hold on;

    drawXeqYLine();

    xlabel('Actual Spots');
    ylabel('Detected Spots');

    %title(plot_title);
end

function drawXeqYLine()
    ax = gca;
    xmax = ax.XLim(2);
    ymax = ax.YLim(2);
    xymax = max(xmax, ymax);
    plot([0 xymax], [0 xymax], 'LineStyle', '-', 'LineWidth', 1, 'Color', 'black');
    hold on;
end

function dirname = getSetOutputDirName(imgname)
    inparts = split(imgname, '_');
    groupname = inparts{1,1};
    if strcmp(groupname, 'sctc')
        dirname = [groupname filesep inparts{2,1}];
    elseif strcmp(groupname, 'simvarmass')
        if contains(imgname, 'TMRL') | contains(imgname, 'CY5L')
            dirname = 'simytc';
        else
            dirname = groupname;
        end
    elseif startsWith(imgname, 'ROI')
        dirname = 'munsky_lab';
    else
        dirname = groupname;
    end
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end