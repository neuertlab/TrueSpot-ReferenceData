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

scriptCtx.DateSuffix = '240214';
scriptCtx.OutputDir = [ImgProcDir filesep 'tables'];

% ========================== Parameters ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];
TablePath_SimNeg = [BaseDir filesep 'test_images_simneg.csv'];

AllTablePaths = {TablePath_Main, TablePath_Mass, TablePath_YTC TablePath_SimNeg};
%AllTablePaths = {TablePath_Mass, TablePath_YTC};
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
        scriptCtx.ResultsPath = ResFilePath;

        if isfile(ResFilePath)
            load(ResFilePath, 'analysis');
        else
            fprintf('> Could not find analysis file. Skipping...\n');
            continue;
        end

        doTheThing(scriptCtx, analysis);

        clear analysis set_group_dir ResFilePath myname
    end
end
scriptCtx = finalize(scriptCtx);

% ========================== Helper Functions ==========================

function ctx = initialize(ctx)
    %TODO fill in action here.
    %ctx = openThOutput(ctx);

    %ctx = open_sctcOutput(ctx);
    %ctx = openExpDumpOutput(ctx);
    %ctx = openCountDumpOutput(ctx);

    %ctx = open_sctcSimCountOutput(ctx);

    %ctx.coords_dir = [ctx.OutputDir filesep 'coords_dump'];
    %mkdir(ctx.coords_dir);
end

function ctx = finalize(ctx)
    %TODO fill in action here.
    if isfield(ctx, 'OutputHandle')
        fclose(ctx.OutputHandle);
    end

    %close_sctcOutput(ctx);
end

function doTheThing(ctx, analysis)
    %TODO fill in action here.
    %Dump_ThreshTable(ctx.OutputHandle, analysis);

    %do_sctcIndiv(ctx, analysis);
    %Dump_expResultStats(ctx.OutputHandle, analysis, 'BHImaris');

    %dumpCountsIndiv(ctx, analysis);

%     analysis = AnalysisFiles.fixExpRefsetOrganization(analysis);
%     %fprintf('hold\n');
%     [analysis, ~] = AnalysisFiles.activateExpRefSet(analysis, 'BHImaris');
%     save(ctx.ResultsPath, 'analysis');

    %Dump_JustCoords_231128(analysis, [ctx.coords_dir filesep analysis.imgname '_calls.mat']);
    analysis = plotbug_correct_240214(analysis);
    save(ctx.ResultsPath, 'analysis');

    %Look for truthset
%     if isfield(analysis, 'simkey') | isfield(analysis, 'exprefset')
%         analysis = Update_TrimAllSim_230912(analysis, 7);
%         save(ctx.ResultsPath, 'analysis');
%     end
end

function bool_res = shouldSkip(imgName)
    %TODO fill in action here.
    bool_res = false;
    %bool_res = skip_sctc(imgName);

    if ~startsWith(imgName, 'simerly_'); bool_res = true; end

%     if ~startsWith(imgName, 'simerly_') & ~startsWith(imgName, 'simneg_')
%         bool_res = true;
%     end

%     if startsWith(imgName, 'sim_'); bool_res = true; end
%     if startsWith(imgName, 'simvar_'); bool_res = true; end
%     if startsWith(imgName, 'simvarmass_'); bool_res = true; end
%     if startsWith(imgName, 'simneg_'); bool_res = true; end
%     if startsWith(imgName, 'rsfish_sim'); bool_res = true; end
end

function ctx = genScriptContextStruct(basedir)
    ctx = struct('BaseDir', basedir);
    ctx.ImgProcDir = basedir;
    ctx.ImgDir = basedir;
    ctx.ResultsDir = [basedir filesep 'data' filesep 'results'];
    ctx.ResultsPath = [basedir filesep 'data' filesep 'results'];
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
    elseif startsWith(imgname, 'simerly_')
        dirname = 'simerly_lab';
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

% ========================== Dump Functions ==========================

function ctx = openExpDumpOutput(ctx)
    outpath = [ctx.OutputDir filesep 'expBHStatsDump_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    %Header
    outfields = {'IMGNAME' 'GROUP_A' 'GROUP_B', ...
        'HB_COUNT', 'HB_MAXREC', 'HB_AUC', 'HB_FSCORE',...
        'BF_COUNT', 'BF_MAXREC', 'BF_AUC', 'BF_FSCORE',...
        'RS_MAXREC', 'RS_AUC', 'DB_MAXREC', 'DB_AUC'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, outfields{i});
    end
    fprintf(ctx.OutputHandle, '\n');
end

function ctx = openCountDumpOutput(ctx)
    outpath = [ctx.OutputDir filesep 'spotCountsDump_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    %Header
    outfields = {'IMGNAME' 'GROUP' 'COUNT_HB' 'COUNT_BF'...
        'COUNT_RS' 'COUNT_DB' 'RS_TH' 'DB_TH'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, outfields{i});
    end
    fprintf(ctx.OutputHandle, '\n');
end

function ctx = openThOutput(ctx)
    outpath = [ctx.OutputDir filesep 'thstatsdump_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    %Header
    outfields = {'IMGNAME' 'GROUP_A' 'GROUP_B' 'THVAL_HB' 'SPOTS_HB' 'FSCORE_HB'...
        'THVAL_BF' 'SPOTS_BF' 'FSCORE_BF'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, outfields{i});
    end
    fprintf(ctx.OutputHandle, '\n');
end

function ctx = open_sctcSimCountOutput(ctx)
    outpath = [ctx.OutputDir filesep 'sctcsim_counts_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    outfields = {'IMAGENAME' 'ACTUAL_SPOTS' 'ACTUAL_SPOTS_TRIMMED'...
        'HBTr_THRESH', 'HBTr_COUNT_VAR', 'HBTr_COUNT_FIXED'...
        'BFTr_THRESH', 'BFTr_COUNT_VAR', 'BFTr_COUNT_FIXED'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, outfields{i});
    end
    fprintf(ctx.OutputHandle, '\n');
end

function ctx = open_sctcOutput(ctx)
    outpath = [ctx.OutputDir filesep 'sctcdump_main_' ctx.DateSuffix '.tsv'];
    maintbl = fopen(outpath, 'w');

    %Header
    outfields = {'IMAGENAME' 'EXP' 'REP' 'TIME'...
        'I_NUM' 'CH' 'THVAL_HB' 'THVAL_BF' 'THSPOTS_HB' 'THSPOTS_BF'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(maintbl, '\t'); end
        fprintf(maintbl, outfields{i});
    end
    fprintf(maintbl, '\n');
    ctx.MultiOutputHandle = struct('maintbl', maintbl);

    %Cell table
    outpath = [ctx.OutputDir filesep 'sctcdump_cell_' ctx.DateSuffix '.tsv'];
    celltbl = fopen(outpath, 'w');

    %Header
    outfields = {'EXP' 'REP' 'TIME'...
        'I_NUM' 'CH' 'CELL_NUM' 'THI_HB_TOT' 'THI_BF_TOT'...
        'THR_HB_TOT' 'THR_BF_TOT' 'THE_HB_TOT' 'THE_BF_TOT'...
        'THC_HB_TOT' 'THC_BF_TOT'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(celltbl, '\t'); end
        fprintf(celltbl, outfields{i});
    end
    fprintf(celltbl, '\n');
    ctx.MultiOutputHandle.celltbl = celltbl;

    %Sim table
    outpath = [ctx.OutputDir filesep 'sctcdump_sim_' ctx.DateSuffix '.tsv'];
    simtbl = fopen(outpath, 'w');

    %Header
    outfields = {'IMAGENAME' 'CH' 'ACTUAL_SPOTS' 'THI_HB' 'THI_BF'...
        'THI_HB_SPOTS' 'THI_BF_SPOTS' 'THF_HB_SPOTS' 'THF_BF_SPOTS'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(simtbl, '\t'); end
        fprintf(simtbl, outfields{i});
    end
    fprintf(simtbl, '\n');
    ctx.MultiOutputHandle.simtbl = simtbl;

end

function ctx = close_sctcOutput(ctx)
    fclose(ctx.MultiOutputHandle.celltbl);
    fclose(ctx.MultiOutputHandle.maintbl);
    fclose(ctx.MultiOutputHandle.simtbl);
end

function do_sctcIndiv(ctx, analysis)

    fixed_th = struct('dummy', 0);

    fixed_th.ch_fixed_th_hb = [75 121];
    fixed_th.ch_fixed_th_bf = [186 215];

    fixed_th.exp_fixed_th_hb = [77 141
        74 108
        187 137];
    fixed_th.exp_fixed_th_bf = [180 186
        190 233
        186 403];

    fixed_th.rep_fixed_th_hb_e1 = [75 134
        79 148];
    fixed_th.rep_fixed_th_hb_e2 = [91 132
        70 111
        59 79];

    fixed_th.rep_fixed_th_bf_e1 = [184 223
        176 149];
    fixed_th.rep_fixed_th_bf_e2 = [257 248
        183 189
        126 264];

    %Dump_sctcStats(ctx.MultiOutputHandle, analysis, fixed_th);
    Dump_sctcSimCounts(ctx.OutputHandle, analysis, fixed_th);
end

function bool_res = skip_sctc(imgname)
    bool_res = true;
    %if startsWith(imgname, 'sctc_'); bool_res = false; end
    if startsWith(imgname, 'simvarmass_')
        if contains(imgname, 'CY5L')
            bool_res = false;
        elseif contains(imgname, 'TMRL')
            bool_res = false;
        end
    end
end

function dumpCountsIndiv(ctx, analysis)
    fprintf(ctx.OutputHandle, '%s\t', analysis.imgname);
    fprintf(ctx.OutputHandle, '.\t');

    if isfield(analysis, 'results_hb')
        thval = analysis.results_hb.threshold;
        callset_t = TrimCallsetEdges(analysis.results_hb, analysis.image_dims);
        if ~isempty(callset_t)
            count = nnz(callset_t{:, 'dropout_thresh'} >= thval);
        else
            count = 0;
        end

        fprintf(ctx.OutputHandle, '%d\t', count);
    else
        fprintf(ctx.OutputHandle, 'NaN\t');
    end

    if isfield(analysis, 'results_bf')
        thval = analysis.results_bf.threshold;
        callset_t = TrimCallsetEdges(analysis.results_bf, analysis.image_dims);
        if ~isempty(callset_t)
            count = nnz(callset_t{:, 'dropout_thresh'} >= thval);
        else
            count = 0;
        end

        fprintf(ctx.OutputHandle, '%d\t', count);
    else
        fprintf(ctx.OutputHandle, 'NaN\t');
    end

    rs_th = 0;
    if isfield(analysis, 'results_rs')
        rs_th = AutothreshRS(analysis.results_rs, analysis.image_dims);
        callset_t = TrimCallsetEdges(analysis.results_rs, analysis.image_dims);
        if ~isempty(callset_t)
            count = nnz(callset_t{:, 'dropout_thresh'} >= rs_th);
        else
            count = 0;
        end

        fprintf(ctx.OutputHandle, '%d\t', count);
    else
        fprintf(ctx.OutputHandle, 'NaN\t');
    end

    db_th = 0;
    if isfield(analysis, 'results_db')
        db_th = 0.95;
        callset_t = TrimCallsetEdges(analysis.results_db, analysis.image_dims);
        if ~isempty(callset_t)
            count = nnz(callset_t{:, 'dropout_thresh'} >= db_th);
        else
            count = 0;
        end

        fprintf(ctx.OutputHandle, '%d\t', count);
    else
        fprintf(ctx.OutputHandle, 'NaN\t');
    end

    fprintf(ctx.OutputHandle, '%.4f\t', rs_th);
    fprintf(ctx.OutputHandle, '%.2f\n', db_th);

end
