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

scriptCtx.DateSuffix = '231205';
scriptCtx.OutputDir = [ImgProcDir filesep 'tables'];

% ========================== Parameters ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];

AllTablePaths = {TablePath_Main, TablePath_Mass, TablePath_YTC};
ImgTableCount = size(AllTablePaths, 2);

DB_THRESH = 0.95;

COLOR_HB = [0.667 0.220 0.220];
COLOR_BF = [0.231 0.231 0.702]; %#3b3bb3
COLOR_RS = [0.318 0.541 0.318]; %#518a51
COLOR_DB = [0.700 0.700 0.000];
COLORS = {COLOR_HB, COLOR_BF, COLOR_RS, COLOR_DB};

RECOUNT = false;

% ========================== Main Loop ==========================

table_file_path = [scriptCtx.OutputDir filesep 'exp_percell_counts_' scriptCtx.DateSuffix '.csv'];
if RECOUNT
    colnames = {'IMGNAME' 'GROUP' 'CELLNO' 'COUNT_HB' 'COUNT_BF'...
        'COUNT_RS' 'COUNT_DB' 'TH_RS' 'TH_DB'};
    colcount = size(colnames, 2);
    outfile = fopen(table_file_path, 'w');

    for i = 1:colcount
        if(i > 1); fprintf(outfile, ','); end
        fprintf(outfile, '%s', colnames{i});
    end
    fprintf(outfile, '\n');

    countStruct = struct();
    for t = 1:ImgTableCount
        fprintf('Trying Table %s...\n', AllTablePaths{t});
        image_table = testutil_opentable(AllTablePaths{t});

        entry_count = size(image_table, 1);
        scriptCtx.ImageInfoTable = image_table;
        for r = 1:entry_count
            scriptCtx.TableRow = r;

            myname = getTableValue(image_table, r, 'IMGNAME');
            fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);
            groupname = determineGroup(myname);
            if isempty(groupname)
                fprintf('\t> Not in specified cell count group. Skipping...\n');
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

            cell_count = getCellCount(scriptCtx.ImgProcDir, image_table, scriptCtx.TableRow);
            if cell_count > 0
                countStruct = takeAndDumpCounts(analysis, groupname, cell_count, countStruct, outfile, DB_THRESH);
            end

            clear analysis set_group_dir ResFilePath myname groupname
        end
    end
    fclose(outfile);
    genGraphs([scriptCtx.OutputDir filesep 'probdistro'], countStruct, COLORS);
else
    %Load table
    tblfmt = '%s%s%d%d%d%d%d%f%f';
    count_table = readtable(table_file_path,'Delimiter',',',...
        'ReadVariableNames',true,'Format', tblfmt);
    genGraphsPrecount([scriptCtx.OutputDir filesep 'probdistro'], count_table, COLORS);
end

% ========================== Functions ==========================

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

function groupname = determineGroup(imgname)
    groupname = [];
    if startsWith(imgname, 'mESC4d_')
        if contains(imgname, 'Tsix')
            groupname = 'mesc4_Tsix_AF594';
        else
            groupname = 'mesc4_Xist_CY5';
        end
    elseif startsWith(imgname, 'mESC_loday_')
        if contains(imgname, 'D0')
            if endsWith(imgname, '_Tsix')
                groupname = 'mesc0_Tsix_TMR';
            else
                groupname = 'mesc0_Xist_CY5';
            end
        elseif contains(imgname, 'DH')
            if endsWith(imgname, '_Tsix')
                groupname = 'mescH_Tsix_TMR';
            else
                groupname = 'mescH_Xist_CY5';
            end
        elseif contains(imgname, 'D1')
            if endsWith(imgname, '_Tsix')
                groupname = 'mesc1_Tsix_TMR';
            else
                groupname = 'mesc1_Xist_CY5';
            end
        end
    elseif startsWith(imgname, 'scprotein_')
    elseif startsWith(imgname, 'histonesc_')
        if contains(imgname, 'D0')
            if endsWith(imgname, '_Tsix')
                groupname = 'mescHistD0_Tsix_TMR';
            elseif endsWith(imgname, '_Histone')
                if contains(imgname, 'H3K4me2')
                    groupname = 'mescHistD0_H3K4me2_AF488';
                else
                    groupname = 'mescHistD0_H3K36me3_AF488';
                end
            else
                groupname = 'mescHistD0_Xist_CY5';
            end
        elseif contains(imgname, 'D2')
            if endsWith(imgname, '_Tsix')
                groupname = 'mescHistD2_Tsix_TMR';
            elseif endsWith(imgname, '_Histone')
                if contains(imgname, 'H3K4me2')
                    groupname = 'mescHistD2_H3K4me2_AF488';
                else
                    groupname = 'mescHistD2_H3K36me3_AF488';
                end
            else
                groupname = 'mescHistD2_Xist_CY5';
            end
        end
    elseif startsWith(imgname, 'ROI0')
    elseif startsWith(imgname, 'sctc_')
        nameinfo = Parse_sctcImgName(imgname);
        groupname = ['sctc_E' num2str(nameinfo.Exp) 'R' num2str(nameinfo.Rep)...
            'C' num2str(nameinfo.Channel) '_' num2str(nameinfo.TimePointMin) 'min'];
    end
end

function cell_count = getCellCount(basedir, table, row)
    cellseg_dir = getTableValue(table, row, 'CELLSEG_DIR');
    cellseg_suffix = getTableValue(table, row, 'CELLSEG_SFX');

    cell_count = 0;
    if strcmp(cellseg_dir, '.'); return; end
    if strcmp(cellseg_suffix, '.'); return; end

    cellseg_dir = replace(cellseg_dir, '/', filesep);
    cellseg_path = [basedir cellseg_dir filesep 'Lab_' cellseg_suffix '.mat'];

    if ~isfile(cellseg_path); return; end
    load(cellseg_path, 'cells');

    cell_count = max(cells, [], 'all', 'omitnan');
    clear cells
end

function countStruct = takeAndDumpCounts(analysis, groupname, cell_count, countStruct, fileHandle, dbthresh)

    if isfield(analysis, 'results_hb')
        thval = analysis.results_hb.threshold;
        callset = filterCallset(analysis.results_hb, thval, analysis.image_dims);

        if ~isfield(countStruct, 'hb')
            countStruct.hb = struct();
        end

        substruct = [];
        if isfield(countStruct.hb, groupname)
            substruct = countStruct.hb.(groupname);
        else
            countStruct.hb.(groupname) = struct();
        end

        [countStruct.hb.(groupname), mycounts_hb] = storeCounts(callset, substruct, cell_count);

        clear thval callset substruct
    else
        mycounts_hb = zeros(1, cell_count);
    end

    if isfield(analysis, 'results_bf')
        thval = analysis.results_bf.threshold;
        callset = filterCallset(analysis.results_bf, thval, analysis.image_dims);

        if ~isfield(countStruct, 'bf')
            countStruct.bf = struct();
        end

        substruct = [];
        if isfield(countStruct.bf, groupname)
            substruct = countStruct.bf.(groupname);
        end

        [countStruct.hb.(groupname), mycounts_bf] = storeCounts(callset, substruct, cell_count);

        clear thval callset substruct
    else
        mycounts_bf = zeros(1, cell_count);
    end

    if isfield(analysis, 'results_rs')
        th_rs = AutothreshRS(analysis.results_rs, analysis.image_dims);
        callset = filterCallset(analysis.results_rs, th_rs, analysis.image_dims);

        if ~isfield(countStruct, 'rs')
            countStruct.rs = struct();
        end

        substruct = [];
        if isfield(countStruct.rs, groupname)
            substruct = countStruct.rs.(groupname);
        end

        [countStruct.rs.(groupname), mycounts_rs] = storeCounts(callset, substruct, cell_count);

        clear callset substruct
    else
        th_rs = 0;
        mycounts_rs = zeros(1, cell_count);
    end

    if isfield(analysis, 'results_db')
        callset = filterCallset(analysis.results_db, dbthresh, analysis.image_dims);

        if ~isfield(countStruct, 'db')
            countStruct.db = struct();
        end

        substruct = [];
        if isfield(countStruct.db, groupname)
            substruct = countStruct.db.(groupname);
        end

        [countStruct.db.(groupname), mycounts_db] = storeCounts(callset, substruct, cell_count);

        clear callset substruct
    else
        mycounts_db = zeros(1, cell_count);
    end

    %Print!
    for c = 1:cell_count
        fprintf(fileHandle, '%s,%s,%d,', analysis.imgname, groupname, c);
        fprintf(fileHandle, '%d,', mycounts_hb(c));
        fprintf(fileHandle, '%d,', mycounts_bf(c));
        fprintf(fileHandle, '%d,', mycounts_rs(c));
        fprintf(fileHandle, '%d,', mycounts_db(c));
        fprintf(fileHandle, '%.5f,', th_rs);
        fprintf(fileHandle, '%.2f\n', dbthresh);
    end
end

function callset = filterCallset(rstruct, thval, idims)
    callset = TrimCallsetEdges(rstruct, idims);
    if thval > 0
        keep_rows = find(callset{:, 'dropout_thresh'} >= thval);
        if isempty(keep_rows)
            callset = [];
            return;
        end
        callset = callset(keep_rows, :);
    end
end

function [countSubStruct, mycounts] = storeCounts(filteredCallset, countSubStruct, cell_count)

    if isempty(countSubStruct)
        alloc = cell_count * 4;
        countSubStruct = struct('counts', NaN(1,alloc));
        countSubStruct.capacity = alloc;
        countSubStruct.used = 0;
        clear alloc
    end

    mycounts = zeros(1, cell_count);
    for c = 1:cell_count
        if ~isempty(filteredCallset)
            mycounts(c) = nnz(filteredCallset{:, 'cell'} == c);
        else
            mycounts(c) = 0;
        end
    end

    avail = countSubStruct.capacity - countSubStruct.used;
    if avail < cell_count
        %Reallocate
        alloc = countSubStruct.capacity + (cell_count * 4);
        newarray = NaN(1, alloc);

        ed = countSubStruct.used;
        newarray(1:ed) = countSubStruct.counts(1:ed);
        countSubStruct.counts = newarray;
        countSubStruct.capacity = alloc;

        clear newarray alloc
    end

    st = countSubStruct.used + 1;
    ed = st + cell_count - 1;
    countSubStruct.counts(st:ed) = mycounts(:);
    countSubStruct.used = countSubStruct.used + cell_count;
end

function genGraphs(outdir, countStruct, colors)
    if ~isfolder(outdir); mkdir(outdir); end

    allgroups = fieldnames(countStruct.hb);
    gcount = size(allgroups, 1);
    for g = 1:gcount
        gname = allgroups{g, 1};

        groupdir = [outdir filesep gname];
        if ~isfolder(groupdir); mkdir(groupdir); end

        %Output both same axis and faceted versions
        %To png and svg
        %Totals 4 files

        allcounts = cell(1,4);

        substruct = countStruct.hb.(gname);
        allcounts{1} = substruct.counts(1:substruct.used);

        substruct = countStruct.bf.(gname);
        allcounts{2} = substruct.counts(1:substruct.used);

        substruct = countStruct.rs.(gname);
        allcounts{3} = substruct.counts(1:substruct.used);

        substruct = countStruct.db.(gname);
        allcounts{4} = substruct.counts(1:substruct.used);

        hist_bins = cell(1,4);
        hist_edges = cell(1,4);

        for i = 1:4
            [hist_bins{i}, hist_edges{i}] = histcounts(allcounts{i});
            hist_bins{i} = hist_bins{i} ./ size(allcounts{i},2);
        end

        %Faceted
        fh = figure(1);
        hold on;
        ylim([0,1]);
        for i = 1:4
            subplot(2,2,i);
            plot(hist_edges{i}, hist_bins{i}, 'LineStyle', '--',...
                'Color', colors{i});
        end
        filestem = [groupdir filesep gname '_facet'];
        saveas(fh, [filestem '.png']);
        saveas(fh, [filestem '.svg']);
        close(fh);

        %Combined
        fh = figure(1);
        hold on;
        ylim([0,1]);
        for i = 1:4
            plot(hist_edges{i}, hist_bins{i}, 'LineStyle', '--',...
                'Color', colors{i});
        end
        filestem = [groupdir filesep gname '_combined'];
        saveas(fh, [filestem '.png']);
        saveas(fh, [filestem '.svg']);
        close(fh);
    end
end

function genGraphsPrecount(outdir, table, colors)
    if ~isfolder(outdir); mkdir(outdir); end

    allgroups = unique(table{:, 'GROUP'});
    gcount = size(allgroups, 1);
    for g = 1:gcount
        gname = allgroups{g, 1};

        groupdir = [outdir filesep gname];
        if ~isfolder(groupdir); mkdir(groupdir); end

        grows = find(strcmp(gname, table{:, 'GROUP'}));
        group_tbl = table(grows, :);

        allcounts = cell(1,4);
        allcounts{1} = group_tbl{:,'COUNT_HB'};
        allcounts{2} = group_tbl{:,'COUNT_BF'};
        allcounts{3} = group_tbl{:,'COUNT_RS'};
        allcounts{4} = group_tbl{:,'COUNT_DB'};

        y = cell(1,4);
        x = cell(1,4);

        for i = 1:4
            cell_count = size(allcounts{i},1);
            [y{i}, hist_edges] = histcounts(allcounts{i});
            y{i} = y{i} ./ cell_count;
            bin_count = size(y{i}, 2);

            x{i} = (hist_edges(1:bin_count) + hist_edges(2:bin_count+1)) ./ 2;
            clear hist_edges
        end

        toolnames = {'TrueSpot', 'Big-FISH', 'RS-FISH', 'DeepBlink'};

        %Faceted
        fh = figure(1);
        clf;
        hold on;
        for i = 1:4
            subplot(2,2,i);
            plot(x{i}, y{i}, 'LineWidth', 2, ...
                'Color', colors{i});
            ylim([0,1]);
            title(toolnames{i});

            cell_count = size(allcounts{i},1);
            subtitle(['n = ' num2str(cell_count)]);
        end
        filestem = [groupdir filesep gname '_facet'];
        saveas(fh, [filestem '.png']);
        saveas(fh, [filestem '.svg']);
        close(fh);

        %Combined
        fh = figure(2);
        clf;
        hold on;
        for i = 1:4
            plot(x{i}, y{i}, 'LineStyle', ':',...
                'LineWidth', 2.5, 'Color', colors{i});
        end
        cell_count = size(allcounts{1},1);
        title(replace(gname, '_', ' '));
        subtitle(['n = ' num2str(cell_count)]);
        legend(toolnames, 'Location', 'northeast');
        filestem = [groupdir filesep gname '_combined_zoom'];
        saveas(fh, [filestem '.png']);
        saveas(fh, [filestem '.svg']);

        ylim([0,1]);
        filestem = [groupdir filesep gname '_combined'];
        saveas(fh, [filestem '.png']);
        saveas(fh, [filestem '.svg']);
        close(fh);

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
