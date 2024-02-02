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
addpath('./test/datadump');

% ========================== Constants ==========================

START_INDEX = 1164;
END_INDEX = 1233;

INCL_LIST = [];
% INCL_LIST = [76 80 88 90 93 98 104 105 108 112 121 ...
%     124 128 129 135 178 179 187 188 209 210 211 230 ...
%     246 247 248 250 251 252 256 259 261 263 267 272];

DO_HOMEBREW = true;
DO_BIGFISH = true;
DO_RSFISH = true;
DO_DEEPBLINK = true;

DO_TRUTHSET = true;
NEW_TS_ONLY = false;

XTRIM = 4;
YTRIM = 4;
OLD_SPOTSRUN_DEF = false;

SNAPRAD_3 = 3;
SNAPRAD_Z = 2;

OutputDir = [BaseDir filesep 'data' filesep 'results'];

DEADPIX_WORKDIR = './bgh_old';

RS_TH_IVAL = 0.1/250;
SCRIPT_VER = 'v24.02.02.03';
COMPUTER_NAME = 'VU_NEUERTLAB_HOSPELB';

EXPTS_INITIALS = 'BHImaris';

% ========================== Import timestamp (for noting settings) ==========================

SCRIPT_TIMESTAMP = datetime;
TIMESTAMP_STR = sprintf('%04d%02d%02d%02d%02d%02d', SCRIPT_TIMESTAMP.Year, ...
    SCRIPT_TIMESTAMP.Month, SCRIPT_TIMESTAMP.Day,...
    SCRIPT_TIMESTAMP.Hour, SCRIPT_TIMESTAMP.Minute, round(SCRIPT_TIMESTAMP.Second));

% ========================== Load csv Table ==========================

%InputTablePath = [BaseDir filesep 'test_images_simneg.csv'];
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

for r = START_INDEX:END_INDEX

    if ~isempty(INCL_LIST)
        if ~ismember(r, INCL_LIST)
            continue;
        end
    end

    is_sim = false;
    myname = getTableValue(image_table, r, 'IMGNAME');
    fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);

    hb_stem_base = getTableValue(image_table, r, 'OUTSTEM');
    hb_stem = [BaseDir replace(hb_stem_base, '/', filesep)];
    srcpath_raw = getTableValue(image_table, r, 'IMAGEPATH');
    srcpath = [ImgDir replace(srcpath_raw, '/', filesep)];

    %Find output file
    GroupOutDir = [OutputDir filesep getSetOutputDirName(myname)];
    if ~isfolder(GroupOutDir)
        mkdir(GroupOutDir);
    end
    OutFilePath = [GroupOutDir filesep myname '_summary.mat'];
    if isfile(OutFilePath)
        load(OutFilePath, 'analysis');
    else
        analysis = struct('imgname', myname);
    end

    if ~isfield(analysis, 'import_settings')
        analysis.import_settings = struct();
    end
    import_settings = struct();
    import_settings.script_timestamp = SCRIPT_TIMESTAMP;
    import_settings.script_version = SCRIPT_VER;
    import_settings.snaprad_3 = SNAPRAD_3;
    import_settings.snaprad_z = SNAPRAD_Z;
    import_settings.xtrim = XTRIM;
    import_settings.ytrim = YTRIM;
    import_settings.rs_thresh_interval = RS_TH_IVAL;
    import_settings.computer = COMPUTER_NAME;
    import_settings.do_hb = DO_HOMEBREW;
    import_settings.do_bf = DO_BIGFISH;
    import_settings.do_rs = DO_RSFISH;
    import_settings.do_db = DO_DEEPBLINK;
    import_settings.do_refset = DO_TRUTHSET;
    import_settings.new_refset_only = NEW_TS_ONLY;
    if DO_TRUTHSET
        import_settings.exp_ts_name = EXPTS_INITIALS;
    end
    if DO_HOMEBREW
        import_settings.old_hb_spotsrun_fmt = OLD_SPOTSRUN_DEF;
    end
    import_settings.table_path = InputTablePath;
    import_settings.start_row = START_INDEX;
    import_settings.end_row = END_INDEX;
    if ~isempty(INCL_LIST)
        import_settings.include_list = INCL_LIST;
    end

    isettingsfieldname = ['run_' TIMESTAMP_STR];
    analysis.import_settings.(isettingsfieldname) = import_settings;
    clear import_settings isettingsfieldname

    %Load original image.
    if endsWith(srcpath, '.mat')
        [idir, ifname, ~] = fileparts(srcpath);
        srcpath = [idir filesep 'tif' filesep ifname '.tif'];
    end
    chcount = getTableValue(image_table, r, 'CH_TOTAL');
    trgch = getTableValue(image_table, r, 'CHANNEL');
    [channels, ~] = LoadTif(srcpath, chcount, [trgch], 1);
    my_image = channels{trgch,1};
    my_image = uint16(my_image);
    clear channels;
    X = size(my_image,2);
    Y = size(my_image,1);
    Z = size(my_image,3);
    analysis.image_dims = struct('x', X, 'y', Y, 'z', Z);

    %Find truthset...
    ts_region = [];
    ref_coords = [];
    ref_coords = loadSimTruthset(image_table, r, ImgDir);
    if isempty(ref_coords) & ~startsWith(myname, 'simneg_')
        if startsWith(myname, 'simerly_')
            ref_coords = loadSimerlyLabRefSet(image_table, r, ImgDir, analysis.image_dims);
        else
            [ref_coords, ts_region] = loadExpTruthset(image_table, r, BaseDir);
        end
    end

    if ~isempty(ts_region)
        analysis.truthset_region = ts_region;
    end

    if startsWith(myname, 'sim_') | startsWith(myname, 'simvar')
        is_sim = true;
    elseif startsWith(myname, 'rsfish_sim')
        is_sim = true;
    elseif startsWith(myname, 'simneg_')
        is_sim = true;
    end

    %--------------------------------------- Truthset
    if DO_TRUTHSET
        fprintf('> Importing truthset...\n');
        if ~isempty(ref_coords)
            %If it's a sim image, go back and find the whole key and load
            %that in.
            if startsWith(myname, 'sim_') | startsWith(myname, 'simvar')
                key = [];
                if endsWith(srcpath, '.mat')
                    %Use this one directly.
                    load(srcpath, 'key');
                    matpath = srcpath;
                elseif endsWith(srcpath, '.tif')
                    %Find mat file and load from that.
                    matpath = replace(srcpath, [filesep 'tif' filesep], filesep);
                    matpath = replace(matpath, '.tif', '.mat');
                    load(matpath, 'key');
                end
                if ~isempty(key)
                    analysis.simkey = key;
                end
                clear key;
                is_sim = true;

                %Look for simparam
                finfo = who('-file', matpath);
                if ~isempty(find(ismember(finfo, 'simparam'),1))
                    load(matpath, 'simparam');
                    analysis.simparam = simparam;
                    clear simparam;
                end

            elseif startsWith(myname, 'rsfish_sim')
                rsrefpath = replace(srcpath, '.tif', '.csv');
                is_sim = true;
                if isfile(srcpath)
                    import_table = table2array(readtable(rsrefpath,'ReadVariableNames',false));
                    import_table = import_table + 1;
                    temp = import_table(:,2);
                    import_table(:,2) = import_table(:,1);
                    import_table(:,1) = temp;
                    analysis.simkey = import_table;
                end
            else
                %Experimental
                analysis.exprefset = ref_coords;
            end
        end
    end

   
    %Some metadata
    px = getTableValue(image_table, r, 'VOXEL_X');
    py = getTableValue(image_table, r, 'VOXEL_Y');
    pz = getTableValue(image_table, r, 'VOXEL_Z');
    analysis.voxel_dims = struct('x', px, 'y', py, 'z', pz);
    px = getTableValue(image_table, r, 'POINT_X');
    py = getTableValue(image_table, r, 'POINT_Y');
    pz = getTableValue(image_table, r, 'POINT_Z');
    analysis.point_dims = struct('x', px, 'y', py, 'z', pz);
    clear px py pz

    %Take some image stats...
    analysis.imin = min(my_image, [], 'all');
    analysis.imax = max(my_image, [], 'all');
    analysis.iprctile = uint16(zeros(7,2));
    analysis.iprctile(:,1) = [50 75 80 85 90 95 99];
    analysis.iprctile(:,2) = prctile(my_image,analysis.iprctile(:,1),'all');
    top1 = find(my_image >= analysis.iprctile(7,2));
    analysis.i999 = prctile(my_image(top1),99,'all');

    if ~is_sim
        %Some more metadata
        analysis.cell_type = getTableValue(image_table, r, 'CELLTYPE');
        analysis.probe_target = getTableValue(image_table, r, 'TARGET');
        analysis.probe = getTableValue(image_table, r, 'PROBE');
        analysis.probe_target_type = getTableValue(image_table, r, 'TARGET_TYPE');
        analysis.species = getTableValue(image_table, r, 'SPECIES');
    end

    %----------------- Import cellseg mask TODO
    cellseg_dir = getTableValue(image_table, r, 'CELLSEG_DIR');
    cellseg_sfx = getTableValue(image_table, r, 'CELLSEG_SFX');

    cellmask = [];
    if ~strcmp(cellseg_dir, '.')
        cellseg_dir_actual = [BaseDir replace(cellseg_dir, '/', filesep)];
        cellseg_path = [cellseg_dir_actual filesep 'Lab_' cellseg_sfx '.mat'];
        if isfile(cellseg_path)
            load(cellseg_path, 'cells');
            cellmask = cells;
            clear cells;
        end
    end

    %--------------------------------------- Homebrew
    if DO_HOMEBREW
        fprintf('> Importing homebrew results...\n');
        %Look for run and load in coord and spot tables.
        spotsrun = RNASpotsRun.loadFrom(hb_stem);
        if ~isempty(spotsrun)
            if OLD_SPOTSRUN_DEF
                spotsrun.out_stem = hb_stem;
                gaussrad = spotsrun.dtune_gaussrad;
                t_min = spotsrun.t_min;
                t_max = spotsrun.t_max;
                [~, spot_table] = spotsrun.loadSpotsTable();
                [~, coord_table] = spotsrun.loadCoordinateTable();

                if (spotsrun.z_min_apply < 0)
                    spotsrun = spotsrun.updateZTrimParams();
                end
                z_min_apply = spotsrun.z_min_apply;
                z_max_apply = spotsrun.z_max_apply;
            else
                [spotsrun.paths.out_dir, spotsrun.paths.out_namestem] = fileparts(hb_stem);
                gaussrad = spotsrun.options.dtune_gaussrad;
                t_min = spotsrun.options.t_min;
                t_max = spotsrun.options.t_max;
                [~, spot_table] = spotsrun.loadSpotsTable();

                if (spotsrun.dims.z_min_apply < 0)
                    spotsrun = spotsrun.updateZTrimParams();
                end
                z_min_apply = spotsrun.dims.z_min_apply;
                z_max_apply = spotsrun.dims.z_max_apply;
            end

            if gaussrad < 1
                gaussrad = 7;
            end
            hb_xtrim = XTRIM;
            hb_ytrim = YTRIM;
            if gaussrad > hb_xtrim; hb_xtrim = gaussrad; end
            if gaussrad > hb_ytrim; hb_ytrim = gaussrad; end

            %Apply filter to image.
            [IMG_filtered] = RNA_Threshold_SpotDetector.run_spot_detection_pre(my_image, DEADPIX_WORKDIR, true, gaussrad, false);

            %Do table transfer
            if NEW_TS_ONLY & isfield(analysis, 'results_hb')
                call_table = analysis.results_hb.callset;
            else
                if OLD_SPOTSRUN_DEF
                    call_table = RNACoords.convertOldCoordTable(spot_table, coord_table, IMG_filtered, my_image, 2);
                else
                    [~, call_table] = spotsrun.loadCallTable();
                    call_table = RNACoords.extendHBOutputCallTable(call_table);
                end
            end
            init_call_count = size(call_table,1);

            %TF call, if applicable
            if ~isempty(ref_coords)
                %Determine minimum threhsold for snapping...
                snapminth = 25;
                if spotsrun.intensity_threshold > 0
                    if spotsrun.intensity_threshold < snapminth
                        snapminth = spotsrun.intensity_threshold;
                    end
                end
                [call_table, ref_call_map] = RNACoords.updateTFCalls(call_table, ref_coords, SNAPRAD_3, SNAPRAD_Z, 1);
                full_call_count = size(call_table, 1);

                %if fnegs were added, get the intensity values for those
                %Also need to update the 1D coords
                if full_call_count > init_call_count
                    addst = init_call_count + 1;
                    added = full_call_count;
                    x = table2array(call_table(addst:added,'isnap_x'));
                    y = table2array(call_table(addst:added,'isnap_y'));
                    z = table2array(call_table(addst:added,'isnap_z'));
                    c1d = sub2ind([Y X Z], y, x, z);
                    call_table(addst:added,'coord_1d') = array2table(uint32(c1d));
                    call_table(addst:added,'intensity_f') = array2table(single(IMG_filtered(c1d)));
                    call_table(addst:added,'intensity') = array2table(single(my_image(c1d)));

                    %Flag any fnegs that are outside detection area (trimmed
                    %out)
                    fneg_count = added - addst + 1;
                    fneg_trimmed = false(fneg_count,1);
                    fneg_trimmed = or(fneg_trimmed, x <= hb_xtrim);
                    fneg_trimmed = or(fneg_trimmed, x > (X - hb_xtrim));
                    fneg_trimmed = or(fneg_trimmed, y <= hb_ytrim);
                    fneg_trimmed = or(fneg_trimmed, y > (Y - hb_ytrim));
                    fneg_trimmed = or(fneg_trimmed, z < z_min_apply);
                    fneg_trimmed = or(fneg_trimmed, z > z_max_apply);
                    call_table(addst:added,'is_trimmed_out') = array2table(fneg_trimmed);
                    clear addst added x y z fneg_trimmed c1d
                end

                %Mask ts region (if applicable)
                if ~isempty(ts_region)
                    inside_ts_mask = true(full_call_count, 1);
                    x = table2array(call_table(:,'isnap_x'));
                    y = table2array(call_table(:,'isnap_y'));
                    z = table2array(call_table(:,'isnap_z'));

                    inside_ts_mask = and(inside_ts_mask, ~(x < ts_region.x0));
                    inside_ts_mask = and(inside_ts_mask, ~(x > ts_region.x1));
                    inside_ts_mask = and(inside_ts_mask, ~(y < ts_region.y0));
                    inside_ts_mask = and(inside_ts_mask, ~(y > ts_region.y1));
                    inside_ts_mask = and(inside_ts_mask, ~(z < ts_region.z0));
                    inside_ts_mask = and(inside_ts_mask, ~(z > ts_region.z1));
                    call_table(:,'in_truth_region') = array2table(inside_ts_mask);

                    clear x y z inside_ts_mask
                else
                    %All inside.
                    call_table{:,'in_truth_region'} = true;
                end

            end

            if startsWith(myname, 'simneg_')
                %No truthset. Everything is a false positive.
                call_table{:,'in_truth_region'} = true;
                call_table{:,'is_trimmed_out'} = false;
                call_table{:,'is_true'} = false;
            end
            
            %TODO Fit matching, if applicable

            %Cell mask
            if ~isempty(cellmask)
                call_table = RNACoords.applyCellSegMask(call_table, cellmask);
            end

            %Save updated results
            if ~isfield(analysis, 'results_hb')
                analysis.results_hb = struct('callset', table.empty());
            end
            analysis.results_hb.timestamp = datetime;
            analysis.results_hb.import_computer = COMPUTER_NAME;
            analysis.results_hb.callset = call_table;
            analysis.results_hb.threshold = spotsrun.intensity_threshold;
            analysis.results_hb.threshold_details = spotsrun.threshold_results;
            analysis.results_hb.gaussrad_xy = gaussrad;
            analysis.results_hb.x_min = hb_xtrim + 1;
            analysis.results_hb.x_max = X - hb_xtrim;
            analysis.results_hb.y_min = hb_ytrim + 1;
            analysis.results_hb.y_max = Y - hb_ytrim;

            analysis.results_hb.z_min = z_min_apply;
            analysis.results_hb.z_max = z_max_apply;
            analysis.results_hb.th_scan_min = t_min;
            analysis.results_hb.th_scan_max = t_max;

            if ~isempty(IMG_filtered)
                %Take some filtered image stats.
                x0 = analysis.results_hb.x_min; x1 = analysis.results_hb.x_max;
                y0 = analysis.results_hb.y_min; y1 = analysis.results_hb.y_max;
                z0 = analysis.results_hb.z_min; z1 = analysis.results_hb.z_max;
                used_x = x1 - x0 + 1;
                used_y = y1 - y0 + 1;
                used_z = z1 - z0 + 1;

                imgf_trimmed = IMG_filtered(y0:y1,x0:x1,z0:z1);
                analysis.results_hb.fvoxels_incl = used_x * used_y * used_z;
                analysis.results_hb.fvoxels_nz = nnz(imgf_trimmed);
                analysis.results_hb.fprop_nz = analysis.results_hb.fvoxels_nz/analysis.results_hb.fvoxels_incl;

                analysis.results_hb.imin_f = min(imgf_trimmed, [], 'all');
                analysis.results_hb.imax_f = max(imgf_trimmed, [], 'all');
                analysis.results_hb.iprctile_f = uint16(zeros(7,2));
                analysis.results_hb.iprctile_f(:,1) = [50 75 80 85 90 95 99];
                analysis.results_hb.iprctile_f(:,2) = uint16(prctile(imgf_trimmed,analysis.results_hb.iprctile_f(:,1),'all'));
                top1 = find(imgf_trimmed >= analysis.results_hb.iprctile_f(7,2));
                analysis.results_hb.i999_f = prctile(imgf_trimmed(top1),99,'all');
                clear imgf_trimmed x0 x1 y0 y1 z0 z1 used_z used_y used_z
            end

            analysis.results_hb = applyTrimToCalls(analysis.results_hb, analysis.image_dims);
            if ~isempty(ref_coords)
                %Calculate performance metrics
                analysis.results_hb = runstats(analysis.results_hb, spot_table, spotsrun.intensity_threshold);
                analysis.results_hb.ref_call_map = ref_call_map;
            elseif startsWith(myname, 'simneg_')
                analysis.results_hb = runstats(analysis.results_hb, spot_table, spotsrun.intensity_threshold);
            end

            if ~is_sim & ~isempty(ref_coords) & ~isempty(EXPTS_INITIALS)
                analysis.results_hb = markTSStats(analysis.results_hb, EXPTS_INITIALS);
            end
            clear z_min_apply z_max_apply
            clear call_table coord_table spot_table IMG_filtered gaussrad ref_call_map hb_xtrim hb_ytrim t_min t_max;
        else
            fprintf('ERROR: Could not find HB run for %s!\n', myname);
        end
        clear spotsrun;
    end

    %--------------------------------------- BigFISH
    if DO_BIGFISH
        fprintf('> Importing BigFISH results...\n');
        bf_stem_base = replace(getTableValue(image_table, r, 'BIGFISH_OUTSTEM'), '/bigfish/', '/bigfish/_rescaled/');
        bf_stem = [BaseDir replace(bf_stem_base, '/', filesep)];

        bf_ct_path = [bf_stem '_coordTable.mat'];
        if isfile(bf_ct_path)
            [bf_dir, ~, ~] = fileparts(bf_stem);
            summary_path = [bf_dir filesep 'summary.txt'];
            bf_st_path = [bf_stem '_spotTable.mat'];

            load(bf_ct_path, 'coord_table');
            load(bf_st_path, 'spot_table');
            [zmin, zmax, bfthresh] = BigfishCompare.readSummaryTxt(summary_path);

            if NEW_TS_ONLY & isfield(analysis, 'results_bf')
                call_table = analysis.results_bf.callset;
            else
                call_table = RNACoords.convertOldCoordTable(spot_table, coord_table, [], my_image, 1);
            end
            init_call_count = size(call_table,1);

            if ~isempty(ref_coords)
                snapminth = 25;
                if bfthresh > 0
                    if bfthresh < snapminth
                        snapminth = bfthresh;
                    end
                end
                [call_table, ref_call_map] = RNACoords.updateTFCalls(call_table, ref_coords, SNAPRAD_3, SNAPRAD_Z, 1);
                full_call_count = size(call_table, 1);

                if full_call_count > init_call_count
                    addst = init_call_count + 1;
                    added = full_call_count;
                    x = table2array(call_table(addst:added,'isnap_x'));
                    y = table2array(call_table(addst:added,'isnap_y'));
                    z = table2array(call_table(addst:added,'isnap_z'));
                    c1d = sub2ind([Y X Z], y, x, z);
                    call_table(addst:added,'coord_1d') = array2table(uint32(c1d));
                    call_table(addst:added,'intensity') = array2table(single(my_image(c1d)));

                    %Flag any fnegs that are outside detection area (trimmed
                    %out)
                    fneg_count = added - addst + 1;
                    fneg_trimmed = false(fneg_count,1);
                    fneg_trimmed = or(fneg_trimmed, z < zmin);
                    fneg_trimmed = or(fneg_trimmed, z > zmax);
                    call_table(addst:added,'is_trimmed_out') = array2table(fneg_trimmed);
                    clear addst added x y z fneg_trimmed c1d
                end

                %Mask ts region (if applicable)
                if ~isempty(ts_region)
                    inside_ts_mask = true(full_call_count, 1);
                    x = table2array(call_table(:,'isnap_x'));
                    y = table2array(call_table(:,'isnap_y'));
                    z = table2array(call_table(:,'isnap_z'));

                    inside_ts_mask = and(inside_ts_mask, ~(x < ts_region.x0));
                    inside_ts_mask = and(inside_ts_mask, ~(x > ts_region.x1));
                    inside_ts_mask = and(inside_ts_mask, ~(y < ts_region.y0));
                    inside_ts_mask = and(inside_ts_mask, ~(y > ts_region.y1));
                    inside_ts_mask = and(inside_ts_mask, ~(z < ts_region.z0));
                    inside_ts_mask = and(inside_ts_mask, ~(z > ts_region.z1));
                    call_table(:,'in_truth_region') = array2table(inside_ts_mask);

                    clear x y z inside_ts_mask
                else
                    %All inside.
                    call_table{:,'in_truth_region'} = true;
                end
            end

            if startsWith(myname, 'simneg_')
                %No truthset. Everything is a false positive.
                call_table{:,'in_truth_region'} = true;
                call_table{:,'is_trimmed_out'} = false;
                call_table{:,'is_true'} = false;
            end

            %Fit matching
            fit_table_path = [bf_dir filesep 'fitspots.csv'];
            if ~NEW_TS_ONLY
                if isfile(fit_table_path)
                    import_table = readtable(fit_table_path,'Delimiter',',',...
                        'ReadVariableNames',true,'Format','%f%f%f');
                    import_mtx = table2array(import_table);

                    %since it is zyx, swap columns 1 and 3
                    temp = import_mtx(:,1);
                    import_mtx(:,1) = import_mtx(:,3);
                    import_mtx(:,3) = temp;
                    clear temp

                    %Let's also adjust to 1-based coords...
                    import_mtx = import_mtx + 1;

                    call_table = RNACoords.addFitData(call_table, import_mtx, bfthresh);
                    clear import_table import_mtx

                    if ~isempty(ref_coords)
                        call_table = RNACoords.updateRefDistancesToUseFits(call_table, ref_coords, ref_call_map);
                    end
                end

                if ~isempty(cellmask)
                    call_table = RNACoords.applyCellSegMask(call_table, cellmask);
                end
            end

            if ~isfield(analysis, 'results_bf')
                analysis.results_bf = struct('callset', table.empty());
            end
            analysis.results_bf.timestamp = datetime;
            analysis.results_bf.import_computer = COMPUTER_NAME;
            analysis.results_bf.callset = call_table;
            analysis.results_bf.threshold = bfthresh;

            analysis.results_bf.x_min = XTRIM + 1;
            analysis.results_bf.x_max = X - XTRIM;
            analysis.results_bf.y_min = YTRIM + 1;
            analysis.results_bf.y_max = Y - YTRIM;
            analysis.results_bf.z_min = zmin;
            analysis.results_bf.z_max = zmax;
            analysis.results_bf = applyTrimToCalls(analysis.results_bf, analysis.image_dims);

            if ~isempty(ref_coords)
                %Calculate performance metrics
                analysis.results_bf = runstats(analysis.results_bf, spot_table, bfthresh);
                analysis.results_bf.ref_call_map = ref_call_map;
            elseif startsWith(myname, 'simneg_')
                analysis.results_bf = runstats(analysis.results_bf, spot_table, bfthresh);
            end
            if ~is_sim & ~isempty(ref_coords) & ~isempty(EXPTS_INITIALS)
                analysis.results_bf = markTSStats(analysis.results_bf, EXPTS_INITIALS);
            end
            clear call_table coord_table spot_table zmin zmax bfthresh ref_call_map;
        end
    end

    %--------------------------------------- RSFISH
    rsdb_dir_ext = getRSDBGroupOutputDir(myname);
    if DO_RSFISH
        fprintf('> Importing RS-FISH results...\n');
        if ~isempty(rsdb_dir_ext)
            rs_stem = [BaseDir filesep 'data' filesep 'rsfish' rsdb_dir_ext myname filesep 'RSFISH_' myname];
            [rs_dir, ~, ~] = fileparts(rs_stem);
            coord_table_path = [rs_stem '_coordTable.mat'];
            spot_table_path = [rs_stem '_spotTable.mat'];

            if isfile(coord_table_path)
                load(coord_table_path, 'coord_table');
                load(spot_table_path, 'spot_table');

                spot_table(:,1) = spot_table(:,1) .* RS_TH_IVAL;

                fit_table_path = [rs_stem '_fitTable.mat'];
                if NEW_TS_ONLY & isfield(analysis, 'results_rs')
                    call_table = analysis.results_rs.callset;
                    init_call_count = size(call_table,1);
                else
                    call_table = RNACoords.convertOldCoordTable(spot_table, coord_table, [], my_image, 1);
                    init_call_count = size(call_table,1);

                    %Fit matching
                    if isfile(fit_table_path)
                        load(fit_table_path, 'fit_table');
                        ftbl = fit_table{1,1};
                        clear fit_table;

                        call_table = RNACoords.addFitData(call_table, ftbl);
                        clear ftbl
                    end
                end
                
                if ~isempty(ref_coords)
                    [call_table, ref_call_map] = RNACoords.updateTFCalls(call_table, ref_coords, SNAPRAD_3, SNAPRAD_Z, RS_TH_IVAL);
                    full_call_count = size(call_table, 1);

                    if full_call_count > init_call_count
                        addst = init_call_count + 1;
                        added = full_call_count;
                        x = table2array(call_table(addst:added,'isnap_x'));
                        y = table2array(call_table(addst:added,'isnap_y'));
                        z = table2array(call_table(addst:added,'isnap_z'));
                        c1d = sub2ind([Y X Z], y, x, z);
                        call_table(addst:added,'coord_1d') = array2table(uint32(c1d));
                        call_table(addst:added,'intensity') = array2table(single(my_image(c1d)));

                        clear addst added x y z c1d
                    end

                    %Mask ts region (if applicable)
                    if ~isempty(ts_region)
                        inside_ts_mask = true(full_call_count, 1);
                        x = table2array(call_table(:,'isnap_x'));
                        y = table2array(call_table(:,'isnap_y'));
                        z = table2array(call_table(:,'isnap_z'));

                        inside_ts_mask = and(inside_ts_mask, ~(x < ts_region.x0));
                        inside_ts_mask = and(inside_ts_mask, ~(x > ts_region.x1));
                        inside_ts_mask = and(inside_ts_mask, ~(y < ts_region.y0));
                        inside_ts_mask = and(inside_ts_mask, ~(y > ts_region.y1));
                        inside_ts_mask = and(inside_ts_mask, ~(z < ts_region.z0));
                        inside_ts_mask = and(inside_ts_mask, ~(z > ts_region.z1));
                        call_table(:,'in_truth_region') = array2table(inside_ts_mask);

                        clear x y z inside_ts_mask
                    else
                        %All inside.
                        call_table{:,'in_truth_region'} = true;
                    end

                    if isfile(fit_table_path)
                        call_table = RNACoords.updateRefDistancesToUseFits(call_table, ref_coords, ref_call_map);
                    end
                end

                if startsWith(myname, 'simneg_')
                    %No truthset. Everything is a false positive.
                    call_table{:,'in_truth_region'} = true;
                    call_table{:,'is_trimmed_out'} = false;
                    call_table{:,'is_true'} = false;
                end

                if ~isempty(cellmask)
                    call_table = RNACoords.applyCellSegMask(call_table, cellmask);
                end
            
                if ~isfield(analysis, 'results_rs')
                    analysis.results_rs = struct('callset', table.empty());
                end
                analysis.results_rs.timestamp = datetime;
                analysis.results_rs.import_computer = COMPUTER_NAME;
                analysis.results_rs.callset = call_table;

                analysis.results_rs.x_min = XTRIM + 1;
                analysis.results_rs.x_max = X - XTRIM;
                analysis.results_rs.y_min = YTRIM + 1;
                analysis.results_rs.y_max = Y - YTRIM;
                analysis.results_rs = applyTrimToCalls(analysis.results_rs, analysis.image_dims);

                if ~isempty(ref_coords)
                    %Calculate performance metrics
                    analysis.results_rs = runstats(analysis.results_rs, spot_table, 0);
                    analysis.results_rs.ref_call_map = ref_call_map;
                elseif startsWith(myname, 'simneg_')
                    analysis.results_rs = runstats(analysis.results_rs, spot_table, 0);
                end

                %If experimental TS, mark ts fields
                if ~is_sim & ~isempty(ref_coords) & ~isempty(EXPTS_INITIALS)
                    analysis.results_rs = markTSStats(analysis.results_rs, EXPTS_INITIALS);
                end

            else
                fprintf('ERROR: Could not find RSFISH run for %s!\n', myname);
            end
            clear coord_table_path spot_table_path coord_table spot_table ref_call_map
        end
    end

    %--------------------------------------- DeepBlink
    if DO_DEEPBLINK
        if ~isempty(rsdb_dir_ext)
            fprintf('> Importing DeepBlink results...\n');
            db_stem = [BaseDir filesep 'data' filesep 'deepblink' rsdb_dir_ext myname filesep 'DeepBlink_' myname];
            [db_dir, ~, ~] = fileparts(db_stem);
            coord_table_path = [db_stem '_coordTable.mat'];
            spot_table_path = [db_stem '_spotTable.mat'];

            if isfile(coord_table_path)
                load(coord_table_path, 'coord_table');
                load(spot_table_path, 'spot_table');
                if NEW_TS_ONLY & isfield(analysis, 'results_db')
                    call_table = analysis.results_db.callset;
                    call_table_raw = analysis.results_db.callset_sliced;
                    callmap = analysis.results_db.callmap_slice_merge;
                else
                    call_table_raw = RNACoords.convertOldCoordTable(spot_table, coord_table, [], my_image, 1);
                    if ~isempty(cellmask)
                        call_table_raw = RNACoords.applyCellSegMask(call_table_raw, cellmask);
                    end

                    %Import Fit (BEFORE merge!)
                    fit_table_path = findDBFitTable(db_dir, myname);
                    if ~isempty(fit_table_path) & isfile(fit_table_path)
                        import_table = readtable(fit_table_path,'Delimiter',',','ReadVariableNames',true,'Format',...
                            '%f%f%f%f');
                        import_mtx = table2array(import_table);
                        import_count = size(import_mtx,1);
                        fit_table = NaN(import_count,3);
                        fit_table(:,1:3) = import_mtx(:,[1 2 4]) + 1;
                        call_table_raw = RNACoords.addFitData(call_table_raw, fit_table);

                        clear import_table import_mtx fit_table import_count
                    end

                    %Merge slice calls for better truthset comparison
                    [call_table, callmap] = RNACoords.mergeSlicedSetTo3D(call_table_raw, 4, 0.5);
                end
                init_call_count = size(call_table,1);

                if ~isempty(ref_coords)
                    [call_table, ref_call_map] = RNACoords.updateTFCalls(call_table, ref_coords, SNAPRAD_3, SNAPRAD_Z, 0.001);
                    full_call_count = size(call_table, 1);

                    if full_call_count > init_call_count
                        %Fnegs added.
                        addst = init_call_count + 1;
                        added = full_call_count;
                        x = table2array(call_table(addst:added,'isnap_x'));
                        y = table2array(call_table(addst:added,'isnap_y'));
                        z = table2array(call_table(addst:added,'isnap_z'));
                        c1d = sub2ind([Y X Z], y, x, z);
                        call_table(addst:added,'coord_1d') = array2table(uint32(c1d));
                        call_table(addst:added,'intensity') = array2table(single(my_image(c1d)));

                        clear addst added x y z c1d
                    end

                    %Mask ts region (if applicable)
                    if ~isempty(ts_region)
                        inside_ts_mask = true(full_call_count, 1);
                        x = table2array(call_table(:,'isnap_x'));
                        y = table2array(call_table(:,'isnap_y'));
                        z = table2array(call_table(:,'isnap_z'));

                        inside_ts_mask = and(inside_ts_mask, ~(x < ts_region.x0));
                        inside_ts_mask = and(inside_ts_mask, ~(x > ts_region.x1));
                        inside_ts_mask = and(inside_ts_mask, ~(y < ts_region.y0));
                        inside_ts_mask = and(inside_ts_mask, ~(y > ts_region.y1));
                        inside_ts_mask = and(inside_ts_mask, ~(z < ts_region.z0));
                        inside_ts_mask = and(inside_ts_mask, ~(z > ts_region.z1));
                        call_table(:,'in_truth_region') = array2table(inside_ts_mask);

                        clear x y z inside_ts_mask
                    else
                        %All inside.
                        call_table{:,'in_truth_region'} = true;
                    end

                    if isfile(fit_table_path)
                        call_table = RNACoords.updateRefDistancesToUseFits(call_table, ref_coords, ref_call_map);
                    end
                end

                if startsWith(myname, 'simneg_')
                    %No truthset. Everything is a false positive.
                    call_table{:,'in_truth_region'} = true;
                    call_table{:,'is_trimmed_out'} = false;
                    call_table{:,'is_true'} = false;
                end

                %Save
                if ~isfield(analysis, 'results_db')
                    analysis.results_db = struct('callset', table.empty());
                end
                analysis.results_db.timestamp = datetime;
                analysis.results_db.import_computer = COMPUTER_NAME;
                analysis.results_db.callset = call_table;
                analysis.results_db.callset_sliced = call_table_raw;
                analysis.results_db.callmap_slice_merge = callmap;

                analysis.results_db.x_min = XTRIM + 1;
                analysis.results_db.x_max = X - XTRIM;
                analysis.results_db.y_min = YTRIM + 1;
                analysis.results_db.y_max = Y - YTRIM;
                analysis.results_db = applyTrimToCalls(analysis.results_db, analysis.image_dims);

                if ~isempty(ref_coords)
                    %Calculate performance metrics
                    analysis.results_db = runstats(analysis.results_db, spot_table, 0);
                    analysis.results_db.ref_call_map = ref_call_map;
                elseif startsWith(myname, 'simneg_')
                    analysis.results_db = runstats(analysis.results_db, spot_table, 0);
                end

                clear call_table call_table_raw callmap ref_call_map

                %If experimental TS, mark ts fields
                if ~is_sim & ~isempty(ref_coords) & ~isempty(EXPTS_INITIALS)
                    analysis.results_db = markTSStats(analysis.results_db, EXPTS_INITIALS);
                end
            else
                fprintf('ERROR: Could not find DeepBlink run for %s!\n', myname);
            end
            clear coord_table_path spot_table_path coord_table spot_table
        end
    end

    %--------------------------------------- Tag exp ts data outside result
    %structs
    % (the ts itself and the mask)
    if ~is_sim & ~isempty(ref_coords) & ~isempty(EXPTS_INITIALS)
        analysis.last_ts = EXPTS_INITIALS;
        substruct_name = ['truthset_' EXPTS_INITIALS];
        if ~isfield(analysis, substruct_name)
            analysis.(substruct_name) = struct('timestamp', datetime);
        else
            analysis.(substruct_name).timestamp = datetime;
        end

        if isfield(analysis, 'exprefset')
            analysis.(substruct_name).exprefset = analysis.exprefset;
        end
        if isfield(analysis, 'truthset_region')
            analysis.(substruct_name).truthset_region = analysis.truthset_region;
        end
    end

    %--------------------------------------- Save
    fprintf('> Saving updated analysis...\n');
    save(OutFilePath, 'analysis', '-v7.3');
    clear analysis;
end

% ========================== Helper functions ==========================

function outdir = getRSDBGroupOutputDir(imgname)
    outdir = [];
    if isempty(imgname); return; end

    if startsWith(imgname, 'mESC4d_')
        outdir = [filesep 'mESC4d' filesep];
    elseif startsWith(imgname, 'scrna_')
        outdir = [filesep 'scrna' filesep];
    elseif startsWith(imgname, 'mESC_loday_')
        outdir = [filesep 'mESC_loday' filesep];
    elseif startsWith(imgname, 'scprotein_')
        outdir = [filesep 'scprotein' filesep];
    elseif startsWith(imgname, 'sim_')
        outdir = [filesep 'sim' filesep];
    elseif startsWith(imgname, 'histonesc_')
        outdir = [filesep 'histonesc' filesep];
    elseif startsWith(imgname, 'ROI0')
        outdir = [filesep 'munsky_lab' filesep];
    elseif startsWith(imgname, 'sctc_')
        inparts = split(imgname, '_');
        ch = 'CH1';
        if endsWith(imgname, 'CTT1')
            ch = 'CH2';
        end
        outdir = [filesep 'yeast_tc' filesep inparts{2,1} filesep ch filesep];
    elseif startsWith(imgname, 'rsfish_')
        outdir = [filesep 'rsfish' filesep];
    elseif startsWith(imgname, 'simvar_')
        outdir = [filesep 'simvar' filesep];
    elseif startsWith(imgname, 'simneg_')
        outdir = [filesep 'simneg' filesep];
    elseif startsWith(imgname, 'simerly_')
        outdir = [filesep 'simerly_lab' filesep];
    elseif startsWith(imgname, 'simvarmass_')
        if contains(imgname, 'TMRL') | contains(imgname, 'CY5L')
            outdir = [filesep 'simytc' filesep];
        else
            outdir = [filesep 'simvarmass' filesep];
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
    elseif strcmp(groupname, 'simerly')
        dirname = 'simerly_lab';
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

function fit_table_path = findDBFitTable(db_dir, image_name)
    fit_table_path = [db_dir filesep image_name];
    if ~isfile(fit_table_path)
        %Find another csv in that dir
        dir_contents = dir(db_dir);

        content_count = size(dir_contents,1);
        for i = 1:content_count
            if endsWith(dir_contents(i,1).name, '.csv')
                fit_table_path = [db_dir filesep dir_contents(i,1).name];
                break;
            end
        end
    end
end

function key_mtx = keyStructs2Mtx(my_key)
    ptcount = size(my_key,2);
    key_mtx = uint16(zeros(ptcount,3));
    key_mtx(:,1) = [my_key.x];
    key_mtx(:,2) = [my_key.y];
    key_mtx(:,3) = [my_key.z];
end

function ref_coords = loadSimTruthsetRS(image_table, row_index, ImgDir)
    myname = getTableValue(image_table, row_index, 'IMGNAME');
    srcpath_raw = getTableValue(image_table, row_index, 'IMAGEPATH');
    
    %I had to convert the locs to csv because MATLAB is a fussbudget
    srcpath = [ImgDir replace(srcpath_raw, '/', filesep)];
    srcpath = replace(srcpath, '.tif', '.csv');
    
    ref_coords = [];
    if ~isfile(srcpath)
        fprintf('ERROR: Could not find sim truthset for %s!\n', myname);
        return;
    end
    
    import_table = table2array(readtable(srcpath,'ReadVariableNames',false));
    %import_table = import_table + 1; %Not needed.
    temp = import_table(:,2);
    import_table(:,2) = import_table(:,1);
    import_table(:,1) = temp;
    
    %Swap out refset and save
    ref_coords = import_table(:,1:3);
end

function ref_coords = loadSimTruthsetSF(image_table, row_index, ImgDir)
    %For simfish sims
    myname = getTableValue(image_table, row_index, 'IMGNAME');
    srcpath_raw = getTableValue(image_table, row_index, 'IMAGEPATH');
    
    srcpath = [ImgDir replace(srcpath_raw, '/', filesep)];
    
    key = [];
    if endsWith(srcpath, '.mat')
        %Use this one directly.
        load(srcpath, 'key');
    elseif endsWith(srcpath, '.tif')
        %Find mat file and load from that.
        srcpath = replace(srcpath, [filesep 'tif' filesep], filesep);
        srcpath = replace(srcpath, '.tif', '.mat');
        load(srcpath, 'key');
    end
    
    if isempty(key)
        fprintf('ERROR: Could not load sim truthset for %s!\n', myname);
        return; 
    end

    ref_coords = keyStructs2Mtx(key); %Importer already adjusts to 1 based coords.

end

function ref_coords = loadSimTruthset(image_table, row_index, ImgDir)
    ref_coords = [];
    myname = getTableValue(image_table, row_index, 'IMGNAME');
    if startsWith(myname, 'sim_')
        ref_coords = loadSimTruthsetSF(image_table, row_index, ImgDir);
    elseif startsWith(myname, 'simvar')
        ref_coords = loadSimTruthsetSF(image_table, row_index, ImgDir);
    elseif startsWith(myname, 'rsfish_sim')
        ref_coords = loadSimTruthsetRS(image_table, row_index, ImgDir);
    end
end

function ref_coords = loadSimerlyLabRefSet(image_table, row_index, ImgDir, image_dims)
    myname = getTableValue(image_table, row_index, 'IMGNAME');
    srcpath_raw = getTableValue(image_table, row_index, 'IMAGEPATH');
    srcpath = [ImgDir replace(srcpath_raw, '/', filesep)];

    tabledir = [ImgDir filesep 'img' filesep 'simerly_lab' filesep 'ImarisSets'];
    [~,tifname,~] = fileparts(srcpath);
    tifnameparts = split(tifname, '-');
    tifname = tifnameparts{1,1};
    ref_coords = [];

    %Check for directory
    tabledir = [tabledir filesep tifname '_Statistics'];
    if isfolder(tabledir)
        probename = getTableValue(image_table, row_index, 'PROBE');
        tabledir = [tabledir filesep probename];
        if isfolder(tabledir)
            tablepath = [tabledir filesep tifname '_Position.csv'];
            if isfile(tablepath)
                fprintf('\t> Imaris set for %s (%s) found!\n', myname, tifname);

                %Need voxel dims to convert to pix from um
                px = double(getTableValue(image_table, row_index, 'VOXEL_X'));
                py = double(getTableValue(image_table, row_index, 'VOXEL_Y'));
                pz = double(getTableValue(image_table, row_index, 'VOXEL_Z'));

                rawtable = readtable(tablepath);
                spotcount = size(rawtable, 1);
                ref_coords = NaN(spotcount, 3);

                %Convert to nm, then to pixels
                ref_coords(:,1) = (rawtable{:,'PositionX'} .* 1000.0) ./ px;
                ref_coords(:,2) = (rawtable{:,'PositionY'} .* 1000.0) ./ py;
                ref_coords(:,3) = (rawtable{:,'PositionZ'} .* 1000.0) ./ pz;

                %Shift to 1-based coords and clamp
                ref_coords = ref_coords + 0.5;
                ref_coords = max(ref_coords, 1);

                ref_coords(:,1) = min(ref_coords(:,1), image_dims.x);
                ref_coords(:,2) = min(ref_coords(:,2), image_dims.y);
                ref_coords(:,3) = min(ref_coords(:,3), image_dims.z);
            end
        end
    end
 
end

function [ref_coords, valid_range] = loadExpTruthset(image_table, row_index, BaseDir)
    ref_coords = [];
    valid_range = struct('x0', 0, 'x1', 0, 'y0', 0, 'y1', 0, 'z0', 0, 'z1', 0);
    
    hb_stem_base = getTableValue(image_table, row_index, 'OUTSTEM');
    hb_stem = [BaseDir replace(hb_stem_base, '/', filesep)];

    if RNA_Threshold_SpotSelector.refsetExists(hb_stem)
        spotanno = RNA_Threshold_SpotSelector.openSelector(hb_stem, true);
        ref_coords = spotanno.ref_coords;
        valid_range.z0 = spotanno.z_min;
        valid_range.z1 = spotanno.z_max;
        if ~isempty(spotanno.selmcoords)
            valid_range.x0 = spotanno.selmcoords(1,1);
            valid_range.x1 = spotanno.selmcoords(2,1);
            valid_range.y0 = spotanno.selmcoords(3,1);
            valid_range.y1 = spotanno.selmcoords(4,1);
        else
            valid_range.x0 = 1;
            valid_range.y0 = 1;
            valid_range.x1 = getTableValue(image_table, row_index, 'IDIM_X');
            valid_range.y1 = getTableValue(image_table, row_index, 'IDIM_Y');
        end
        clear spotanno;
    end

end

function rstruct = markTSStats(rstruct, tag)
    if isempty(tag); return; end

    substruct_name = ['truthset_' tag];
    if ~isfield(rstruct, substruct_name)
        rstruct.(substruct_name) = struct('timestamp', datetime);
    else
        rstruct.(substruct_name).timestamp = datetime;
    end

    if isfield(rstruct, 'callset')
        %Need to move over 'is_true' and 'in_truth_region'
        targcol_name = ['is_true_' tag];
        newcol_A = renamevars(rstruct.callset(:,'is_true'), 'is_true', targcol_name);
        targcol_name = ['in_truth_region_' tag];
        newcol_B = renamevars(rstruct.callset(:,'in_truth_region'), 'in_truth_region', targcol_name);
        rstruct.callset = [rstruct.callset newcol_A newcol_B];
        rstruct.callset{:,'is_true'} = false;
        rstruct.callset{:,'in_truth_region'} = false;
    end
    if isfield(rstruct, 'callset_sliced')
        %DB only
        targcol_name = ['is_true_' tag];
        newcol_A = renamevars(rstruct.callset_sliced(:,'is_true'), 'is_true', targcol_name);
        targcol_name = ['in_truth_region_' tag];
        newcol_B = renamevars(rstruct.callset_sliced(:,'in_truth_region'), 'in_truth_region', targcol_name);
        rstruct.callset_sliced = [rstruct.callset_sliced newcol_A newcol_B];
        rstruct.callset_sliced{:,'is_true'} = false;
        rstruct.callset_sliced{:,'in_truth_region'} = false;
    end
    if isfield(rstruct, 'ref_call_map')
        rstruct.(substruct_name).ref_call_map = rstruct.ref_call_map;
    end
    if isfield(rstruct, 'performance')
        rstruct.(substruct_name).performance = rstruct.performance;
        rstruct.(substruct_name).pr_auc = rstruct.pr_auc;
        rstruct.(substruct_name).fscore_peak = rstruct.fscore_peak;
        if isfield(rstruct, 'fscore_autoth')
            rstruct.(substruct_name).fscore_autoth = rstruct.fscore_autoth;
        end
    end
    if isfield(rstruct, 'performance_trimmed')
        rstruct.(substruct_name).performance_trimmed = rstruct.performance_trimmed;
        rstruct.(substruct_name).pr_auc_trimmed = rstruct.pr_auc_trimmed;
        rstruct.(substruct_name).fscore_peak_trimmed = rstruct.fscore_peak_trimmed;
        if isfield(rstruct, 'fscore_autoth_trimmed')
            rstruct.(substruct_name).fscore_autoth_trimmed = rstruct.fscore_autoth_trimmed;
        end
    end
    rstruct.last_ts = tag;

end

function rstruct = applyTrimToCalls(rstruct, dims)
    X = dims.x;
    Y = dims.y;
    Z = dims.z;

    x_min = 1;
    x_max = X;
    if isfield(rstruct, 'x_min')
        x_min = rstruct.x_min;
    end
    if isfield(rstruct, 'x_max')
        x_max = rstruct.x_max;
    end

    y_min = 1;
    y_max = Y;
    if isfield(rstruct, 'y_min')
        y_min = rstruct.y_min;
    end
    if isfield(rstruct, 'y_max')
        y_max = rstruct.y_max;
    end

    xx = rstruct.callset{:,'isnap_x'};
    x_pass = and(xx >= x_min, xx <= x_max);
    yy = rstruct.callset{:,'isnap_y'};
    y_pass = and(yy >= y_min, yy <= y_max);

    z_min = 1;
    z_max = Z;
    if isfield(rstruct, 'z_min')
        z_min = rstruct.z_min;
    end
    if isfield(rstruct, 'z_max')
        z_max = rstruct.z_max;
    end

    zz = rstruct.callset{:,'isnap_z'};
    z_pass = and(zz >= z_min, zz <= z_max);
    all_pass = and(x_pass, y_pass);
    all_pass = and(all_pass, z_pass);

    rstruct.callset{:,'is_trimmed_out'} = ~all_pass;
end

function rstruct = runstats(rstruct, spot_table, th_val)

    if nargin < 3; th_val = 0; end

    call_table = rstruct.callset;
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
        if isfield(rstruct, 'performance_trimmed')
            rstruct = rmfield(rstruct, 'performance_trimmed');
        end
        if isfield(rstruct, 'pr_auc_trimmed')
            rstruct = rmfield(rstruct, 'pr_auc_trimmed');
        end
        if isfield(rstruct, 'fscore_peak_trimmed')
            rstruct = rmfield(rstruct, 'fscore_peak_trimmed');
        end
        if isfield(rstruct, 'fscore_autoth_trimmed')
            rstruct = rmfield(rstruct, 'fscore_autoth_trimmed');
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

    th_idx = 0;
    if th_val > 0
        th_idx = RNAUtils.findThresholdIndex(th_val, spot_table(:,1).');
    end

    %Save to output struct
    rstruct.performance = res_untrimmed;
    rstruct.pr_auc = pr_auc;
    rstruct.fscore_peak = peak_fscore;
    if th_idx > 0
        rstruct.fscore_autoth = res_untrimmed{th_idx, 'fScore'};
    end
    if any_trimmed
        rstruct.performance_trimmed = res_trimmed;
        rstruct.pr_auc_trimmed = pr_auc_trim;
        rstruct.fscore_peak_trimmed = peak_fscore_trim;
        if th_idx > 0
            rstruct.fscore_autoth_trimmed = res_trimmed{th_idx, 'fScore'};
        end
    end

    rstruct.timestamp = datetime();

end

function rstruct = runstats_old(rstruct, spot_table, th_val)

    if nargin < 3; th_val = 0; end

    call_table = rstruct.callset;
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

    th_idx = 0;
    if th_val > 0
        th_idx = RNAUtils.findThresholdIndex(th_val, spot_table(:,1).');
    end

    %Save to output struct
    rstruct.performance = res_untrimmed;
    rstruct.pr_auc = pr_auc;
    rstruct.fscore_peak = peak_fscore;
    if th_idx > 0
        rstruct.fscore_autoth = res_untrimmed{th_idx, 'fScore'};
    end
    if any_trimmed
        rstruct.performance_trimmed = res_trimmed;
        rstruct.pr_auc_trimmed = pr_auc_trim;
        rstruct.fscore_peak_trimmed = peak_fscore_trim;
        if th_idx > 0
            rstruct.fscore_autoth_trimmed = res_trimmed{th_idx, 'fScore'};
        end
    end

end
