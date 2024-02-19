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

OutputDir = [BaseDir filesep 'figures' filesep 'group_prc'];
ResultsDir = [BaseDir filesep 'data' filesep 'results'];

RS_TLUT = [0.0004:0.0004:0.1];
DB_TLUT = [0.01:0.01:1.0];

COLOR_HB = [0.667 0.220 0.220];
COLOR_BF = [0.231 0.231 0.702]; %#3b3bb3
COLOR_RS = [0.318 0.541 0.318]; %#518a51
COLOR_DB = [0.700 0.700 0.000];

COLORS = [COLOR_HB; 
    COLOR_BF;
    COLOR_RS;
    COLOR_DB];

% ========================== Parameters ==========================

TablePath = [BaseDir filesep 'test_images.csv'];

DoGroup = 'CTT1_CY5';

% ========================== Main Loop ==========================

used_th_range = NaN(2,4); %Rows are min, max. Cols are tool.

image_table = testutil_opentable(TablePath);
entry_count = size(image_table, 1);

multifighandle = figure(1);
clf;
i = 1;

T = 2000;
totals = double(zeros(T, 4, 4)); %Th val, cols, tool
%Cols: Th val, tp, fp, fn
totals(:,1,1) = 1:T;
totals(:,1,2) = 1:T;

lutsize = size(RS_TLUT,2);
totals(1:lutsize,1,3) = RS_TLUT';
lutsize = size(DB_TLUT,2);
totals(1:lutsize,1,4) = DB_TLUT';

for r = 1:entry_count
    scriptCtx.TableRow = r;

    myname = getTableValue(image_table, r, 'IMGNAME');
    fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);

    %See if in group of interest
    groupname = getGroupName(myname);
    if ~strcmp(groupname, DoGroup)
        fprintf('> Not part of current group. Skipping...\n');
        continue;
    end

    set_group_dir = getSetOutputDirName(myname);
    ResFilePath = [ResultsDir filesep set_group_dir filesep myname '_summary.mat'];

    if isfile(ResFilePath)
        load(ResFilePath, 'analysis');
    else
        fprintf('> Could not find analysis file. Skipping...\n');
        continue;
    end

    if isfield(analysis, 'refsets')
        %Add to totals
        subplot(2,4,i);
        hold on;

        if isfield(analysis, 'results_hb')
            countTable = getCounts(analysis.results_hb, []);
            tblrows = size(countTable, 1);
            if tblrows > T
                %Reallocate
                temp = double(zeros(tblrows, 4, 4));
                temp(1:T,:,:) = totals(:,:,:);
                totals = temp;

                T = tblrows;
                clear temp
            end

            totals(1:tblrows,2:4,1) = totals(1:tblrows,2:4,1) + countTable(:, 2:4);
            precision = countTable(:,2) ./ (countTable(:,2) + countTable(:,3));
            recall = countTable(:,2) ./ (countTable(:,2) + countTable(:,4));
            plot(recall,precision,'Color',COLOR_HB,'LineWidth',1.5,'LineStyle','-');

            [minth, maxth] = getMinAndMaxUsedTh(analysis.results_hb);
            if isnan(used_th_range(1,1)) | minth > used_th_range(1,1)
                used_th_range(1,1) = minth;
            end
            if isnan(used_th_range(2,1)) | maxth < used_th_range(2,1)
                used_th_range(2,1) = maxth;
            end
            clear minth maxth
        end

        if isfield(analysis, 'results_bf')
            countTable = getCounts(analysis.results_bf, []);
            tblrows = size(countTable, 1);
            if tblrows > T
                %Reallocate
                temp = double(zeros(tblrows, 4, 4));
                temp(1:T,:,:) = totals(:,:,:);
                totals = temp;

                T = tblrows;
                clear temp
            end

            totals(1:tblrows,2:4,2) = totals(1:tblrows,2:4,2) + countTable(:, 2:4);
            precision = countTable(:,2) ./ (countTable(:,2) + countTable(:,3));
            recall = countTable(:,2) ./ (countTable(:,2) + countTable(:,4));
            plot(recall,precision,'Color',COLOR_BF,'LineWidth',1.5,'LineStyle','-');

            [minth, maxth] = getMinAndMaxUsedTh(analysis.results_bf);
            if isnan(used_th_range(1,2)) | minth > used_th_range(1,2)
                used_th_range(1,2) = minth;
            end
            if isnan(used_th_range(2,2)) | maxth < used_th_range(2,2)
                used_th_range(2,2) = maxth;
            end
            clear minth maxth
        end

        if isfield(analysis, 'results_rs')
            countTable = getCounts(analysis.results_rs, RS_TLUT);
            tblrows = size(countTable, 1);
            totals(1:tblrows,2:4,3) = totals(1:tblrows,2:4,3) + countTable(:, 2:4);
            precision = countTable(:,2) ./ (countTable(:,2) + countTable(:,3));
            recall = countTable(:,2) ./ (countTable(:,2) + countTable(:,4));
            plot(recall,precision,'Color',COLOR_RS,'LineWidth',1.5,'LineStyle','-');

            [minth, maxth] = getMinAndMaxUsedTh(analysis.results_rs);
            if isnan(used_th_range(1,3)) | minth > used_th_range(1,3)
                used_th_range(1,3) = minth;
            end
            if isnan(used_th_range(2,3)) | maxth < used_th_range(2,3)
                used_th_range(2,3) = maxth;
            end
            clear minth maxth
        end

        if isfield(analysis, 'results_db')
            countTable = getCounts(analysis.results_db, DB_TLUT);
            tblrows = size(countTable, 1);
            totals(1:tblrows,2:4,4) = totals(1:tblrows,2:4,4) + countTable(:, 2:4);
            precision = countTable(:,2) ./ (countTable(:,2) + countTable(:,3));
            recall = countTable(:,2) ./ (countTable(:,2) + countTable(:,4));
            plot(recall,precision,'Color',COLOR_DB,'LineWidth',1.5,'LineStyle','-');

            [minth, maxth] = getMinAndMaxUsedTh(analysis.results_db);
            if isnan(used_th_range(1,4)) | minth > used_th_range(1,4)
                used_th_range(1,4) = minth;
            end
            if isnan(used_th_range(2,4)) | maxth < used_th_range(2,4)
                used_th_range(2,4) = maxth;
            end
            clear minth maxth
        end
    

        %Subplot 95% recall line, adjust axis lims
        xline(0.95, 'LineWidth', 1, 'LineStyle', '-.');
        xlim([0.0 1.0]);
        ylim([0.0 1.0]);
        title(string(myname),'Interpreter','none');
        xlabel('Recall');
        ylabel('Precision');

        i = i + 1;
    end

    clear analysis set_group_dir ResFilePath myname countTable precision recall
end
legend({'TrueSpot', 'Big-FISH', 'RS-FISH', 'DeepBlink'});

%Totals plot
combofighandle = figure(2);
clf;
hold on;

for i = 1:4
    %Omit unused rows
%     counttotal = totals(:,2,i) + totals(:,3,i) + totals(:,4,i);
%     ed = find(counttotal == 0, 1);
%     if isempty(ed)
%         ed = size(totals, 1);
%     else
%         ed = ed-1;
%     end

    minth = used_th_range(1,i);
    maxth = used_th_range(2,i);

    minidx = find(totals(:,1,i) >= minth, 1);
    maxidx = find(totals(:,1,i) >= maxth, 1);

    precision = totals(minidx:maxidx,2,i) ./ (totals(minidx:maxidx,2,i) + totals(minidx:maxidx,3,i));
    recall = totals(minidx:maxidx,2,i) ./ (totals(minidx:maxidx,2,i) + totals(minidx:maxidx,4,i));
    plot(recall,precision,'Color',COLORS(i,:),'LineWidth',1.5,'LineStyle','-');

    clear minth maxth minidx maxidx
end

xline(0.95, 'LineWidth', 1, 'LineStyle', '-.');
xlim([0.0 1.0]);
ylim([0.0 1.0]);
xlabel('Recall');
ylabel('Precision');
title(string(DoGroup),'Interpreter','none');
legend({'TrueSpot', 'Big-FISH', 'RS-FISH', 'DeepBlink'});

saveas(multifighandle, [OutputDir filesep 'prc_' DoGroup '_facet.png']);
saveas(multifighandle, [OutputDir filesep 'prc_' DoGroup '_facet.svg']);
saveas(combofighandle, [OutputDir filesep 'prc_' DoGroup '_totaled.png']);
saveas(combofighandle, [OutputDir filesep 'prc_' DoGroup '_totaled.svg']);

% ========================== Helper Functions ==========================

function [minth, maxth] = getMinAndMaxUsedTh(rstruct)
    all_th = rstruct.callset{:, 'dropout_thresh'};
    all_th(all_th == 0) = NaN;

    maxth = max(all_th, [], 'all', 'omitnan');
    minth = min(all_th, [], 'all', 'omitnan');
end

function countTable = getCounts(rstruct, tlut)
    if isempty(tlut)
        T = max(rstruct.callset{:, 'dropout_thresh'}, [], 'all', 'omitnan');
    else
        T = size(tlut, 2);
    end

    countTable = NaN(T,4);

    for t = 1:T
        val = t;
        if ~isempty(tlut)
            val = tlut(t);
        end

        countTable(t,1) = val;

        posall = (rstruct.callset{:, 'dropout_thresh'} >= val);

        trimmed_out = rstruct.callset{:, 'is_trimmed_out'};
        inreg = rstruct.callset{:, 'in_truth_region'};
        posvalid = and(inreg, ~trimmed_out);

        tp = and(posall, rstruct.callset{:, 'is_true'});
        fp = and(posall, ~rstruct.callset{:, 'is_true'});
        fn = and(~posall, rstruct.callset{:, 'is_true'});

        tp = and(tp, posvalid);
        fp = and(fp, posvalid);
        fn = and(fn, posvalid);

        countTable(t,2) = nnz(tp);
        countTable(t,3) = nnz(fp);
        countTable(t,4) = nnz(fn);
    end
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end

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
    elseif startsWith(imgname, 'ROI')
        dirname = 'munsky_lab';
    else
        dirname = groupname;
    end
end

function groupName = getGroupName(imgname)
    groupName = [];
    if startsWith(imgname, 'mESC4d_')
        if contains(imgname, 'Tsix')
            groupName = 'TsixE_AF594';
        else
            groupName = 'XistE_CY5';
        end
    elseif startsWith(imgname, 'scrna_')
        if contains(imgname, 'STL1')
            groupName = 'CTT1_CY5';
        else
            groupName = 'STL1_TMR';
        end
    elseif startsWith(imgname, 'mESC_loday_')
        if contains(imgname, 'Tsix')
            groupName = 'TsixE_TMR';
        else
            groupName = 'XistE_CY5';
        end
    elseif startsWith(imgname, 'scprotein_')
        if contains(imgname, 'Msb2')
            groupName = 'scprotein_Msb2';
        else
            groupName = 'scprotein_Opy2';
        end
    elseif startsWith(imgname, 'histonesc_')
        if contains(imgname, 'Tsix')
            groupName = 'TsixI_TMR';
        elseif contains(imgname, 'Xist')
            groupName = 'XistI_CY5';
        else
            if contains(imgname, 'H3K36me3')
                groupName = 'H3K36me3';
            else
                groupName = 'H3K4me2';
            end
        end
    elseif startsWith(imgname, 'ROI0')
        if contains(imgname, 'GFP')
            groupName = 'HeLa_GFP';
        else
            groupName = 'HeLa_CY5';
        end
    elseif startsWith(imgname, 'simerly_')
    end
end
