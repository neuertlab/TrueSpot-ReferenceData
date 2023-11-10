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

% ========================== General Context ==========================

scriptCtx = genScriptContextStruct(BaseDir);
scriptCtx.ImgProcDir = ImgProcDir;
scriptCtx.ImgDir = ImgDir;

scriptCtx.DateSuffix = '230724';
scriptCtx.OutputDir = [ImgProcDir filesep 'tables'];

% ========================== Parameters ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];

AllTablePaths = {TablePath_Main, TablePath_Mass, TablePath_YTC};
ImgTableCount = size(AllTablePaths, 2);

% ========================== Main Loop ==========================

scriptCtx = initialize(scriptCtx);

for t = 1:ImgTableCount
    fprintf('Trying Table %s...\n', AllTablePaths{t});
    image_table = testutil_opentable(AllTablePaths{t});

    entry_count = size(image_table, 1);
    scriptCtx.ImageInfoTable = image_table;
    for r = 1:entry_count
        scriptCtx.TableRow = r;

        myname = getTableValue(image_table, r, 'IMGNAME');
        fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);
        if shouldSkip(myname)
            fprintf('\t> Skipping for this operation...\n');
            continue;
        end

        %Get res file path
        set_group_dir = getSetOutputDirName(myname);
        ResFilePath = [scriptCtx.ResultsDir filesep set_group_dir filesep myname '_summary.mat'];

        if isfile(ResFilePath)
            load(ResFilePath, 'analysis');
        else
            fprintf('> Could not find analysis file. Skipping...\n');
            continue;
        end

        analysis = doTheThing(scriptCtx, analysis);

        %Save
        save(ResFilePath, 'analysis');

        clear analysis set_group_dir ResFilePath myname
    end
end

scriptCtx = finalize(scriptCtx);

% ========================== Helper Functions ==========================

function ctx = initialize(ctx)
    ctx.OutputHandle = fopen([ctx.OutputDir, filesep, 'deepblink_2d_', ctx.DateSuffix, '.tsv'], 'w');
    fprintf(ctx.OutputHandle, 'IMGNAME\tDB_PRAUC\tDB_FSPEAK\tDB_MAXREC\tDBALT_PRAUC\tDBALT_FSPEAK\tDBALT_MAXREC\n');
end

function ctx = finalize(ctx)
    if isfield(ctx, 'OutputHandle')
        fclose(ctx.OutputHandle);
    end
end

function bool_res = shouldSkip(imgName)
    bool_res = false;
end

function analysis = doTheThing(ctx, analysis)
    %Clean up trim results that aren't valid any longer...

    truthset = []; %TODO

    if isfield(analysis, 'simkey')
        if isstruct(analysis.simkey)
            truthspots = size(analysis.simkey, 2);
            truthset = zeros(truthspots, 3);
            truthset(:,1) = [analysis.simkey.x];
            truthset(:,2) = [analysis.simkey.y];
            clear truthspots;
        else
            truthset = analysis.simkey(:,1:3);
            truthset = round(truthset);
        end
    end
    if isfield(analysis, 'exprefset')
        truthset = analysis.exprefset(:,1:3);
    end
    
    if isempty(truthset)
        return;
    end

    %Remove redundant xy
    truthset(:,3) = 1;
    [truthset, ~, ~] = unique(truthset, 'rows');

    fprintf(ctx.OutputHandle, '%s\t', analysis.imgname);
    
    if isfield(analysis, 'results_db')
        %Trim and truth region mask
        analysis.results_db.callset_sliced = flagOkayRegions(analysis, ...
            analysis.results_db, analysis.results_db.callset_sliced);
        analysis.results_db = db2d(analysis.results_db, truthset, ctx.OutputHandle);
        fprintf(ctx.OutputHandle, '\t');
    else
        fprintf(ctx.OutputHandle, 'NaN\tNaN\tNaN\t');
    end

    if isfield(analysis, 'results_db_simmdl')
        analysis.results_db_simmdl.callset_sliced = flagOkayRegions(analysis, ...
            analysis.results_db_simmdl, analysis.results_db_simmdl.callset_sliced);
        analysis.results_db_simmdl = db2d(analysis.results_db_simmdl, truthset, ctx.OutputHandle);
        fprintf(ctx.OutputHandle, '\n');
    else
        fprintf(ctx.OutputHandle, 'NaN\tNaN\tNaN\n');
    end

end

function callset = flagOkayRegions(analysis, rstruct, callset)

    if isfield(analysis, 'truthset_region')
        ts_okay = callset{:,'isnap_x'} >= analysis.truthset_region.x0;
        ts_okay = ts_okay & (callset{:,'isnap_x'} <= analysis.truthset_region.x1);
        ts_okay = ts_okay & (callset{:,'isnap_y'} >= analysis.truthset_region.y0);
        ts_okay = ts_okay & (callset{:,'isnap_y'} <= analysis.truthset_region.y1);
        ts_okay = ts_okay & (callset{:,'isnap_z'} >= analysis.truthset_region.z0);
        ts_okay = ts_okay & (callset{:,'isnap_z'} <= analysis.truthset_region.z1);
        callset{:,'in_truth_region'} = ts_okay;
    else
        callset{:,'in_truth_region'} = true;
    end

    callset{:,'is_trimmed_out'} = false;
    if isfield(rstruct, 'x_min')
        callset{:,'is_trimmed_out'}  = callset{:,'is_trimmed_out'} | ...
            (callset{:,'isnap_x'} < rstruct.x_min);
    end

    if isfield(rstruct, 'x_max')
        callset{:,'is_trimmed_out'}  = callset{:,'is_trimmed_out'} | ...
            (callset{:,'isnap_x'} > rstruct.x_max);
    end

    if isfield(rstruct, 'y_min')
        callset{:,'is_trimmed_out'}  = callset{:,'is_trimmed_out'} | ...
            (callset{:,'isnap_y'} < rstruct.y_min);
    end

    if isfield(rstruct, 'y_max')
        callset{:,'is_trimmed_out'}  = callset{:,'is_trimmed_out'} | ...
            (callset{:,'isnap_y'} > rstruct.x_max);
    end

    if isfield(rstruct, 'z_min')
        callset{:,'is_trimmed_out'}  = callset{:,'is_trimmed_out'} | ...
            (callset{:,'isnap_z'} < rstruct.z_min);
    end

    if isfield(rstruct, 'z_max')
        callset{:,'is_trimmed_out'}  = callset{:,'is_trimmed_out'} | ...
            (callset{:,'isnap_z'} > rstruct.z_max);
    end

end

function ctx = genScriptContextStruct(basedir)
    ctx = struct('BaseDir', basedir);
    ctx.ImgProcDir = basedir;
    ctx.ImgDir = basedir;
    ctx.ResultsDir = [basedir filesep 'data' filesep 'results'];
    ctx.OutputDir = basedir;
    ctx.ImageInfoTable = table.empty();
    ctx.TableRow = 0;
    ctx.DateSuffix = '000000';
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

function rstruct = db2d(rstruct, truthset, table_handle)
    rstruct.callset_2d = rstruct.callset_sliced;
    max_x = max(rstruct.callset_2d{:, 'isnap_x'}, [], 'all', 'omitnan');
    max_y = max(rstruct.callset_2d{:, 'isnap_y'}, [], 'all', 'omitnan');

    %Remove any rows outside evaluation zone
    okayrows = find(~rstruct.callset_2d{:, 'is_trimmed_out'} | rstruct.callset_2d{:, 'in_truth_region'});
    rstruct.callset_2d = rstruct.callset_2d(okayrows, :);
    
    %Temp - for quicker matching
    coords1 = sub2ind([max_y max_x], ...
        rstruct.callset_2d{:, 'isnap_y'}, rstruct.callset_2d{:, 'isnap_x'});
    rstruct.callset_2d{:, 'coord_1d'} = coords1;

    rstruct.callset_2d = sortrows(rstruct.callset_2d, 'dropout_thresh', 'descend');
    rstruct.callset_2d = sortrows(rstruct.callset_2d, 'coord_1d', 'ascend');

    %Merge - use row with highest dropout thresh
    [~, urows, ~] = unique(rstruct.callset_2d{:, 'coord_1d'});
    rstruct.callset_2d = rstruct.callset_2d(urows, :);

    %Match to ref
    rstruct.callset_2d{:, 'isnap_z'} = 1;
    [rstruct.callset_2d, rstruct.ref_call_map_2d] = RNACoords.updateTFCalls(...
        rstruct.callset_2d, truthset, 3, 1, 0.001);

    %Remove superfluous fields
    rstruct.callset_2d(:, 'coord_1d') = [];
    rstruct.callset_2d(:, 'isnap_z') = [];
    rstruct.callset_2d(:, 'intensity_f') = [];
    rstruct.callset_2d(:, 'zdist_ref') = [];
    rstruct.callset_2d(:, 'xyzdist_ref') = [];
    rstruct.callset_2d(:, 'fit_z') = [];

    %Performance stats
    T = 100;
    spot_table = NaN(T, 2);
    spot_table(:,1) = [0.01:0.01:1]';
%     for t = 1:T
%         rr = find(rstruct.callset_2d{:, 'dropout_thresh'} >= spot_table(t,1));
%         if ~isempty(rr)
%             spot_table(t,2) = size(rr,1);
%         else
%             spot_table(t,2) = 0;
%         end
%     end
    rstruct = runstats(rstruct, spot_table, rstruct.callset_2d);

    %Print
    fprintf(table_handle, '%f\t', rstruct.pr_auc_2d);
    fprintf(table_handle, '%f\t', rstruct.fscore_peak_2d);

    max_recall = max(rstruct.performance_2d{:,'sensitivity'}, [], 'all', 'omitnan');
    fprintf(table_handle, '%f', max_recall);

    %Stamp
    rstruct.timestamp = datetime();
end

function rstruct = runstats(rstruct, spot_table, call_table)

    vec_istrimmed = table2array(call_table(:,'is_trimmed_out'));
    vec_intsreg = table2array(call_table(:,'in_truth_region'));
    vec_isreal = table2array(call_table(:,'is_true'));
    vec_dropth = table2array(call_table(:,'dropout_thresh'));

    any_trimmed = nnz(vec_istrimmed) > 0;
    
    th_count = size(spot_table,1);
    res_untrimmed = ImageResults.initializeResTable(th_count);
    res_trimmed = table.empty();

    thval_tbl = array2table(double(spot_table(:,1)));
    res_untrimmed(:,'thresholdValue') = thval_tbl;

    if any_trimmed
        res_trimmed = ImageResults.initializeResTable(th_count);
        res_trimmed(:,'thresholdValue') = thval_tbl;
    else
        %Clean trimmed struct if it is present
        if isfield(rstruct, 'performance_trimmed_2d')
            rstruct = rmfield(rstruct, 'performance_trimmed_2d');
        end
        if isfield(rstruct, 'pr_auc_trimmed_2d')
            rstruct = rmfield(rstruct, 'pr_auc_trimmed_2d');
        end
        if isfield(rstruct, 'fscore_peak_trimmed_2d')
            rstruct = rmfield(rstruct, 'fscore_peak_trimmed_2d');
        end
        if isfield(rstruct, 'fscore_autoth_trimmed_2d')
            rstruct = rmfield(rstruct, 'fscore_autoth_trimmed_2d');
        end
    end

    sc_all = NaN(th_count,2);
    tp_all = NaN(th_count,2);
    fp_all = NaN(th_count,2);
    fn_all = NaN(th_count,2);
    for t = 1:th_count
        th = spot_table(t,1);
        pos_vec = (vec_dropth >= th) & vec_intsreg;
        tp_vec = pos_vec & vec_isreal;
        fp_vec = pos_vec & ~vec_isreal;
        fn_vec = (vec_dropth < th) & vec_intsreg & vec_isreal;

        tp_all(t,1) = nnz(tp_vec);
        fp_all(t,1) = nnz(fp_vec);
        fn_all(t,1) = nnz(fn_vec);
        sc_all(t,1) = nnz(pos_vec);

        %Repeat for trimmed, if applicable
        if any_trimmed
            pos_vec = (vec_dropth >= th) & vec_intsreg & ~vec_istrimmed;
            neg_vec = (vec_dropth < th) & vec_intsreg & ~vec_istrimmed;
            tp_vec = pos_vec & vec_isreal;
            fp_vec = pos_vec & ~vec_isreal;
            fn_vec = neg_vec & vec_isreal;

            tp_all(t,2) = nnz(tp_vec);
            fp_all(t,2) = nnz(fp_vec);
            fn_all(t,2) = nnz(fn_vec);
            sc_all(t,2) = nnz(pos_vec);
        end
    end

    %Let's speed up the easy calculations...
    res_untrimmed(:, 'spotCount') = array2table(uint32(sc_all(:,1)));
    res_untrimmed(:, 'true_pos') = array2table(uint32(tp_all(:,1)));
    res_untrimmed(:, 'false_pos') = array2table(uint32(fp_all(:,1)));
    res_untrimmed(:, 'false_neg') = array2table(uint32(fn_all(:,1)));

    recall = tp_all(:,1) ./ (tp_all(:,1) + fn_all(:,1));
    precision = tp_all(:,1) ./ (tp_all(:,1) + fp_all(:,1));
    fscores = (2 .* precision .* recall) ./ (precision + recall);
    pr_auc = RNAUtils.calculateAUC(recall, precision);
    peak_fscore = max(fscores, [], 'all');
    res_untrimmed(:, 'sensitivity') = array2table(recall);
    res_untrimmed(:, 'precision') = array2table(precision);
    res_untrimmed(:, 'fScore') = array2table(fscores);
    if any_trimmed
        res_trimmed(:, 'spotCount') = array2table(uint32(sc_all(:,2)));
        res_trimmed(:, 'true_pos') = array2table(uint32(tp_all(:,2)));
        res_trimmed(:, 'false_pos') = array2table(uint32(fp_all(:,2)));
        res_trimmed(:, 'false_neg') = array2table(uint32(fn_all(:,2)));

        recall = tp_all(:,2) ./ (tp_all(:,2) + fn_all(:,2));
        precision = tp_all(:,2) ./ (tp_all(:,2) + fp_all(:,2));
        fscores = (2 .* precision .* recall) ./ (precision + recall);
        pr_auc_trim = RNAUtils.calculateAUC(recall, precision);
        peak_fscore_trim = max(fscores, [], 'all');
        res_trimmed(:, 'sensitivity') = array2table(recall);
        res_trimmed(:, 'precision') = array2table(precision);
        res_trimmed(:, 'fScore') = array2table(fscores);
    end

    %Save to output struct
    rstruct.performance_2d = res_untrimmed;
    rstruct.pr_auc_2d = pr_auc;
    rstruct.fscore_peak_2d = peak_fscore;
    if any_trimmed
        rstruct.performance_trimmed_2d = res_trimmed;
        rstruct.pr_auc_trimmed_2d = pr_auc_trim;
        rstruct.fscore_peak_trimmed_2d = peak_fscore_trim;
    end

end