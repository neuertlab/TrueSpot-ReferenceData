%
%%  !! UPDATE TO YOUR BASE DIR
%BaseDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
BaseDir = 'D:\usr\bghos\labdat\imgproc';

%ImgProcDir = 'D:\Users\hospelb\labdata\imgproc';
ImgProcDir = 'D:\usr\bghos\labdat\imgproc';

%ImgDir = 'C:\Users\hospelb\labdata\imgproc';
ImgDir = 'D:\usr\bghos\labdat\imgproc';

TblOutDir = [BaseDir filesep 'tables'];
FigOutDir = [ImgProcDir filesep 'figures' filesep 'curvereg'];
ResultsDir = [BaseDir filesep 'data' filesep 'results'];

addpath('./core');
addpath('./test');

% ========================== Constants ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];

AllTablePaths = {TablePath_Main, TablePath_Mass, TablePath_YTC};
ImgTableCount = size(AllTablePaths, 2);

OutTablePath = [TblOutDir filesep 'thflags.tsv'];

ImageTableCols = {'IMGNAME', 'IS_SIM', 'HB_AUC', 'HB_FSCORE', 'LEADIN', 'FALLOFF', 'ELBOW',...
    'SIGNAL', 'DROPOUT', 'FLAG_SPOTMAX', 'FLAG_DIFFMAX', 'FLAG_GENTLEMAX', 'FLAG_LOGDIFF'...
    'FLAG_DIAG', 'FLAG_SLOWFALL', 'FLAG_SLOWBEND', 'FLAG_LONGLEAD', 'FLAG_NODROP', 'FLAG_LO', 'FLAG_HI'};
ImageTableColCount = size(ImageTableCols,2);

%For column placeholding
REGCOUNT = 5;
FLAGCOUNT = 11;

% ========================== Prep ==========================

if ~isfolder(TblOutDir)
    mkdir(TblOutDir);
end

OutTableFile = fopen(OutTablePath, 'w');

for i = 1:ImageTableColCount
    if i ~= 1; fprintf(OutTableFile, '\t'); end
    fprintf(OutTableFile, ImageTableCols{i});
end
fprintf(OutTableFile, '\n');

% ========================== Do Things ==========================

for t = 1:ImgTableCount
    fprintf('Trying Table %s...\n', AllTablePaths{t});
    image_table = testutil_opentable(AllTablePaths{t});

    entry_count = size(image_table, 1);
    for r = 1:entry_count
        myname = getTableValue(image_table, r, 'IMGNAME');
        fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);

        %Get res file path
        set_group_dir = getSetOutputDirName(myname);
        ResFilePath = [ResultsDir filesep set_group_dir filesep myname '_summary.mat'];

        is_sim = false;
        if startsWith(myname, 'simvar') | startsWith(myname, 'sim_') | startsWith(myname, 'rsfish_sim')
            is_sim = true;
        end

        if isfile(ResFilePath)
            load(ResFilePath, 'analysis');
            fprintf(OutTableFile, '%s\t%d\t', myname, is_sim);
            
            if isfield(analysis, 'results_hb')
                prauc = NaN;
                fscore = NaN;

                if isfield(analysis.results_hb, 'performance')
                    T = size(analysis.results_hb.performance, 1);
                    spot_table = NaN(T,2);

                    spot_table(:,1) = analysis.results_hb.performance{:,'thresholdValue'};
                    spot_table(:,2) = analysis.results_hb.performance{:,'spotCount'};
                    prauc = analysis.results_hb.pr_auc;
                    fscore = analysis.results_hb.fscore_autoth;
                else
                    thres = analysis.results_hb.threshold_details;
                    T = size(analysis.results_hb.threshold_details.x, 1);
                    spot_table = NaN(T,2);
                    spot_table(:,1) = analysis.results_hb.threshold_details.x(:,1);
                    dropout_th = analysis.results_hb.callset{:,'dropout_thresh'};
                    for j = 1:T
                        thval = spot_table(j,1);
                        spot_table(j,2) = nnz(dropout_th >= thval);
                    end
                end

                %Check flags and regions...
                th_res = RNA_Threshold_Common.genEmptyThresholdResultStruct();
                th_res.threshold = analysis.results_hb.threshold;
                th_res.regions = RNA_Threshold_Common.estimateCurveFeatureRegions(spot_table);
                th_res = RNA_Threshold_Common.flagCurveFeatures(spot_table, th_res);

                %Output
                fprintf(OutTableFile, '%f\t%f\t', prauc, fscore);
                fprintf(OutTableFile, '%d,%d\t', th_res.regions.LeadinStart, th_res.regions.LeadinEnd);
                fprintf(OutTableFile, '%d,%d\t', th_res.regions.FalloffStart, th_res.regions.FalloffEnd);
                fprintf(OutTableFile, '%d,%d\t', th_res.regions.ElbowStart, th_res.regions.ElbowEnd);
                fprintf(OutTableFile, '%d,%d\t', th_res.regions.SignalStart, th_res.regions.SignalEnd);
                fprintf(OutTableFile, '%d,%d\t', th_res.regions.DropoutStart, th_res.regions.DropoutEnd);

                fprintf(OutTableFile, '%d\t', th_res.flags.low_spot_max);
                fprintf(OutTableFile, '%d\t', th_res.flags.low_slope_max);
                fprintf(OutTableFile, '%d\t', th_res.flags.gentle_max_slope);
                fprintf(OutTableFile, '%d\t', th_res.flags.low_max_th_logdiff);
                fprintf(OutTableFile, '%d\t', th_res.flags.possible_diag_feature);
                fprintf(OutTableFile, '%d\t', th_res.flags.slow_fall);
                fprintf(OutTableFile, '%d\t', th_res.flags.slow_elbow);
                fprintf(OutTableFile, '%d\t', th_res.flags.slow_leadin);
                fprintf(OutTableFile, '%d\t', th_res.flags.possible_nodrop);
                fprintf(OutTableFile, '%d\t', th_res.flags.th_likely_low);
                fprintf(OutTableFile, '%d\n', th_res.flags.th_likely_high);

                fig_out_dir = [FigOutDir filesep set_group_dir];
                if ~isfolder(fig_out_dir)
                    mkdir(fig_out_dir);
                end
                [fig_s, fig_d] = plotThRegions(spot_table, th_res.regions);
                if ~isempty(fig_s)
                    saveas(fig_s, [fig_out_dir filesep myname '_spots.png']);
                    close(fig_s);
                end
                if ~isempty(fig_d)
                    saveas(fig_d, [fig_out_dir filesep myname '_absdiff.png']);
                    close(fig_d);
                end

            else
                %Output NaN line
                fprintf(OutTableFile, 'NaN\tNaN');
                for j = 1:REGCOUNT
                    fprintf(OutTableFile, '\t0,0');
                end
                for j = 1:FLAGCOUNT
                    fprintf(OutTableFile, '\t-1');
                end
                fprintf(OutTableFile, '\n');
            end

        else
            fprintf('Could not find summary file. Skipping...\n');
        end

    end
end

% ========================== Close Output Files ==========================

fclose(OutTableFile);

% ========================== Helper Functions ==========================

function [fig_s, fig_d] = plotThRegions(spot_table, reg_struct)
    fig_s = []; fig_d = [];

    if isempty(spot_table); return; end
    if isempty(reg_struct); return; end

    T = size(spot_table,1);
    absdiff = zeros(T,1);
    absdiff(2:T,1) = abs(diff(spot_table(:,2)));

    fig_s = figure(1);
    logspots = log10(double(spot_table(:,2)));
    plot(spot_table(:,1), logspots,'LineWidth',2,'Color','black');
    hold on;

    fig_d = figure(2);
    logabsdiff = log10(absdiff(:,1));
    plot(spot_table(:,1), logabsdiff, 'LineWidth',2,'Color','black');
    hold on;

    color_leadin = [1 0 0];
    color_falloff = [0.7 0.7 0];
    color_elbow = [0 0.8 0];
    color_signal = [0 0 0.8];
    color_dropout = [0.8 0 0.8];

%     if reg_struct.LeadinStart > 0
%         figure(fig_s);
%         xline(reg_struct.LeadinStart, ':', 'Lead-in', 'Color', color_leadin,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
%         figure(fig_d);
%         xline(reg_struct.LeadinStart, ':', 'Lead-in', 'Color', color_leadin,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
%     end

    if reg_struct.LeadinEnd > 0
        figure(fig_s);
        xline(reg_struct.LeadinEnd, ':', 'Lead-in', 'Color', color_leadin,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.LeadinEnd, ':', 'Lead-in', 'Color', color_leadin,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.FalloffStart > 0
        figure(fig_s);
        xline(reg_struct.FalloffStart, ':', 'Falloff', 'Color', color_falloff,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.FalloffStart, ':', 'Falloff', 'Color', color_falloff,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.FalloffEnd > 0
        figure(fig_s);
        xline(reg_struct.FalloffEnd, ':', 'Falloff', 'Color', color_falloff,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.FalloffEnd, ':', 'Falloff', 'Color', color_falloff,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.ElbowStart > 0
        figure(fig_s);
        xline(reg_struct.ElbowStart, ':', 'Elbow', 'Color', color_elbow,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.ElbowStart, ':', 'Elbow', 'Color', color_elbow,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.ElbowEnd > 0
        figure(fig_s);
        xline(reg_struct.ElbowEnd, ':', 'Elbow', 'Color', color_elbow,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.ElbowEnd, ':', 'Elbow', 'Color', color_elbow,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.SignalStart > 0
        figure(fig_s);
        xline(reg_struct.SignalStart, ':', 'Signal', 'Color', color_signal,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.SignalStart, ':', 'Signal', 'Color', color_signal,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.SignalEnd > 0
        figure(fig_s);
        xline(reg_struct.SignalEnd, ':', 'Signal', 'Color', color_signal,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.SignalEnd, ':', 'Signal', 'Color', color_signal,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

    if reg_struct.DropoutStart > 0
        figure(fig_s);
        xline(reg_struct.DropoutStart, ':', 'Dropout', 'Color', color_dropout,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        xline(reg_struct.DropoutEnd, ':', 'Dropout', 'Color', color_dropout,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        figure(fig_d);
        xline(reg_struct.DropoutStart, ':', 'Dropout', 'Color', color_dropout,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
        xline(reg_struct.DropoutEnd, ':', 'Dropout', 'Color', color_dropout,'LineWidth',1,'LabelHorizontalAlignment','center','LabelVerticalAlignment','middle');
    end

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
    else
        if startsWith(groupname, 'ROI')
            dirname = 'munsky_lab';
        else
            dirname = groupname;
        end
    end
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end

