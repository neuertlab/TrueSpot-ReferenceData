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

% ========================== Groups to Show ==========================

%Types:
%   0 - All transcripts in cell
%   1 - Nucleus only (w/nascent)
%   2 - Cytoplasm only
%   3 - Non-nascent nucleus
%   4 - Nascent nucleus

SingleGene = 'STL1';

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

for ff = 1:fileCount
    fTable = readTableFile([ImportDir filesep ImportFiles{ff}]);
    if isempty(fTable); continue; end

    %For each target...
    for tt = 1:targetCount
        myTarget = TargetGroups{tt};
        %TODO
    end

end

% ========================== Helper Functions ==========================

function table = readTableFile(path)
    fmtString = [repmat('%s', 1, 4) repmat('%d', 1, 5) repmat('%f', 1, 2) repmat('%d', 1, 6)];
    table = readtable(path,'Delimiter','\t','ReadVariableNames',true,'Format', fmtString);
end

function [timeVal, timeStr] = tpFromName(imgname)
%This varies depending upon the set.
%TODO
end



