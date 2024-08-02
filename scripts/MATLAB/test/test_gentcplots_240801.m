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
CLR_CYAN = [0.000 1.000 1.000];

% ========================== Other Settings ==========================

TimeUnitName = 'min';

XMAX = 150;
YMAX = 1.0;
BINSIZE = 10;

% ========================== Groups to Show ==========================

%Types:
%   0 - All transcripts in cell
%   1 - Nucleus only (w/nascent)
%   2 - Cytoplasm only
%   3 - Non-nascent nucleus
%   4 - Nascent nucleus

SingleGene = 'HSP12';

TargetGroups = {struct('name', SingleGene, 'baseColor', CLR_MAGENTA, 'txtype', 0) ...
                struct('name', SingleGene, 'baseColor', CLR_INDIGO, 'txtype', 1) ...
                struct('name', SingleGene, 'baseColor', CLR_GREEN, 'txtype', 2) ...
                struct('name', SingleGene, 'baseColor', CLR_CYAN, 'txtype', 4)};

% ========================== Process ==========================

%Storage index: replicate, target -> struct with a list of counts for each
%time point
%Just collect counts for each and store in big cell table

fileCount = size(ImportFiles, 2);
targetCount = size(TargetGroups, 2);

countStorage = cell(fileCount, targetCount);
utp = [];

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
        end
        countStorage{ff, tt} = ctStore;
    end
end

%Remove replicates with no data (check rows)
%https://stackoverflow.com/questions/3400515/how-do-i-detect-empty-cells-in-a-cell-array
usedCells = ~cellfun('isempty', countStorage);
rowUsed = sum(usedCells, 2);
countStorage = countStorage((rowUsed > 0), :);
repCount = size(countStorage, 1);

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
    plotter.targets{tt} = targInfo;
end
plotter = plotter.reallocateDataMtx();

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

figh = figure(1);
[plotter, figh] = plotter.render(figh);
 
% ========================== Helper Functions ==========================

function colors = getColorsFromBase(baseColor, count)
    colors = zeros(count, 3);
    colors(1,:) = baseColor;

    stepUp = (1.0 - baseColor) ./ count;
    stepDown = baseColor ./ count;
    upLast = baseColor;
    downLast = baseColor;

    for i = 2:count
        if mod(i,2) ~= 0
            %Down
            downLast = downLast - stepDown;
            colors(i,:) = downLast;
        else
            %Up
            upLast = upLast + stepUp;
            colors(i,:) = upLast;
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



