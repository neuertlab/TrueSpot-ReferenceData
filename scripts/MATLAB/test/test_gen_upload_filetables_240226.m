%
%%  !! UPDATE TO YOUR BASE DIR
BaseDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
%BaseDir = 'D:\usr\bghos\labdat\imgproc';

ImgProcDir = 'D:\Users\hospelb\labdata\imgproc';
%ImgProcDir = 'D:\usr\bghos\labdat\imgproc';

ImgDir = 'C:\Users\hospelb\labdata\imgproc';
%ImgDir = 'D:\usr\bghos\labdat\imgproc';

StageDir = 'C:\Users\hospelb\labdata\biostudies_ftp';

addpath('./core');
addpath('./test');
addpath('./test/datadump');

% ========================== General Context ==========================

DateSuffix = '240226';
OutputDir = [BaseDir filesep 'upload'];

% ========================== Parameters ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];
TablePath_SimNeg = [BaseDir filesep 'test_images_simneg.csv'];

AllTablePaths = {TablePath_Main, TablePath_Mass, TablePath_YTC TablePath_SimNeg};
%AllTablePaths = {TablePath_Mass, TablePath_YTC};
ImgTableCount = size(AllTablePaths, 2);

% ========================== Main Loop ==========================

fhStruct = openOutputTables(OutputDir);
lasttif = [];
for t = 1:ImgTableCount
    fprintf('Trying Table %s...\n', AllTablePaths{t});
    image_table = testutil_opentable(AllTablePaths{t});

    entry_count = size(image_table, 1);
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

%----------- DO THING
        groupname = getSupergroupName(imgname);
        doResultsEntry(fhStruct, image_table, r, analysis, supergroup);

        tifpath = getTableValue(image_table, r, 'IMAGEPATH');
        [~, tifname, ~] = fileparts(tifpath);

        if isempty(lasttif) | ~strcmp(tifname, lasttif)
            if strcmp(supergroup, 'scProtein')
                doImageFileEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'simBig')
                doImageFileEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'simVar')
                doImageFileEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'simvarmass')
                doImageFileEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'simytc')
                doImageFileEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'simneg')
                doImageFileEntry(fhStruct, image_table, r, analysis, supergroup);
            end

            if strcmp(supergroup, 'sctc')
                doCellSegEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'mescE')
                doCellSegEntry(fhStruct, image_table, r, analysis, supergroup);
            elseif strcmp(supergroup, 'mescI')
                doCellSegEntry(fhStruct, image_table, r, analysis, supergroup);
            end

        end
        
%----------- DONE THING

        clear analysis set_group_dir ResFilePath myname
    end
end
closeOutputTables(fhStruct);

% ========================== Helper Functions ==========================

function doResultsEntry(fhStruct, table, table_row, analysis, supergroup)
    fhandle = fhStruct.(supergroup);
    iname = analysis.imgname;
    tifpath = getTableValue(table, table_row, 'IMAGEPATH');
    [~, tifname, ~] = fileparts(tifpath);

    subgroup = getSubgroup(analysis, supergroup, tifname);

    fprintf(fhandle, '%s/%s.mat\t%s\t%s', supergroup, iname, ...
        iname, subgroup);

    tstr = getTableValue(table, table_row, 'TARGET');
    if isempty(tstr); tstr = '[Unknown]'; end
    if strcmp(tstr, 'Sim'); tstr = '(Simulation)'; end
    fprintf(fhandle, '%s\t', tstr);

    tstr = getTableValue(table, table_row, 'PROBE');
    if isempty(tstr); tstr = '[Unknown]'; end
    if strcmp(tstr, 'Sim'); tstr = '(Simulation)'; end
    fprintf(fhandle, '%s\t', tstr);
    
    fprintf(fhandle, '%s\t', tifname);

    if strcmp(supergroup, 'hela')
        fprintf(fhandle, '60X\t');
    elseif strcmp(supergroup, 'mouseTissue')
        if contains(iname, '40x')
            fprintf(fhandle, '40X\t');
        else
            fprintf(fhandle, '20X\t');
        end
    else
        fprintf(fhandle, '100X\t');
    end

    if strcmp(supergroup, 'hela')
        if endsWith(iname, 'GFP')
            fprintf(fhandle, 'MS2/MCP-GFP\t');
        else
            fprintf(fhandle, 'RNA-FISH (smiFISH)\t');
        end
    elseif strcmp(supergroup, 'mouseTissue')
        fprintf(fhandle, 'RNA-SCOPE\t');
    elseif strcmp(supergroup, 'scProtein')
        fprintf(fhandle, 'GFP/Target Hybridization\t');
    elseif strcmp(supergroup, 'mescI')
        if endsWith(iname, 'Histone')
            fprintf(fhandle, 'Immunofluroescence\t');
        else
            fprintf(fhandle, 'RNA-FISH (smFISH)\t');
        end
    elseif strcmp(supergroup, 'misc')
        if contains(iname, '_sim_')
            fprintf(fhandle, 'Simulation\t');
        else
            fprintf(fhandle, 'RNA-FISH\t');
        end
    elseif startsWith(supergroup, 'sim')
        fprintf(fhandle, 'Simulation\t');
    else
        fprintf(fhandle, 'RNA-FISH (smFISH)\t');
    end

    tval = getTableValue(table, table_row, 'CHANNEL');
    fprintf(fhandle, '%d\t', tval);

    idims = analysis.image_dims;
    fprintf(fhandle, '%d,%d,%d\t', idims.x, idims.y, idims.z);

    idims = analysis.voxel_dims;
    fprintf(fhandle, '%d,%d,%d\t', idims.x, idims.y, idims.z);

    %Ground truth type TODO DOUBLE CHECK STRUCT NAMES
    if isfield(analysis, 'refsets')
        if strcmp(supergroup, 'mouseTissue')
            fprintf(fhandle, 'Manual Threshold w/ Imaris');
        else
            fprintf(fhandle, 'Manual Agnostic');
        end
    elseif isfield(analysis, 'simkey')
        fprintf(fhandle, 'Simulated Ground Truth');
    else
        fprintf(fhandle, 'None');
    end

    %Supergroup specific...
    if startsWith(supergroup, 'mESC')
        if contains(iname, 'D0')
            fprintf(fhandle, '\t0');
        elseif contains(iname, 'DH')
            fprintf(fhandle, '\t0.5');
        elseif contains(iname, 'D1')
            fprintf(fhandle, '\t1');
        elseif contains(iname, 'D2')
            fprintf(fhandle, '\t2');
        elseif contains(iname, '4d')
            fprintf(fhandle, '\t4');
        else
            fprintf(fhandle, '\t[Unknown]');
        end
    elseif strcmp(supergroup, 'sctc')
        nameinfo = Parse_sctcImgName(iname);
        if nameinfo.Exp == 1
            fprintf(fhandle, '\t0.2M');
        elseif nameinfo.Exp == 2
            fprintf(fhandle, '\t0.4M');
        else
            fprintf(fhandle, '\t[Unknown]');
        end
        fprintf(fhandle, '\t%d\t%02d min', nameinfo.Rep, nameinfo.TimePointMin);

        clear nameinfo
    elseif strcmp(supergroup, 'mouseTissue')
        tstr = getTableValue(table, table_row, 'IMAGEPATH');
        [~, tstr, ~] = fileparts(tstr);
        nameinfo = parseSimerlySampleName(iname, tstr);
        fprintf(fhandle, '\t%s\t%s-%s\t%s\t%s', nameinfo.Tissue,...
            nameinfo.Exp, nameinfo.Mouse, nameinfo.Sex, nameinfo.Section);
    elseif startsWith(supergroup, 'sim')
        fprintf(fhandle, '\tSim-FISH');
    end

    fprintf(fhandle, '\n');
end

function doImageFileEntry(fhStruct, table, table_row, analysis, supergroup)
    tifpath = getTableValue(table, table_row, 'IMAGEPATH');
    [~, tifname, ~] = fileparts(tifpath);

    srcstring = 'Experimental';
    if startsWith(supergroup, 'sim')
        fhandle = fhStruct.simImages;
        srcstring = 'Sim-FISH';
    else
        fname = [supergroup 'Images'];
        fhandle = fhStruct.(fname);
    end

    fprintf(fhandle, '%s/image/%s.tif\t', supergroup, tifname);
    fprintf(fhandle, '%s\t%s\t', tifname, supergroup);

    idims = analysis.image_dims;
    fprintf(fhandle, '%d,%d,%d\t', idims.x, idims.y, idims.z);

    idims = analysis.voxel_dims;
    fprintf(fhandle, '%d,%d,%d\t', idims.x, idims.y, idims.z);

    if strcmp(supergroup, 'hela')
        fprintf(fhandle, '60X\t');
    elseif strcmp(supergroup, 'mouseTissue')
        if contains(iname, '40x')
            fprintf(fhandle, '40X\t');
        else
            fprintf(fhandle, '20X\t');
        end
    else
        fprintf(fhandle, '100X\t');
    end

    fprintf(fhandle, '%s', srcstring);
    fprintf(fhandle, '\n');
end

function doCellSegEntry(fhStruct, table, table_row, analysis, supergroup)
    cellseg_suffix = getTableValue(table, table_row, 'CELLSEG_SFX');
    tifpath = getTableValue(table, table_row, 'IMAGEPATH');
    [~, tifname, ~] = fileparts(tifpath);

    fname = [supergroup 'CellSeg'];
    fhandle = fhStruct.(fname);

    fprintf(fhandle, '%s/cellmask/Lab_%s.mat\t', supergroup, cellseg_suffix);
    fprintf(fhandle, '%s\t', tifname);

    tval = getTableValue(table, table_row, 'CH_DAPI');
    fprintf(fhandle, '%d\t', tval);
    tval = getTableValue(table, table_row, 'CH_LIGHT');
    fprintf(fhandle, '%d', tval);

    iname = analysis.imgname;
    if strcmp(supergroup, 'sctc')
        nameinfo = Parse_sctcImgName(iname);
        if nameinfo.Exp == 1
            fprintf(fhandle, '\t0.2M');
        elseif nameinfo.Exp == 2
            fprintf(fhandle, '\t0.4M');
        else
            fprintf(fhandle, '\t[Unknown]');
        end
        fprintf(fhandle, '\t%d\t%02d min', nameinfo.Rep, nameinfo.TimePointMin);

        clear nameinfo
    elseif startsWith(supergroup, 'mesc')
        if contains(iname, 'D0')
            fprintf(fhandle, '\t0');
        elseif contains(iname, 'DH')
            fprintf(fhandle, '\t0.5');
        elseif contains(iname, 'D1')
            fprintf(fhandle, '\t1');
        elseif contains(iname, 'D2')
            fprintf(fhandle, '\t2');
        elseif contains(iname, '4d')
            fprintf(fhandle, '\t4');
        else
            fprintf(fhandle, '\t[Unknown]');
        end
    end

    fprintf(fhandle, '\n');
end

function groupname = getSubgroup(analysis, supergroup, tifname)
    iname = analysis.imgname;

    groupname = supergroup;
    if strcmp(supergroup, 'scProtein')
        if contains(iname, 'Msb2')
            groupname = 'Msb2-GFP';
        elseif contains(iname, 'Opy2')
            groupname = 'Opy2-GFP';
        end
    elseif strcmp(supergroup, 'sctc')
        nameinfo = Parse_sctcImgName(iname);
        groupname = ['sctc_E' num2str(nameinfo.Exp) 'R' num2str(nameinfo.Rep) 'C' num2str(nameinfo.Channel)];
    elseif strcmp(supergroup, 'mescE')
        day = 'Day4';
        if contains(iname, 'D0')
            day = 'Day0';
        elseif contains(iname, 'DH')
            day = 'HalfDay';
        elseif contains(iname, 'D1')
            day = 'Day1';
        end
        if contains(iname, 'Tsix')
            groupname = ['TsixE_' day];
        elseif contains(iname, 'Xist')
            groupname = ['XistE_' day];
        end
    elseif strcmp(supergroup, 'mescI')
        day = 'UnkDay';
        if contains(iname, 'D0')
            day = 'Day0';
        elseif contains(iname, 'D2')
            day = 'Day2';
        end
        if contains(iname, 'Tsix')
            groupname = ['TsixI_' day];
        elseif contains(iname, 'Xist')
            groupname = ['XistI_' day];
        elseif contains(iname, 'Histone')
            if contains(iname, 'H3K36me3')
                groupname = ['H3K36me3' day];
            else
                groupname = ['H3K4me2' day];
            end
        end
    elseif strcmp(supergroup, 'hela')
        probe = 'CY5';
        if endsWith(iname, 'GFP'); probe = 'GFP'; end
        if contains(tifname, '18minTPL')
            groupname = ['HeLa_' probe '_18min'];
        elseif contains(tifname, '5hTPL')
            groupname = ['HeLa_' probe '_5hr'];
        elseif contains(tifname, 'woStim')
            groupname = ['HeLa_' probe '_noStim'];
        end
    elseif strcmp(supergroup, 'mouseTissue')
        sgroup = 'LoBkg';
        if contains(iname, '_40x_')
            sgroup = '40X';
        elseif contains(iname, '_HiBkg_')
            sgroup = 'HiBkg';
        end
        ttype = 'BST';
        if contains(tifname, 'ARH'); ttype = 'ARH'; end
        groupname = ['mTissue_' sgroup '_' ttype '_' analysis.probe_target '_' analysis.probe];
    elseif strcmp(supergroup, 'misc')
        if startsWith(iname, 'rsfish_')
            if startsWith(iname, 'rsfish_sim')
                groupname = ['RSSim'];
            else
                groupname = ['Misc'];
            end
        end
    end

end

function nameinfo = parseSimerlySampleName(iname, tifname)
    nameinfo = struct();
    
    tifname_spl = split(tifname, '_');
    spllen = size(tifname_spl, 1);
    if contains(iname, '_40x_')
        nameinfo.BoxBatch = '40x';
        nameinfo.Tissue = 'BST';
        nameinfo.Section = 'N/A';
        if startsWith(tifname, 'Female')
            nameinfo.Sex = 'F';
            nameinfo.Mouse = 'FX';
        else
            nameinfo.Sex = 'M';
            nameinfo.Mouse = 'MX';
        end

        if contains(tifname, '_MEO_')
            nameinfo.Exp = 'MEO';
        elseif contains(tifname, '_MGG_')
            nameinfo.Exp = 'MGG';
        elseif contains(tifname, '_MTG_')
            nameinfo.Exp = 'MTG';
        end
    elseif contains(iname, '_HiBkg_')
        nameinfo.BoxBatch = 'HiBkg';
        if contains(tifname, 'ARH')
            nameinfo.Tissue = 'ARH';
            nameinfo.Exp = 'MAK';
            nameinfo.Sex = 'F';

            splpart = tifname_spl{1, 1};
            splpart = splpart(2:end);
            strlen = size(splpart, 2);
            if strlen < 2
                splpart = ['0' splpart];
            end
            nameinfo.Mouse = ['F' splpart];

            splpart = tifname_spl{3, 1};
            nameinfo.Section = splpart(2:3);
        else
            nameinfo.Tissue = 'BST';
            nameinfo.Exp = 'MCP';

            if contains(tifname, 'female')
                nameinfo.Sex = 'F';
                %Get animal ID
                for i = 1:spllen
                    splpart = tifname_spl{i, 1};
                    if startsWith(splpart, 'female')
                        splpart = replace(splpart, 'female', '');
                        splpart = replace(splpart, 'BST', '');
                        strlen = size(splpart, 2);
                        if strlen < 2
                            splpart = ['0' splpart];
                        end
                        nameinfo.Mouse = ['F' splpart];
                        break;
                    end
                end
            else
                nameinfo.Sex = 'M';
                %Get animal ID
                for i = 1:spllen
                    splpart = tifname_spl{i, 1};
                    if startsWith(splpart, 'male')
                        splpart = replace(splpart, 'male', '');
                        splpart = replace(splpart, 'BST', '');
                        strlen = size(splpart, 2);
                        if strlen < 2
                            splpart = ['0' splpart];
                        end
                        nameinfo.Mouse = ['M' splpart];
                        break;
                    end
                end
            end

            %Section
            for i = 1:spllen
                splpart = tifname_spl{i, 1};
                if contains(splpart, 'stack')
                    nameinfo.Section = splpart(1:2);
                    break;
                end
            end
        end
    elseif contains(iname, '_LoBkg_')
        nameinfo.BoxBatch = 'LoBkg';
        nameinfo.Tissue = 'ARH';

        shifted = false;
        if startsWith(tifname, 'F_')
            shifted = true;
        elseif startsWith(tifname, 'M_')
            shifted = true;
        end
        nameinfo.Sex = tifname(1);

        if ~shifted
            nameinfo.Exp = tifname_spl{2, 1};
            splpart = tifname_spl{1, 1};
            splpart = splpart(2:end);
            strlen = size(splpart, 2);
            if strlen < 2
                splpart = ['0' splpart];
            end
            nameinfo.Mouse = [nameinfo.Sex splpart];

            splpart = tifname_spl{4, 1};
            nameinfo.Section = splpart(2:3);
        else
            nameinfo.Exp = tifname_spl{3, 1};
            nameinfo.Mouse = [nameinfo.Sex tifname_spl{2, 1}];
            splpart = tifname_spl{5, 1};
            nameinfo.Section = splpart(2:3);
        end
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
    elseif startsWith(imgname, 'simerly_')
        dirname = 'simerly_lab';
    else
        dirname = groupname;
    end
end

function groupname = getSupergroupName(imgname)
    inparts = split(imgname, '_');
    groupname = inparts{1,1};
    if strcmp(groupname, 'simvarmass')
        if contains(imgname, 'TMRL') | contains(imgname, 'CY5L')
            groupname = 'simytc';
        end
    elseif startsWith(imgname, 'ROI')
        groupname = 'hela';
    elseif startsWith(imgname, 'simerly_')
        groupname = 'mouseTissue';
    elseif startsWith(imgname, 'mESC4d_')
        groupname = 'mescE';
    elseif startsWith(imgname, 'mESC_loday_')
        groupname = 'mescE';
    elseif startsWith(imgname, 'histonesc_')
        groupname = 'mescI';
    elseif startsWith(imgname, 'scprotein_')
        groupname = 'scProtein';
    elseif startsWith(imgname, 'sim_')
        groupname = 'simBig';
    elseif startsWith(imgname, 'simvar_')
        groupname = 'simVar';
    elseif startsWith(imgname, 'rsfish_')
        groupname = 'misc';
    end
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end

function fhStruct = openOutputTables(dir)
    COMMON_COLS = {'Files' 'Image Name' 'Group'...
        'Target' 'Probe' 'TIF Name' 'Magnification'...
        'Imaging Technique' 'Channel' 'Image Dimensions'...
        'Voxel Dimensions' 'Ground Truth'};

    MESC_COLS = {'Day'};
    SCTC_COLS = {'NaCl Concentration' 'Biological Replicate' 'Time Point'};
    SIM_COLS = {'Source'};
    SIMERLY_COLS = {'Tissue' 'Animal' 'Animal Sex' 'Section'}; %eg. ARH MTV-M27 Male BL

    tpath = [dir filesep 'scProtein.tsv'];
    fhStruct.scProtein = openOutputTable(tpath, COMMON_COLS, []);

    tpath = [dir filesep 'sctc.tsv'];
    fhStruct.sctc = openOutputTable(tpath, COMMON_COLS, SCTC_COLS);

    tpath = [dir filesep 'mescE.tsv'];
    fhStruct.mescE = openOutputTable(tpath, COMMON_COLS, MESC_COLS);

    tpath = [dir filesep 'mescI.tsv'];
    fhStruct.mescI = openOutputTable(tpath, COMMON_COLS, MESC_COLS);

    tpath = [dir filesep 'hela.tsv'];
    fhStruct.hela = openOutputTable(tpath, COMMON_COLS, []);

    tpath = [dir filesep 'mouseTissue.tsv'];
    fhStruct.mouseTissue = openOutputTable(tpath, COMMON_COLS, SIMERLY_COLS);

    tpath = [dir filesep 'simBig.tsv'];
    fhStruct.simBig = openOutputTable(tpath, COMMON_COLS, SIM_COLS);

    tpath = [dir filesep 'simVar.tsv'];
    fhStruct.simVar = openOutputTable(tpath, COMMON_COLS, SIM_COLS);

    tpath = [dir filesep 'simvarmass.tsv'];
    fhStruct.simvarmass = openOutputTable(tpath, COMMON_COLS, SIM_COLS);

    tpath = [dir filesep 'simytc.tsv'];
    fhStruct.simytc = openOutputTable(tpath, COMMON_COLS, SIM_COLS);

    tpath = [dir filesep 'simneg.tsv'];
    fhStruct.simneg = openOutputTable(tpath, COMMON_COLS, SIM_COLS);

    tpath = [dir filesep 'misc.tsv'];
    fhStruct.misc = openOutputTable(tpath, COMMON_COLS, []);


    IMG_COMMON_COLS = {'Files' 'TIF Name' 'Group' 'Image Dimensions'...
        'Voxel Dimensions' 'Magnification' 'Source'};

    tpath = [dir filesep 'scProteinImages.tsv'];
    fhStruct.scProteinImages = openOutputTable(tpath, IMG_COMMON_COLS, []);

    tpath = [dir filesep 'simImages.tsv'];
    fhStruct.simImages = openOutputTable(tpath, IMG_COMMON_COLS, []);

    CELLSEG_COMMON_COLS = {'Files' 'TIF Name' 'DAPI Channel' 'Light Channel'};

    tpath = [dir filesep 'sctcCellSeg.tsv'];
    fhStruct.sctcCellSeg = openOutputTable(tpath, CELLSEG_COMMON_COLS, SCTC_COLS);

    tpath = [dir filesep 'mescICellSeg.tsv'];
    fhStruct.mescICellSeg = openOutputTable(tpath, CELLSEG_COMMON_COLS, MESC_COLS);

    tpath = [dir filesep 'mescECellSeg.tsv'];
    fhStruct.mescECellSeg = openOutputTable(tpath, CELLSEG_COMMON_COLS, MESC_COLS);

end

function fhandle = openOutputTable(path, cols_common, cols_spec)
    fhandle = fopen(path, 'w');
    if ~isempty(cols_common)
        count = size(cols_common, 2);
        for i = 1:count
            if i > 1; fprintf(fhandle, '\t'); end
            fprintf(fhandle, '%s', cols_common{i});
        end
    end
    if ~isempty(cols_spec)
        count = size(cols_spec, 2);
        for i = 1:count
            fprintf(fhandle, '\t%s', cols_spec{i});
        end
    end

    fprintf(fhandle, '\n');
end

function closeOutputTables(fhStruct)
    if ~isempty(fhStruct)
        fnlist = fieldnames(fhStruct);
        fncount = size(fnlist, 1);
        for i = 1:fncount
            fn = fnlist{i, 1};
            fclose(fhStruct.(fn));
        end
    end
end

