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

SimResCSVPath = [BaseDir filesep 'sim_results.csv'];

DateDir = '20230913';
DateSuffix = '230913';
OutDir = [ImgProcDir filesep 'figures' filesep DateDir];

% ========================== Parameters ==========================

% ========================== Read Table ==========================

fmt_string = ['%s' repmat('%f', 1, 6) '%s' repmat('%f', 1, 47)];
simres_table = readtable(SimResCSVPath,'Delimiter',',','ReadVariableNames',true,'Format',...
    fmt_string);

% ========================== Do plot ==========================

entry_count = size(simres_table,1);
mtx = NaN(entry_count, 5);

xlbl = {'HBTr' 'BFTr' 'RSTr' 'DBTr' 'DBAltTr'};

%Recall Max

mtx(:,1) = simres_table{:, 'HBTr_MAXREC'};
%mtx(:,2) = simres_table{:, 'HB_MAXREC'};
mtx(:,2) = simres_table{:, 'BFTr_MAXREC'};
mtx(:,3) = simres_table{:, 'RSTr_MAXREC'};
mtx(:,4) = simres_table{:, 'DBTr_MAXREC'};
mtx(:,5) = simres_table{:, 'DBALTTr_MAXREC'};

fig_handle = doHeatmap(1, mtx, xlbl);
xlabel('Tool');

%PRAUC

mtx(:,1) = simres_table{:, 'PRAUC_HBTr'};
%mtx(:,2) = simres_table{:, 'PRAUC_HB'};
mtx(:,2) = simres_table{:, 'PRAUC_BFTr'};
mtx(:,3) = simres_table{:, 'PRAUC_RSTr'};
mtx(:,4) = simres_table{:, 'PRAUC_DBTr'};
mtx(:,5) = simres_table{:, 'PRAUC_DBALTTr'};

fig_handle = doHeatmap(2, mtx, xlbl);
xlabel('Tool');

%FScores
mtx = NaN(entry_count, 4);
xlbl = {'HBTr' 'HB' 'BFTr' 'BF'};

mtx(:,1) = simres_table{:, 'HBTr_FSCORE'};
mtx(:,2) = simres_table{:, 'HB_FSCORE'};
mtx(:,3) = simres_table{:, 'BFTr_FSCORE'};
mtx(:,4) = simres_table{:, 'BF_FSCORE'};

fig_handle = doHeatmap(3, mtx, xlbl);
xlabel('Tool');

% ========================== Helper functions ==========================

function fig_handle = doHeatmap(figno, heatmtx, xlbl)

    %Replace NaNs with 0.0
    heatmtx(isnan(heatmtx)) = 0.0;

    %Sort rows
    heatmtx = sortrows(heatmtx,1);
    
    ycount = size(heatmtx,1);
    ylbl = NaN(1,ycount);
    for i = 1:ycount; ylbl(i) = i; end
    fig_handle = figure(figno);
    clf;
    hm = heatmap(xlbl, ylbl, heatmtx);
    hm.Colormap = turbo;
    hm.ColorLimits = [0.0 1.0];
    hm.CellLabelColor = 'none';
    hm.GridVisible = 'off';
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end
