%
%%
DataDir = 'D:\Users\hospelb\labdata';
%DataDir = 'D:\usr\bghos\labdat\imgproc';

addpath('./core');
addpath('./thirdparty');

% ========================== I/O Info ==========================

RNAFISH_DIR = [DataDir filesep 'RNAFISH' filesep 'Analysis'];
RNAFISHIMG_DIR = [DataDir filesep 'RNAFISH' filesep 'Images'];

IMGDAT_DIR = [RNAFISH_DIR filesep 'JA20240514' filesep 'JA_20240514_GNY0117_10min_I1'];
CHDAT_DIR = [IMGDAT_DIR filesep 'CH3'];
PREFIX = 'JA_20240514_GNY0117_10min_I1_CH3_spotCall';

TIF_PATH = [RNAFISHIMG_DIR filesep 'JA20240514' filesep...
    'JA_2024_05_14_10 min_GNY0117_GPP2-TMR1-1000_HSP12-AF5941-1000_GPD1-CY51-1000_1_MMStack_Pos0.ome.tif'];
CS_PATH = [IMGDAT_DIR filesep 'CellSeg_JA_20240514_GNY0117_10min_I1.mat'];

TOTAL_CH = 5;
SAMPLE_CH = 3;

% ========================== Load Call Table ==========================
fprintf('Loading spots run info...\n');

spotsrun = RNASpotsRun.loadFrom([CHDAT_DIR filesep PREFIX], true);
[spotsrun, call_table] = spotsrun.loadCallTable();

% ========================== Load Image ==========================
fprintf('Loading TIF...\n');

[channels, ~] = LoadTif(TIF_PATH, TOTAL_CH, [SAMPLE_CH], 1);
chData = channels{SAMPLE_CH, 1};
clear channels

% ========================== Preprocess ==========================

maxProjRaw = max(chData, [], 3);

%Filter
[sampleFilt] = RNA_Threshold_SpotDetector.run_spot_detection_pre(...
    chData, [CHDAT_DIR filesep spotsrun.paths.out_namestem], true, spotsrun.options.dtune_gaussrad, false);
clear sampleCh

maxProjFilt = max(sampleFilt, [], 3);
clear sampleFilt

% ========================== Render ==========================

vis = SpotCallVisualization;
vis = vis.initializeMe();
vis.visCommon = vis.visCommon.initializeMe(spotsrun.dims.idims_sample);
vis.callTable = call_table;
vis.zMIPColor = true;

thVal = spotsrun.intensity_threshold;
thOkay = call_table(call_table{:, 'dropout_thresh'} >= spotsrun.intensity_threshold, :);

fh1 = figure(1);
clf;
imshow(maxProjRaw, []);
hold on;
[fh1, okay1] = vis.drawResultsBasic(fh1, spotsrun.intensity_threshold);

fh2 = figure(2);
clf;
imshow(maxProjFilt, []);
hold on;
[fh2, okay2] = vis.drawResultsBasic(fh2, spotsrun.intensity_threshold);

