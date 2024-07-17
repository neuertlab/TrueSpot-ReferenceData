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

TIF_PATH = [RNAFISHIMG_DIR filesep 'JA20240514' filesep...
    'JA_2024_05_14_10 min_GNY0117_GPP2-TMR1-1000_HSP12-AF5941-1000_GPD1-CY51-1000_1_MMStack_Pos0.ome.tif'];
CS_PATH = [IMGDAT_DIR filesep 'CellSeg_JA_20240514_GNY0117_10min_I1.mat'];

TOTAL_CH = 5;
TRANS_CH = 1;
DAPI_CH = 2;

% ========================== Load Cellseg Data ==========================

fprintf('Loading cellseg data...\n');
cell_mask = CellSeg.openCellMask(CS_PATH);
nuc_mask = CellSeg.openNucMask(CS_PATH, 2);

% ========================== Load Image ==========================
fprintf('Loading TIF...\n');

[channels, ~] = LoadTif(TIF_PATH, TOTAL_CH, [TRANS_CH DAPI_CH], 1);
lightData = channels{TRANS_CH, 1};
dapiData = channels{DAPI_CH, 1};
clear channels

% ========================== Render ==========================

renderer = CellsegDrawer;
renderer = renderer.initializeMe();

renderer.cell_mask = cell_mask ~= 0;
renderer.nuc_mask = nuc_mask ~= 0;

renderer.cell_color = [1.000 0.400 0.847];

figure(1);
clf;
lightDataOvr = renderer.applyCellMask(lightData);
imshow(lightDataOvr);
hold on;

figure(2);
clf;
dapiDataOvr = renderer.applyNucMask(dapiData);
imshow(dapiDataOvr, []);
hold on;

