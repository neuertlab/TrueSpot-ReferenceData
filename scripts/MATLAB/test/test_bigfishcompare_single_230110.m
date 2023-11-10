%
%%  !! UPDATE TO YOUR BASE DIR
%ImgDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
ImgDir = 'D:\usr\bghos\labdat\imgproc';

%ImgProcDir = 'D:\Users\hospelb\labdata\imgproc';
ImgProcDir = 'D:\usr\bghos\labdat\imgproc';

addpath('./core');
% ========================== Constants ==========================

% ========================== Load csv Table ==========================

AllFigDir = [ImgProcDir filesep 'figures' filesep 'curves'];

InputTablePath = [ImgDir filesep 'test_images.csv'];
imgtbl = testutil_opentable(InputTablePath);

%For one image
SingleImgName = 'sim_yeast_proteinGFP_100x_2_blur';

% ========================== Iterate through table entries ==========================
entry_count = size(imgtbl,1);

for i = 1:entry_count
    if ~isempty(SingleImgName)
        myname = getTableValue(imgtbl, i, 'IMGNAME');
        if ~strcmp(myname, SingleImgName); continue; end
    end

    mystem = replace(getTableValue(imgtbl, i, 'OUTSTEM'), '/', filesep);
    mystem = [ImgDir mystem];

    spotsrun = RNASpotsRun.loadFrom(mystem);
    if isempty(spotsrun)
        fprintf("Image %d of %d - Run could not be found for %s! Skipping...\n", i, entry_count, mystem);
        continue;
    end
    fprintf("Image %d of %d - Processing %s...\n", i, entry_count, mystem);

    bfstem = replace(getTableValue(imgtbl, i, 'BIGFISH_OUTSTEM'), '/', filesep);
    bfstem = [ImgDir bfstem];
    [bfdir, bfpref, ~] = fileparts(bfstem);

    [success_bool, fighandles] = BigfishCompare.doBigfishCompare(mystem, bfdir, bfpref, true, true, false);

end

%%
function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index,field};
    if iscell(val)
        val = val{1,1};
    end
end