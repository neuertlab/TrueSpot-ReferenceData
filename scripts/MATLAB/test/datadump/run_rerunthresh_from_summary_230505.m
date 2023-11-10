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

START_INDEX = 1;
END_INDEX = 1000;

PRESET_INDEX = 5;

% ========================== Other Paths ==========================

%InputTablePath = [BaseDir filesep 'test_images_simytc.csv'];
InputTablePath = [BaseDir filesep 'test_images_simvarmass.csv'];
%InputTablePath = [BaseDir filesep 'test_images.csv'];

image_table = testutil_opentable(InputTablePath);

OutputDir = [BaseDir filesep 'data' filesep 'results'];

% ========================== Iterate through table entries ==========================

entry_count = size(image_table,1);

if START_INDEX < 1; START_INDEX = 1; end
if END_INDEX > entry_count; END_INDEX = entry_count; end

for r = START_INDEX:END_INDEX
    is_sim = false;
    myname = getTableValue(image_table, r, 'IMGNAME');
    fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);

    %Find output file
    GroupOutDir = [OutputDir filesep getSetOutputDirName(myname)];
    if ~isfolder(GroupOutDir)
        mkdir(GroupOutDir);
    end
    OutFilePath = [GroupOutDir filesep myname '_summary.mat'];

    if ~isfile(OutFilePath)
        fprintf('> No summary file found. Skipping!\n');
        continue;
    end

    load(OutFilePath, 'analysis');

    t_count = size(analysis.results_hb.performance,1);
    spot_count = NaN(t_count,2);
    spot_count(:,1) = analysis.results_hb.performance{:,'thresholdValue'};
    spot_count(:,2) = analysis.results_hb.performance{:,'spotCount'};

    threshold_results = RNAThreshold.runWithPreset(spot_count, [], PRESET_INDEX);

    analysis.results_hb.threshold_details = threshold_results;
    analysis.results_hb.threshold = threshold_results.threshold;
    %analysis.results_hb = runstats(analysis.results_hb, spot_count, threshold_results.threshold);

    thresh_idx = RNAUtils.findThresholdIndex(threshold_results.threshold, transpose(spot_count(:,1)));
    analysis.results_hb.fscore_autoth = analysis.results_hb.performance{thresh_idx, 'fScore'};

    if isfield(analysis.results_hb, 'performance_trimmed')
        analysis.results_hb.fscore_autoth_trimmed = analysis.results_hb.performance_trimmed{thresh_idx, 'fScore'};
    end

    save(OutFilePath, 'analysis');
end

% ========================== Helper functions ==========================

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
