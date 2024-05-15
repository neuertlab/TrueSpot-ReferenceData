%
%%  !! UPDATE TO YOUR BASE DIR
BaseDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
%BaseDir = 'D:\usr\bghos\labdat\imgproc';

ImgProcDir = 'D:\Users\hospelb\labdata\imgproc';
%ImgProcDir = 'D:\usr\bghos\labdat\imgproc';

ImgDir = 'C:\Users\hospelb\labdata\imgproc';
%ImgDir = 'D:\usr\bghos\labdat\imgproc';

addpath('./core');
addpath('./test');

% ========================== General Context ==========================

scriptCtx = genScriptContextStruct(BaseDir);
scriptCtx.ImgProcDir = ImgProcDir;
scriptCtx.ImgDir = ImgDir;

scriptCtx.DateSuffix = '240515';
%scriptCtx.OutputDir = [ImgProcDir filesep 'tables'];
scriptCtx.OutputDir = [BaseDir filesep 'istats'];

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
    %ctx = openThPresetCompareOutput(ctx, 11);

    %ctx = open_sctcSimCountOutput(ctx);

    %ctx.coords_dir = [ctx.OutputDir filesep 'coords_dump'];
    %mkdir(ctx.coords_dir);

    %ctx = openMinThCountOutput(ctx);

    ctx = openImageStatsOutput(ctx);
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
    %Dump_expResultStats(ctx.OutputHandle, analysis, 'BH');

    %dumpCountsIndiv(ctx, analysis);

%     analysis = AnalysisFiles.fixExpRefsetOrganization(analysis);
%     %fprintf('hold\n');
%     [analysis, ~] = AnalysisFiles.activateExpRefSet(analysis, 'BHImaris');
%     save(ctx.ResultsPath, 'analysis');

    %doThPresetScan(ctx, analysis, 11);

    %Dump_JustCoords_231128(analysis, [ctx.coords_dir filesep analysis.imgname '_calls.mat']);
    %analysis = plotbug_correct_240214(analysis);
%       analysis = rethresh_all_240219(analysis, true);
%       save(ctx.ResultsPath, 'analysis');

    %Look for truthset
%     if isfield(analysis, 'simkey') | isfield(analysis, 'exprefset')
%         analysis = Update_TrimAllSim_230912(analysis, 7);
%         save(ctx.ResultsPath, 'analysis');
%     end

    %writeMinThCountLine(ctx, analysis);

    doImageStats(ctx, analysis);
end

function bool_res = shouldSkip(imgName)
    %TODO fill in action here.
    %bool_res = false;
    %bool_res = skip_sctc(imgName);

    %if ~startsWith(imgName, 'simerly_'); bool_res = true; end

%     if ~startsWith(imgName, 'simerly_') & ~startsWith(imgName, 'simneg_')
%         bool_res = true;
%     end

%     if startsWith(imgName, 'sim_'); bool_res = true; end
%     if startsWith(imgName, 'simvar_'); bool_res = true; end
%     if startsWith(imgName, 'simvarmass_'); bool_res = true; end
%     if startsWith(imgName, 'simneg_'); bool_res = true; end
%     if startsWith(imgName, 'rsfish_sim'); bool_res = true; end

    %bool_res = ~bool_res;

    bool_res = true;
    if startsWith(imgName, 'histonesc_'); bool_res = false; end
    if startsWith(imgName, 'mESC_loday_'); bool_res = false; end
    if startsWith(imgName, 'mESC4d_'); bool_res = false; end
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

function ctx = openImageStatsOutput(ctx)
    outpath = [ctx.OutputDir filesep 'imgStatsSummary_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    %Header
    outfields = {'IMGNAME' 'CELLTYPE' 'PROBE' 'TARGET' ...
        'BKG_MEAN' 'BKG_STD' 'BKG_MEDIAN' 'BKG_MIN' 'BKG_MAX' ...
        'CELLBKG_MEAN' 'CELLBKG_STD' 'CELLBKG_MEDIAN' 'CELLBKG_MIN' 'CELLBKG_MAX'...
        'SIGNAL_MEAN' 'SIGNAL_STD', 'SIGNAL_MEDIAN', 'SIGNAL_MIN' 'SIGNAL_MAX'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, outfields{i});
    end
    fprintf(ctx.OutputHandle, '\n');
end

function ctx = openThPresetCompareOutput(ctx, presetCount)
    outpath = [ctx.OutputDir filesep 'thPresetCompare_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    outfields = {'THVAL' 'SPOTCOUNT' 'FSCORE'};
    field_count = size(outfields, 2);

    fprintf(ctx.OutputHandle, '#IMAGE\t');
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, 'FPEAK_%s', outfields{i});
    end

    for p = 1:presetCount
        for i = 1:field_count
            if i > 1; fprintf(ctx.OutputHandle, '\t'); end
            fprintf(ctx.OutputHandle, 'P%02d_%s', p, outfields{i});
        end
    end
    fprintf(ctx.OutputHandle, '\n');
end

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

function ctx = doThPresetScan(ctx, analysis, presetCount)
    imgname = analysis.imgname;

    if ~isfield(analysis, 'results_hb')
        return;
    end

    is_sim = false;
    if contains(imgname, 'sim')
        if ~startsWith(imgname, 'simerly_')
            is_sim = true;
        end
    end

    fprintf(ctx.OutputHandle, '%s\t', imgname);
    tsname = 'BH';

    %Get F-score peak (if applicable)
    bstruct = [];
    if is_sim
        bstruct = analysis.results_hb;
    else
        if isfield(analysis.results_hb, 'benchmarks')
            if isfield(analysis.results_hb.benchmarks, tsname)
                bstruct = analysis.results_hb.benchmarks.(tsname);
            else
                if isfield(analysis.results_hb.benchmarks, 'BHImaris')
                    bstruct = analysis.results_hb.benchmarks.BHImaris;
                end
            end
        end
    end

    if ~isempty(bstruct)
        if isfield(bstruct, 'fscore_peak_trimmed')
            [~, maxidx] = max(bstruct.performance_trimmed{:, 'fScore'}, [], 'all', 'omitnan');
            fprintf(ctx.OutputHandle, '%d\t', bstruct.performance_trimmed{maxidx, 'thresholdValue'});
            fprintf(ctx.OutputHandle, '%d\t', bstruct.performance_trimmed{maxidx, 'spotCount'});
            fprintf(ctx.OutputHandle, '%.5f', bstruct.performance_trimmed{maxidx, 'fScore'});
        elseif isfield(bstruct, 'fscore_peak')
            [~, maxidx] = max(bstruct.performance{:, 'fScore'}, [], 'all', 'omitnan');
            fprintf(ctx.OutputHandle, '%d\t', bstruct.performance{maxidx, 'thresholdValue'});
            fprintf(ctx.OutputHandle, '%d\t', bstruct.performance{maxidx, 'spotCount'});
            fprintf(ctx.OutputHandle, '%.5f', bstruct.performance{maxidx, 'fScore'});
        else
            fprintf(ctx.OutputHandle, 'NaN\tNaN\tNaN');
        end
    else
        fprintf(ctx.OutputHandle, 'NaN\tNaN\tNaN');
    end

    for pre = 1:presetCount
        if is_sim
            analysis = AnalysisFiles.rethresholdSim(analysis, pre, 1, false);

            %Dump to table
            fprintf(ctx.OutputHandle, '\t%d', analysis.results_hb.threshold);
            if (analysis.results_hb.threshold > 0)
                spots = nnz(analysis.results_hb.callset{:, 'dropout_thresh'} >= analysis.results_hb.threshold);
                fprintf(ctx.OutputHandle, '\t%d', spots);
                
                if isfield(analysis.results_hb, 'fscore_peak_trimmed')
                    fprintf(ctx.OutputHandle, '\t%.5f', analysis.results_hb.fscore_peak_trimmed);
                elseif isfield(analysis.results_hb, 'fscore_peak')
                    fprintf(ctx.OutputHandle, '\t%.5f', analysis.results_hb.fscore_peak);
                else
                    fprintf(ctx.OutputHandle, '\tNaN');
                end
            else
                fprintf(ctx.OutputHandle, '\tNaN\tNaN');
            end
        else
            analysis = AnalysisFiles.rethresholdExp(analysis, pre, 1, false);

            %Dump to table
            fprintf(ctx.OutputHandle, '\t%d', analysis.results_hb.threshold);
            if (analysis.results_hb.threshold > 0)
                spots = nnz(analysis.results_hb.callset{:, 'dropout_thresh'} >= analysis.results_hb.threshold);
                fprintf(ctx.OutputHandle, '\t%d', spots);
                
                bstruct = [];
                if isfield(analysis.results_hb, 'benchmarks')
                    if isfield(analysis.results_hb.benchmarks, tsname)
                        bstruct = analysis.results_hb.benchmarks.(tsname);
                    elseif isfield(analysis.results_hb.benchmarks, 'BHImaris')
                        bstruct = analysis.results_hb.benchmarks.BHImaris;
                    end

                    if ~isempty(bstruct)
                        if isfield(bstruct, 'fscore_peak_trimmed')
                            fprintf(ctx.OutputHandle, '\t%.5f', bstruct.fscore_peak_trimmed);
                        elseif isfield(bstruct, 'fscore_peak')
                            fprintf(ctx.OutputHandle, '\t%.5f', bstruct.fscore_peak);
                        else
                            fprintf(ctx.OutputHandle, '\tNaN');
                        end
                    else
                        fprintf(ctx.OutputHandle, '\tNaN');
                    end
                else
                    fprintf(ctx.OutputHandle, '\tNaN');
                end

            else
                fprintf(ctx.OutputHandle, '\tNaN\tNaN');
            end
        end
    end

    fprintf(ctx.OutputHandle, '\n');
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

function ctx = openMinThCountOutput(ctx)
    outpath = [ctx.OutputDir filesep 'minthSpots_' ctx.DateSuffix '.tsv'];
    ctx.OutputHandle = fopen(outpath, 'w');

    outfields = {'IMGNAME' 'SIM_OR_EXP' 'TOTAL_VOXELS' 'MIN_TH_VAL' 'MIN_TH_SPOTS' ...
        'TOTAL_VOX_LOG' 'MINTH_SPOTS_LOG' 'PROP'};
    field_count = size(outfields, 2);
    for i = 1:field_count
        if i > 1; fprintf(ctx.OutputHandle, '\t'); end
        fprintf(ctx.OutputHandle, outfields{i});
    end
    fprintf(ctx.OutputHandle, '\n');
end

function ctx = writeMinThCountLine(ctx, analysis)
    if ~isfield(analysis, 'results_hb'); return; end

    imgname = analysis.imgname;
    fprintf(ctx.OutputHandle, '%s\t', imgname);

    if (startsWith(imgname, 'sim') & ~startsWith(imgname, 'simerly_')) | ...
        startsWith(imgname, 'rsfish_sim')
        fprintf(ctx.OutputHandle, 'Sim\t');
    else
        fprintf(ctx.OutputHandle, 'Exp\t');
    end

    rstruct = analysis.results_hb;

    X = rstruct.x_max - rstruct.x_min + 1;
    Y = rstruct.y_max - rstruct.y_min + 1;
    Z = rstruct.z_max - rstruct.z_min + 1;
    totvox = X * Y * Z;
    fprintf(ctx.OutputHandle, '%d\t', totvox);

    minth = rstruct.th_scan_min;
    fprintf(ctx.OutputHandle, '%d\t', minth);
    spotcount = nnz(rstruct.callset{:, 'dropout_thresh'} >= minth);
    fprintf(ctx.OutputHandle, '%d\t', spotcount);

    logval = log10(totvox);
    fprintf(ctx.OutputHandle, '%f\t', logval);
    logval = log10(spotcount);
    fprintf(ctx.OutputHandle, '%f\t', logval);

    prop = spotcount/totvox;
    fprintf(ctx.OutputHandle, '%f\n', prop);

end

function ctx = doImageStats(ctx, analysis)
%TODO
    SCOLCOUNT = 15;

    fprintf(ctx.OutputHandle, '%s', analysis.imgname);
    fprintf(ctx.OutputHandle, '\t%s', analysis.cell_type);
    fprintf(ctx.OutputHandle, '\t%s', analysis.probe);
    fprintf(ctx.OutputHandle, '\t%s', analysis.probe_target);

    %Load cellseg mask
    cellsegDir = getTableValue(ctx.ImageInfoTable, ctx.TableRow, 'CELLSEG_DIR');
    if strcmp(cellsegDir, '.')
        fprintf('\t>Could not find cellseg data! Skipping...\n');
        for i = 1:SCOLCOUNT; fprintf(ctx.OutputHandle, '\tNaN'); end
        fprintf(ctx.OutputHandle, '\n');
        return;
    end

    cellsegSuffix = getTableValue(ctx.ImageInfoTable, ctx.TableRow, 'CELLSEG_SFX');
    if strcmp(cellsegSuffix, '.')
        fprintf('\t>Could not find cellseg data! Skipping...\n');
        for i = 1:SCOLCOUNT; fprintf(ctx.OutputHandle, '\tNaN'); end
        fprintf(ctx.OutputHandle, '\n');
        return;
    end

    cellsegPath = [ctx.BaseDir replace(cellsegDir, '/', filesep) filesep 'Lab_' cellsegSuffix '.mat'];
    cellMask = CellSeg.openCellMask(cellsegPath);

    %Load TIF
    chTotal = getTableValue(ctx.ImageInfoTable, ctx.TableRow, 'CH_TOTAL');
    chSample = getTableValue(ctx.ImageInfoTable, ctx.TableRow, 'CHANNEL');
    tifPathRaw = getTableValue(ctx.ImageInfoTable, ctx.TableRow, 'IMAGEPATH');
    tifPath = [ctx.ImgDir replace(tifPathRaw, '/', filesep)];
    [channels, ~] = LoadTif(tifPath, chTotal, [chSample], 1);

    loadedImage = channels{chSample, 1};
    clear channels;

    stats = GetImageIntensityStats(loadedImage, analysis, cellMask);
    if ~isempty(stats)
        %Copy to table and output matlab file
        matpath = [ctx.OutputDir filesep 'stats_' analysis.imgname '.mat'];
        save(matpath, 'stats', '-v7.3');

        fprintf(ctx.OutputHandle, '\t%.4f', mean(stats.bkgMean, 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', mean(stats.bkgStd, 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', median(stats.bkgMedian, 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', min(stats.bkgMin, [], 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', max(stats.bkgMax, [], 'all', 'omitnan'));

        fprintf(ctx.OutputHandle, '\t%.4f', mean(stats.cellBkgMean, 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', mean(stats.cellBkgStd, 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', median(stats.cellBkgMedian, 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', min(stats.cellBkgMin, [], 'all', 'omitnan'));
        fprintf(ctx.OutputHandle, '\t%.4f', max(stats.cellBkgMax, [], 'all', 'omitnan'));

        fprintf(ctx.OutputHandle, '\t%.4f', stats.signalMean);
        fprintf(ctx.OutputHandle, '\t%.4f', stats.signalStd);
        fprintf(ctx.OutputHandle, '\t%.4f', stats.signalMedian);
        fprintf(ctx.OutputHandle, '\t%.4f', stats.signalMin);
        fprintf(ctx.OutputHandle, '\t%.4f', stats.signalMax);

    else
        %Write NaNs to table
        fprintf('\t>Stat derivation failed! Skipping...\n');
        for i = 1:SCOLCOUNT; fprintf(ctx.OutputHandle, '\tNaN'); end
        fprintf(ctx.OutputHandle, '\n');
        return;
    end

    fprintf(ctx.OutputHandle, '\n');
end
