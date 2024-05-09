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

scriptCtx.DateSuffix = '240502';
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

colnames = {'IMGNAME' 'GROUP' 'CELLNO'...
    'COUNT_HB' 'COUNT_BF' 'COUNT_RS' 'COUNT_DB'...
    'COUNT_BH' 'COUNT_BK' 'TH_RS' 'TH_DB'...
    'CVG_XY_HB' 'CVG_Z_HB' 'CVG_XY_BF' 'CVG_Z_BF'...
    'CVG_XY_RS' 'CVG_Z_RS' 'CVG_XY_DB' 'CVG_Z_DB'...
    'CVG_XY_BH' 'CVG_Z_BH' 'CVG_XY_BK' 'CVG_Z_BK'};
coltypes = {'string' 'string' 'uint16'...
    'uint32' 'uint32' 'uint32' 'uint32'...
    'uint32' 'uint32' 'single' 'single'...
    'single' 'single' 'single' 'single'...
    'single' 'single' 'single' 'single'...
    'single' 'single' 'single' 'single'};
colcount = size(colnames, 2);

% ========================== Main Loop ==========================

table_file_path = [scriptCtx.OutputDir filesep 'exp_percell_counts_' scriptCtx.DateSuffix '.csv'];
if RECOUNT
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

            [cellseg_mask, cell_count] = loadCellSegMask(scriptCtx.ImgProcDir, image_table, scriptCtx.TableRow);

            %Update cell assignments for some groups
            if startsWith(myname, 'ROI0')
                if ~isempty(cellseg_mask)
                    analysis = updateCallCellAssignments(analysis, cellseg_mask);
                    save(ResFilePath, 'analysis');
                end
            elseif contains(myname, '_H3K4me2_')
                if ~isempty(cellseg_mask)
                    analysis = updateCallCellAssignments(analysis, cellseg_mask);
                    save(ResFilePath, 'analysis');
                end
            end

            if cell_count > 0
                takeAndDumpCounts(analysis, groupname, cell_count, cellseg_mask, outfile, colnames, coltypes, DB_THRESH);
            end

            clear analysis set_group_dir ResFilePath myname groupname cellseg_mask cell_count
        end
    end
    fclose(outfile);
    %genGraphs([scriptCtx.OutputDir filesep 'probdistro'], countStruct, COLORS);
else
    %Format string...
    tblfmt = '';
    for i = 1:colcount
        coltype = coltypes{i};
        colname = colnames{i};

        if strcmp(coltype, 'single') | strcmp(coltype, 'double')
            tblfmt = [tblfmt '%f'];
        elseif strcmp(coltype, 'string')
            tblfmt = [tblfmt '%s'];
        elseif contains(coltype, 'uint')
            tblfmt = [tblfmt '%d'];
        end
    end

    %Load table
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
            groupname = 'mesc4_TsixE_AF594';
        else
            groupname = 'mesc4_XistE_CY5';
        end
    elseif startsWith(imgname, 'mESC_loday_')
        if contains(imgname, 'D0')
            if endsWith(imgname, '_Tsix')
                groupname = 'mesc0_TsixE_TMR';
            else
                groupname = 'mesc0_XistE_CY5';
            end
        elseif contains(imgname, 'DH')
            if endsWith(imgname, '_Tsix')
                groupname = 'mescH_TsixE_TMR';
            else
                groupname = 'mescH_XistE_CY5';
            end
        elseif contains(imgname, 'D1')
            if endsWith(imgname, '_Tsix')
                groupname = 'mesc1_TsixE_TMR';
            else
                groupname = 'mesc1_XistE_CY5';
            end
        end
    elseif startsWith(imgname, 'scprotein_')
    elseif startsWith(imgname, 'histonesc_')
        if contains(imgname, 'D0')
            if endsWith(imgname, '_Tsix')
                groupname = 'mescHistD0_TsixI_TMR';
            elseif endsWith(imgname, '_Histone')
                if contains(imgname, 'H3K4me2')
                    groupname = 'mescHistD0_H3K4me2_AF488';
                else
                    groupname = 'mescHistD0_H3K36me3_AF488';
                end
            else
                groupname = 'mescHistD0_XistI_CY5';
            end
        elseif contains(imgname, 'D2')
            if endsWith(imgname, '_Tsix')
                groupname = 'mescHistD2_TsixI_TMR';
            elseif endsWith(imgname, '_Histone')
                if contains(imgname, 'H3K4me2')
                    groupname = 'mescHistD2_H3K4me2_AF488';
                else
                    groupname = 'mescHistD2_H3K36me3_AF488';
                end
            else
                groupname = 'mescHistD2_XistI_CY5';
            end
        end
    elseif startsWith(imgname, 'ROI0')
        if startsWith(imgname, 'ROI001_P')
            if endsWith(imgname, '_GFP')
                groupname = 'hela_18min_GFP';
            else
                groupname = 'hela_18min_CY5';
            end
        elseif contains(imgname, 'XY1657822')
            if endsWith(imgname, '_GFP')
                groupname = 'hela_5hr_GFP';
            else
                groupname = 'hela_5hr_CY5';
            end
        else
            if endsWith(imgname, '_GFP')
                groupname = 'hela_nostim_GFP';
            else
                groupname = 'hela_nostim_CY5';
            end
        end
    elseif startsWith(imgname, 'sctc_')
        nameinfo = Parse_sctcImgName(imgname);
        groupname = ['sctc_E' num2str(nameinfo.Exp) 'R' num2str(nameinfo.Rep)...
            'C' num2str(nameinfo.Channel) '_' num2str(nameinfo.TimePointMin) 'min'];
    end
end

function [mask, cell_count] = loadCellSegMask(basedir, table, row)
    cellseg_dir = getTableValue(table, row, 'CELLSEG_DIR');
    cellseg_suffix = getTableValue(table, row, 'CELLSEG_SFX');

    cell_count = 0;
    mask = [];
    if strcmp(cellseg_dir, '.'); return; end
    if strcmp(cellseg_suffix, '.'); return; end

    cellseg_dir = replace(cellseg_dir, '/', filesep);
    cellseg_path = [basedir cellseg_dir filesep 'Lab_' cellseg_suffix '.mat'];

    if ~isfile(cellseg_path); return; end
    load(cellseg_path, 'cells');

    cell_count = max(cells, [], 'all', 'omitnan');
    mask = cells;
    clear cells
end

function analysis = updateCallCellAssignments(analysis, cellseg_mask)
    tools = {'hb' 'bf' 'rs' 'db'};
    toolCount = size(tools, 2);

    for i = 1:toolCount
        resStructName = ['results_' tools{i}];
        if isfield(analysis, resStructName)
            if isfield(analysis.(resStructName), 'callset')
                analysis.(resStructName).callset = RNACoords.applyCellSegMask(analysis.(resStructName).callset, cellseg_mask);
            end
        end
    end
end

function trimmedMask = trimCellsegMask(cellseg_mask, rstruct)
    X = size(cellseg_mask, 2);
    Y = size(cellseg_mask, 1);
    Z = 1;

    if ndims(cellseg_mask) > 2
        Z = size(cellseg_mask,3);
    end

    xmin = 1; ymin = 1; zmin = 1;
    xmax = X;
    ymax = Y;
    zmax = Z;
    
    if isfield(rstruct, 'x_min'); xmin = rstruct.x_min; end
    if isfield(rstruct, 'x_max'); xmax = rstruct.x_max; end
    if isfield(rstruct, 'y_min'); ymin = rstruct.y_min; end
    if isfield(rstruct, 'y_max'); ymax = rstruct.y_max; end
    if isfield(rstruct, 'z_min'); zmin = rstruct.z_min; end
    if isfield(rstruct, 'z_max'); zmax = rstruct.z_max; end

    [xx, yy, zz] = meshgrid(1:X, 1:Y, 1:Z);
    xmask = double(and(xx >= xmin, xx <= xmax));
    ymask = double(and(yy >= ymin, yy <= ymax));

    trimmedMask = double(cellseg_mask);
    trimmedMask = trimmedMask .* xmask;
    trimmedMask = trimmedMask .* ymask;

    if Z > 1
        zmask = double(and(zz >= zmin, zz <= zmax));
        trimmedMask = trimmedMask .* zmask;
    end
end

function takeAndDumpCounts(analysis, groupname, cell_count, cellseg_mask, fileHandle, colnames, coltypes, dbthresh)
    tools = {'hb' 'bf' 'rs' 'db'};
    toolCount = size(tools, 2);
    colcount = size(colnames, 2);
    
    countTable = table('Size', [cell_count colcount], 'VariableTypes',coltypes, 'VariableNames',colnames);

    th_rs = 0;
    if isfield(analysis, 'results_rs')
        th_rs = AutothreshRS(analysis.results_rs, analysis.image_dims);
    end

    countTable{:, 'TH_RS'} = th_rs;
    countTable{:, 'TH_DB'} = dbthresh;
    countTable{:, 'IMGNAME'} = string(analysis.imgname);
    countTable{:, 'GROUP'} = string(groupname);
    countTable{:, 'CELLNO'} = [1:cell_count]';

    for i = 1:toolCount
        toolid = tools{i};
        resStructName = ['results_' toolid];
        if isfield(analysis, resStructName)
            rstruct = analysis.(resStructName);
            if ~isfield(rstruct, 'callset'); continue; end

            thval = 0;
            if isfield(rstruct, 'threshold'); thval = rstruct.threshold; end
            if strcmp(toolid, 'rs'); thval = th_rs; end
            if strcmp(toolid, 'db'); thval = dbthresh; end

            %Get count
            callset = TrimCallsetEdges(rstruct, analysis.image_dims);
            trimmedMask = trimCellsegMask(cellseg_mask, rstruct);
            inclz = analysis.image_dims.z;
            if isfield(rstruct, 'z_min')
                inclz = inclz - rstruct.z_min + 1;
            end
            if isfield(rstruct, 'z_max')
                chopped = analysis.image_dims.z - rstruct.z_max;
                inclz = inclz - chopped;
                clear chopped
            end

            for c = 1:cell_count
                if ~isempty(callset)
                    cell_pass = (callset{:,'cell'} == c);
                    cell_pass = and(cell_pass, (callset{:,'dropout_thresh'} >= thval));

                    fieldName = ['COUNT_' upper(toolid)];
                    countTable{c, fieldName} = nnz(cell_pass);
                end

                %Get prop of untrimmed cell
                if ndims(cellseg_mask) < 3
                    cellSize = nnz(cellseg_mask == c);
                    cellTrimmed = nnz(trimmedMask == c);
                    fieldName = ['CVG_XY_' upper(toolid)];
                    countTable{c, fieldName} = cellTrimmed ./ cellSize;

                    %For Z just the proportion of incl slices to total
                    fieldName = ['CVG_Z_' upper(toolid)];
                    countTable{c, fieldName} = inclz ./ analysis.image_dims.z;
                else
                    cellSize = nnz(cellseg_mask == c);
                    cellTrimmed = nnz(trimmedMask == c);
                    fieldName = ['CVG_' upper(toolid)];
                    countTable{c, fieldName} = cellTrimmed ./ cellSize;
                end
            end
        end
    end

    refsets = {'BH' 'BK'};
    refsetCount = size(refsets, 2);
    %Refsets
    if isfield(analysis, 'refsets')
        for i = 1:refsetCount
            refsetid = refsets{i};
            if isfield(analysis.refsets, refsetid)
                refstruct = analysis.refsets.(refsetid);
                %Convert to dummy table and struct so can use existing
                %funcs

                rcount = size(refstruct.exprefset, 1);
                reftbl = table('Size', [rcount 4],...
                    'VariableTypes',{'uint16' 'uint16' 'uint16' 'uint16'},...
                    'VariableNames',{'isnap_x' 'isnap_y' 'isnap_z' 'cell'});
                reftbl{:, 'isnap_x'} = refstruct.exprefset(:,1);
                reftbl{:, 'isnap_y'} = refstruct.exprefset(:,2);
                reftbl{:, 'isnap_z'} = refstruct.exprefset(:,3);

                reftbl = RNACoords.applyCellSegMask(reftbl, cellseg_mask);

                inclz = analysis.image_dims.z;
                if isfield(refstruct, 'truthset_region')
                    dummystr = struct();
                    dummystr.x_min = refstruct.truthset_region.x0;
                    dummystr.x_max = refstruct.truthset_region.x1;
                    dummystr.y_min = refstruct.truthset_region.y0;
                    dummystr.y_max = refstruct.truthset_region.y1;
                    dummystr.z_min = refstruct.truthset_region.z0;
                    dummystr.z_max = refstruct.truthset_region.z1;
                    trimmedMask = trimCellsegMask(cellseg_mask, dummystr);
                    inclz = inclz - dummystr.z_min + 1;

                    chopped = analysis.image_dims.z - dummystr.z_max;
                    inclz = inclz - chopped;
                    clear chopped
                else
                    trimmedMask = cellseg_mask;
                end

                for c = 1:cell_count
                    if ~isempty(reftbl)
                        cell_pass = (reftbl{:,'cell'} == c);

                        fieldName = ['COUNT_' upper(refsetid)];
                        countTable{c, fieldName} = nnz(cell_pass);
                    end

                    %Get prop of untrimmed cell
                    if ndims(cellseg_mask) < 3
                        cellSize = nnz(cellseg_mask == c);
                        cellTrimmed = nnz(trimmedMask == c);
                        fieldName = ['CVG_XY_' upper(refsetid)];
                        countTable{c, fieldName} = cellTrimmed ./ cellSize;

                        %For Z just the proportion of incl slices to total
                        fieldName = ['CVG_Z_' upper(refsetid)];
                        countTable{c, fieldName} = inclz ./ analysis.image_dims.z;
                    else
                        cellSize = nnz(cellseg_mask == c);
                        cellTrimmed = nnz(trimmedMask == c);
                        fieldName = ['CVG_' upper(refsetid)];
                        countTable{c, fieldName} = cellTrimmed ./ cellSize;
                    end
                end
                
            end
        end
    end

    %Print!
    for c = 1:cell_count
        for i = 1:colcount
            coltype = coltypes{i};
            colname = colnames{i};

            if i > 1
                fprintf(fileHandle, ',');
            end

            if strcmp(coltype, 'single') | strcmp(coltype, 'double')
                fprintf(fileHandle, '%.5f', countTable{c, colname});
            elseif strcmp(coltype, 'string')
                fprintf(fileHandle, '%s', countTable{c, colname});
            elseif contains(coltype, 'uint')
                fprintf(fileHandle, '%d', countTable{c, colname});
            end
        end
        fprintf(fileHandle, '\n');
    end

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

    x_max = 450;
    x_incr = 25;
    save_plots = false;

    %%Cycle through all groups one by one
%     allgroups = unique(table{:, 'GROUP'});
%     gcount = size(allgroups, 1);
%     for g = 1:gcount
%         gname = allgroups{g, 1};
% 
%         if ~isempty(onegroup_mode_group)
%             if ~strcmp(gname, onegroup_mode_group)
%                 continue;
%             end
%         end
% 
%         groupdir = [outdir filesep gname];
%         if ~isfolder(groupdir); mkdir(groupdir); end
% 
%         grows = find(strcmp(gname, table{:, 'GROUP'}));
%         group_tbl = table(grows, :);
% 
%         genGraphsFrom([groupdir filesep gname], gname, group_tbl, x_incr, x_max, colors, save_plots);
%     end

    %%Combine groups
    groupList = {'hela_18min_GFP' 'hela_5hr_GFP' 'hela_nostim_GFP'};
    groupName = 'HeLa_GFP';
%     groupList = {'hela_18min_CY5' 'hela_5hr_CY5' 'hela_nostim_CY5'};
%     groupName = 'HeLa_CY5';
%     groupList = {'mesc0_XistE_CY5' 'mescH_XistE_CY5' 'mesc1_XistE_CY5'...
%         'mesc4_XistE_CY5'};
%     groupName = 'XistE_CY5';
%     groupList = {'mescHistD0_XistI_CY5' 'mescHistD2_XistI_CY5'};
%     groupName = 'XistI_CY5';
%     groupList = {'mesc0_TsixE_TMR' 'mescH_TsixE_TMR' 'mesc1_TsixE_TMR'};
%     groupName = 'TsixE_TMR';
%     groupList = {'mescHistD0_TsixI_TMR' 'mescHistD2_TsixI_TMR'};
%     groupName = 'TsixI_TMR';
%     groupList = {'mescHistD0_H3K36me3_AF488' 'mescHistD2_H3K36me3_AF488'};
%     groupName = 'H3K36me3-AF488';
%     groupList = {'mescHistD0_H3K4me2_AF488' 'mescHistD2_H3K4me2_AF488'};
%     groupName = 'H3K4me2-AF488';

    rowTotal = size(table, 1);
    groupTotal = size(groupList, 2);
    grows = false(rowTotal,1);
    for i = 1:groupTotal
        grows = or(grows, strcmp(table{:, 'GROUP'}, groupList{i}));
    end

    group_tbl = table(grows, :);
    saveStem = [outdir filesep groupName];
    genGraphsFrom(saveStem, groupName, group_tbl, x_incr, x_max, colors, save_plots);

end

function genGraphsFrom(savestem, groupName, subtable, x_incr, x_max, colors, save_plots)

    apply_xy_scale = true;
    apply_z_scale = true;

    allcounts = cell(1,5);
    allcounts{1} = double(subtable{:,'COUNT_HB'});
    allcounts{2} = double(subtable{:,'COUNT_BF'});
    allcounts{3} = double(subtable{:,'COUNT_RS'});
    allcounts{4} = double(subtable{:,'COUNT_DB'});

    if apply_xy_scale
        allcounts{1} = round(allcounts{1} ./ subtable{:,'CVG_XY_HB'});
        allcounts{2} = round(allcounts{2} ./ subtable{:,'CVG_XY_BF'});
        allcounts{3} = round(allcounts{3} ./ subtable{:,'CVG_XY_RS'});
        allcounts{4} = round(allcounts{4} ./ subtable{:,'CVG_XY_DB'});
    end

    if apply_z_scale
        allcounts{1} = round(allcounts{1} ./ subtable{:,'CVG_Z_HB'});
        allcounts{2} = round(allcounts{2} ./ subtable{:,'CVG_Z_BF'});
        allcounts{3} = round(allcounts{3} ./ subtable{:,'CVG_Z_RS'});
        allcounts{4} = round(allcounts{4} ./ subtable{:,'CVG_Z_DB'});
    end

    y = cell(1,5);
    x = cell(1,5);

    xx = [0:x_incr:x_max];
    hist_edges = [(xx - (x_incr./2)) (x_max + (x_incr./2))];

    for i = 1:4
        cell_count = size(allcounts{i},1);

        [yy, ~] = histcounts(allcounts{i}, hist_edges);
        yy = yy ./ cell_count;

        x{i} = xx;
        y{i} = yy;

        %cm = cumsum(y{i});
        %x_ax_sugg(i) = xx(find(cm >= X_CU_CUTOFF, 1));
        clear cm yy nz_count nzbinnable
    end

    %Look for reference...
    %Remove any cells where XY coverage is 0
    cells_w_ref = find(subtable{:,'CVG_XY_BH'} > 0.0);
    ref_cell_count = 0;
    if ~isempty(cells_w_ref)
        has_ref = true;
        allcounts{5} = double(subtable{cells_w_ref,'COUNT_BH'});
        if apply_xy_scale
            allcounts{5} = round(allcounts{5} ./ subtable{cells_w_ref,'CVG_XY_BH'});
        end
        if apply_z_scale
            allcounts{5} = round(allcounts{5} ./ subtable{cells_w_ref,'CVG_Z_BH'});
        end

        cell_count = size(allcounts{5},1);

        [yy, ~] = histcounts(allcounts{5}, hist_edges);
        yy = yy ./ cell_count;
        bin_count = size(yy, 2);

        xx = (hist_edges(1:bin_count) + hist_edges(2:bin_count+1)) ./ 2;

        x{5} = xx;
        y{5} = yy;

        ref_cell_count = cell_count;
        clear cell_count yy nz_count nzbinnable
    else
        has_ref = false;
    end


    if has_ref
        toolnames = {'TrueSpot', 'Big-FISH', 'RS-FISH', 'DeepBlink'...
            ['Reference [BH] (n = ' num2str(ref_cell_count) ')']};
    else
        toolnames = {'TrueSpot', 'Big-FISH', 'RS-FISH', 'DeepBlink'};
    end

    %Faceted
    fh1 = figure(1);
    clf;
    hold on;
    for i = 1:4
        subplot(2,2,i);
        plot(x{i}, y{i}, 'LineWidth', 2, ...
            'Color', colors{i});
        ylim([0,1]);
        xlim([0,x_max]);
        title(toolnames{i});

        cell_count = size(allcounts{i},1);
        subtitle(['n = ' num2str(cell_count)]);
    end

    if save_plots
        filestem = [savestem '_facet'];
        saveas(fh1, [filestem '.png']);
        saveas(fh1, [filestem '.svg']);
        close(fh1);
    end

    %Combined
    fh = figure(2);
    clf;
    hold on;
    for i = 1:4
        plot(x{i}, y{i},...
            'LineWidth', 1.5, 'Color', colors{i});
    end
    if has_ref
        plot(x{5}, y{5}, 'LineStyle', '-.',...
            'LineWidth', 1.5, 'Color', [0.0 0.0 0.0]);
    end
    cell_count = size(allcounts{1},1);
    title(replace(groupName, '_', ' '));
    subtitle(['n = ' num2str(cell_count)]);
    legend(toolnames, 'Location', 'northeast');
    if save_plots
        filestem = [savestem '_combined_zoomy'];
        saveas(fh, [filestem '.png']);
        saveas(fh, [filestem '.svg']);
    end

    ylim([0,1]);
    if save_plots
        filestem = [savestem '_combined'];
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

