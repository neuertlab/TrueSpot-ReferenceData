%
%% BASE DIR

%ImgProcBaseDir = 'D:\usr\bghos\labdat\imgproc';
ImgProcBaseDir = 'C:\Users\hospelb\labdata\imgproc';

% ========================== Constants ==========================

addpath('./core');

UseDir = [ImgProcBaseDir filesep 'img' filesep 'simerly_lab'];
TifDir = [UseDir filesep 'tif'];

settings = struct();

%These are just DEFAULTS. Need to update in output for EACH IMAGE.
settings.vox_xy = 195;
settings.vox_z = 350;
settings.point_xy = 390;
settings.point_z = 400;
settings.dim_x = 1024;
settings.dim_y = 1024;
settings.dim_z = 26;

settings.ch_total = 4;
settings.ch_dapi = 4;
settings.ch_trans = 0;
settings.ch_trg_count = 3;
settings.ch_trg_list = {'AF647' 'tdTom' 'AF488'};
settings.trg_list = {'Unknown' 'Unknown' 'Unknown'};
settings.trg_type_list = {'Unknown' 'Unknown' 'Unknown'};

settings.species = 'Mus musculus';
settings.cellType = 'Tissue';

settings.prefix = 'simerly';
settings.dir_prefix = 'simerly_lab';

% ========================== Loop ==========================

doDirectory(TifDir, settings);

% ========================== Functions ==========================

function doDirectory(dirpath, settings)
    dirContents = dir(dirpath);
    childCount = size(dirContents, 1);

    tifcount = 0;
    trgcount = size(settings.ch_trg_list, 2);
    [~, dirname, ~] = fileparts(dirpath);
    for i = 1:childCount
        child = dirContents(i, 1);

        if child.isdir
            if strcmp(child.name, '.'); continue; end
            if strcmp(child.name, '..'); continue; end
            doDirectory([dirpath filesep child.name], settings);
        else
            if endsWith(child.name, '.tiff') | endsWith(child.name, '.tif')
                tifpath = [dirpath filesep child.name];
                imgname_base = [settings.prefix '_' dirname '_' sprintf('%02d', tifcount);];
                
                for j = 1:trgcount
                    mytrg = settings.ch_trg_list{j};
                    imgname = [imgname_base '_' mytrg];
                    fprintf('%s', imgname);

                    tifpath_rel = ['/img/' settings.dir_prefix '/' dirname '/' child.name];
                    fprintf('\t%s', tifpath_rel);
                    fprintf('\t%d\t%d\t%d\t%d', j, settings.ch_trans, settings.ch_dapi, settings.ch_total);
                    fprintf('\t%s', ['/data/preprocess/' settings.dir_prefix '/' dirname '/' imgname '/' imgname '_all_3d']);
                    fprintf('\t%s', settings.cellType);
                    fprintf('\t%s', settings.trg_list{j});
                    fprintf('\t%s', settings.ch_trg_list{j});
                    fprintf('\t%s', settings.trg_type_list{j});
                    fprintf('\t%s', settings.species);
                    fprintf('\t%s', ['/data/bigfish/' settings.dir_prefix '/' dirname '/' imgname '/BIGFISH_' imgname]);
                    fprintf('\t3\t.\t.\t.');
                    fprintf('\t%d\t%d\t%d', settings.dim_x, settings.dim_y, settings.dim_z);
                    fprintf('\t%d\t%d\t%d', settings.vox_xy, settings.vox_xy, settings.vox_z);
                    fprintf('\t%d\t%d\t%d', settings.point_xy, settings.point_xy, settings.point_z);
                    fprintf('\t0\t0\t1\t.');

                    fprintf('\n');
                end
                
                tifcount = tifcount + 1;
            end
        end
    end

end

