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
addpath('./thirdparty');
addpath('./test/datadump');

% ========================== General Context ==========================

DataDir = [BaseDir filesep 'data'];
ResultsDir = [DataDir filesep 'results'];

ImgName = 'mESC_loday_D1I32_Tsix';
REFSETNAME = 'BH';

% ========================== Read Table ==========================

%InputTablePath = [BaseDir filesep 'test_images_simytc.csv'];
%InputTablePath = [BaseDir filesep 'test_images_simvarmass.csv'];
InputTablePath = [BaseDir filesep 'test_images.csv'];
image_table = testutil_opentable(InputTablePath);

rec_row = 0;
rec_count = size(image_table,1);
for r = 1:rec_count
    iname = getTableValue(image_table, r, 'IMGNAME');
    if strcmp(iname, ImgName)
        rec_row = r;
        break;
    end
end

if rec_row < 1
    fprintf('Image with name %s could not be found!\n', ImgName);
    return;
end

% ========================== Load Refset ==========================

outstem = [BaseDir replace(getTableValue(image_table, rec_row, 'OUTSTEM'), '/', filesep)];
RefTablePath = [outstem 'spotAnnoObj_refset.mat'];
if ~isfile(RefTablePath)
    fprintf('Refset does not exist for %s!', iname);
    return;
end

load(RefTablePath, 'ref_coord_tbl');

%Mask
AnnoObjPath = [outstem 'spotAnnoObj.mat'];
load(AnnoObjPath, 'mask_selection', 'zmin', 'zmax');
truth_mask = struct();

% ========================== Load Analysis File ==========================

set_group_dir = getSetOutputDirName(iname);
ResFilePath = [ResultsDir filesep set_group_dir filesep iname '_summary.mat'];

if ~isfile(ResFilePath)
    fprintf('Analysis file does not exist for %s!', iname);
    return;
end

load(ResFilePath, 'analysis');

% ========================== Apply ==========================

if ~isempty(mask_selection)
    truth_mask.x0 = mask_selection(1,1);
    truth_mask.y0 = mask_selection(3,1);
    truth_mask.z0 = zmin;

    truth_mask.x1 = mask_selection(2,1);
    truth_mask.y1 = mask_selection(4,1);
    truth_mask.z1 = zmax;
else
    truth_mask.x0 = 1;
    truth_mask.y0 = 1;
    truth_mask.z0 = 1;

    truth_mask.x1 = analysis.image_dims.x;
    truth_mask.y1 = analysis.image_dims.y;
    truth_mask.z1 = analysis.image_dims.z;
end

[analysis, okay] = AnalysisFiles.addExpRefSet(analysis, ref_coord_tbl, truth_mask, REFSETNAME, 4, 2, 0.0001);
save(ResFilePath, 'analysis', '-v7.3');
fprintf('Hold\n');

% ========================== Helper Functions ==========================

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
