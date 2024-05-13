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

START_INDEX = 243;
END_INDEX = 272;

DO_HOMEBREW = true;
DO_BIGFISH = true;
DO_RSFISH = false;
DO_DEEPBLINK = false;

XTRIM = 7;
YTRIM = 7;

Z_MIN = 0;
Z_MAX = 0;
SNAP_RAD = 4;
FILTER_Z_RAD = 2;
MIDPOINT = 6;

OutputDir = [BaseDir filesep 'data' filesep 'results'];

DEADPIX_WORKDIR = './bgh_old';

RS_TH_IVAL = 0.1/250;
SCRIPT_VER = 'v24.05.09.01';
COMPUTER_NAME = 'CHROMAT_WIN';
%COMPUTER_NAME = 'VU_NEUERTLAB_HOSPELB';

EXPTS_INITIALS = 'BH';

% ========================== Load csv Table ==========================

%InputTablePath = [BaseDir filesep 'test_images_simytc.csv'];
%InputTablePath = [BaseDir filesep 'test_images_simvarmass.csv'];
InputTablePath = [BaseDir filesep 'test_images.csv'];
image_table = testutil_opentable(InputTablePath);

% ========================== Iterate through table entries ==========================
if ~isfolder(OutputDir)
    mkdir(OutputDir);
end

entry_count = size(image_table,1);

if START_INDEX < 1; START_INDEX = 1; end
if END_INDEX > entry_count; END_INDEX = entry_count; end

z_min = Z_MIN;
z_max = Z_MAX;
if z_min < 1; z_min = 1; end
Z_MIN_STR = num2str(z_min);

if z_max > 0
    Z_MAX_STR = num2str(z_max);
else
    Z_MAX_STR = 'Z';
end
mipFieldName = ['mip_' Z_MIN_STR '_' Z_MAX_STR];

for r = START_INDEX:END_INDEX
    myname = getTableValue(image_table, r, 'IMGNAME');
    fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);

    %Load analysis file
    groupdir = getSetOutputDirName(myname);
    ResFilePath = [OutputDir filesep groupdir filesep myname '_summary.mat'];

    if isfile(ResFilePath)
        load(ResFilePath, 'analysis');
    else
        fprintf('> Could not find analysis file. Skipping...\n');
        continue;
    end

    idims = analysis.image_dims;
    if Z_MAX < 1
        z_max = idims.z;
    end

    %MIP refset (Filter outside of included slices)
    myref = [];
    refFieldName = ['refsets_' mipFieldName];
    if isfield(analysis, 'refsets')
        if isfield(analysis.refsets, EXPTS_INITIALS)
            analysis.(refFieldName) = struct();
            myref = analysis.refsets.(EXPTS_INITIALS);

            myref.timestamp = datetime;
            if isfield(myref, 'truthset_region')
                myref.truthset_region = rmfield(myref.truthset_region, 'z0');
                myref.truthset_region = rmfield(myref.truthset_region, 'z1');
            end

            zz_min = max(1, z_min - FILTER_Z_RAD);
            zz_max = min(idims.z, z_max + FILTER_Z_RAD);

            %Filter.
            keepmtx = myref.exprefset(:,3) >= zz_min;
            keepmtx = and(keepmtx, myref.exprefset(:,3) <= zz_max);
            myref.exprefset = myref.exprefset(find(keepmtx),(1:2));
            clear keepmtx

            analysis.(refFieldName).(EXPTS_INITIALS) = myref;
        end
    end

    %Load cellseg (if applicable)
    cell_mask = [];
    cellSegDir = [BaseDir filesep replace(getTableValue(image_table, r, 'CELLSEG_DIR'), '/', filesep)];
    cellSegSuffix = getTableValue(image_table, r, 'CELLSEG_SFX');
    if ~strcmp(cellSegDir, '.')
        cellSegPath = [cellSegDir filesep 'Lab_' cellSegSuffix '.mat'];
        cell_mask = CellSeg.openCellMask(cellSegPath);
    end
    

    if DO_HOMEBREW
        %hb_stem_base = getTableValue(image_table, r, 'OUTSTEM');
        %hb_stem = [BaseDir replace(hb_stem_base, '/', filesep)];
        %hb_stem = getHBStem(hb_stem, Z_MIN, Z_MAX);
        tiffPath = getTableValue(image_table, r, 'IMAGEPATH');
        [~,tifName, ~] = fileparts(tiffPath);
        trgName = getTableValue(image_table, r, 'TARGET');
        hb_stem = getHBStem(BaseDir, myname, trgName, tifName, Z_MIN, Z_MAX);
        clear tiffPath tifName trgName

        %Read tool output
        callTablePath = [hb_stem '_callTable.mat'];
        if isfile(callTablePath)
            load(callTablePath, 'call_table');

            if ~isfield(analysis, 'results_hb')
                analysis.results_hb = struct();
            end

            rstruct = struct();

            %Metadata (timestamp, version etc)
            rstruct.importMeta = struct();
            rstruct.importMeta.timestamp = datetime;
            rstruct.importMeta.scriptVersion = SCRIPT_VER;
            rstruct.importMeta.importComputer = COMPUTER_NAME;

            rstruct.callset = call_table;
            rstruct.z_min = z_min;
            rstruct.z_max = z_max;

            rstruct.x_min = XTRIM + 1;
            rstruct.x_max = idims.x - XTRIM;
            rstruct.y_min = YTRIM + 1;
            rstruct.y_max = idims.y - YTRIM;

            %Load threshold info
            th_val = 0;
            spotsrun = RNASpotsRun.loadFrom(hb_stem);
            if ~isempty(spotsrun)
                rstruct.threshold = spotsrun.intensity_threshold;
                rstruct.threshold_details = spotsrun.threshold_results;
                th_val = rstruct.threshold;

                rstruct.th_scan_min = spotsrun.options.t_min;
                rstruct.th_scan_max = spotsrun.options.t_max;

                if isempty(rstruct.threshold_details)
                    %Try rethresh
                    fprintf('\t> Thresholding did not run. Trying now...\n');
                    spot_table = RNAUtils.spotTableFromCallTable(call_table, true, rstruct.th_scan_min, rstruct.th_scan_max);
            
                    if startsWith(myname, 'histonesc_')
                        if endsWith(myname, '_Histone')
                            threshold_results = RNAThreshold.runWithPreset(spot_table, [], MIDPOINT + 5);
                        elseif endsWith(myname, '_Tsix')
                            threshold_results = RNAThreshold.runWithPreset(spot_table, [], MIDPOINT - 2);
                        else
                            threshold_results = RNAThreshold.runSavedParameters(spotsrun, 1, spot_table, []);
                        end
                    else
                        threshold_results = RNAThreshold.runSavedParameters(spotsrun, 1, spot_table, []);
                    end

                    rstruct.threshold_details = threshold_results;
                    rstruct.threshold = threshold_results.threshold;
                    th_val = rstruct.threshold;
                end
            else
                rstruct.threshold = 0;
                rstruct.threshold_details = [];
            end

            %Compare to reference, if applicable
            if ~isempty(myref)
                [call_table, ref_assign] = RNACoords.updateTFCalls2D(call_table, myref.exprefset, SNAP_RAD, 25);
                rstruct.callset = call_table;

                %Calculate performance metrics
                pstruct = struct();
                pstruct.name = EXPTS_INITIALS;
                pstruct.ref_call_map = ref_assign;

                %Update trimming flags in table
                if isfield(myref, 'truthset_region')
                    [rstruct.callset, ~] = AnalysisFiles.applyTruthRegionMask(myref.truthset_region, rstruct.callset, idims, true);
                else
                    rstruct.callset{:,'in_truth_region'} = true;
                end
                [rstruct, ~] = AnalysisFiles.updateCallsetTrimRes(rstruct, idims, true);

                %Update metrics
                pstruct = AnalysisFiles.calculatePerformanceMetrics(rstruct.callset, th_val, pstruct);

                pstruct.timestamp = datetime;

                if isfield(rstruct, 'benchmarsk')
                    %Oops lol
                    rstruct = rmfield(rstruct, 'benchmarsk');
                end
                if ~isfield(rstruct, 'benchmarks')
                    rstruct.benchmarks = struct();
                end
                rstruct.benchmarks.(EXPTS_INITIALS) = pstruct;
            end

            %Cell seg (if applicable)
            if ~isempty(cell_mask)
                rstruct.callset = RNACoords.applyCellSegMask(rstruct.callset, cell_mask);
            end

            analysis.results_hb.(mipFieldName) = rstruct;
        else
            fprintf('\t> TrueSpot output data was not found. Skipping...\n');
        end
    end

    if DO_BIGFISH
        bf_stem = getBFStem(image_table, r, mipFieldName);
        bf_stem = [BaseDir replace(bf_stem, '/', filesep)];
        [bf_dir, ~, ~] = fileparts(bf_stem);

        callTablePath = [bf_stem '_callTable.mat'];
        if isfile(callTablePath)
            load(callTablePath, 'call_table');

            if ~isfield(analysis, 'results_bf')
                analysis.results_bf = struct();
            end

            rstruct = struct();

            %Metadata (timestamp, version etc)
            rstruct.importMeta = struct();
            rstruct.importMeta.timestamp = datetime;
            rstruct.importMeta.scriptVersion = SCRIPT_VER;
            rstruct.importMeta.importComputer = COMPUTER_NAME;

            rstruct.callset = call_table;
            rstruct.z_min = z_min;
            rstruct.z_max = z_max;

            rstruct.x_min = XTRIM + 1;
            rstruct.x_max = idims.x - XTRIM;
            rstruct.y_min = YTRIM + 1;
            rstruct.y_max = idims.y - YTRIM;

            %Load threshold info
            summary_path = [bf_dir filesep 'summary.txt'];
            [~, ~, th_val, ~] = BigfishCompare.readSummaryTxt(summary_path);
            rstruct.threshold = th_val;

            %Compare to reference, if applicable
            if ~isempty(myref)
                [call_table, ref_assign] = RNACoords.updateTFCalls2D(call_table, myref.exprefset, SNAP_RAD, 25);
                rstruct.callset = call_table;

                %Calculate performance metrics
                pstruct = struct();
                pstruct.name = EXPTS_INITIALS;
                pstruct.ref_call_map = ref_assign;

                %Update trimming flags in table
                if isfield(myref, 'truthset_region')
                    [rstruct.callset, ~] = AnalysisFiles.applyTruthRegionMask(myref.truthset_region, rstruct.callset, idims, true);
                else
                    rstruct.callset{:,'in_truth_region'} = true;
                end
                [rstruct, ~] = AnalysisFiles.updateCallsetTrimRes(rstruct, idims, true);

                %Update metrics
                pstruct = AnalysisFiles.calculatePerformanceMetrics(rstruct.callset, th_val, pstruct);

                pstruct.timestamp = datetime;

                if ~isfield(rstruct, 'benchmarks')
                    rstruct.benchmarks = struct();
                end
                rstruct.benchmarks.(EXPTS_INITIALS) = pstruct;
            end

            %Cell seg (if applicable)
            if ~isempty(cell_mask)
                rstruct.callset = RNACoords.applyCellSegMask(rstruct.callset, cell_mask);
            end

            rstruct.th_scan_min = 10;
            rstruct.th_scan_max = 1000;

            analysis.results_bf.(mipFieldName) = rstruct;
        else
            fprintf('\t> Big-FISH output data was not found. Skipping...\n');
        end

    end

    save(ResFilePath, 'analysis', '-v7.3');
    clear analysis
end

% ========================== Helper Functions ==========================

function pathstem = getBFStem(mytable, row_index, mipFieldName)
    pathstem = '/data/bigfish/maxproj';
    myName = getTableValue(mytable, row_index, 'IMGNAME');
    tifPath = getTableValue(mytable, row_index, 'IMAGEPATH');

    sspl = split(myName, '_');
    pieceCount = size(sspl, 1);
    groupName = sspl{1,1};
    iName = '';
    for i = 2:pieceCount-1
        if i > 2; iName = [iName '_']; end
        iName = [iName sspl{i,1}];
    end

    myTarget = getTableValue(mytable, row_index, 'TARGET');
    [~, tifName, ~] = fileparts(tifPath);

    pathstem = [pathstem '/' groupName '/' mipFieldName '/' tifName '/' myTarget '/' myName '_bf_mip'];
end

function pathstem = getHBStem(baseDir, iName, targetName, tifName, minZ, maxZ)
%     hbstem = replace(hbstem_default, 'preprocess', ['preprocess' filesep 'maxproj']);
%     hbstem = replace(hbstem, '_all_3d', '_max_proj');
% 
%     %Get group name dir
%     pparts = split(hbstem, filesep);
%     pcount = size(pparts, 1);
%     groupdir = [];
%     for i = 1:(pcount-1)
%         if strcmp(pparts{i,1}, 'maxproj')
%             groupdir = pparts{i+1,1};
%             break;
%         end
%     end

    zminstr = '1';
    if minZ > 0
        zminstr = num2str(minZ);
    end
    zmaxstr = 'Z';
    if maxZ > 0
        zmaxstr = num2str(maxZ);
    end

    pparts = split(iName, '_');
    groupDir = pparts{1,1};

    zdir = [zminstr '_' zmaxstr];
%     pathstem = replace(hbstem, groupdir, [groupdir filesep zdir]);
    pathstem = [baseDir filesep 'data' filesep 'preprocess' filesep ...
        'maxproj' filesep groupDir filesep zdir filesep tifName filesep ...
        targetName filesep iName];
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
