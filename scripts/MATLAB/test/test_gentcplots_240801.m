%
%%

addpath('./core');
addpath('./plots');

% ========================== I/O Info ==========================

ImportDir = 'D:\Users\hospelb\labdata\RNAFISH\Analysis';
ImportFiles = {'JA20240510\cellCounts.tsv' 'JA20240514\cellCounts.tsv' ...
    'JA20240604\cellCounts.tsv' 'JA20240606\cellCounts.tsv'};

% ========================== Some Neat Colors ==========================

CLR_MAGENTA = [1.000 0.000 1.000];
CLR_INDIGO = [0.231 0.212 0.737];
CLR_GREEN = [0.325 0.737 0.212];
CLR_CYAN = [0.000 0.800 0.800];

CLR_GREY1 = [0.678 0.678 0.678];
CLR_GREY2 = [0.400 0.400 0.400];
CLR_GREY3 = [0.222 0.222 0.222];

CLR_BLUEGREY1 = [0.000 0.443 0.569];
CLR_BLUEGREY2 = [0.553 0.737 0.788];

% ========================== Other Settings ==========================

TimeUnitName = 'min';

XMAX = 75;
YMAX = 0.5;
BINSIZE = 5;

AUTO_X = false; %If this is set, don't use XMAX

INCL_LI_NEUERT = true;
LI_NEUERT_CSV_PATH = 'D:\Users\hospelb\labdata\imgproc\imgproc\tables\LiNeuert_sctc.csv';

% ========================== Groups to Show ==========================

%Types:
%   0 - All transcripts in cell
%   1 - Nucleus only (w/nascent)
%   2 - Cytoplasm only
%   3 - Non-nascent nucleus
%   4 - Nascent nucleus

SingleGene = 'STL1';

TargetGroups = {struct('name', SingleGene, 'baseColor', CLR_MAGENTA, 'txtype', 0) ...
                struct('name', SingleGene, 'baseColor', CLR_GREEN, 'txtype', 2) ...
                struct('name', SingleGene, 'baseColor', CLR_INDIGO, 'txtype', 1) ...
                struct('name', SingleGene, 'baseColor', CLR_CYAN, 'txtype', 4)};

% ========================== Process ==========================

%Storage index: replicate, target -> struct with a list of counts for each
%time point
%Just collect counts for each and store in big cell table

fileCount = size(ImportFiles, 2);
targetCount = size(TargetGroups, 2);
impLiNeuert = INCL_LI_NEUERT & (strcmp(SingleGene, 'STL1') | strcmp(SingleGene, 'CTT1'));

if impLiNeuert
    countStorage = cell(fileCount + 5, targetCount);
else
    countStorage = cell(fileCount, targetCount);
end
utp = [];

if AUTO_X
    XMAX = 0;
end

for ff = 1:fileCount
    fTable = readTableFile([ImportDir filesep ImportFiles{ff}]);
    if isempty(fTable); continue; end

    %For each target...
    for tt = 1:targetCount
        ctStore = struct();
        myTarget = TargetGroups{tt};
        %Filter table down to just target

        trecords = fTable(strcmp(fTable{:, 'TARGET'}, myTarget.name),:);
        if isempty(trecords); continue; end

        %Determine timepoint assignments
        [timeVal, ~] = tpFromName(trecords{:, 'x_SRCIMGNAME'}, TimeUnitName);
        uniqueTimes = unique(timeVal');
        utp = unique([utp uniqueTimes]);

        localTPCount = size(uniqueTimes, 2);
        for tpi = 1:localTPCount
            tpinfo = struct('timeval', uniqueTimes(tpi));
            tpStr = getTPStr(uniqueTimes(tpi), TimeUnitName);
            recSubset = trecords(timeVal(:,1) == uniqueTimes(tpi),:);
            if isempty(recSubset); continue; end
            if myTarget.txtype == 0
                %Cell total
                ctvec = recSubset{:, 'EST_COUNT_NUC'} + recSubset{:, 'EST_COUNT_NUC_CLOUD'}...
                    + recSubset{:, 'EST_COUNT_CYTO'} + recSubset{:, 'EST_COUNT_CYTO_CLOUD'};
            elseif myTarget.txtype == 1
                %Nucleus only (all)
                ctvec = recSubset{:, 'EST_COUNT_NUC'} + recSubset{:, 'EST_COUNT_NUC_CLOUD'};
            elseif myTarget.txtype == 2
                %Cytoplasm only
                ctvec = recSubset{:, 'EST_COUNT_CYTO'} + recSubset{:, 'EST_COUNT_CYTO_CLOUD'};
            elseif myTarget.txtype == 3
                %Nucleus only (w/o nascent)
                ctvec = (recSubset{:, 'EST_COUNT_NUC'} - recSubset{:, 'EST_NASCENT_COUNT_NUC'}) +...
                    (recSubset{:, 'EST_COUNT_NUC_CLOUD'} - recSubset{:, 'EST_NASCENT_COUNT_NUC_CLOUD'});
            elseif myTarget.txtype == 4
                ctvec = recSubset{:, 'EST_NASCENT_COUNT_NUC'} + recSubset{:, 'EST_NASCENT_COUNT_NUC_CLOUD'};
            else
                fprintf('ERROR: Target type %d not recognized!\t', myTarget.txtype);
                break;
            end
            tpinfo.ctvec = ctvec';
            ctStore.(tpStr) = tpinfo;

            if AUTO_X
                localxMax = ProbDistroPlots.suggestXMax(tpinfo.ctvec, BINSIZE);
                if localxMax > XMAX; XMAX = localxMax; end
                clear localxMax;
            end
        end
        countStorage{ff, tt} = ctStore;
    end
end
clear ctStore ctvec ff fTable recSubset tpStr tpinfo timeVal uniqueTimes trecords

if AUTO_X
    fprintf('X max set to: %d\n', XMAX);
end

if impLiNeuert
    %Import control, if requested.
    ch = 1;
    if strcmp(SingleGene, 'STL1'); ch = 2; end
    [countStorage, utp] = importLiNeuertTable(LI_NEUERT_CSV_PATH,...
        countStorage, TargetGroups, fileCount, utp, ch, TimeUnitName);
end

%Remove replicates with no data (check rows)
%https://stackoverflow.com/questions/3400515/how-do-i-detect-empty-cells-in-a-cell-array
usedCells = ~cellfun('isempty', countStorage);
rowUsed = sum(usedCells, 2);
countStorage = countStorage((rowUsed > 0), :);
repCount = size(countStorage, 1);
clear usedCells rowUsed

%Prep plotter settings
plotter = ProbDistroPlots;
plotter.xMax = XMAX;
plotter.yMax = YMAX;
plotter.binSize = BINSIZE;
plotter.timeUnit = TimeUnitName;

plotter.timePoints = utp;
plotter.targets = cell(1, targetCount);
for tt = 1:targetCount
    myTarget = TargetGroups{tt};
    targInfo = ProbDistroPlots.genTargetInfoStruct(repCount);
    targInfo.name = myTarget.name;
    if myTarget.txtype == 0
        targInfo.subtitle = 'Total';
    elseif myTarget.txtype == 1
        targInfo.subtitle = 'Nucleus';
    elseif myTarget.txtype == 2
        targInfo.subtitle = 'Cytoplasm';
    elseif myTarget.txtype == 3
        targInfo.subtitle = 'Nucleus (Mature)';
    elseif myTarget.txtype == 4
        targInfo.subtitle = 'Nucleus (Nascent)';
    end
    targInfo.colors = getColorsFromBase(myTarget.baseColor, repCount);

    if impLiNeuert
        %Add LiNeuert styling to last 5 reps.
        rr = repCount - 4;
        for j = 1:2
            targInfo.repNames{rr} = ['0.2M R' num2str(j)];
            targInfo.lineStyle{rr} = '--';
            if j == 1
                targInfo.colors(rr, :) = CLR_BLUEGREY1;
            elseif j == 2
                targInfo.colors(rr, :) = CLR_BLUEGREY2;
            end
            rr = rr + 1;
        end

        for j = 1:3
            targInfo.repNames{rr} = ['0.4M R' num2str(j)];
            targInfo.lineStyle{rr} = '--';
            if j == 1
                targInfo.colors(rr, :) = CLR_GREY1;
            elseif j == 2
                targInfo.colors(rr, :) = CLR_GREY2;
            elseif j == 3
                targInfo.colors(rr, :) = CLR_GREY3;
            end
            rr = rr + 1;
        end
    end

    plotter.targets{tt} = targInfo;
end
plotter = plotter.reallocateDataMtx();
clear j  myTarget targInfo

tpCount = size(utp, 2);
for rr = repCount:-1:1
    for tt = 1:targetCount
        ctStore = countStorage{rr, tt};
        for tpi = 1:tpCount
            sname = getTPStr(utp(tpi), TimeUnitName);
            if isfield(ctStore, sname)
                ctvec = ctStore.(sname).ctvec;
                plotter = plotter.loadRawCountSet(ctvec, tt, tpi, rr);
            end
        end
    end
end
clear rr tt tpi tpCount ctStore ctvec sname

figh = figure(1);
[plotter, figh] = plotter.render(figh);
 
% ========================== Helper Functions ==========================

function colors = getColorsFromBase(baseColor, count)
%     colors = zeros(count, 3);
%     colors(1,:) = baseColor;
% 
%     stepUp = (1.0 - baseColor) ./ count;
%     stepDown = baseColor ./ count;
%     upLast = baseColor;
%     downLast = baseColor;
% 
%     for i = 2:count
%         if mod(i,2) ~= 0
%             %Down
%             downLast = downLast - stepDown;
%             colors(i,:) = downLast;
%         else
%             %Up
%             upLast = upLast + stepUp;
%             colors(i,:) = upLast;
%         end
%     end

    dark = VisCommon.generateDarkColors(count + 2, baseColor);
    light = VisCommon.generateLightColors(count + 2, baseColor);

    colors = zeros(count, 3);
    colors(1,:) = baseColor;
    d = 2; l = 2;
    for i = 2:count
        if mod(i,2) ~= 0
            colors(i, :) = dark(d, :);
            d = d + 1;
        else
            colors(i, :) = light(l, :);
            l = l + 1;
        end
    end
end

function table = readTableFile(path)
    fmtString = [repmat('%s', 1, 4) repmat('%d', 1, 5) repmat('%f', 1, 2) repmat('%d', 1, 6)];
    table = readtable(path,'Delimiter','\t','ReadVariableNames',true,'Format', fmtString, 'FileType', 'text');
end

function timeStr = getTPStr(ival, unit)
    timeStr = [unit '_' num2str(ival)];
    timeStr = replace(timeStr, '.', 'pt');
end

function [timeVal, timeStr] = tpFromName(imgname, timeUnit)
%This varies depending upon the set.
%Can also take a vector of image names
    timePattern = '_' + asManyOfPattern(digitsPattern) + timeUnit + '_';
    timePiece = extract(imgname, timePattern);
    timePiece = replace(timePiece, '_', '');
    timePiece = replace(timePiece, timeUnit, '');
    timeStr = string(timePiece);
    timeVal = str2double(timeStr);

    %This part is specific to certain sets. Change if needed
    timeVal(timeVal == 75) = 7.5;
end

function [countStorage, utp] = importLiNeuertTable(tablePath, countStorage, TargetGroups, fileCount, utp, ch, TimeUnitName)
    %Find matching targets
    targetCount = size(TargetGroups, 2);
    cytoTrg = 0;
    nucTrg = 0;
    totTrg = 0;
    trgName = 'CTT1';
    if(ch == 2); trgName = 'STL1'; end
    for tt = 1:targetCount
        tg = TargetGroups{tt};
        if strcmp(tg.name, trgName)
            if tg.txtype == 0
                totTrg = tt;
            elseif tg.txtype == 1
                nucTrg = tt;
            elseif tg.txtype == 2
                cytoTrg = tt;
            end
        end
    end

    expReps = [[1,1];[1,2];[2,1];[2,2];[2,3]];
    expRepCount = size(expReps, 1);

    fmtString = repmat('%d', 1, 7);
    table = readtable(tablePath,'ReadVariableNames',true,'Format', fmtString);
    table = table(table{:,'CH'} == ch, :);

    for i = 1:expRepCount
        storeSlot = fileCount + i;
        ctStoreNuc = struct();
        ctStoreTot = struct();
        ctStoreCyto = struct();

        expNo = expReps(i, 1);
        repNo = expReps(i, 2);
        myTable = table(table{:,'EXP'} == expNo, :);
        myTable = myTable(myTable{:,'REP'} == repNo, :);

        uniqueTimes = unique(double(myTable{:, 'TIME'}))';
        %utp = unique([utp uniqueTimes]);

        localTPCount = size(uniqueTimes, 2);
        for tpi = 1:localTPCount
            myTime = uniqueTimes(tpi);
            tpinfo = repmat(struct('timeval', myTime, 'ctvec', []), 1, 3);
            tpStr = getTPStr(myTime, TimeUnitName);

            recSubset = myTable(myTable{:, 'TIME'} == myTime,:);
            if isempty(recSubset); continue; end

            ctVecNuc = recSubset{:, 'NUC'};
            ctVecTotal = recSubset{:, 'TOTAL'};
            ctVecCyto = ctVecTotal - ctVecNuc;

            tpinfo(1).ctvec = ctVecNuc';
            tpinfo(2).ctvec = ctVecCyto';
            tpinfo(3).ctvec = ctVecTotal';

            ctStoreNuc.(tpStr) = tpinfo(1);
            ctStoreCyto.(tpStr) = tpinfo(2);
            ctStoreTot.(tpStr) = tpinfo(3);
        end

        %Save to matching targets
        if cytoTrg > 0
            countStorage{storeSlot, cytoTrg} = ctStoreCyto;
        end
        if nucTrg > 0
            countStorage{storeSlot, nucTrg} = ctStoreNuc;
        end
        if totTrg > 0
            countStorage{storeSlot, totTrg} = ctStoreTot;
        end

    end
end

