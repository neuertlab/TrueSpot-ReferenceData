%
%%

TRUESPOT_DIR = '/nobackup/p_neuert_lab/hospelb/TrueSpot_Release';
SCRIPT_WD = '/nobackup/p_neuert_lab/hospelb/imgproc/slurm/script';

%SCRIPT_DIR_LOCAL = 'C:\Users\bghos\Desktop\slurm';
SCRIPT_DIR_LOCAL = 'C:\Users\hospelb.VUDS\Desktop\slurm';
MATLAB_MODULE_NAME = 'MATLAB/2022a';

% ========================== I/O Info ==========================

IN_DIR = '/nobackup/p_neuert_lab/hospelb/RNAFISH/Images/JA20240510';
%RECURSIVE = true;

OUT_DIR = '/nobackup/p_neuert_lab/hospelb/RNAFISH/Analysis/JA20240510';

% ========================== Image Options ==========================

CH_SAMPLE = 3;
%CH_SAMPLE = 4;
%CH_SAMPLE = 5;

CH_LIGHT = 1;
CH_DAPI = 2;
CH_TOTAL = 5;
VOX_SIZE = [110 110 500];

CELLSEG_PRESET = 'sacCer_100x';
CELLSEG_ZMIN = 15;
CELLSEG_ZMAX = 23;

GAUSS_RAD = 7;
TH_PRESET = 0; %Offset from default

TARGET_NAME = 'CTT1';
PROBE_NAME = 'CY5';
%TARGET_NAME = 'STL1';
%PROBE_NAME = 'TMR';
%TARGET_NAME = 'GPP1';
%PROBE_NAME = 'AF594';

TARGET_TYPE = 'mRNA';
SPECIES_NAME = 'Saccharomyces cerevisiae';
CELL_TYPE = 'GNY0117 Haploid';

% ========================== Slurm Options ==========================

CPUS_PER_JOB = 4;
RAM_GB_PER_JOB = 32;
HR_PER_JOB = 10;

% ========================== Generate Scripts ==========================

%Generate a script that generates a list of tif files in the directory of
%interest then creates a script for each one and submits a job

MASTER_SCRIPT_PATH = [SCRIPT_DIR_LOCAL filesep 'ts_batch_gen.sh'];
IMAGE_LIST_PATH = [SCRIPT_WD '/imglist.txt'];
SUBMISSION_SCRIPT_PATH = [SCRIPT_WD '/ts_batch.sh'];

masterScript = fopen(MASTER_SCRIPT_PATH, 'w');

fprintf(masterScript, '#!/bin/bash\n\n');
fprintf(masterScript, 'inputDir="%s"\n', IN_DIR);
fprintf(masterScript, 'outputDir="%s"\n', OUT_DIR);
fprintf(masterScript, 'imageListPath="%s"\n', IMAGE_LIST_PATH);
fprintf(masterScript, 'trueSpotDir="%s"\n', TRUESPOT_DIR);
fprintf(masterScript, 'scriptDir="%s"\n', SCRIPT_WD);
fprintf(masterScript, 'find "${inputDir}" -name *.tif > ${imageListPath}\n\n');

fprintf(masterScript, 'submitScript="%s"\n', SUBMISSION_SCRIPT_PATH);
fprintf(masterScript, 'echo -e "#!/bin/bash\\n" > "${submitScript}"\n');
fprintf(masterScript, 'chmod 770 "${submitScript}"\n\n');

%https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
%https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
fprintf(masterScript, 'while read -r ipath; do\n');
fprintf(masterScript, '\techo -e "Image found: ${ipath}"\n');
fprintf(masterScript, '\tfname=$(basename "${ipath}")\n');
fprintf(masterScript, '\tfname=${fname%%.*}\n');
fprintf(masterScript, '\tfname=${fname// /_}\n');
fprintf(masterScript, '\tfname=${fname//.ome/}\n');
fprintf(masterScript, '\tfname=${fname//./}\n');
fprintf(masterScript, '\tiname=${fname}_CH%d\n', CH_SAMPLE);
fprintf(masterScript, '\techo -e "\\tImage name: ${iname}"\n\n');

fprintf(masterScript, '\tioutDir="${outputDir}/${fname}/CH%d"\n', CH_SAMPLE);
fprintf(masterScript, '\tif [ ! -d "${ioutDir}" ]; then\n');
fprintf(masterScript, '\t\tmkdir -p "${ioutDir}"\n');
fprintf(masterScript, '\tfi\n\n');

fprintf(masterScript, '\tmyImgScript="${ioutDir}/${iname}_truespot.sh"\n');
fprintf(masterScript, '\techo -e "#!/bin/bash\\n" > "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "module load %s" >> "${myImgScript}"\n\n', MATLAB_MODULE_NAME);

%Cellseg
fprintf(masterScript, '\tcsResFile="${ioutDir}/CellSeg_${iname}.mat"\n');
fprintf(masterScript, '\techo -e "if [ ! -s \\"${csResFile}\\" ]; then" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\t\\"${trueSpotDir}/TrueSpot_CellSeg.sh\\"');
fprintf(masterScript, ' -input \\"${ipath}\\"');
fprintf(masterScript, ' -outpath \\"${ioutDir}\\"');
fprintf(masterScript, ' -imgname \\"${iname}\\"');
fprintf(masterScript, ' -chtotal %d', CH_TOTAL);
fprintf(masterScript, ' -chlight %d', CH_LIGHT);
fprintf(masterScript, ' -chnuc %d', CH_DAPI);
fprintf(masterScript, ' -fzmin %d', CELLSEG_ZMIN);
fprintf(masterScript, ' -fzmax %d', CELLSEG_ZMAX);
fprintf(masterScript, ' -template \\"%s\\"', CELLSEG_PRESET);
fprintf(masterScript, ' -log \\"${ioutDir}/${iname}_cellseg_mat.log\\"');
fprintf(masterScript, '" >> "${myImgScript}"\n\n');
fprintf(masterScript, '\techo -e "else" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "\\techo -e \\"Cellseg results found! Skipping cell segmentation...\\"" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n" >> "${myImgScript}"\n\n');

%Spots
fprintf(masterScript, '\tspotsResStem="${ioutDir}/${iname}_spotCall"\n');
fprintf(masterScript, '\techo -e "if [ -s \\"${csResFile}\\" ]; then" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\t\\"${trueSpotDir}/TrueSpot_RNASpots.sh\\"');
fprintf(masterScript, ' -input \\"${ipath}\\"');
fprintf(masterScript, ' -outstem \\"${spotsResStem}\\"');
fprintf(masterScript, ' -imgname \\"${iname}\\"');
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

fprintf(masterScript, ' -log \\"${ioutDir}/${iname}_spots_mat.log\\"');
fprintf(masterScript, '" >> "${myImgScript}"\n\n');
fprintf(masterScript, '\techo -e "else" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "\\techo -e \\"Cellseg results not found! Terminating...\\"" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "\\texit 1" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n" >> "${myImgScript}"\n\n');

%Quant
fprintf(masterScript, '\tquantResFile="${ioutDir}/${iname}_quantData.mat"\n');
fprintf(masterScript, '\techo -e "if [ -s \\"${spotsResStem}_callTable.mat\\" ]; then" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\t\\"${trueSpotDir}/TrueSpot_RNAQuant.sh\\"');
fprintf(masterScript, ' -runinfo \\"${spotsResStem}_rnaspotsrun.mat\\"');
fprintf(masterScript, ' -outdir \\"${ioutDir}\\"');
fprintf(masterScript, ' -cellsegpath \\"${csResFile}\\"');
fprintf(masterScript, ' -coordtable \\"${spotsResStem}_callTable.mat\\"');
fprintf(masterScript, ' -workers %d', CPUS_PER_JOB);
fprintf(masterScript, ' -log \\"${ioutDir}/${iname}_quant_mat.log\\"');
fprintf(masterScript, '" >> "${myImgScript}"\n\n');
fprintf(masterScript, '\techo -e "else" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "\\techo -e \\"Spot call results not found! Terminating...\\"" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "\\texit 1" >> "${myImgScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n" >> "${myImgScript}"\n\n');

%Image job
fprintf(masterScript, '\techo -e "if [ -s \\"${ipath}\\" ]; then" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\tif [ -s \\"${quantResFile}\\" ]; then" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\techo -e \\"Quant data already found! Skipping...\\"" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\telse" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tchmod 770 \\"${myImgScript}\\"" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\t\\tsbatch');
fprintf(masterScript, ' --job-name=\\"TS_${iname}\\"');
fprintf(masterScript, ' --cpus-per-task=%d', CPUS_PER_JOB);
fprintf(masterScript, ' --time=%d:00:00', HR_PER_JOB);
fprintf(masterScript, ' --mem=%dg', RAM_GB_PER_JOB);
fprintf(masterScript, ' --error=\\"${ioutDir}/${iname}_truespot_slurm.err\\"');
fprintf(masterScript, ' --out=\\"${ioutDir}/${iname}_truespot_slurm.out\\"');
fprintf(masterScript, ' \\"${myImgScript}\\"');
fprintf(masterScript, '" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\tfi" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n" >> "${submitScript}"\n\n');

fprintf(masterScript, 'done < ${imageListPath}\n\n');

fclose(masterScript);
