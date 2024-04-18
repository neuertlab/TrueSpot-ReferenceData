%
%%  !! UPDATE TO YOUR BASE DIR
ImgDir = 'C:\Users\hospelb\labdata\imgproc';
%ImgDir = 'D:\usr\bghos\labdat\imgproc';

DataDir = 'D:\Users\hospelb\labdata\imgproc\imgproc';
%DataDir = 'D:\usr\bghos\labdat\imgproc';

ScriptDir = 'C:\Users\hospelb.VUDS\Desktop\slurm';
%ScriptDir = 'C:\Users\bghos\Desktop\slurm';

ClusterWorkDir = '/nobackup/p_neuert_lab/hospelb/imgproc';
ClusterSlurmDir = '/nobackup/p_neuert_lab/hospelb/imgproc/slurm/script';
ClusterScriptsDir = '/nobackup/p_neuert_lab/hospelb/scripts';
ClusterPyenvDir = '/home/hospelb/pyvenv';

addpath('./core');
addpath('./test');
% ========================== Constants ==========================

DETECT_THREADS = 2;
RAM_PER_CORE = 16;
SERIAL_HR = 6;

%For finding file
Z_MIN = 20;
Z_MAX = 42;

TH_MIN_BF = 10;
OVERWRITE = false;

MODULE_NAME = 'MATLAB/2018b';
MATLAB_DIR = [ClusterWorkDir '/matlab'];
PYVENV_NAME = 'bigfish';
BF_OUTDIR = [ClusterWorkDir '/data/bigfish/mip'];

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

TifDirName = ['MIP_' num2str(Z_MIN)];

if Z_MAX < 1
    TifDirName = [TifDirName '_Z'];
else
    TifDirName = [TifDirName '_' num2str(Z_MAX)];
end

% ========================== Generate Bash Script & Slurm Command ==========================

script_master = fopen([ScriptDir filesep 'runall_bf_mip.sh'], 'w');
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
    mipiPath = [idir '/' TifDirName '/' ifilename '_MIP_'...
        num2str(zmin) '-' num2str(zmax) '_c' num2str(ch) '.tif'];

    %Determine output file dir
    trgname = getTableValue(image_table, r, 'TARGET');
    resOutDir = [BF_OUTDIR '/' GroupOutDir '/' ifilename '/' trgname];

    %Script
    scriptFileName = [iname '_bf_mip.sh'];
    script_file = fopen([ScriptDir filesep scriptFileName], 'w');

    fprintf(script_file, '#!/bin/bash\n\n');
    fprintf(script_file, 'module load GCC/6.4.0-2.28\n');
    fprintf(script_file, 'module load Intel/2017.4.196\n');
    fprintf(script_file, 'module load Python/3.6.3\n');
    fprintf(script_file, 'source %s/%s/bin/activate\n', ClusterPyenvDir, PYVENV_NAME);
    fprintf(script_file, 'python3 %s/bigfish_wrapper.py "%s" "%s"', ClusterScriptsDir, mipiPath, resOutDir);

    %- BF Options
    fprintf(script_file, ' --ch_target 1');
    fprintf(script_file, ' --minth 10');
    fprintf(script_file, ' --maxth 1000');

    vx = getTableValue(image_table, r, 'VOXEL_X');
    vy = getTableValue(image_table, r, 'VOXEL_Y');
    fprintf(script_file, ' --pixelsz "(%d,%d)"', vy,vx);
    px = getTableValue(image_table, r, 'POINT_X');
    py = getTableValue(image_table, r, 'POINT_Y');

    px = max(vx,px);
    py = max(vy,py);
    fprintf(script_file, ' --pointsz "(%d,%d)"', py,px);
    clear px py vx vy

    fprintf(script_file, ' --zkeep 1.0');
    fprintf(script_file, ' --gaussfit');

    bfStem = [resOutDir '/' iname '_bf_mip'];
    fprintf(script_file, '\ndeactivate\n\n');
    fprintf(script_file, 'module load %s\n', MODULE_NAME);
    fprintf(script_file, 'cd %s\n', MATLAB_DIR);
    fprintf(script_file, 'matlab -nodisplay -nosplash -logfile "%s" -r "cd %s; Main_Bigfish2Mat(''%s'',''%s''); quit;"\n',...
        [bfStem '_mat.log'], MATLAB_DIR, resOutDir, bfStem);
    fprintf(script_file, 'module unload\n\n');

    fprintf(script_file, 'if [ -s "%s_callTable.mat" ]; then\n', bfStem);
    fprintf(script_file, '\techo -e "Call table file found. Assuming conversion success."\n');
    fprintf(script_file, '\tcd "%s"\n', resOutDir);
    fprintf(script_file, '\trm ./spots_*.csv\n');
    fprintf(script_file, 'fi\n\n');

    fclose(script_file);

    if ~OVERWRITE
        fprintf(script_master, '\tif [ ! -s "%s" ]; then\n', [bfStem '_callTable.mat']);
        fprintf(script_master, '\t\tchmod 770 "${SCRIPTDIR}/%s"\n', scriptFileName);
        fprintf(script_master, '\t\tmkdir -p "%s"\n', resOutDir);
        fprintf(script_master, '\t\tsbatch');
    else
        fprintf(script_master, '\tchmod 770 "${SCRIPTDIR}/%s"\n', scriptFileName);
        fprintf(script_master, '\tmkdir -p "%s"\n', resOutDir);
        fprintf(script_master, '\tsbatch');
    end

    fprintf(script_master, ' --job-name="%s"', ['BigfishMIP_' iname]);
    fprintf(script_master, ' --cpus-per-task=4');
    fprintf(script_master, ' --time=%d:00:00', SERIAL_HR);
    fprintf(script_master, ' --mem=%dg', RAM_PER_CORE);
    fprintf(script_master, ' --error="%s"', [bfStem '_slurm.err']);
    fprintf(script_master, ' --output="%s"', [bfStem '_slurm.out']);
    fprintf(script_master, ' "${SCRIPTDIR}/%s"\n', scriptFileName);

    if ~OVERWRITE
        fprintf(script_master, '\telse\n');
        fprintf(script_master, '\t\techo -e "BF MIP run for %s found! Not resubmitting..."\n', iname);
        fprintf(script_master, '\tfi\n');
    end

    clear ipath zmin zmax mipipath dimZ ch idir ifilename trgname bfStem
end

fclose(script_master);

% ========================== Helper Functions ==========================

function val = getTableValue(mytable, row_index, field)
    val = mytable{row_index, field};
    if iscell(val)
        val = val{1,1};
    end
end
