%
%%  !! UPDATE TO YOUR BASE DIR
DataDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
%DataDir = 'D:\usr\bghos\labdat\imgproc';

ImgDir = 'C:\Users\hospelb\labdata\imgproc\img';

% ========================== Settings ==========================
addpath('./core');
addpath('./test');
addpath('./thirdparty');

MaskDir = [ImgDir filesep 'munsky_lab' filesep 'analysis'];
OutputDir = [DataDir filesep 'data' filesep 'cell_seg' filesep 'munsky_lab'];

% ========================== Loop Subfolders ==========================

DirContents = dir(MaskDir);
childCount = size(DirContents, 1);
for i = 1:childCount
    child = DirContents(i,1);
    if ~child.isdir; continue; end
    if ~startsWith(child.name, 'masks_'); continue; end

    MaskSubDir = [MaskDir filesep child.name];
    subDirContents = dir(MaskSubDir);
    grandchildCount = size(subDirContents,1);

    for j = 1:grandchildCount
        grandchild = subDirContents(j,1);
        if grandchild.isdir; continue; end

        imgpath = [MaskSubDir filesep grandchild.name];
        if startsWith(grandchild.name, 'masks_cyto_')
            if startsWith(grandchild.name, 'masks_cyto_no_nuclei')
                continue;
            end

            imgname = replace(grandchild.name, 'masks_cyto_', '');
            imgname = replace(imgname, '_merged.tif', '');
            imgname = replace(imgname, ' - Position ', '_P0');

            [channels, ~] = LoadTif(imgpath, 1, [1], 1);
            cells = uint16(channels{1,1});
            clear channels

            outpath = [OutputDir filesep 'Lab_' imgname '.mat'];
            save(outpath, 'cells', '-v7.3');
            clear cells

        elseif startsWith(grandchild.name, 'masks_nuclei_')

            imgname = replace(grandchild.name, 'masks_nuclei_', '');
            imgname = replace(imgname, '_merged.tif', '');
            imgname = replace(imgname, ' - Position ', '_P0');

            [channels, ~] = LoadTif(imgpath, 1, [1], 1);
            nuclei = uint16(channels{1,1});
            clear channels

            outpath = [OutputDir filesep 'nuclei_' imgname '.mat'];
            save(outpath, 'nuclei', '-v7.3');
            clear nuclei
        end

        clear imgname
        clear imgpath
    end

end