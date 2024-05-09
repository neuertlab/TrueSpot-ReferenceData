%
%%  !! UPDATE TO YOUR BASE DIR
%ImgDir = 'C:\Users\hospelb\labdata\imgproc';
ImgDir = 'D:\usr\bghos\labdat\imgproc';

%DataDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
DataDir = 'D:\usr\bghos\labdat\imgproc';

%ScriptDir = 'C:\Users\hospelb.VUDS\Desktop\slurm';
ScriptDir = 'C:\Users\bghos\Desktop\slurm';

ClusterWorkDir = '/nobackup/p_neuert_lab/hospelb/imgproc';
ClusterSlurmDir = '/nobackup/p_neuert_lab/hospelb/imgproc/slurm/script';
ClusterScriptsDir = '/nobackup/p_neuert_lab/hospelb/scripts';

addpath('./core');
addpath('./test');

% ========================== Constants ==========================

DETECT_THREADS = 2;
RAM_PER_CORE = 16;
SERIAL_HR = 2;

%For finding file
Z_MIN = 20;
Z_MAX = 42;

OVERWRITE = false;

MODULE_NAME = 'MATLAB/2018b';
MATLAB_DIR = [ClusterWorkDir '/matlab'];
HB_OUTDIR = [ClusterWorkDir '/data/preprocess/mip'];

% ========================== Load csv Table ==========================
%InputTablePath = [DataDir filesep 'test_images_simneg.csv'];
%InputTablePath = [DataDir filesep 'test_images_simytc.csv'];
%InputTablePath = [DataDir filesep 'test_images_simvarmass.csv'];
InputTablePath = [DataDir filesep 'test_images.csv'];
image_table = testutil_opentable(InputTablePath);

%ImageName='scrna_E2R2I5_CTT1';
GroupPrefix = 'histonesc_';
GroupSuffix = [];
GroupOutDir = 'histonesc';

% ========================== Param Adjust ==========================

if Z_MIN < 1
    TifDirName = 'MIP_1';
else
    TifDirName = ['MIP_' num2str(Z_MIN)];
end

if Z_MAX < 1
    TifDirName = [TifDirName '_Z'];
else
    TifDirName = [TifDirName '_' num2str(Z_MAX)];
end

GAUSS_RAD = 7;

% ========================== Generate Bash Script & Slurm Command ==========================

script_master = fopen([ScriptDir filesep 'runall_hb_mip.sh'], 'w');
fprintf(script_master, '#!/bin/bash\n\n');
fprintf(script_master, 'SCRIPTDIR=%s\n', ClusterSlurmDir);

rec_count = size(image_table, 1);

for r = 1:rec_count
    iname = getTableValue(image_table, r, 'IMGNAME');
    
    if ~startsWith(iname, GroupPrefix); continue; end
    if ~isempty(GroupSuffix)
        if ~endsWith(iname, GroupSuffix); continue; end
    end

    ipath = getTableValue(image_table, r, 'IMAGEPATH');
    if endsWith(ipath, '.mat')
        ipath = replace(ipath, '.mat', '.tif');
    end

    dimZ = getTableValue(image_table, r, 'IDIM_Z');
    ch = getTableValue(image_table, r, 'CHANNEL');

    %Determine input file path
    ipath = [ClusterWorkDir ipath];
    [idir,ifilename,~] = fileparts(ipath);
    zmin = Z_MIN;
    zmax = Z_MAX;
    if zmax < 1
        zmax = dimZ;
    end
    if zmin < 1
        zmin = 1;
    end
    mipiPath = [idir '/' TifDirName '/' ifilename '_MIP_'...
        num2str(zmin) '-' num2str(zmax) '_c' num2str(ch) '.tif'];

    %Determine output file dir
    trgname = getTableValue(image_table, r, 'TARGET');
    resOutDir = [HB_OUTDIR '/' GroupOutDir '/' ifilename '/' trgname];
    resOutStem = [resOutDir '/' iname];

    %Script
    scriptFileName = [iname '_hb_mip.sh'];
    script_file = fopen([ScriptDir filesep scriptFileName], 'w');

    fprintf(script_file, '#!/bin/bash\n\n');
    fprintf(script_file, 'module load %s\n', MODULE_NAME);
    fprintf(script_file, 'cd %s\n', MATLAB_DIR);
    fprintf(script_file, 'matlab -nodisplay -nosplash -logfile "%s_mat.log" -r "cd %s; ', resOutStem, MATLAB_DIR);
    fprintf(script_file, 'Main_RNASpots(');

    printMatArg(script_file, 'imgname', iname, false);
    printMatArg(script_file, 'tif', mipiPath, true);
    printMatArg(script_file, 'outstem', resOutStem, true);

    csegdir = getTableValue(image_table, r, 'CELLSEG_DIR');
    csegsfx = getTableValue(image_table, r, 'CELLSEG_SFX');
    if ~strcmp(csegdir, '.')
        printMatArg(script_file, 'cellseg', [ClusterWorkDir csegdir '/Lab_' csegsfx '.mat'], true);
    end

    printMatArg(script_file, 'chsamp', '1', true);
    printMatArg(script_file, 'chtotal', '1', true);
    printMatFlagArg(script_file, 'autominth', true);
    printMatFlagArg(script_file, 'automaxth', true);
    printMatArg(script_file, 'sensitivity', '0', true);
    printMatFlagArg(script_file, 'maxzproj', true);
    printMatFlagArg(script_file, 'verbose', true);

    vx = getTableValue(image_table, r, 'VOXEL_X');
    vy = getTableValue(image_table, r, 'VOXEL_Y');
    printMatArg(script_file, 'pixelsize', sprintf('(%d,%d)', vx, vy), true);
    px = getTableValue(image_table, r, 'POINT_X');
    py = getTableValue(image_table, r, 'POINT_Y');

    px = max(vx,px);
    py = max(vy,py);
    printMatArg(script_file, 'expspotsize', sprintf('(%d,%d)', px, py), true);
    clear px py vx vy

    printMatArg(script_file, 'probetype', getTableValue(image_table, r, 'PROBE'), true);
    printMatArg(script_file, 'target', getTableValue(image_table, r, 'TARGET'), true);
    printMatArg(script_file, 'targettype', getTableValue(image_table, r, 'TARGET_TYPE'), true);
    printMatArg(script_file, 'species', getTableValue(image_table, r, 'SPECIES'), true);
    printMatArg(script_file, 'celltype', getTableValue(image_table, r, 'CELLTYPE'), true);
    printMatArg(script_file, 'gaussrad', num2str(GAUSS_RAD), true);

    printMatFlagArg(script_file, 'nodpc', true);
    fprintf(script_file, '); quit;"\n');

    fclose(script_file);

    fprintf(script_master, 'if [ -s "%s" ]; then\n', mipiPath);
    if ~OVERWRITE
        fprintf(script_master, '\tif [ ! -s "%s" ]; then\n', [resOutStem '_callTable.mat']);
        fprintf(script_master, '\t\tchmod 770 "${SCRIPTDIR}/%s"\n', scriptFileName);
        fprintf(script_master, '\t\tmkdir -p "%s"\n', resOutDir);
        fprintf(script_master, '\t\tsbatch');
    else
        fprintf(script_master, '\tchmod 770 "${SCRIPTDIR}/%s"\n', scriptFileName);
        fprintf(script_master, '\tmkdir -p "%s"\n', resOutDir);
        fprintf(script_master, '\tsbatch');
    end

    fprintf(script_master, ' --job-name="%s"', ['TrueSpotMIP_' iname]);
    fprintf(script_master, ' --cpus-per-task=%d', DETECT_THREADS);
    fprintf(script_master, ' --time=%d:00:00', SERIAL_HR);
    fprintf(script_master, ' --mem=%dg', RAM_PER_CORE);
    fprintf(script_master, ' --error="%s"', [resOutStem '_slurm.err']);
    fprintf(script_master, ' --output="%s"', [resOutStem '_slurm.out']);
    fprintf(script_master, ' "${SCRIPTDIR}/%s"\n', scriptFileName);

    if ~OVERWRITE
        fprintf(script_master, '\telse\n');
        fprintf(script_master, '\t\techo -e "HB MIP run for %s found! Not resubmitting..."\n', iname);
        fprintf(script_master, '\tfi\n');
    end
    fprintf(script_master, 'fi\n');

end

fclose(script_master);

% ========================== Helper Functions ==========================

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index, field};
    if iscell(val)
        val = val{1,1};
    end
end

function printMatFlagArg(fhandle, key, leading_comma)
    if leading_comma
        fprintf(fhandle, ', ');
    end
    fprintf(fhandle, '''-%s''', key);
end

function printMatArg(fhandle, key, value, leading_comma)
    if leading_comma
        fprintf(fhandle, ', ');
    end
    fprintf(fhandle, '''-%s'', ''%s''', key, value);
end

