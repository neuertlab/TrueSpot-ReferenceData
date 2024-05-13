%
%%

%TODO Also have script check for output and not resubmit if it's there.

TRUESPOT_DIR = '/nobackup/p_neuert_lab/hospelb/TrueSpot_Release';
SCRIPT_WD = '/nobackup/p_neuert_lab/hospelb/imgproc/slurm/script';

SCRIPT_DIR_LOCAL = 'C:\Users\bghos\Desktop\slurm';
MATLAB_MODULE_NAME = 'MATLAB/2022a';

% ========================== I/O Info ==========================

IN_DIR = '/nobackup/p_neuert_lab/JohnAdams/Yeast FISH';
%RECURSIVE = true;

OUT_DIR = '/nobackup/p_neuert_lab/hospelb/RNAFISH/JA20240510';

% ========================== Image Options ==========================

CH_SAMPLE = 3;
CH_LIGHT = 1;
CH_DAPI = 2;
CH_TOTAL = 5;
VOX_SIZE = [110 110 500];

CELLSEG_PRESET = 'sacCer_100x';
CELLSEG_ZMIN = 1;
CELLSEG_ZMAX = 1;

GAUSS_RAD = 7;
TH_PRESET = 0; %Offset from default

TARGET_NAME = 'CTT1';
PROBE_NAME = 'CY5';
TARGET_TYPE = 'mRNA';
SPECIES_NAME = 'Saccharomyces cerevisiae';
CELL_TYPE = 'Haploid';

% ========================== Slurm Options ==========================

CPUS_PER_JOB = 4;
RAM_GB_PER_JOB = 16;
HR_PER_JOB = 6;

% ========================== Generate Scripts ==========================

%Generate a script that generates a list of tif files in the directory of
%interest then creates a script for each one and submits a job

MASTER_SCRIPT_PATH = [SCRIPT_DIR_LOCAL filesep 'ts_batch.sh'];
IMAGE_LIST_PATH = [SCRIPT_WD '/imglist.txt'];

CELLSEG_SCRIPT_PATH = [SCRIPT_WD '/ts_cellseg.sh'];
SPOT_SCRIPT_PATH = [SCRIPT_WD '/ts_spots.sh'];
QUANT_SCRIPT_PATH = [SCRIPT_WD '/ts_quant.sh'];

masterScript = fopen(MASTER_SCRIPT_PATH, 'w');

fprintf(masterScript, '#!/bin/bash\n\n');
fprintf(masterScript, 'inputDir="%s"\n', IN_DIR);
fprintf(masterScript, 'outputDir="%s"\n', OUT_DIR);
fprintf(masterScript, 'imageListPath="%s"\n', IMAGE_LIST_PATH);
fprintf(masterScript, 'trueSpotDir="%s"\n', TRUESPOT_DIR);
fprintf(masterScript, 'scriptDir="%s"\n', SCRIPT_WD);
fprintf(masterScript, 'find "${inputDir}" -name *.tif > ${imageListPath}\n\n');

fprintf(masterScript, 'cellSegScript="%s"\n', CELLSEG_SCRIPT_PATH);
fprintf(masterScript, 'spotScript="%s"\n', SPOT_SCRIPT_PATH);
fprintf(masterScript, 'quantScript="%s"\n', QUANT_SCRIPT_PATH);
fprintf(masterScript, 'echo -e "#!/bin/bash\\n\\n" > "${cellSegScript}"\n');
fprintf(masterScript, 'echo -e "#!/bin/bash\\n\\n" > "${spotScript}"\n');
fprintf(masterScript, 'echo -e "#!/bin/bash\\n\\n" > "${quantScript}"\n');
fprintf(masterScript, 'chmod 770 "${cellSegScript}"\n');
fprintf(masterScript, 'chmod 770 "${spotScript}"\n');
fprintf(masterScript, 'chmod 770 "${quantScript}"\n\n');

%https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
%https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
fprintf(masterScript, 'while read -r ipath; do\n');
fprintf(masterScript, '\techo -e "Image found: ${ipath}"\n');
fprintf(masterScript, '\tfname=$(basename "${ipath}")\n');
fprintf(masterScript, '\tfname="${fname%%.*}"\n');
fprintf(masterScript, '\techo -e "\\tImage name: ${fname}"\n\n');

fprintf(masterScript, '\tioutDir="${outputDir}/${fname}"\n');
fprintf(masterScript, '\tif [ ! -d "${ioutDir}" ]; then\n');
fprintf(masterScript, '\t\tmkdir -p "${ioutDir}"\n');
fprintf(masterScript, '\tfi\n\n');

%Cellseg
fprintf(masterScript, '\tmyCsScript="${ioutDir}/${fname}_cellseg.sh"\n');
fprintf(masterScript, '\techo -e "#!/bin/bash\\n\\n" > "${myCsScript}"\n');
fprintf(masterScript, '\techo -e "module load %s\\n" >> "${myCsScript}"\n', MATLAB_MODULE_NAME);
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\"${trueSpotDir}/TrueSpot_CellSeg.sh\\"');
fprintf(masterScript, ' -input \\"${ipath}\\"');
fprintf(masterScript, ' -outpath \\"${ioutDir}\\"');
fprintf(masterScript, ' -imgname \\"${fname}\\"');
fprintf(masterScript, ' -chtotal %d', CH_TOTAL);
fprintf(masterScript, ' -chlight %d', CH_LIGHT);
fprintf(masterScript, ' -chnuc %d', CH_DAPI);
fprintf(masterScript, ' -fzmin %d', CELLSEG_ZMIN);
fprintf(masterScript, ' -fzmax %d', CELLSEG_ZMAX);
fprintf(masterScript, ' -template \\"%s\\"', CELLSEG_PRESET);
fprintf(masterScript, ' -log \\"${ioutDir}/${fname}_cellseg_mat.log\\"');
fprintf(masterScript, '\\n');
fprintf(masterScript, '" >> "${myCsScript}"\n\n');

fprintf(masterScript, '\tcsResFile="${ioutDir}/CellSeg_${fname}.mat"\n');
fprintf(masterScript, '\techo -e "if [ -s \\"${ipath}\\" ]; then\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\tif [ -s \\"${csResFile}\\" ]; then\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\techo -e \\"\\\\tCellseg result found! Skipping...\\"\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\telse\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tchmod 770 \\"${myCsScript}\\"\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tsbatch" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e " --job-name=\\"TSCellSeg_${fname}\\"" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e " --cpus-per-task=%d" >> "${cellSegScript}"\n', CPUS_PER_JOB);
fprintf(masterScript, '\techo -e " --time=%d:00:00" >> "${cellSegScript}"\n', HR_PER_JOB);
fprintf(masterScript, '\techo -e " --mem=%dg" >> "${cellSegScript}"\n', RAM_GB_PER_JOB);
fprintf(masterScript, '\techo -e " --error=\\"${ioutDir}/${fname}_cellseg_slurm.err\\"" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e " --output=\\"${ioutDir}/${fname}_cellseg_slurm.out\\"" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e " \\"${myCsScript}\\"" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "\\tfi\\n" >> "${cellSegScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n\\n" >> "${cellSegScript}"\n\n');


%Spots
fprintf(masterScript, '\tspotsResStem="${ioutDir}/${fname}_spotCall"\n');
fprintf(masterScript, '\tmySpotScript="${ioutDir}/${fname}_spots.sh"\n');
fprintf(masterScript, '\techo -e "#!/bin/bash\\n\\n" > "${mySpotScript}"\n');
fprintf(masterScript, '\techo -e "module load %s\\n" >> "${mySpotScript}"\n', MATLAB_MODULE_NAME);
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\"${trueSpotDir}/TrueSpot_RNASpots.sh\\"');
fprintf(masterScript, ' -input \\"${ipath}\\"');
fprintf(masterScript, ' -outstem \\"${spotsResStem}\\"');
fprintf(masterScript, ' -imgname \\"${fname}\\"');
fprintf(masterScript, ' -chtotal %d', CH_TOTAL);
fprintf(masterScript, ' -chlight %d', CH_LIGHT);
fprintf(masterScript, ' -chsamp %d', CH_SAMPLE);
fprintf(masterScript, ' -cellseg \\"${csResFile}\\"');
fprintf(masterScript, ' -voxelsize \\"(%d,%d,%d)\\"', VOX_SIZE(1), VOX_SIZE(2), VOX_SIZE(3));
fprintf(masterScript, ' -probetype \\"%s\\"', PROBE_NAME);
fprintf(masterScript, ' -target \\"%s\\"', TARGET_NAME);
fprintf(masterScript, ' -targettype \\"%s\\"', TARGET_TYPE);
fprintf(masterScript, ' -species \\"%s\\"', SPECIES_NAME);
fprintf(masterScript, ' -celltype \\"%s\\"', CELL_TYPE);
fprintf(masterScript, ' -gaussrad %d', GAUSS_RAD);
fprintf(masterScript, ' -autominth -automaxth');
fprintf(masterScript, ' -threads %d', CPUS_PER_JOB);
if TH_PRESET < 0
    fprintf(masterScript, ' -precision %d', (TH_PRESET * -1));
else
    fprintf(masterScript, ' -sensitivity %d', TH_PRESET);
end

fprintf(masterScript, ' -log \\"${ioutDir}/${fname}_spots_mat.log\\"');
fprintf(masterScript, '\\n');
fprintf(masterScript, '" >> "${mySpotScript}"\n\n');

fprintf(masterScript, '\techo -e "if [ -s \\"${ipath}\\" ]; then\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\tif [ ! -s \\"${csResFile}\\" ]; then\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\techo -e \\"\\\\tWARNING: Cellseg result not found!\\"\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\tfi\\n" >> "${spotScript}"\n\n');
fprintf(masterScript, '\techo -e "\\tif [ -s \\"${spotsResStem}_callTable.mat\\" ]; then\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\techo -e \\"\\\\tCall table already found! Skipping...\\"\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\telse\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tchmod 770 \\"${mySpotScript}\\"\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tsbatch" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e " --job-name=\\"TSSpotCall_${fname}\\"" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e " --cpus-per-task=%d" >> "${spotScript}"\n', CPUS_PER_JOB);
fprintf(masterScript, '\techo -e " --time=%d:00:00" >> "${spotScript}"\n', HR_PER_JOB);
fprintf(masterScript, '\techo -e " --mem=%dg" >> "${spotScript}"\n', RAM_GB_PER_JOB);
fprintf(masterScript, '\techo -e " --error=\\"${ioutDir}/${fname}_spots_slurm.err\\"" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e " --output=\\"${ioutDir}/${fname}_spots_slurm.out\\"" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e " \\"${mySpotScript}\\"" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\tfi\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n\\n" >> "${spotScript}"\n\n');

%Quant
fprintf(masterScript, '\tmyQuantScript="${ioutDir}/${fname}_quant.sh"\n');
fprintf(masterScript, '\techo -e "#!/bin/bash\\n\\n" > "${myQuantScript}"\n');
fprintf(masterScript, '\techo -e "module load %s\\n" >> "${myQuantScript}"\n', MATLAB_MODULE_NAME);
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\"${trueSpotDir}/TrueSpot_RNAQuant.sh\\"');
fprintf(masterScript, ' -runinfo \\"${spotsResStem}_rnaspotsrun.mat\\"');
fprintf(masterScript, ' -outdir \\"${ioutDir}\\"');
fprintf(masterScript, ' -cellsegpath \\"${csResFile}\\"');
fprintf(masterScript, ' -coordtable \\"${spotsResStem}_callTable.mat\\"');
fprintf(masterScript, ' -workers %d', CPUS_PER_JOB);
fprintf(masterScript, ' -log \\"${ioutDir}/${fname}_quant_mat.log\\"');
fprintf(masterScript, '\\n');
fprintf(masterScript, '" >> "${myQuantScript}"\n\n');

fprintf(masterScript, '\techo -e "if [ -s \\"${ipath}\\" ]; then\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\tif [ -s \\"${fname}_quantData.mat\\" ]; then\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\techo -e \\"\\\\tQuant data already found! Skipping...\\"\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\telse\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tif [ ! -s \\"${spotsResStem}_callTable.mat\\" ]; then\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\t\\techo -e \\"\\\\tSpot call data not found! Skipping...\\"\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\telse\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\t\\tchmod 770 \\"${myQuantScript}\\"\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\t\\tsbatch" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e " --job-name=\\"TSQuant_${fname}\\"" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e " --cpus-per-task=%d" >> "${quantScript}"\n', CPUS_PER_JOB);
fprintf(masterScript, '\techo -e " --time=%d:00:00" >> "${quantScript}"\n', HR_PER_JOB);
fprintf(masterScript, '\techo -e " --mem=%dg" >> "${quantScript}"\n', RAM_GB_PER_JOB);
fprintf(masterScript, '\techo -e " --error=\\"${ioutDir}/${fname}_quant_slurm.err\\"" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e " --output=\\"${ioutDir}/${fname}_quant_slurm.out\\"" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e " \\"${myQuantScript}\\"" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tfi\\n" >> "${spotScript}"\n');
fprintf(masterScript, '\techo -e "\\tfi\\n" >> "${quantScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n\\n" >> "${quantScript}"\n\n');

fprintf(masterScript, 'done < ${imageListPath}\n\n');

fclose(masterScript);
