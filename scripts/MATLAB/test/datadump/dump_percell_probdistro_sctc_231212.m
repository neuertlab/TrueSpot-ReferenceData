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

% ========================== General Context ==========================

scriptCtx = genScriptContextStruct(BaseDir);
scriptCtx.ImgProcDir = ImgProcDir;
scriptCtx.ImgDir = ImgDir;

scriptCtx.DateSuffix = '231215';
scriptCtx.OutputDir = [ImgProcDir filesep 'tables'];

% ========================== Parameters ==========================

TablePath_Main = [BaseDir filesep 'test_images.csv'];
TablePath_Mass = [BaseDir filesep 'test_images_simvarmass.csv'];
TablePath_YTC = [BaseDir filesep 'test_images_simytc.csv'];

AllTablePaths = {TablePath_Main};
ImgTableCount = size(AllTablePaths, 2);

COLOR_HB = [0.667 0.220 0.220];
COLOR_BF = [0.231 0.231 0.702]; %#3b3bb3
COLOR_RS = [0.318 0.541 0.318]; %#518a51
COLOR_DB = [0.700 0.700 0.000];

colnames = {'IMGNAME' 'GROUP' 'CELLNO'...
    'COUNT_HB' 'COUNT_BF' 'COUNT_RS' 'COUNT_DB'...
    'COUNT_BH' 'COUNT_BK' 'TH_RS' 'TH_DB'...
    'CVG_XY_HB' 'CVG_Z_HB' 'CVG_XY_BF' 'CVG_Z_BF'...
    'CVG_XY_RS' 'CVG_Z_RS' 'CVG_XY_DB' 'CVG_Z_DB'...
    'CVG_XY_BH' 'CVG_Z_BH' 'CVG_XY_BK' 'CVG_Z_BK'};
coltypes = {'string' 'string' 'uint16'...
    'uint32' 'uint32' 'uint32' 'uint32'...
    'uint32' 'uint32' 'single' 'single'...
    'single' 'single' 'single' 'single'...
    'single' 'single' 'single' 'single'...
    'single' 'single' 'single' 'single'};
colcount = size(colnames, 2);

allTimepoints = [0 1 2 4 6 8 10 15 20 25 30 35 40 45 50 55 60];
MAXCOL = 6;
EXP =  1;
REP = [1 2];
CH = 2;

% ========================== Main Loop ==========================

table_file_path = [scriptCtx.OutputDir filesep 'exp_percell_counts_' scriptCtx.DateSuffix '.csv'];

tblfmt = '';
for i = 1:colcount
    coltype = coltypes{i};
    colname = colnames{i};

    if strcmp(coltype, 'single') | strcmp(coltype, 'double')
        tblfmt = [tblfmt '%f'];
    elseif strcmp(coltype, 'string')
        tblfmt = [tblfmt '%s'];
    elseif contains(coltype, 'uint')
        tblfmt = [tblfmt '%d'];
    end
end

count_table = readtable(table_file_path,'Delimiter',',',...
    'ReadVariableNames',true,'Format', tblfmt);

ref_table_file_path = [scriptCtx.OutputDir filesep 'LiNeuert_sctc.csv'];
ref_table = readtable(ref_table_file_path,'Delimiter',',',...
    'ReadVariableNames',true,'Format', '%d%d%d%d%d%d%d');

timepointCount = size(allTimepoints, 2);
colCount = MAXCOL;
if timepointCount < MAXCOL
    colCount = timepointCount;
end
rowCount = ceil(timepointCount ./ colCount);

rr = 0;
cc = 0;
x_space = 0.015;
y_space = 0.055;
ww = (1.0 / colCount) - (x_space * 1.5);
hh = (1.0 / rowCount) - (y_space * 1.5);
xx = x_space * 2;
yy = 1.0 - hh - y_space;

fh = [];
for t = 1:timepointCount
    %TODO Skip empty time points
    subpos = [xx yy ww hh];

    %onLeft = mod((t - 1), colCount) == 0;
    onLeft = (cc == 0);
    fh = genFigure(count_table, ref_table, EXP, REP, CH, allTimepoints(t), ...
        fh, subpos, onLeft, (t == timepointCount));

    cc = cc + 1;
    xx = xx + ww + x_space;
    if cc >= colCount
        cc = 0;
        rr = rr + 1;
        xx = x_space * 2;
        yy = yy - hh - y_space;
    end
end

% ========================== Functions ==========================

function ctx = genScriptContextStruct(basedir)
    ctx = struct('BaseDir', basedir);
    ctx.ImgProcDir = basedir;
    ctx.ImgDir = basedir;
    ctx.ResultsDir = [basedir filesep 'data' filesep 'results'];
    ctx.ResultsPath = [basedir filesep 'data' filesep 'results'];
    ctx.OutputDir = basedir;
    ctx.ImageInfoTable = table.empty();
    ctx.TableRow = 0;
    ctx.DateSuffix = '000000';
end

function fighandle = genFigure(mytable, reftable, exp, reps, channel, timepoint, fighandle, subplotpos, showYLabel, showLegend)
    SCALE_XY = true;
    SCALE_Z = true;

    INCL_RS = true;
    INCL_DB = true;
    COLOR_RS = [0.318 0.541 0.318]; %#518a51
    COLOR_DB = [0.700 0.700 0.000];
    LINE_TYPES = {'-' '--' ':'};

    colors = NaN(5,3);
    colors(5,:) = [0 0 0];
    colors(1,:) = [1 0 0];
    colors(2,:) = [0 0 1];
    colors(3,:) = COLOR_RS;
    colors(4,:) = COLOR_DB;

    xmin = 0;
    xmax = 150;
    xincr = 10;
    x = [xmin:xincr:xmax];
    binEdges = [(x - (xincr ./ 2)) (xmax + 5)];

    repCount = size(reps, 2);
    repOkay = false(1,repCount);
    toolCount = 3;
    if INCL_RS; toolCount = toolCount + 1; end
    if INCL_DB; toolCount = toolCount + 1; end
    storedLines = cell(repCount, toolCount);
    for r = 1:repCount
        rep = reps(r);
        groupname = ['sctc_E' num2str(exp) 'R' num2str(rep)...
            'C' num2str(channel) '_' num2str(timepoint) 'min'];

        groupRows = find(strcmp(mytable{:,'GROUP'}, groupname));
        if isempty(groupRows); continue; end
        repOkay(r) = true;

        groupEntries = mytable(groupRows, :);

        hb_counts = double(groupEntries{:, 'COUNT_HB'});
        bf_counts = double(groupEntries{:, 'COUNT_BF'});
        rs_counts = double(groupEntries{:, 'COUNT_RS'});
        db_counts = double(groupEntries{:, 'COUNT_DB'});

        if SCALE_XY
            hb_counts = round(hb_counts ./ groupEntries{:, 'CVG_XY_HB'});
            bf_counts = round(bf_counts ./ groupEntries{:, 'CVG_XY_BF'});
            rs_counts = round(rs_counts ./ groupEntries{:, 'CVG_XY_RS'});
            db_counts = round(db_counts ./ groupEntries{:, 'CVG_XY_DB'});
        end

        if SCALE_Z
            hb_counts = round(hb_counts ./ groupEntries{:, 'CVG_Z_HB'});
            bf_counts = round(bf_counts ./ groupEntries{:, 'CVG_Z_BF'});
            rs_counts = round(rs_counts ./ groupEntries{:, 'CVG_Z_RS'});
            db_counts = round(db_counts ./ groupEntries{:, 'CVG_Z_DB'});
        end

        ingroup = (reftable{:,'EXP'} == exp);
        ingroup = and(ingroup, (reftable{:,'REP'} == rep));
        ingroup = and(ingroup, (reftable{:,'CH'} == channel));
        ingroup = and(ingroup, (reftable{:,'TIME'} == timepoint));
        groupRows = find(ingroup);
        refEntries = reftable(groupRows, :);
        ref_counts = (refEntries{:, 'TOTAL'});

        [y_hb, ~] = histcounts(hb_counts, binEdges);
        [y_bf, ~] = histcounts(bf_counts, binEdges);
        [y_rs, ~] = histcounts(rs_counts, binEdges);
        [y_db, ~] = histcounts(db_counts, binEdges);
        [y_ref, ~] = histcounts(ref_counts, binEdges);

        cellCount = size(groupEntries, 1);
        y_hb = y_hb ./ cellCount;
        y_bf = y_bf ./ cellCount;
        y_rs = y_rs ./ cellCount;
        y_db = y_db ./ cellCount;

        cellCount = size(refEntries, 1);
        y_ref = y_ref ./ cellCount;

        if isempty(fighandle)
            fighandle = figure(1);
            clf;
            title(groupname);
            hold on;
        end

        linewidth = 1.5;
        legendNames = {'TrueSpot' 'Big-FISH' '' '' ''};
        li = 3;

        %subplot(figrows, figcols, subfigno);
        subplot('Position', subplotpos);
        hold on;
        storedLines{r, 1} = plot(x, y_hb, 'LineWidth', linewidth, ...
            'LineStyle', LINE_TYPES{r}, 'Color', [1 0 0]);
        storedLines{r, 2} = plot(x, y_bf, 'LineWidth', linewidth, ...
            'LineStyle', LINE_TYPES{r}, 'Color', [0 0 1]);

        if INCL_RS
            storedLines{r, li} = plot(x, y_rs, 'LineWidth', linewidth, ...
                'LineStyle', LINE_TYPES{r}, 'Color', COLOR_RS);
            legendNames{li} = 'RS-FISH';
            li = li+1;
        end

        if INCL_DB
            storedLines{r, li} = plot(x, y_db, 'LineWidth', linewidth, ...
                'LineStyle', LINE_TYPES{r}, 'Color', COLOR_DB);
            legendNames{li} = 'DeepBlink';
            li = li+1;
        end

        storedLines{r, li} = plot(x, y_ref, 'LineWidth', linewidth, ...
            'LineStyle', LINE_TYPES{r}, 'Color', [0 0 0]);
        legendNames{li} = 'Li & Neuert';
    end

    %Polygons
    repOkayCount = nnz(repOkay);
    if repOkayCount > 2
        %Shade avg +- stdev
        for t = 1:toolCount
            all_y = NaN(repCount, size(x, 2));
            for r = 1:repCount
                if repOkay(r)
                    line = storedLines{r, t};
                    all_y(r,:) = line.YData;
                    clear line
                end
            end

            avgY = mean(all_y, 1, 'omitnan');
            stdY = std(all_y, 0, 1, 'omitnan');
            y_hi = avgY + stdY;
            y_lo = avgY - stdY;
            plot(x, avgY, 'LineWidth', linewidth, ...
                'LineStyle', '-.', 'Color', colors(t, :));

            xx = [x flip(x)];
            yy = [y_lo flip(y_hi)];
            poly = polyshape(xx, yy);
            polyp = plot(poly);
            polyp.FaceColor = colors(t, :);
            polyp.FaceAlpha = 0.33;
            polyp.LineStyle = 'none';
            
            clear y_hi y_lo poly polyp xx yy all_y avgY stdY
        end
    elseif repOkayCount == 2
        %Shade between the two lines
        for t = 1:toolCount
            line1 = storedLines{find(repOkay, 1, 'first'), t};
            line2 = storedLines{find(repOkay, 1, 'last'), t};
            y_hi = max(line1.YData, line2.YData);
            y_lo = min(line1.YData, line2.YData);

            xx = [x flip(x)];
            yy = [y_lo flip(y_hi)];
            poly = polyshape(xx, yy);
            polyp = plot(poly);
            polyp.FaceColor = colors(t, :);
            polyp.FaceAlpha = 0.33;
            polyp.LineStyle = 'none';
            
            clear line1 line2 y_hi y_lo poly polyp xx yy
        end
    end

    xlim([xmin, xmax]);
    ylim([0,1]);
    title([num2str(timepoint) ' min']);

    %if showLegend; legend(legendNames); end

    if ~showYLabel
        set(gca,'YTickLabel',[]);
    end

end
