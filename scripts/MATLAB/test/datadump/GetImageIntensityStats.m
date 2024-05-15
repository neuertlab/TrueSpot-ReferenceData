%
%%

function stats = GetImageIntensityStats(loadedImage, analysis, cellMask, xy_rad, z_rad)

    if nargin < 4; xy_rad = 2; end
    if nargin < 5; z_rad = 1; end

    stats = [];
    if isempty(loadedImage); return; end
    if isempty(analysis); return; end
    if isempty(cellMask); return; end

    if ~isfield(analysis, 'results_hb'); return; end
    if ~isfield(analysis.results_hb, 'callset'); return; end

    Z = size(loadedImage, 3);
    Y = size(loadedImage, 1);
    X = size(loadedImage, 2);

    stats = struct();
    stats.minValue = NaN;
    stats.maxValue = NaN;
    stats.overallMean = NaN;
    stats.overallStd = NaN;
    stats.sliceMeans = nan(1, Z);
    stats.sliceStd = nan(1, Z);
    stats.sliceMedian = nan(1, Z);
    stats.bkgMean = nan(1, Z);
    stats.bkgMedian = nan(1, Z);
    stats.bkgStd = nan(1, Z);
    stats.bkgMin = nan(1, Z);
    stats.bkgMax = nan(1, Z);
    stats.cellBkgMean = nan(1, Z);
    stats.cellBkgMedian = nan(1, Z);
    stats.cellBkgStd = nan(1, Z);
    stats.cellBkgMin = nan(1, Z);
    stats.cellBkgMax = nan(1, Z);
    stats.signalMean = NaN;
    stats.signalMedian = NaN;
    stats.signalStd = NaN;
    stats.signalMin = NaN;
    stats.signalMax = NaN;
    stats.signalRegMean = NaN;
    stats.signalRegMedian = NaN;
    stats.signalRegStd = NaN;

    %Get overall slice stats
    fprintf('\t> Calculating overall stats...\n');
    stats.minValue = min(loadedImage, [], 'all', 'omitnan');
    stats.maxValue = max(loadedImage, [], 'all', 'omitnan');
    stats.overallMean = mean(loadedImage, 'all', 'omitnan');
    stats.overallStd = std(loadedImage, 0, 'all', 'omitnan');

    fprintf('\t> Calculating slice stats...\n');
    for z = 1:Z
        myslice = loadedImage(:,:,z);
        stats.sliceMeans(z) = mean(myslice, 'all', 'omitnan');
        stats.sliceStd(z) = std(myslice, 0, 'all', 'omitnan');
        stats.sliceMedian(z) = median(myslice, 'all', 'omitnan');
    end
    clear myslice

    %Derive image background mask (and take stats)
    bkgExObj = Background_Extractor;
    bkgExObj.cell_mask = (cellMask == 0);
    bkgExObj = bkgExObj.initializeMaskLoaded(loadedImage);
    bkgMask = bkgExObj.bkg_mask;
    clear bkgExObj

    bkgMask = double(bkgMask);
    bkgMask(bkgMask == 0) = NaN;

    fprintf('\t> Calculating per-slice image background stats...\n');
    for z = 1:Z
        myslice = immultiply(loadedImage(:,:,z), bkgMask);
        myslice(myslice == 0) = NaN;
        stats.bkgMean(z) = mean(myslice, 'all', 'omitnan');
        stats.bkgStd(z) = std(myslice, 0, 'all', 'omitnan');
        stats.bkgMedian(z) = median(myslice, 'all', 'omitnan');
        stats.bkgMin(z) = min(myslice, [], 'all', 'omitnan');
        stats.bkgMax(z) = max(myslice, [], 'all', 'omitnan');
    end
    clear myslice

    %Get signal stats from call table and threshold
    thVal = analysis.results_hb.threshold;
    callSet = analysis.results_hb.callset;
    keepRows = find(callSet{:, 'dropout_thresh'} >= thVal);
    callCoords = callSet{keepRows, 'coord_1d'};
    pointSet = loadedImage(callCoords);
    stats.signalMean = mean(pointSet, 'all', 'omitnan');
    stats.signalStd = std(pointSet, 0, 'all', 'omitnan');
    stats.signalMedian = median(pointSet, 'all', 'omitnan');
    stats.signalMin = min(pointSet, [], 'all', 'omitnan');
    stats.signalMax = max(pointSet, [], 'all', 'omitnan');
    clear pointSet

    sigMask = false(Y, X, Z);
    xx = callSet{keepRows, 'isnap_x'};
    yy = callSet{keepRows, 'isnap_y'};
    zz = callSet{keepRows, 'isnap_z'};
    sigMask(callCoords) = true;

    for offset = 1:xy_rad
        x2 = min(xx + offset, X);
        ii = sub2ind([Y X Z], yy, x2, zz);
        sigMask(ii) = true;

        x2 = max(xx - offset, 1);
        ii = sub2ind([Y X Z], yy, x2, zz);
        sigMask(ii) = true;
    end
    clear x2

    for offset = 1:xy_rad
        y2 = min(yy + offset, Y);
        ii = sub2ind([Y X Z], y2, xx, zz);
        sigMask(ii) = true;

        y2 = max(yy - offset, 1);
        ii = sub2ind([Y X Z], y2, xx, zz);
        sigMask(ii) = true;
    end
    clear y2

    for offset = 1:z_rad
        z2 = min(zz + offset, Z);
        ii = sub2ind([Y X Z], yy, xx, z2);
        sigMask(ii) = true;

        z2 = max(zz - offset, 1);
        ii = sub2ind([Y X Z], yy, xx, z2);
        sigMask(ii) = true;
    end
    clear z2

    sigMask = double(sigMask);
    sigMask(sigMask == 0) = NaN;
    sigRegVals = immultiply(loadedImage, sigMask);
    stats.signalRegMean = mean(sigRegVals, 'all', 'omitnan');
    stats.signalRegStd = std(sigRegVals, 0, 'all', 'omitnan');
    stats.signalRegMedian = median(sigRegVals, 'all', 'omitnan');

    %Derive cell background mask (try to remove signal)
    cellMaskBool = (cellMask > 0);
    for z = 1:Z
        myslice = loadedImage(:,:,z);
        slice_bkg = medfilt2(myslice, [20 20]); 
        slice_bkg = immultiply(double(slice_bkg), double(cellMaskBool));
        slice_bkg(slice_bkg == 0) = NaN;
        stats.cellBkgMean(z) = mean(slice_bkg, 'all', 'omitnan');
        stats.cellBkgStd(z) = std(slice_bkg, 0, 'all', 'omitnan');
        stats.cellBkgMedian(z) = median(slice_bkg, 'all', 'omitnan');
        stats.cellBkgMin(z) = min(slice_bkg, [], 'all', 'omitnan');
        stats.cellBkgMax(z) = max(slice_bkg, [], 'all', 'omitnan');
    end
    clear myslice
    
end