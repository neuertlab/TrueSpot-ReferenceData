%
%%  !! UPDATE TO YOUR BASE DIR
ImgDir = 'C:\Users\hospelb\labdata\imgproc';
%ImgDir = 'D:\usr\bghos\labdat\imgproc';

DataDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
%DataDir = 'D:\usr\bghos\labdat\imgproc';

addpath('./core');
addpath('./thirdparty');

% ========================== Constants ==========================

Z_MIN = 0;
Z_MAX = 0;

if Z_MIN < 1; Z_MIN = 1; end

OutDir = ['MIP_' num2str(Z_MIN)];
if Z_MAX > 0 
    OutDir = [OutDir '_' num2str(Z_MAX)]; 
else
    OutDir = [OutDir '_Z']; 
end

% ========================== Load csv Table ==========================
%InputTablePath = [DataDir filesep 'test_images_simneg.csv'];
%InputTablePath = [DataDir filesep 'test_images_simytc.csv'];
%InputTablePath = [DataDir filesep 'test_images_simvarmass.csv'];
InputTablePath = [DataDir filesep 'test_images.csv'];
image_table = testutil_opentable(InputTablePath);

GroupPrefix = 'histonesc_';
GroupSuffix = [];

% ========================== Loop ==========================

last_ipath = [];
rec_count = size(image_table,1);
for r = 1:rec_count
    iname = getTableValue(image_table, r, 'IMGNAME');
    
    if ~startsWith(iname, GroupPrefix); continue; end
    if ~isempty(GroupSuffix)
        if ~endsWith(iname, GroupSuffix); continue; end
    end
    hb_outstem = getTableValue(image_table, r, 'OUTSTEM');
    
    ipath = getTableValue(image_table, r, 'IMAGEPATH');
    if endsWith(ipath, '.mat')
        ipath = replace(ipath, '.mat', '.tif');
    end
    if strcmp(last_ipath, ipath); continue; end
    last_ipath = ipath;

    ipath = [ImgDir replace(ipath, '/', filesep)];

    fprintf('> Loading %s...\n', ipath);

    chcount = getTableValue(image_table, r, 'CH_TOTAL');
    [channels, idims] = LoadTif(ipath, chcount, [1:chcount], 0);

    [fdir, fname, ~] = fileparts(ipath);

    odir = [fdir filesep OutDir];
    if ~isfolder(odir)
        mkdir(odir);
    end
     
    z_min = Z_MIN;
    z_max = Z_MAX;
    if z_max < 1
        z_max = idims.z;
    end

    for cc = 1:chcount
        fprintf('\tWorking on channel %d...\n', cc);
        outpath = [odir filesep fname '_MIP_' num2str(z_min) '-' num2str(z_max) '_c' num2str(cc) '.tif'];
        if isfile(outpath)
            delete(outpath);
        end
        mychannel = channels{cc,1};
        zproj = max(mychannel(:,:,z_min:z_max), [], 3, 'omitnan');
        zproj = uint16(zproj);
        saveastiff(zproj, outpath);
    end

end

% ========================== Helper Functions ==========================

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end