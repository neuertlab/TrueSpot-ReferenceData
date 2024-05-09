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
addpath('./test/datadump');

% ========================== General Context ==========================

ResultsDir = [BaseDir filesep 'data' filesep 'results'];

DateSuffix = '240507';
OutputDir = [ImgProcDir filesep 'tables'];

TablePath_Main = [BaseDir filesep 'test_images.csv'];

INCLUDE_CELL_ZERO = false;
FILTER_Z_RAD = 2;

% ========================== Fixed Thresholds ==========================

fixed_th = struct();

%These are the averages of the th_vals at the PEAK F-scores for the handful
%of curated images in each group.
%Xist Tsix H3K36me3 H3K4me2
fixed_th.histonesc_fixed_th_hb = [81 824 80 98];
fixed_th.histonesc_fixed_th_bf = [254 288 664 642];
%For H3K36me3 BF, I removed the outlier for the average

%Same as from main sctc fixed vs. variable (replicate level)
fixed_th.rep_fixed_th_hb_e1 = [75 134
    79 148];
fixed_th.rep_fixed_th_hb_e2 = [91 132
    70 111
    59 79];

fixed_th.rep_fixed_th_bf_e1 = [184 223
    176 149];
fixed_th.rep_fixed_th_bf_e2 = [257 248
    183 189
    126 264];

% ========================== Open Output ==========================

outpath = [OutputDir filesep 'maxprojResults_' DateSuffix '.tsv'];
OutputHandle = fopen(outpath, 'w');

%Header
outfields = {'IMGNAME' 'CELLNO' 'TARGET' 'CH' 'EXP' 'REP' 'MIN' ...
    'COUNT_3DF_HBV' 'COUNT_3DT_HBV' 'COUNT_2DF_HBV' 'COUNT_2DT_HBV' ...
    'COUNT_3DF_HBF' 'COUNT_3DT_HBF' 'COUNT_2DF_HBF' 'COUNT_2DT_HBF' ...
    'COUNT_3DF_BFV' 'COUNT_3DT_BFV' 'COUNT_2DF_BFV' 'COUNT_2DT_BFV' ...
    'COUNT_3DF_BFF' 'COUNT_3DT_BFF' 'COUNT_2DF_BFF' 'COUNT_2DT_BFF'};
field_count = size(outfields, 2);
for i = 1:field_count
    if i > 1; fprintf(OutputHandle, '\t'); end
    fprintf(OutputHandle, outfields{i});
end
fprintf(OutputHandle, '\n');

% ========================== Loop ==========================

image_table = testutil_opentable(TablePath_Main);
entry_count = size(image_table, 1);

for r = 1:entry_count

    myname = getTableValue(image_table, r, 'IMGNAME');
    fprintf('> Now processing %s (%d of %d)...\n', myname, r, entry_count);
    if shouldSkip(myname)
        fprintf('\t> Skipping for this operation...\n');
        continue;
    end

    %Get res file path
    set_group_dir = getSetOutputDirName(myname);
    ResFilePath = [ResultsDir filesep set_group_dir filesep myname '_summary.mat'];

    if isfile(ResFilePath)
        load(ResFilePath, 'analysis');
    else
        fprintf('> Could not find analysis file. Skipping...\n');
        clear set_group_dir ResFilePath
        continue;
    end

    if ~isfield(analysis, 'results_hb')
        fprintf('> Could not find TrueSpot results info. Skipping...\n');
        clear set_group_dir ResFilePath analysis
        continue;
    end

    if ~isfield(analysis.results_hb, 'callset')
        fprintf('> Could not find TrueSpot results info. Skipping...\n');
        clear set_group_dir ResFilePath analysis
        continue;
    end

    clear set_group_dir ResFilePath

    cellCount = max(analysis.results_hb.callset{:, 'cell'}, [], 'all', 'omitnan');
    hbTh = analysis.results_hb.threshold;
    bfTh = analysis.results_bf.threshold;
    expNo = 0;
    repNo = 0;
    timePoint = 0;
    targetName = '[UNK]';
    fixedThHB = 0;
    fixedThBF = 0;

    if startsWith(myname, 'sctc_')
        nameBreakdown = Parse_sctcImgName(myname);
        expNo = nameBreakdown.Exp;
        repNo = nameBreakdown.Rep;
        timePoint = nameBreakdown.TimePointMin;
        channelNo = nameBreakdown.Channel;

        if channelNo == 1
            targetName = 'CTT1';
        else
            targetName = 'STL1';
        end

        if expNo == 1
            fixedThHB = fixed_th.rep_fixed_th_hb_e1(repNo, channelNo);
            fixedThBF = fixed_th.rep_fixed_th_bf_e1(repNo, channelNo);
        else
            fixedThHB = fixed_th.rep_fixed_th_hb_e2(repNo, channelNo);
            fixedThBF = fixed_th.rep_fixed_th_bf_e2(repNo, channelNo);
        end
    elseif startsWith(myname, 'histonesc_')
        if endsWith(myname, 'Tsix')
            channelNo = 3;
            targetName = 'Tsix';
            fixedThHB = fixed_th.histonesc_fixed_th_hb(2);
            fixedThBF = fixed_th.histonesc_fixed_th_bf(2);
        elseif endsWith(myname, 'Xist')
            channelNo = 2;
            targetName = 'Xist';
            fixedThHB = fixed_th.histonesc_fixed_th_hb(1);
            fixedThBF = fixed_th.histonesc_fixed_th_bf(1);
        else
            channelNo = 4;
            if contains(myname, 'H3K36')
                targetName = 'H3K36me3';
                fixedThHB = fixed_th.histonesc_fixed_th_hb(3);
                fixedThBF = fixed_th.histonesc_fixed_th_bf(3);
            else
                targetName = 'H3K4me2';
                fixedThHB = fixed_th.histonesc_fixed_th_hb(4);
                fixedThBF = fixed_th.histonesc_fixed_th_bf(4);
            end
        end
    end

    trimMipStructName = 'mip_10_16';
    zMin = 10;
    zMax = 16;
    if startsWith(myname, 'histonesc_')
        trimMipStructName = 'mip_20_42';
        zMin = 20;
        zMax = 42;
    end

    if ~isfield(analysis.results_hb, 'mip_1_Z')
        fprintf('\t>> WARNING: 2D full stack results (HB) could not be found!!\n');
    end
    if ~isfield(analysis.results_hb, trimMipStructName)
        fprintf('\t>> WARNING: 2D trimmed results (HB) could not be found!!\n');
    end
    if ~isfield(analysis.results_bf, 'mip_1_Z')
        fprintf('\t>> WARNING: 2D full stack results (BF) could not be found!!\n');
    end
    if ~isfield(analysis.results_bf, trimMipStructName)
        fprintf('\t>> WARNING: 2D trimmed results (BF) could not be found!!\n');
    end

    cstart = 1;
    if INCLUDE_CELL_ZERO; cstart = 0; end
    for c = cstart:cellCount
        %Write basic info columns...
        fprintf(OutputHandle, '%s\t%d\t%s\t%d\t%d\t%d\t%d', ...
            myname, c, targetName, channelNo, expNo, repNo, timePoint);

        %Take counts...
        %HB
        %3D...
        callset = analysis.results_hb.callset;
        inZRegion = (callset{:, 'isnap_z'} >= (zMin - FILTER_Z_RAD));
        inZRegion = inZRegion & (callset{:, 'isnap_z'} <= (zMax + FILTER_Z_RAD));
        
        inCell = (callset{:, 'cell'} == c);
        passesTh = (callset{:, 'dropout_thresh'} >= hbTh);
        spotCount3FV = nnz(inCell & passesTh);
        spotCount3TV = nnz(inCell & passesTh & inZRegion);

        passesTh = (callset{:, 'dropout_thresh'} >= fixedThHB);
        spotCount3FF = nnz(inCell & passesTh);
        spotCount3TF = nnz(inCell & passesTh & inZRegion);

        %2D full stack...
        if isfield(analysis.results_hb, 'mip_1_Z')
            callset = analysis.results_hb.mip_1_Z.callset;
            inCell = (callset{:, 'cell'} == c);
            passesTh = (callset{:, 'dropout_thresh'} >= analysis.results_hb.mip_1_Z.threshold);
            spotCount2FV = nnz(inCell & passesTh);

            passesTh = (callset{:, 'dropout_thresh'} >= fixedThHB);
            spotCount2FF = nnz(inCell & passesTh);
        else
            spotCount2FV = NaN;
            spotCount2FF = NaN;
        end
        

        %2D maxproj
        if isfield(analysis.results_hb, trimMipStructName)
            callset = analysis.results_hb.(trimMipStructName).callset;
            inCell = (callset{:, 'cell'} == c);
            passesTh = (callset{:, 'dropout_thresh'} >= analysis.results_hb.(trimMipStructName).threshold);
            spotCount2TV = nnz(inCell & passesTh);

            passesTh = (callset{:, 'dropout_thresh'} >= fixedThHB);
            spotCount2TF = nnz(inCell & passesTh);
        else
            spotCount2TV = NaN;
            spotCount2TF = NaN;
        end
        

        %Print HB
        clear inCell passesTh callset
        fprintf(OutputHandle, '\t%d\t%d\t%d\t%d', spotCount3FV, spotCount3TV, spotCount2FV, spotCount2TV);
        fprintf(OutputHandle, '\t%d\t%d\t%d\t%d', spotCount3FF, spotCount3TF, spotCount2FF, spotCount2TF);
        clear spotCount3FV spotCount3FF spotCount2FV spotCount2FF 
        clear spotCount2TV spotCount2TF spotCount3TV spotCount3TF
        
        %Repeat for BF
        callset = analysis.results_bf.callset;
        inZRegion = (callset{:, 'isnap_z'} >= (zMin - FILTER_Z_RAD));
        inZRegion = inZRegion & (callset{:, 'isnap_z'} <= (zMax + FILTER_Z_RAD));
        
        inCell = (callset{:, 'cell'} == c);
        passesTh = (callset{:, 'dropout_thresh'} >= bfTh);
        spotCount3FV = nnz(inCell & passesTh);
        spotCount3TV = nnz(inCell & passesTh & inZRegion);

        passesTh = (callset{:, 'dropout_thresh'} >= fixedThBF);
        spotCount3FF = nnz(inCell & passesTh);
        spotCount3TF = nnz(inCell & passesTh & inZRegion);

        %2D full stack...
        if isfield(analysis.results_bf, 'mip_1_Z')
            callset = analysis.results_bf.mip_1_Z.callset;
            inCell = (callset{:, 'cell'} == c);
            passesTh = (callset{:, 'dropout_thresh'} >= analysis.results_bf.mip_1_Z.threshold);
            spotCount2FV = nnz(inCell & passesTh);

            passesTh = (callset{:, 'dropout_thresh'} >= fixedThBF);
            spotCount2FF = nnz(inCell & passesTh);
        else
            spotCount2FV = NaN;
            spotCount2FF = NaN;
        end
        

        %2D maxproj
        if isfield(analysis.results_bf, trimMipStructName)
            callset = analysis.results_bf.(trimMipStructName).callset;
            inCell = (callset{:, 'cell'} == c);
            passesTh = (callset{:, 'dropout_thresh'} >= analysis.results_bf.(trimMipStructName).threshold);
            spotCount2TV = nnz(inCell & passesTh);

            passesTh = (callset{:, 'dropout_thresh'} >= fixedThBF);
            spotCount2TF = nnz(inCell & passesTh);
        else
            spotCount2TV = NaN;
            spotCount2TF = NaN;
        end
        

        fprintf(OutputHandle, '\t%d\t%d\t%d\t%d', spotCount3FV, spotCount3TV, spotCount2FV, spotCount2TV);
        fprintf(OutputHandle, '\t%d\t%d\t%d\t%d', spotCount3FF, spotCount3TF, spotCount2FF, spotCount2TF);


        fprintf(OutputHandle, '\n');
        clear inCell passesTh callset
        clear spotCount3FV spotCount3FF spotCount2FV spotCount2FF 
        clear spotCount2TV spotCount2TF spotCount3TV spotCount3TF
    end

    clear c bhTh hbTh myname channelNo expNo repNo targetName timePoint cellCount
    clear analysis trimMipStructName zMin zMax
end

fclose(OutputHandle);

% ========================== Helper Functions ==========================

function bool = shouldSkip(imgname)
    bool = true;

    if startsWith(imgname, 'sctc_'); bool = false; end
    if startsWith(imgname, 'histonesc_'); bool = false; end
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
    elseif startsWith(imgname, 'simerly_')
        dirname = 'simerly_lab';
    else
        dirname = groupname;
    end
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end