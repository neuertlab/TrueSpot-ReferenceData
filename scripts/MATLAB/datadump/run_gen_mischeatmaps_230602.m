%
%%  !! UPDATE TO YOUR BASE DIR
%BaseDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
BaseDir = 'D:\usr\bghos\labdat\imgproc';

%ImgProcDir = 'D:\Users\hospelb\labdata\imgproc';
ImgProcDir = 'D:\usr\bghos\labdat\imgproc';

%ImgDir = 'C:\Users\hospelb\labdata\imgproc';
ImgDir = 'D:\usr\bghos\labdat\imgproc';

ResultsDir = [BaseDir filesep 'data' filesep 'results'];

addpath('./core');
addpath('./test');

% ========================== Constants ==========================

DateDir = '20230603';
DateSuffix = '230603';
OutDir = [ImgProcDir filesep 'figures' filesep DateDir];

% ========================== Parameters ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];

AllTablePaths = {TablePath_Main, TablePath_Mass, TablePath_YTC};
ImgTableCount = size(AllTablePaths, 2);

% ========================== Do Things ==========================

count_struct = struct('all_sim', zeros(1,20));
count_struct.all_exp = zeros(1,20);

%Gather counts for each group
for t = 1:ImgTableCount
    fprintf('Trying Table %s...\n', AllTablePaths{t});
    image_table = testutil_opentable(AllTablePaths{t});

    entry_count = size(image_table, 1);
    for r = 1:entry_count

        %Check if sim
        myname = getTableValue(image_table, r, 'IMGNAME');
        fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);

        %Get res file path
        set_group_dir = getSetOutputDirName(myname);
        ResFilePath = [ResultsDir filesep set_group_dir filesep myname '_summary.mat'];

        if isfile(ResFilePath)
            load(ResFilePath, 'analysis');
        else
            fprintf('> Could not find analysis file. Skipping...\n');
            continue;
        end

        if isfield(analysis, 'results_hb')
            if isfield(analysis.results_hb, 'fprop_nz')
                zprop = 1.0 - analysis.results_hb.fprop_nz;
                idx = ceil(zprop / 0.05);
                if idx < 1; idx = 1; end
                if idx > 20; idx = 20; end

                [is_sim, group_name] = determineGroup(myname);

                if is_sim
                    if ~isfield(count_struct, 'sim_groups')
                        count_struct.sim_groups = struct(group_name, zeros(1,20));
                    else
                        if ~isfield(count_struct.sim_groups, group_name)
                            count_struct.sim_groups.(group_name) = zeros(1,20);
                        end
                    end

                    count_vec = count_struct.sim_groups.(group_name);
                    count_vec(idx) = count_vec(idx) + 1;
                    count_struct.sim_groups.(group_name) = count_vec;

                    count_struct.all_sim(idx) = count_struct.all_sim(idx) + 1;
                else
                    if ~isfield(count_struct, 'exp_groups')
                        count_struct.exp_groups = struct(group_name, zeros(1,20));
                    else
                        if ~isfield(count_struct.exp_groups, group_name)
                            count_struct.exp_groups.(group_name) = zeros(1,20);
                        end
                    end

                    count_vec = count_struct.exp_groups.(group_name);
                    count_vec(idx) = count_vec(idx) + 1;
                    count_struct.exp_groups.(group_name) = count_vec;

                    count_struct.all_exp(idx) = count_struct.all_exp(idx) + 1;
                end
            end
        end

        clear analysis
    end
end

%Heatmaps
raw_mtx = [count_struct.all_sim; count_struct.all_exp];
fig_handle = doHeatmap(1, raw_mtx, {'Simulated', 'Experimental'});

%Sim groups
simgroup_names = fieldnames(count_struct.sim_groups);
group_count = size(simgroup_names, 1);
raw_mtx = zeros(group_count, 20);
for i = 1:group_count
    group_name = simgroup_names{i,1};
    raw_mtx(i, 1:20) = count_struct.sim_groups.(group_name);
end
fig_handle = doHeatmap(2, raw_mtx, simgroup_names);

%Exp groups
expgroup_names = fieldnames(count_struct.exp_groups);
group_count = size(expgroup_names, 1);
raw_mtx = zeros(group_count, 20);
for i = 1:group_count
    group_name = expgroup_names{i,1};
    raw_mtx(i, 1:20) = count_struct.exp_groups.(group_name);
end
fig_handle = doHeatmap(3, raw_mtx, expgroup_names);

% ========================== Helper Functions ==========================

function fig_handle = doHeatmap(figno, raw_mtx, labels)

    %raw_mtx is not normalized, just the raw counts
    rowsums = sum(raw_mtx, 2);
    rowsums(rowsums == 0) = NaN;
    scaled_mtx = raw_mtx ./ rowsums;
    scaled_mtx(isnan(scaled_mtx)) = 0;

    fig_handle = figure(figno);
    clf;
    hm = heatmap([0:0.05:0.95], labels, scaled_mtx);
    hm.Colormap = turbo;
    hm.ColorLimits = [0.0 1.0];
    hm.CellLabelColor = 'none';
    xlabel('Zero Voxel Proportion');
    
end

function [is_sim, group_name] = determineGroup(imgname)
    is_sim = false;
    group_name = [];
    if isempty(imgname); return; end

    if startsWith(imgname, 'mESC4d_')
        if contains(imgname, 'Tsix')
            group_name = 'mESC_Tsix';
        elseif contains(imgname, 'Xist')
            group_name = 'mESC_Xist';
        end
    elseif startsWith(imgname, 'scrna_')
        if endsWith(imgname, '_STL1')
            group_name = 'yeast_CY5';
        elseif endsWith(imgname, '_CTT1')
            group_name = 'yeast_TMR';
        end
    elseif startsWith(imgname, 'mESC_loday_')
        if endsWith(imgname, '_Tsix')
            group_name = 'mESC_Tsix';
        elseif endsWith(imgname, '_Xist')
            group_name = 'mESC_Xist';
        end
    elseif startsWith(imgname, 'scprotein_')
        group_name = 'scprotein';
    elseif startsWith(imgname, 'sim_')
        group_name = 'simbig';
        is_sim = true;
    elseif startsWith(imgname, 'histonesc_')
        if endsWith(imgname, '_Tsix')
            group_name = 'mESC_Tsix';
        elseif endsWith(imgname, '_Xist')
            group_name = 'mESC_Xist';
        elseif endsWith(imgname, '_Histone')
            group_name = 'mESC_Histone';
        end
    elseif startsWith(imgname, 'ROI0')
        if endsWith(imgname, '_CY5')
            group_name = 'HeLa_CY5';
        elseif endsWith(imgname, '_GFP')
            group_name = 'HeLa_GFP';
        end
    elseif startsWith(imgname, 'sctc_')
        if endsWith(imgname, '_STL1')
            group_name = 'yeast_CY5';
        elseif endsWith(imgname, '_CTT1')
            group_name = 'yeast_TMR';
        end
    elseif startsWith(imgname, 'rsfish_')
        if startsWith(imgname, 'rsfish_sim')
            is_sim = true;
            group_name = 'plab_sim';
        else
            group_name = 'celegans';
        end
    elseif startsWith(imgname, 'simvar_')
        group_name = 'simvar';
        is_sim = true;
    elseif startsWith(imgname, 'simvarmass_')
        is_sim = true;
        if contains(imgname, 'TMRL')
            group_name = 'sim_TMRL';
        elseif contains(imgname, 'CY5L')
            group_name = 'sim_CY5L';
        else
            group_name = 'simvarmass';
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
