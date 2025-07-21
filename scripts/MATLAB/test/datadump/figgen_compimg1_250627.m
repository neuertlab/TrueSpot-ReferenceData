%
%%

addpath('./core');
addpath('./thirdparty');

% ------------------------ INPUT PATHS ------------------------

% TablePath = 'D:\Users\hospelb\labdata\figImages.csv';
% 
% DataBasePath = 'D:\Users\hospelb\labdata\imgproc\imgproc';
% ImagesBasePath = 'C:\Users\hospelb\labdata\imgproc';

TablePath = 'D:\usr\bghos\labdat\figImages.csv';

DataBasePath = 'D:\usr\bghos\labdat\imgproc';
ImagesBasePath = 'D:\usr\bghos\labdat\imgproc';

% ------------------------ Options ------------------------

DO_COMP_FIG = false;
DO_MAXPROJ_FIG = true;
DO_SQPICKER = false;

GEN_FOR_ROTATION = true;

TILE_DIM = 1024;

TOP_MARGIN = 0.030;
LEFT_MARGIN = 0.030;
X_SPACE = 0.004;
Y_SPACE = 0.003;

MIN_ROW = 12;
MAX_ROW = 14;

ROW_MAXPROJ_COMP = 12;
MAXPROJ_COMP_ZMIN = 0;
MAXPROJ_COMP_ZMAX = 0;
MAXPROJ_COMP_ZSHOWMIN = 17;
MAXPROJ_COMP_ZSHOWMAX = 40;
% MAXPROJ_COMP_ZSHOWMIN = 41;
% MAXPROJ_COMP_ZSHOWMAX = 64;
% MAXPROJ_COMP_ZSHOWMIN = 49;
% MAXPROJ_COMP_ZSHOWMAX = 67;
%MAXPROJ_FIXED_TH = 111; %E2R2C2
%MAXPROJ_FIXED_TH = 64; %XistE (Appr. Mean + Stdev)
MAXPROJ_FIXED_TH = 98; %H3K4me2
MAXPROJ_COL_COUNT = 8;

MARKER_COLOR = [1 0 0];

Z_MARKER_COLOR = [1 0 0];
Z_MARKER_COLOR_ABOVE = [0 1 1];
Z_MARKER_COLOR_BELOW = [1 1 0];
Z_DRAW_RAD = 0;

SQUARE_PICKER_ROW = 12;

% ------------------------ LUTs ------------------------

DAPI_LUT_PATH = [ImagesBasePath filesep 'img' filesep 'dapi_lut.lut'];

CELL_CH_LUT = genGreyscaleLUT();
DAPI_CH_LUT = readBinaryLUT(DAPI_LUT_PATH);
SAMPLE_CH_LUT = genGreyscaleLUT();
SAMPLE_CH_LUT(:, [1 3]) = 0.0;

% ------------------------ Read Table ------------------------

image_table = readtable(TablePath,'Delimiter',',','ReadVariableNames',true,'Format',...
    '%s%d%d%d%d%s%d%d%d%d%d%d%s%s%s%d%d%s%d');

% ------------------------ Prep Figure ------------------------

COLCOUNT = 8;
%groupCount = size(image_table, 1);
groupCount = MAX_ROW - MIN_ROW + 1;

ww = ((1.0 - LEFT_MARGIN) / COLCOUNT) - (X_SPACE);
hh = ((1.0 - TOP_MARGIN) / groupCount) - (Y_SPACE);
yy = 1.0 - hh - TOP_MARGIN;

%Columns: Original, Raw channel, Filtered, Ref, TS, BF, RS, DB
if DO_COMP_FIG
    fh = figure(1);
    clf;
    for r = MIN_ROW:MAX_ROW
        xx = LEFT_MARGIN;

        %Load image
        imageStruct = loadImageData(image_table, r, ImagesBasePath, DataBasePath, TILE_DIM, CELL_CH_LUT, DAPI_CH_LUT, SAMPLE_CH_LUT);

        opStruct = genEmptyDrawOptionsStruct();
        opStruct.drawCellMask = true;
        opStruct.drawNucMask = true;
        opStruct.flipRotateScaleBar = GEN_FOR_ROTATION;

        %subplot(groupCount, COLCOUNT, sp); sp = sp + 1;
        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        [fh, iRender] = drawOriginalImage(fh, imageStruct, opStruct);

        opStruct.drawNucChannel = false;
        opStruct.drawLightCh = false;
        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        [fh, irRender] = drawOriginalImage(fh, imageStruct, opStruct);

        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        [fh, fRender] = drawFilteredImage(fh, imageStruct, opStruct);

        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        imshow(irRender); hold on;
        fh = plotReferenceOverlay(fh, imageStruct, [1 0 0]);

        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        imshow(irRender); hold on;
        fh = plotTSCallsetOverlay(fh, imageStruct, [1 0 0]);

        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        imshow(irRender); hold on;
        fh = plotBFCallsetOverlay(fh, imageStruct, [1 0 0]);

        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        imshow(irRender); hold on;
        fh = plotRSCallsetOverlay(fh, imageStruct, [1 0 0]);

        subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
        imshow(irRender); hold on;
        fh = plotDBCallsetOverlay(fh, imageStruct, [1 0 0]);

        yy = yy - (hh + Y_SPACE);
    end

    clear row
end

% ------------------------ 2D vs. 3D ------------------------

if DO_MAXPROJ_FIG
    fh2 = figure(2);
    clf;

    image_table{ROW_MAXPROJ_COMP, 'z0'} = MAXPROJ_COMP_ZMIN;
    image_table{ROW_MAXPROJ_COMP, 'z1'} = MAXPROJ_COMP_ZMAX;
    imageStruct = loadImageData(image_table, ROW_MAXPROJ_COMP, ImagesBasePath, DataBasePath, TILE_DIM, CELL_CH_LUT, DAPI_CH_LUT, SAMPLE_CH_LUT, true);
    Z = size(imageStruct.signal3D, 3);
    ShowZ = MAXPROJ_COMP_ZSHOWMAX - MAXPROJ_COMP_ZSHOWMIN + 1;
    rowCount = ceil(ShowZ ./ MAXPROJ_COL_COUNT) + 1;

    %Fetch appropriate 2D and 3D callsets
    callset3 = imageStruct.resultsStruct.results_hb.callset;
    callset3 = callset3(callset3{:,'dropout_thresh'} >= MAXPROJ_FIXED_TH, :);
    zmin_str = num2str(MAXPROJ_COMP_ZMIN);
    zmax_str = num2str(MAXPROJ_COMP_ZMAX);
    if MAXPROJ_COMP_ZMIN < 1; zmin_str = '1'; end
    if MAXPROJ_COMP_ZMAX < 1; zmax_str = 'Z'; end
    sname = ['mip_' zmin_str '_' zmax_str];
    if isfield(imageStruct.resultsStruct.results_hb, sname)
        callset2 = imageStruct.resultsStruct.results_hb.(sname).callset;
    else
        callset2 = imageStruct.altResults.results_hb.(sname).callset;
    end
    callset2 = callset2(callset2{:,'dropout_thresh'} >= MAXPROJ_FIXED_TH, :);

    %Filter callsets to sample region
    [callX3, callY3, callZ3] = adjustCallsetToRegion(callset3, ...
        imageStruct.xOffset, imageStruct.yOffset, imageStruct.zOffset, imageStruct.sampleDims);
    [callX2, callY2, ~] = adjustCallsetToRegion(callset2, ...
        imageStruct.xOffset, imageStruct.yOffset, 0, imageStruct.sampleDims);

    %Top row is max projection, max projection with 2D calls, space, max
    %projection with 3D calls
    ww = ((1.0 - LEFT_MARGIN) / MAXPROJ_COL_COUNT) - (X_SPACE);
    hh = ((1.0 - TOP_MARGIN) / rowCount) - (Y_SPACE);
    yy = 1.0 - hh - TOP_MARGIN;
    xx = LEFT_MARGIN;

    %(1,1) - Max projection alone
    [smplRescale, bwShift, bwRange] = rescaleSampleChannel(imageStruct.signalCh);
    iRender = bw2rgb(smplRescale, imageStruct.sampleLUT, false);
    iRender = addScaleBar(iRender, imageStruct, GEN_FOR_ROTATION);
    subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
    imshow(iRender);

    %(1,2) - Max projection w/ 2D calls
    subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
    imshow(iRender); hold on;
    plot(callX2, callY2, 'LineStyle', 'none', ...
        'MarkerEdgeColor', MARKER_COLOR, 'Marker', 'o', 'MarkerSize', 5);

    %(1,4) - Max projection w/ 3D calls
    xx = xx + ww + X_SPACE; %Skip col
    subplot('Position', [xx yy ww hh]); yy = yy - (hh + Y_SPACE);
    imshow(iRender); hold on;
    plot(callX3, callY3, 'LineStyle', 'none', ...
        'MarkerEdgeColor', MARKER_COLOR, 'Marker', 'o', 'MarkerSize', 5);

    drawMin = MAXPROJ_COMP_ZMIN;
    drawMax = MAXPROJ_COMP_ZMAX;
    if drawMin < 1; drawMin = 1; end
    if drawMax < 1; drawMax = Z; end

    %Individual slices
    currentSlice = MAXPROJ_COMP_ZSHOWMIN;
    for r = 2:rowCount
        xx = LEFT_MARGIN;
        for l = 1:MAXPROJ_COL_COUNT
            if currentSlice > MAXPROJ_COMP_ZSHOWMAX; break; end
            sliceData = imageStruct.signal3D(:,:,currentSlice);
            %Rescale to global range
            sliceData = sliceData - bwShift;
            sliceData = sliceData ./ bwRange;
            iRender = bw2rgb(sliceData, imageStruct.sampleLUT, false);
            iRender = addScaleBar(iRender, imageStruct, GEN_FOR_ROTATION);

            subplot('Position', [xx yy ww hh]); xx = xx + ww + X_SPACE;
            imshow(iRender); hold on;

            if Z_DRAW_RAD > 0
                for rz = 1:Z_DRAW_RAD
                    upCheck = currentSlice + rz;
                    downCheck = currentSlice - rz;
                    if downCheck >= drawMin
                        sliceBool = (callZ3 == downCheck);
                        if nnz(sliceBool) > 0
                            plot(callX3(sliceBool), callY3(sliceBool), 'LineStyle', 'none', ...
                                'MarkerEdgeColor', Z_MARKER_COLOR_BELOW, 'Marker', 'o', 'MarkerSize', 5);
                        end
                    end
                    if upCheck <= drawMax
                        sliceBool = (callZ3 == upCheck);
                        if nnz(sliceBool) > 0
                            plot(callX3(sliceBool), callY3(sliceBool), 'LineStyle', 'none', ...
                                'MarkerEdgeColor', Z_MARKER_COLOR_ABOVE, 'Marker', 'o', 'MarkerSize', 5);
                        end
                    end

                end
                clear upCheck downCheck rz
            end

            sliceBool = (callZ3 == currentSlice);
            if nnz(sliceBool) > 0
                plot(callX3(sliceBool), callY3(sliceBool), 'LineStyle', 'none', ...
                    'MarkerEdgeColor', Z_MARKER_COLOR, 'Marker', 'o', 'MarkerSize', 5);
            end

            currentSlice = currentSlice + 1;
        end
        yy = yy - (hh + Y_SPACE);
    end
    clear sliceData currentSlice xx yy ww hh smplRescale
    clear bwRange bwShift callset2 callset3 iRender
    clear callX2 callY2 callX3 callY3 callZ3

end

% ------------------------ ROI Pick Helper ------------------------

if DO_SQPICKER
    fh3 = figure(3);
    clf;

    sqPick = SquarePicker;
    tifPathRaw = image_table{SQUARE_PICKER_ROW, 'TifPath'};
    tifPath = strjoin([ImagesBasePath replace(tifPathRaw, '/', filesep)], '');
    totalCh = image_table{SQUARE_PICKER_ROW, 'Ch_Total'};
    sampleCh = image_table{SQUARE_PICKER_ROW, 'Channel'};
    [channels, idims] = LoadTif(tifPath, totalCh, sampleCh, 1);

    z0 = double(image_table{SQUARE_PICKER_ROW, 'z0'});
    z1 = double(image_table{SQUARE_PICKER_ROW, 'z1'});
    if z0 < 1; z0 = double(1); end
    if z1 < 1; z1 = double(idims.z); end

    sampleCh = channels{sampleCh, 1}; clear channels;
    sqPick.imageMaxproj = max(sampleCh(:,:,z0:z1), [], 3, 'omitnan');
    clear sampleCh;

    %Load cellseg
    csPathBase = image_table{SQUARE_PICKER_ROW, 'CellSegPath'};
    if ~strcmp(csPathBase, '<N/A>')
        csPathBase = strjoin([DataBasePath replace(csPathBase, '/', filesep) '.mat'], '');
        cellMaskPath = replace(csPathBase, '*', 'Lab_');
        nucMaskPath = replace(csPathBase, '*', 'nuclei_');
        if isfile(cellMaskPath)
            sqPick.cellMask = CellSeg.openCellMask(cellMaskPath);
        end
        if isfile(nucMaskPath)
            sqPick.nucMask = CellSeg.openNucMask(nucMaskPath);
            if ~isempty(sqPick.nucMask)
                sqPick.nucMask = max(sqPick.nucMask(:,:,z0:z1), [], 3, 'omitnan');
            end
        end
    end

    x0 = double(image_table{SQUARE_PICKER_ROW, 'x0'} + 1);
    x1 = double(image_table{SQUARE_PICKER_ROW, 'x1'});
    y0 = double(image_table{SQUARE_PICKER_ROW, 'y0'} + 1);
    y1 = double(image_table{SQUARE_PICKER_ROW, 'y1'});
    sqPick.currentSelection.x_min = x0;
    sqPick.currentSelection.x_max = x1;
    sqPick.currentSelection.y_min = y0;
    sqPick.currentSelection.y_max = y1;

    sqPick.sampleLUT = SAMPLE_CH_LUT;
    sqPick.figHandle = fh3;

    sqPick = sqPick.launchFigureGUI();
end

% ------------------------ Helper Functions ------------------------

function imageStruct = genEmptyImageDrawingStruct()
    imageStruct = struct();
    imageStruct.signalCh = [];
    imageStruct.dapiCh = [];
    imageStruct.lightCh = [];
    imageStruct.signal3D = [];
    imageStruct.xOffset = 0.0;
    imageStruct.yOffset = 0.0;
    imageStruct.zOffset = 0.0;
    imageStruct.sampleDims = struct('x', 0, 'y', 0, 'z', 0);
    imageStruct.cellMask = [];
    imageStruct.nucMask = [];
    imageStruct.resultsStruct = [];
    imageStruct.altResults = [];

    imageStruct.cellLUT = [];
    imageStruct.nucLUT = [];
    imageStruct.sampleLUT = [];
    imageStruct.filtLUT = [];
    imageStruct.cellMaskColor = [1 0 1];
    imageStruct.nucMaskColor = [0 0 1];
    imageStruct.targetDim = 0;
    imageStruct.resizeFactor = NaN;
    imageStruct.pixDim = 0;

    imageStruct.wd = [];
end

function optionsStruct = genEmptyDrawOptionsStruct()
    optionsStruct = struct();
    optionsStruct.drawLightCh = true;
    optionsStruct.drawCellMask = true;
    optionsStruct.cellMaskAsOutline = true;
    optionsStruct.drawNucChannel = true;
    optionsStruct.drawNucMask = true;
    optionsStruct.nucMaskAsOutline = true;
    optionsStruct.drawScaleBar = true;
    optionsStruct.flipRotateScaleBar = false;
end

function [callX, callY, callZ] = adjustCallsetToRegion(callset, xOffset, yOffset, zOffset, sampleDims)
    callX = callset{:, 'isnap_x'} - xOffset;
    callY = callset{:, 'isnap_y'} - yOffset;
    callZ = callset{:, 'isnap_z'} - zOffset;

    rflag = callX < 1;
    rflag = or(rflag, callX > sampleDims.x);
    rflag = or(rflag, callY < 1);
    rflag = or(rflag, callY > sampleDims.y);
    rflag = or(rflag, callZ < 1);
    rflag = or(rflag, callZ > sampleDims.z);

    kflag = ~rflag;

    callX = callX(kflag);
    callY = callY(kflag);
    callZ = callZ(kflag);
end

function imageStruct = loadImageData(imageTable, row, ImagesBasePath, DataBasePath, TILE_DIM, CELL_CH_LUT, DAPI_CH_LUT, SAMPLE_CH_LUT, keep3D)
    if nargin < 9; keep3D = false; end

    %Load image
    tifPathRaw = imageTable{row, 'TifPath'};
    tifPath = strjoin([ImagesBasePath replace(tifPathRaw, '/', filesep)], '');
    totalCh = imageTable{row, 'Ch_Total'};
    sampleCh = imageTable{row, 'Channel'};
    dapiCh = imageTable{row, 'Ch_DAPI'};
    lightCh = imageTable{row, 'Ch_Light'};
    ch_to_read = sampleCh;
    if dapiCh > 0; ch_to_read = [ch_to_read dapiCh]; end
    if lightCh > 0; ch_to_read = [ch_to_read lightCh]; end
    [channels, idims] = LoadTif(tifPath, totalCh, ch_to_read, 1);

    %Get trim area
    x0 = double(imageTable{row, 'x0'} + 1);
    x1 = double(imageTable{row, 'x1'});
    y0 = double(imageTable{row, 'y0'} + 1);
    y1 = double(imageTable{row, 'y1'});
    z0 = double(imageTable{row, 'z0'});
    z1 = double(imageTable{row, 'z1'});
    if z0 < 1; z0 = double(1); end
    if z1 < 1; z1 = double(idims.z); end
    imageStruct = genEmptyImageDrawingStruct();
    imageStruct.wd = DataBasePath;

    imageStruct.pixDim = double(imageTable{row, 'Pix_nm'});

    chDat = channels{sampleCh, 1};
    chDat = chDat(y0:y1, x0:x1, z0:z1);
    imageStruct.signalCh = max(chDat, [], 3);
    if keep3D
        imageStruct.signal3D = chDat;
    end
    if dapiCh > 0
        chDat = channels{dapiCh, 1};
        chDat = chDat(y0:y1, x0:x1, z0:z1);
        imageStruct.dapiCh = max(chDat, [], 3);
    end
    if lightCh > 0
        chDat = channels{lightCh, 1};
        chDat = chDat(y0:y1, x0:x1, z0:z1);
        
        imageStruct.lightCh = max(chDat, [], 3);
    end
    clear channels

    imageStruct.xOffset = x0 - 1;
    imageStruct.yOffset = y0 - 1;
    imageStruct.zOffset = z0 - 1;
    imageStruct.sampleDims.x = size(imageStruct.signalCh, 2);
    imageStruct.sampleDims.y = size(imageStruct.signalCh, 1);
    imageStruct.sampleDims.z = z1 - z0 + 1;
    imageStruct.targetDim = TILE_DIM;
    imageStruct.resizeFactor = TILE_DIM ./ imageStruct.sampleDims.y;

    imageStruct.cellLUT = CELL_CH_LUT;
    imageStruct.nucLUT = DAPI_CH_LUT;
    imageStruct.sampleLUT = SAMPLE_CH_LUT;
    imageStruct.filtLUT = CELL_CH_LUT;

    %Load cellseg
    csPathBase = imageTable{row, 'CellSegPath'};
    if ~strcmp(csPathBase, '<N/A>')
        csPathBase = strjoin([DataBasePath replace(csPathBase, '/', filesep) '.mat'], '');
        cellMaskPath = replace(csPathBase, '*', 'Lab_');
        nucMaskPath = replace(csPathBase, '*', 'nuclei_');
        if isfile(cellMaskPath)
            imageStruct.cellMask = CellSeg.openCellMask(cellMaskPath);
            imageStruct.cellMask = imageStruct.cellMask(y0:y1, x0:x1);
        end
        if isfile(nucMaskPath)
            imageStruct.nucMask = CellSeg.openNucMask(nucMaskPath);
            if ~isempty(imageStruct.nucMask)
                imageStruct.nucMask = imageStruct.nucMask(y0:y1, x0:x1, z0:z1);
                imageStruct.nucMask = max(imageStruct.nucMask, [], 3, 'omitnan');
            end
        end
    end

    %Load results
    resPathBase = imageTable{row, 'ResultsPath'};
    resPathBase = strjoin([DataBasePath replace(resPathBase, '/', filesep)], '');
    load(resPathBase, 'analysis');
    imageStruct.resultsStruct = analysis;
    clear analysis

    %If there is second results file (ie. for sctc), load
    resPathBase = imageTable{row, 'AltResultsPath'};
    if ~strcmp(resPathBase, '<N/A>')
        resPathBase = strjoin([DataBasePath replace(resPathBase, '/', filesep)], '');
        load(resPathBase, 'analysis');
        imageStruct.altResults = analysis;
        clear analysis
    end
end

function compImg = compositeNewChannel(baseImageRGB, overlayImage, overlayLUT, rescaleOverlay)
    if nargin < 4; rescaleOverlay = true; end
    rgbOverlay = bw2rgb(overlayImage, overlayLUT, rescaleOverlay);
    rgbOverlay = double(rgbOverlay) ./ 255.0;
    baseDbl = double(baseImageRGB) ./ 255.0;
    baseDbl = baseDbl .* (1.0 - rgbOverlay);
    baseDbl = baseDbl + rgbOverlay;
    compImg = uint8(round(baseDbl .* 255.0));
end

function compImg = compositeMaskOverlay(baseImageRGB, mask, color, alpha, doOutline)
    compImg = baseImageRGB;
    if isempty(mask); return; end
    if nnz(mask) < 1; return; end
    baseDbl = double(baseImageRGB) ./ 255.0;
    if doOutline
        lineExpand = 3 ./ 500;
        Y = size(mask, 1);
        lineExpand = round(Y .* lineExpand);
        mask = bwperim(mask, 8);
        se = strel('disk',lineExpand);
        mask = imdilate(mask,se);
        clear se lineExpand 
    end
    Y = size(mask, 1);
    X = size(mask, 2);
    maskrgb = zeros(Y,X,3);
    maskrgb(:,:,1) = double(mask) .* color(1);
    maskrgb(:,:,2) = double(mask) .* color(2);
    maskrgb(:,:,3) = double(mask) .* color(3);
    maskrgb = maskrgb .* alpha;
    baseDbl = baseDbl .* (1.0 - maskrgb);
    baseDbl = baseDbl + maskrgb;
    compImg = uint8(round(baseDbl .* 255.0));
end

function bwImageScaled = rescaleLightChannel(bwImage)
    bwImage = double(bwImage);
    bwMed = median(bwImage, 'all', 'omitnan');
    bwStd = std(bwImage, 0, 'all', 'omitnan');
    bwMin = bwMed - (1 * bwStd);
    bwImage = bwImage - bwMin;
    bwMax = max(bwImage, [], 'all', 'omitnan');
    bwMax = bwMax + (8 * bwStd);
    bwImageScaled = bwImage ./ bwMax;
end

function bwImageScaled = rescaleNucChannel(bwImage)
    bwImage = double(bwImage);
    bwMin = prctile(bwImage, 70, 'all');
    bwImage = bwImage - bwMin;
    bwMax = max(bwImage, [], 'all', 'omitnan');
    bwImageScaled = bwImage ./ bwMax;
end

function [bwImageScaled, bwShift, bwRange] = rescaleSampleChannel(bwImage)
    bwImage = double(bwImage);
    %bwMin = prctile(bwImage, 2, 'all');
    bwMin = min(bwImage, [], 'all', 'omitnan');
    bwImage = bwImage - bwMin;
    bwMed = median(bwImage, 'all', 'omitnan');
    bwStd = std(bwImage, 0, 'all', 'omitnan');
    bwMax = bwMed + round(10 * bwStd);
    %bwMax = max(bwImage, [], 'all', 'omitnan');
    bwImageScaled = bwImage ./ bwMax;
    bwShift = bwMin;
    bwRange = bwMax;
end

function rgbImage = bw2rgb(bwImage, lut, doRescale)
    if nargin < 3; doRescale = true; end
    X = size(bwImage, 2);
    Y = size(bwImage, 1);
    rgbImage = zeros(Y,X,3);

    if doRescale
        bwImage = double(bwImage);
        bwMin = min(bwImage, [], 'all', 'omitnan');
        bwImage = bwImage - bwMin;
        bwMed = median(bwImage, 'all', 'omitnan');
        bwStd = std(bwImage, 0, 'all', 'omitnan');
        bwMax = bwMed + round(10 * bwStd);
        %bwMax = max(bwImage, [], 'all', 'omitnan');
        bwImage = bwImage ./ bwMax;
    end

    bwImage = round(bwImage .* 255.0);
    bwImage = bwImage + 1;
    bwImage = min(bwImage, 256);
    bwImage = max(bwImage, 1);

    for c = 1:3
        cmult = lut(bwImage, c);
        rgbImage(:,:,c) = reshape(cmult, Y, X);
    end

    rgbImage = rgbImage .* 255.0;
    rgbImage = uint8(rgbImage);
end

function renderedImage = addScaleBar(inputRgb, imageStruct, flipRotate)
    if nargin < 3; flipRotate = false; end
    barSize = 5000; %nm
    barLenPix = round(barSize ./ imageStruct.pixDim);

    thickness = 3 ./ 256;
    thicknessActual = round(thickness .* imageStruct.sampleDims.y);
    xOff = round(imageStruct.sampleDims.x ./ 10);
    yOff = round(imageStruct.sampleDims.y ./ 10);
    yOff = imageStruct.sampleDims.y - yOff - thicknessActual;

    %rectangle('Position', [xOff yOff barLenPix thickness], 'FaceColor', 'w', ...
    %    'LineStyle', 'none');

    renderedImage = inputRgb;
    y1 = yOff + thicknessActual;
    x1 = xOff + barLenPix;
    if ~flipRotate
        renderedImage(yOff:y1, xOff:x1, :) = 255;
    else
        renderedImage(xOff:x1, yOff:y1, :) = 255;
    end
end

function [figHandle, iRender] = drawOriginalImage(figHandle, imageStruct, opStruct)
    iRender = [];

    %1. Cell channel
    if (opStruct.drawLightCh) & ~isempty(imageStruct.lightCh)
        iRender = rescaleLightChannel(imageStruct.lightCh);
        iRender = bw2rgb(iRender, imageStruct.cellLUT, false);
    end

    %2. Nuc channel
    if (opStruct.drawNucChannel) & ~isempty(imageStruct.dapiCh)
        nucRescale = rescaleNucChannel(imageStruct.dapiCh);
        if isempty(iRender)
            iRender = bw2rgb(nucRescale, imageStruct.nucLUT, false);
        else
            iRender = compositeNewChannel(iRender, nucRescale, imageStruct.nucLUT, false);
        end
    end

    %3. Sample channel
    [smplRescale, ~, ~] = rescaleSampleChannel(imageStruct.signalCh);
    if ~isempty(iRender)
        iRender = compositeNewChannel(iRender, smplRescale, imageStruct.sampleLUT, false);
    else
        iRender = bw2rgb(smplRescale, imageStruct.sampleLUT, false);
    end

    %4. Cell mask
    if (opStruct.drawCellMask) & ~isempty(imageStruct.cellMask)
        iRender = compositeMaskOverlay(iRender, imageStruct.cellMask, ...
            imageStruct.cellMaskColor, 0.5, opStruct.cellMaskAsOutline);
    end

    %5. Nuc mask
    if (opStruct.drawNucMask) & ~isempty(imageStruct.nucMask)
        iRender = compositeMaskOverlay(iRender, imageStruct.nucMask, ...
            imageStruct.nucMaskColor, 0.5, opStruct.nucMaskAsOutline);
    end

    if opStruct.drawScaleBar & (imageStruct.pixDim > 0)
        iRender = addScaleBar(iRender, imageStruct, opStruct.flipRotateScaleBar);
    end

    %Resize
    %iRender = imresize(iRender, imageStruct.resizeFactor);

    imshow(iRender);
end

function [figHandle, iRender] = drawFilteredImage(figHandle, imageStruct, opStruct)
    %Filter sample channel
    [iFiltered] = RNA_Threshold_SpotDetector.run_spot_detection_pre(...
        imageStruct.signalCh, [imageStruct.wd filesep 'figgen'], true, 7, false);
    iRender = bw2rgb(iFiltered, imageStruct.filtLUT);

    %2. Cell mask
    if (opStruct.drawCellMask) & ~isempty(imageStruct.cellMask)
        iRender = compositeMaskOverlay(iRender, imageStruct.cellMask, ...
            imageStruct.cellMaskColor, 0.5, opStruct.cellMaskAsOutline);
    end

    %3. Nuc mask
    if (opStruct.drawNucMask) & ~isempty(imageStruct.nucMask)
        iRender = compositeMaskOverlay(iRender, imageStruct.nucMask, ...
            imageStruct.nucMaskColor, 0.5, opStruct.nucMaskAsOutline);
    end

    if opStruct.drawScaleBar & (imageStruct.pixDim > 0)
        iRender = addScaleBar(iRender, imageStruct, opStruct.flipRotateScaleBar);
    end

    imshow(iRender);
end

function figHandle = plotReferenceOverlay(figHandle, imageStruct, color)
    if isempty(imageStruct); return; end
    if isempty(imageStruct.resultsStruct); return; end
    if ~isfield(imageStruct.resultsStruct, 'refsets'); return; end
    if ~isfield(imageStruct.resultsStruct.refsets, 'BH'); return; end
    refData = imageStruct.resultsStruct.refsets.BH;
    
    x0 = imageStruct.xOffset + 1;
    x1 = imageStruct.sampleDims.x + imageStruct.xOffset;
    y0 = imageStruct.yOffset + 1;
    y1 = imageStruct.sampleDims.y + imageStruct.yOffset;
    z0 = imageStruct.zOffset + 1;
    z1 = imageStruct.sampleDims.z + imageStruct.zOffset;

    %Only plot if ref set region covers selected region...
    if isfield(refData, 'truthset_region') & ~isempty(refData.truthset_region)
        if refData.truthset_region.x0 > x0; return; end
        if refData.truthset_region.x1 < x1; return; end
        if refData.truthset_region.y0 > y0; return; end
        if refData.truthset_region.y1 < y1; return; end
        if refData.truthset_region.z0 > z0; return; end
        if refData.truthset_region.z1 < z1; return; end
    end

    refCoordsShift = refData.exprefset;
    refCoordsShift(:,1) = refCoordsShift(:,1) - imageStruct.xOffset;
    refCoordsShift(:,2) = refCoordsShift(:,2) - imageStruct.yOffset;
    refCoordsShift(:,3) = refCoordsShift(:,3) - imageStruct.zOffset;

    zFlex = 5;
    rflag = refCoordsShift(:,1) < 1;
    rflag = or(rflag, refCoordsShift(:,1) > imageStruct.sampleDims.x);
    rflag = or(rflag, refCoordsShift(:,2) < 1);
    rflag = or(rflag, refCoordsShift(:,2) > imageStruct.sampleDims.y);
    rflag = or(rflag, refCoordsShift(:,3) < (1 - zFlex));
    rflag = or(rflag, refCoordsShift(:,3) > (imageStruct.sampleDims.z + zFlex));

    refCoordsShift = refCoordsShift(~rflag, :);
    plot(refCoordsShift(:,1), refCoordsShift(:,2), 'LineStyle', 'none', ...
        'MarkerEdgeColor', color, 'Marker', 'o', 'MarkerSize', 5);

end

function figHandle = plotCallsetTableCalls(figHandle, imageStruct, callset, color)
    callX = callset{:, 'isnap_x'} - imageStruct.xOffset;
    callY = callset{:, 'isnap_y'} - imageStruct.yOffset;
    callZ = callset{:, 'isnap_z'} - imageStruct.zOffset;

    zFlex = 5;
    rflag = callX < 1;
    rflag = or(rflag, callX > imageStruct.sampleDims.x);
    rflag = or(rflag, callY < 1);
    rflag = or(rflag, callY > imageStruct.sampleDims.y);
    rflag = or(rflag, callZ < (1 - zFlex));
    rflag = or(rflag, callZ > (imageStruct.sampleDims.z + zFlex));

    kflag = ~rflag;
    if nnz(kflag) > 0
        callX = callX(kflag);
        callY = callY(kflag);
        plot(callX, callY, 'LineStyle', 'none', ...
            'MarkerEdgeColor', color, 'Marker', 'o', 'MarkerSize', 5);
    end
end

function figHandle = plotTSCallsetOverlay(figHandle, imageStruct, color)
    if isempty(imageStruct); return; end
    if isempty(imageStruct.resultsStruct); return; end
    if ~isfield(imageStruct.resultsStruct, 'results_hb'); return; end
    if ~isfield(imageStruct.resultsStruct.results_hb, 'callset'); return; end
    callset = imageStruct.resultsStruct.results_hb.callset;
    if isempty(callset); return; end

    th = imageStruct.resultsStruct.results_hb.threshold;
    callset = callset(callset{:, 'dropout_thresh'} >= th, :);
 
    figHandle = plotCallsetTableCalls(figHandle, imageStruct, callset, color);
end

function figHandle = plotBFCallsetOverlay(figHandle, imageStruct, color)
    if isempty(imageStruct); return; end
    if isempty(imageStruct.resultsStruct); return; end
    if ~isfield(imageStruct.resultsStruct, 'results_bf'); return; end
    if ~isfield(imageStruct.resultsStruct.results_bf, 'callset'); return; end
    callset = imageStruct.resultsStruct.results_bf.callset;
    if isempty(callset); return; end

    th = imageStruct.resultsStruct.results_bf.threshold;
    callset = callset(callset{:, 'dropout_thresh'} >= th, :);
 
    figHandle = plotCallsetTableCalls(figHandle, imageStruct, callset, color);
end

function figHandle = plotRSCallsetOverlay(figHandle, imageStruct, color)
    if isempty(imageStruct); return; end
    if isempty(imageStruct.resultsStruct); return; end
    if ~isfield(imageStruct.resultsStruct, 'results_rs'); return; end
    if ~isfield(imageStruct.resultsStruct.results_rs, 'callset'); return; end
    callset = imageStruct.resultsStruct.results_rs.callset;
    if isempty(callset); return; end

    %Use F-score peak
    scoreTable = imageStruct.resultsStruct.results_rs.benchmarks.BH.performance;
    [~,idx] = max(scoreTable{:, 'fScore'}, [], 'all', 'omitnan');
    th = scoreTable{idx, 'thresholdValue'};
    callset = callset(callset{:, 'dropout_thresh'} >= th, :);
 
    figHandle = plotCallsetTableCalls(figHandle, imageStruct, callset, color);
end

function figHandle = plotDBCallsetOverlay(figHandle, imageStruct, color)
    if isempty(imageStruct); return; end
    if isempty(imageStruct.resultsStruct); return; end
    if ~isfield(imageStruct.resultsStruct, 'results_db'); return; end
    if ~isfield(imageStruct.resultsStruct.results_db, 'callset'); return; end
    callset = imageStruct.resultsStruct.results_db.callset;
    if isempty(callset); return; end

    th = 0.9;
    callset = callset(callset{:, 'dropout_thresh'} >= th, :);
 
    figHandle = plotCallsetTableCalls(figHandle, imageStruct, callset, color);
end

function lut = genGreyscaleLUT()
    [~, lut] = meshgrid(1:3, 1:256);
    lut = lut - 1;
    lut = lut ./ 255.0;
end

function lut = readBinaryLUT(filePath)
    fh = fopen(filePath, 'r');
    lut = fread(fh,[256, 3],'uint8');
    lut = double(lut);
    fclose(fh);
    lut = lut ./ 255.0;
end

