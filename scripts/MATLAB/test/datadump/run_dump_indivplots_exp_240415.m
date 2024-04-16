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

ROW_INDEX =  76;

DUMP_SPOTCOUNTS_NOLOG = true;
DUMP_SPOTCOUNTS = true;
DUMP_FSCORES = true;
DUMP_PRC = true;

DB_TYPE_NORMAL = 1;
DB_TYPE_ALT = 2;
DB_TYPE_2D = 3;
DB_TYPE_2DALT = 4;

DB_TYPE = DB_TYPE_NORMAL;
REFSET_ID = 'BH';

USE_TRIMMED = true;

COLOR_HB = [0.667 0.220 0.220];
COLOR_BF = [0.231 0.231 0.702]; %#3b3bb3
COLOR_RS = [0.318 0.541 0.318]; %#518a51
COLOR_DB = [0.700 0.700 0.000];

% ========================== Other Paths ==========================

ImageDumpDir = [ImgProcDir filesep 'figures' filesep 'all_curves'];

ResultsDir = [BaseDir filesep 'data' filesep 'results'];

% ========================== Read Table ==========================

%InputTablePath = [BaseDir filesep 'test_images_simytc.csv'];
%InputTablePath = [BaseDir filesep 'test_images_simvarmass.csv'];
InputTablePath = [BaseDir filesep 'test_images.csv'];

image_table = testutil_opentable(InputTablePath);

% ========================== Go through ==========================

figno = 1;

%Find summary file.
myname = getTableValue(image_table, ROW_INDEX, 'IMGNAME');
set_group_dir = getSetOutputDirName(myname);
ResFilePath = [ResultsDir filesep set_group_dir filesep myname '_summary.mat'];
if isfile(ResFilePath)
    load(ResFilePath, 'analysis');
else
    return;
end

if DUMP_SPOTCOUNTS | DUMP_SPOTCOUNTS_NOLOG
    if isfield(analysis, 'results_hb')
        if isfield(analysis.results_hb, 'benchmarks')
            if isfield(analysis.results_hb.benchmarks, REFSET_ID)
                bstruct = analysis.results_hb.benchmarks.(REFSET_ID);
                if USE_TRIMMED
                    if isfield(bstruct, 'performance_trimmed')
                        x = bstruct.performance_trimmed{:,'thresholdValue'};
                        y = double(bstruct.performance_trimmed{:,'spotCount'});
                    else
                        x = bstruct.performance{:,'thresholdValue'};
                        y = double(bstruct.performance{:,'spotCount'});
                    end
                else
                    x = bstruct.performance{:,'thresholdValue'};
                    y = double(bstruct.performance{:,'spotCount'});
                end

                if DUMP_SPOTCOUNTS_NOLOG
                    SpotPlots.renderSpotCountPlot(x, y,...
                        COLOR_HB, analysis.results_hb.threshold,...
                        analysis.results_hb.threshold_details, figno, []);
                    figno = figno + 1;
                end

                if DUMP_SPOTCOUNTS
                    y = log10(y);

                    SpotPlots.renderLogSpotCountPlot(x, y,...
                        COLOR_HB, analysis.results_hb.threshold,...
                        analysis.results_hb.threshold_details, figno, []);
                    figno = figno + 1;
                end
            end
        end
    end

    if isfield(analysis, 'results_bf')
        if isfield(analysis.results_bf, 'benchmarks')
            if isfield(analysis.results_bf.benchmarks, REFSET_ID)
                bstruct = analysis.results_bf.benchmarks.(REFSET_ID);
                if USE_TRIMMED
                    if isfield(bstruct, 'performance_trimmed')
                        x = bstruct.performance_trimmed{:,'thresholdValue'};
                        y = double(bstruct.performance_trimmed{:,'spotCount'});
                    else
                        x = bstruct.performance{:,'thresholdValue'};
                        y = double(bstruct.performance{:,'spotCount'});
                    end
                else
                    x = bstruct.performance{:,'thresholdValue'};
                    y = double(bstruct.performance{:,'spotCount'});
                end

                if DUMP_SPOTCOUNTS_NOLOG
                    SpotPlots.renderSpotCountPlot(x, y,...
                        COLOR_BF, analysis.results_bf.threshold,...
                        [], figno, []);
                    figno = figno + 1;
                end

                if DUMP_SPOTCOUNTS
                    y = log10(y);

                    SpotPlots.renderLogSpotCountPlot(x, y,...
                        COLOR_BF, analysis.results_bf.threshold,...
                        [], figno, []);
                    figno = figno + 1;
                end
            end
        end
    end

    if isfield(analysis, 'results_rs')
        if isfield(analysis.results_rs, 'benchmarks')
            if isfield(analysis.results_rs.benchmarks, REFSET_ID)
                bstruct = analysis.results_rs.benchmarks.(REFSET_ID);
                x = bstruct.performance{:,'thresholdValue'};
                y = double(bstruct.performance{:,'spotCount'});

                if DUMP_SPOTCOUNTS_NOLOG
                    SpotPlots.renderSpotCountPlot(x, y,...
                        COLOR_RS, 0,...
                        [], figno, []);
                    figno = figno + 1;
                end

                if DUMP_SPOTCOUNTS
                    y = log10(y);

                    SpotPlots.renderLogSpotCountPlot(x, y,...
                        COLOR_RS, 0,...
                        [], figno, []);
                    figno = figno + 1;
                end
            end
        end
    end

    if isfield(analysis, 'results_db') & ((DB_TYPE == DB_TYPE_NORMAL) | (DB_TYPE == DB_TYPE_2D))
        if isfield(analysis.results_db, 'benchmarks') & (DB_TYPE == DB_TYPE_NORMAL)
            if isfield(analysis.results_db.benchmarks, REFSET_ID)
                bstruct = analysis.results_db.benchmarks.(REFSET_ID);

                x = bstruct.performance{:,'thresholdValue'};
                y = double(bstruct.performance{:,'spotCount'});

                if DUMP_SPOTCOUNTS_NOLOG
                    SpotPlots.renderSpotCountPlot(x, y,...
                        COLOR_DB, 0,...
                        [], figno, []);
                    figno = figno + 1;
                end

                if DUMP_SPOTCOUNTS
                    y = log10(y);

                    SpotPlots.renderLogSpotCountPlot(x, y,...
                        COLOR_DB, 0,...
                        [], figno, []);
                    figno = figno + 1;
                end
            end
        end

        if isfield(analysis.results_db, 'performance_2d') & (DB_TYPE == DB_TYPE_2D)
            x = analysis.results_db.performance_2d{:,'thresholdValue'};
            y = double(analysis.results_db.performance_2d{:,'spotCount'});

            if DUMP_SPOTCOUNTS_NOLOG
                SpotPlots.renderSpotCountPlot(x, y,...
                    COLOR_DB, 0,...
                    [], figno, []);
                figno = figno + 1;
            end

            if DUMP_SPOTCOUNTS
                y = log10(y);

                SpotPlots.renderLogSpotCountPlot(x, y,...
                    COLOR_DB, 0,...
                    [], figno, []);
                figno = figno + 1;
            end
        end
    end
end

if DUMP_FSCORES
    if isfield(analysis, 'results_hb')
        if isfield(analysis.results_hb, 'benchmarks')
            if isfield(analysis.results_hb.benchmarks, REFSET_ID)
                bstruct = analysis.results_hb.benchmarks.(REFSET_ID);

                if USE_TRIMMED
                    if isfield(bstruct, 'performance_trimmed')
                        x = bstruct.performance_trimmed{:,'thresholdValue'};
                        y = double(bstruct.performance_trimmed{:,'fScore'});
                    else
                        x = bstruct.performance{:,'thresholdValue'};
                        y = double(bstruct.performance{:,'fScore'});
                    end
                else
                    x = bstruct.performance{:,'thresholdValue'};
                    y = double(bstruct.performance{:,'fScore'});
                end

                SpotPlots.renderFScorePlot(x, y,...
                    COLOR_HB, analysis.results_hb.threshold,...
                    analysis.results_hb.threshold_details, figno, []);
                figno = figno + 1;
            end
        end
    end

    if isfield(analysis, 'results_bf')
        if isfield(analysis.results_bf, 'benchmarks')
            if isfield(analysis.results_bf.benchmarks, REFSET_ID)
                bstruct = analysis.results_bf.benchmarks.(REFSET_ID);

                if USE_TRIMMED
                    if isfield(bstruct, 'performance_trimmed')
                        x = bstruct.performance_trimmed{:,'thresholdValue'};
                        y = double(bstruct.performance_trimmed{:,'fScore'});
                    else
                        x = bstruct.performance{:,'thresholdValue'};
                        y = double(bstruct.performance{:,'fScore'});
                    end
                else
                    x = bstruct.performance{:,'thresholdValue'};
                    y = double(bstruct.performance{:,'fScore'});
                end

                SpotPlots.renderFScorePlot(x, y,...
                    COLOR_BF, analysis.results_bf.threshold,...
                    [], figno, []);
                figno = figno + 1;
            end
        end
    end

    if isfield(analysis, 'results_rs')
        if isfield(analysis.results_rs, 'benchmarks')
            if isfield(analysis.results_rs.benchmarks, REFSET_ID)
                bstruct = analysis.results_rs.benchmarks.(REFSET_ID);

                x = bstruct.performance{:,'thresholdValue'};
                y = double(bstruct.performance{:,'fScore'});

                SpotPlots.renderFScorePlot(x, y,...
                    COLOR_RS, 0,...
                    [], figno, []);
                figno = figno + 1;
            end
        end
    end

    if isfield(analysis, 'results_db') & ((DB_TYPE == DB_TYPE_NORMAL) | (DB_TYPE == DB_TYPE_2D))
        if isfield(analysis.results_db, 'benchmarks') & (DB_TYPE == DB_TYPE_NORMAL)
            if isfield(analysis.results_db.benchmarks, REFSET_ID)
                bstruct = analysis.results_db.benchmarks.(REFSET_ID);

                x = bstruct.performance{:,'thresholdValue'};
                y = double(bstruct.performance{:,'fScore'});

                SpotPlots.renderFScorePlot(x, y,...
                    COLOR_DB, 0,...
                    [], figno, []);
                figno = figno + 1;
            end
        end

        if isfield(analysis.results_db, 'performance_2d') & (DB_TYPE == DB_TYPE_2D)
            x = analysis.results_db.performance_2d{:,'thresholdValue'};
            y = double(analysis.results_db.performance_2d{:,'fScore'});

            SpotPlots.renderFScorePlot(x, y,...
                COLOR_DB, 0,...
                [], figno, []);
            figno = figno + 1;
        end
    end
end

if DUMP_PRC
    if isfield(analysis, 'results_hb')
        if isfield(analysis.results_hb, 'benchmarks')
            if isfield(analysis.results_hb.benchmarks, REFSET_ID)
                bstruct = analysis.results_hb.benchmarks.(REFSET_ID);

                if USE_TRIMMED
                    if isfield(bstruct, 'performance_trimmed')
                        x = bstruct.performance_trimmed{:,'sensitivity'};
                        y = double(bstruct.performance_trimmed{:,'precision'});
                    else
                        x = bstruct.performance{:,'sensitivity'};
                        y = double(bstruct.performance{:,'precision'});
                    end
                else
                    x = bstruct.performance{:,'sensitivity'};
                    y = double(bstruct.performance{:,'precision'});
                end

                SpotPlots.renderPRPlot(x, y, COLOR_HB, figno, []);
                figno = figno + 1;
            end
        end
    end

    if isfield(analysis, 'results_bf')
        if isfield(analysis.results_bf, 'benchmarks')
            if isfield(analysis.results_bf.benchmarks, REFSET_ID)
                bstruct = analysis.results_bf.benchmarks.(REFSET_ID);

                if USE_TRIMMED
                    if isfield(bstruct, 'performance_trimmed')
                        x = bstruct.performance_trimmed{:,'sensitivity'};
                        y = double(bstruct.performance_trimmed{:,'precision'});
                    else
                        x = bstruct.performance{:,'sensitivity'};
                        y = double(bstruct.performance{:,'precision'});
                    end
                else
                    x = bstruct.performance{:,'sensitivity'};
                    y = double(bstruct.performance{:,'precision'});
                end

                SpotPlots.renderPRPlot(x, y, COLOR_BF, figno, []);
                figno = figno + 1;
            end
        end
    end

    if isfield(analysis, 'results_rs')
        if isfield(analysis.results_rs, 'benchmarks')
            if isfield(analysis.results_rs.benchmarks, REFSET_ID)
                bstruct = analysis.results_rs.benchmarks.(REFSET_ID);

                x = bstruct.performance{:,'sensitivity'};
                y = double(bstruct.performance{:,'precision'});

                SpotPlots.renderPRPlot(x, y, COLOR_RS, figno, []);
                figno = figno + 1;
            end
        end
    end

    if isfield(analysis, 'results_db') & ((DB_TYPE == DB_TYPE_NORMAL) | (DB_TYPE == DB_TYPE_2D))
        if isfield(analysis.results_db, 'benchmarks') & (DB_TYPE == DB_TYPE_NORMAL)
            if isfield(analysis.results_db.benchmarks, REFSET_ID)
                bstruct = analysis.results_db.benchmarks.(REFSET_ID);

                x = bstruct.performance{:,'sensitivity'};
                y = double(bstruct.performance{:,'precision'});

                SpotPlots.renderPRPlot(x, y, COLOR_DB, figno, []);
                figno = figno + 1;
            end
        end

        if isfield(analysis.results_db, 'performance_2d') & (DB_TYPE == DB_TYPE_2D)
            x = analysis.results_db.performance_2d{:,'sensitivity'};
            y = double(analysis.results_db.performance_2d{:,'precision'});

            SpotPlots.renderPRPlot(x, y, COLOR_DB, figno, []);
            figno = figno + 1;
        end
    end
end

% ========================== Helper Functions ==========================

function cleanupFormatting()
    set(gca,'FontSize',12);
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
    else
        if startsWith(groupname, 'ROI')
            dirname = 'munsky_lab';
        else
            dirname = groupname;
        end
    end
end

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end
