%
%%

TRUESPOT_DIR = '/nobackup/p_neuert_lab/hospelb/TrueSpot_Release';
SCRIPT_WD = '/nobackup/p_neuert_lab/hospelb/imgproc/slurm/script';

%SCRIPT_DIR_LOCAL = 'C:\Users\bghos\Desktop\slurm';
SCRIPT_DIR_LOCAL = 'C:\Users\hospelb.VUDS\Desktop\slurm';
MATLAB_MODULE_NAME = 'MATLAB/2022a';

% ========================== I/O Info ==========================

IN_DIR = '/nobackup/p_neuert_lab/hospelb/RNAFISH/Images/JA20240514';
%RECURSIVE = true;

OUT_DIR = '/nobackup/p_neuert_lab/hospelb/RNAFISH/Analysis/JA20240514';

% ========================== Image Options ==========================

CH_SAMPLE = [3 4 5];

CH_LIGHT = 1;
CH_DAPI = 2;
CH_TOTAL = 5;
VOX_SIZE = [110 110 500];

CELLSEG_PRESET = 'sacCer_60x';
CELLSEG_ZMIN = 34;
CELLSEG_ZMAX = 39;
NUCSEG_ZMIN = 30;
NUCSEG_ZMAX = 39;

GAUSS_RAD = 7;
TH_PRESET = 0; %Offset from default

%TARGET_NAMES = {'CTT1' 'STL1' 'GPP1'}; %JA 5/10/24
%TARGET_NAMES = {'STL1' 'GPP1' 'CTT1'}; %JA 6/4/24
TARGET_NAMES = {'GPD1' 'GPP2' 'HSP12'}; %JA 5/14/24
%TARGET_NAMES = {'GPP2' 'GPD1' 'HSP12'}; %JA 6/6/24
PROBE_NAMES = {'CY5' 'TMR' 'AF594'}; %JA 5/10 and 5/14
%PROBE_NAMES = {'TMR' 'AF594' 'CY5'}; %JA 6/4
%PROBE_NAMES = {'TMR' 'CY5' 'AF594'}; %JA 6/6
TARGET_TYPES = {'mRNA' 'mRNA' 'mRNA'};

SPECIES_NAME = 'Saccharomyces cerevisiae';
CELL_TYPE = 'GNY0117 Haploid';

% ========================== Slurm Options ==========================

CPUS_PER_JOB_CELLSEG = 2;
RAM_GB_PER_JOB_CELLSEG = 32;
HR_PER_JOB_CELLSEG = 4;

CPUS_PER_JOB_POSTRES = 2;
RAM_GB_PER_JOB_POSTRES = 16;
HR_PER_JOB_POSTRES = 4;

CPUS_PER_JOB = 4;
RAM_GB_PER_JOB = 32;
HR_PER_JOB = 10;

% ========================== Generate Scripts ==========================

%Generate a script that generates a list of tif files in the directory of
%interest then creates a script for each one and submits a job

MASTER_SCRIPT_PATH = [SCRIPT_DIR_LOCAL filesep 'ts_batch_gen.sh'];
IMAGE_LIST_PATH = [SCRIPT_WD '/imglist.txt'];
SUBMISSION_SCRIPT_PATH = [SCRIPT_WD '/ts_batch.sh'];

sampleChannelCount = size(CH_SAMPLE, 2);

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
%fprintf(masterScript, '\tiname=${fname}_CH%d\n', CH_SAMPLE);
fprintf(masterScript, '\techo -e "\\tImage name: ${fname}"\n\n');

%fprintf(masterScript, '\tioutDir="${outputDir}/${fname}/CH%d"\n', CH_SAMPLE);
fprintf(masterScript, '\tioutDir="${outputDir}/${fname}"\n');
fprintf(masterScript, '\tif [ ! -d "${ioutDir}" ]; then\n');
fprintf(masterScript, '\t\tmkdir -p "${ioutDir}"\n');
fprintf(masterScript, '\tfi\n\n');

% fprintf(masterScript, '\tmyImgScript="${ioutDir}/${iname}_truespot.sh"\n');
% fprintf(masterScript, '\techo -e "#!/bin/bash\\n" > "${myImgScript}"\n');
% fprintf(masterScript, '\techo -e "module load %s" >> "${myImgScript}"\n\n', MATLAB_MODULE_NAME);

fprintf(masterScript, '\tmyCellsegScript="${ioutDir}/${fname}_truespot_cs.sh"\n');
fprintf(masterScript, '\techo -e "#!/bin/bash\\n" > "${myCellsegScript}"\n');
fprintf(masterScript, '\techo -e "module load %s" >> "${myCellsegScript}"\n\n', MATLAB_MODULE_NAME);

%Cellseg
fprintf(masterScript, '\tcsResFile="${ioutDir}/CellSeg_${fname}.mat"\n');
fprintf(masterScript, '\techo -e "if [ ! -s \\"${csResFile}\\" ]; then" >> "${myCellsegScript}"\n');
fprintf(masterScript, '\techo -e "');
fprintf(masterScript, '\\t\\"${trueSpotDir}/TrueSpot_CellSeg.sh\\"');
fprintf(masterScript, ' -input \\"${ipath}\\"');
fprintf(masterScript, ' -outpath \\"${ioutDir}\\"');
fprintf(masterScript, ' -imgname \\"${fname}\\"');
fprintf(masterScript, ' -chtotal %d', CH_TOTAL);
fprintf(masterScript, ' -chlight %d', CH_LIGHT);
fprintf(masterScript, ' -chnuc %d', CH_DAPI);
fprintf(masterScript, ' -fzmin %d', CELLSEG_ZMIN);
fprintf(masterScript, ' -fzmax %d', CELLSEG_ZMAX);
fprintf(masterScript, ' -nuczmin %d', NUCSEG_ZMIN);
fprintf(masterScript, ' -nuczmax %d', NUCSEG_ZMAX);
%fprintf(masterScript, ' -ocellmask \"${ioutDir}/${fname}_cellmask.tif\"');
%fprintf(masterScript, ' -onucmask \"${ioutDir}/${fname}_nucmask.tif\"');
fprintf(masterScript, ' -template \\"%s\\"', CELLSEG_PRESET);
fprintf(masterScript, ' -log \\"${ioutDir}/${fname}_cellseg_mat.log\\"');
fprintf(masterScript, '" >> "${myCellsegScript}"\n\n');
fprintf(masterScript, '\techo -e "else" >> "${myCellsegScript}"\n');
fprintf(masterScript, '\techo -e "\\techo -e \\"Cellseg results found! Skipping cell segmentation...\\"" >> "${myCellsegScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n" >> "${myCellsegScript}"\n\n');

%Individual channels...
for ci = 1:sampleChannelCount
    sampleCh = CH_SAMPLE(ci);

    fprintf(masterScript, '\n\tiname=${fname}_CH%d\n', sampleCh);
    fprintf(masterScript, '\tcoutDir=${ioutDir}/CH%d\n', sampleCh);
    fprintf(masterScript, '\tif [ ! -d "${coutDir}" ]; then\n');
    fprintf(masterScript, '\t\tmkdir -p "${coutDir}"\n');
    fprintf(masterScript, '\tfi\n\n');

    fprintf(masterScript, '\tmyChannelScript="${coutDir}/${iname}_truespot.sh"\n');
    fprintf(masterScript, '\techo -e "#!/bin/bash\\n" > "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "module load %s" >> "${myChannelScript}"\n\n', MATLAB_MODULE_NAME);

    %Spots
    fprintf(masterScript, '\tspotsResStem="${coutDir}/${iname}_spotCall"\n');
    fprintf(masterScript, '\techo -e "if [ -s \\"${csResFile}\\" ]; then" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "');
    fprintf(masterScript, '\\t\\"${trueSpotDir}/TrueSpot_RNASpots.sh\\"');
    fprintf(masterScript, ' -input \\"${ipath}\\"');
    fprintf(masterScript, ' -outstem \\"${spotsResStem}\\"');
    fprintf(masterScript, ' -imgname \\"${iname}\\"');
    fprintf(masterScript, ' -chtotal %d', CH_TOTAL);
    fprintf(masterScript, ' -chtrans %d', CH_LIGHT);
    fprintf(masterScript, ' -chsamp %d', sampleCh);
    fprintf(masterScript, ' -cellseg \\"${csResFile}\\"');
    fprintf(masterScript, ' -voxelsize \\"(%d,%d,%d)\\"', VOX_SIZE(1), VOX_SIZE(2), VOX_SIZE(3));
    fprintf(masterScript, ' -probetype \\"%s\\"', PROBE_NAMES{ci});
    fprintf(masterScript, ' -target \\"%s\\"', TARGET_NAMES{ci});
    fprintf(masterScript, ' -targettype \\"%s\\"', TARGET_TYPES{ci});
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

    fprintf(masterScript, ' -log \\"${coutDir}/${iname}_spots_mat.log\\"');
    fprintf(masterScript, '" >> "${myChannelScript}"\n\n');
    fprintf(masterScript, '\techo -e "else" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "\\techo -e \\"Cellseg results not found! Terminating...\\"" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "\\texit 1" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "fi\\n" >> "${myChannelScript}"\n\n');

    %Quant
    fprintf(masterScript, '\tquantResFile="${coutDir}/${iname}_quantData.mat"\n');
    fprintf(masterScript, '\techo -e "if [ -s \\"${spotsResStem}_callTable.mat\\" ]; then" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "');
    fprintf(masterScript, '\\t\\"${trueSpotDir}/TrueSpot_RNAQuant.sh\\"');
    fprintf(masterScript, ' -runinfo \\"${spotsResStem}_rnaspotsrun.mat\\"');
    fprintf(masterScript, ' -outdir \\"${coutDir}\\"');
    fprintf(masterScript, ' -cellsegpath \\"${csResFile}\\"');
    fprintf(masterScript, ' -coordtable \\"${spotsResStem}_callTable.mat\\"');
    %fprintf(masterScript, ' -workers %d', CPUS_PER_JOB);
    fprintf(masterScript, ' -log \\"${coutDir}/${iname}_quant_mat.log\\"');
    fprintf(masterScript, '" >> "${myChannelScript}"\n\n');
    fprintf(masterScript, '\techo -e "else" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "\\techo -e \\"Spot call results not found! Terminating...\\"" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "\\texit 1" >> "${myChannelScript}"\n');
    fprintf(masterScript, '\techo -e "fi\\n" >> "${myChannelScript}"\n\n');

    %Image job
    fprintf(masterScript, '\techo -e "if [ -s \\"${quantResFile}\\" ]; then" >> "${myCellsegScript}"\n');
    fprintf(masterScript, '\techo -e "\\techo -e \\"Quant data already found! Skipping...\\"" >> "${myCellsegScript}"\n');
    fprintf(masterScript, '\techo -e "else" >> "${myCellsegScript}"\n');
    fprintf(masterScript, '\techo -e "\\tchmod 770 \\"${myChannelScript}\\"" >> "${myCellsegScript}"\n');
    fprintf(masterScript, '\techo -e "\\tsbatch');
    fprintf(masterScript, ' --job-name=\\"TS_${iname}\\"');
    fprintf(masterScript, ' --cpus-per-task=%d', CPUS_PER_JOB);
    fprintf(masterScript, ' --time=%d:00:00', HR_PER_JOB);
    fprintf(masterScript, ' --mem=%dg', RAM_GB_PER_JOB);
    fprintf(masterScript, ' --error=\\"${coutDir}/${iname}_truespot_slurm.err\\"');
    fprintf(masterScript, ' --out=\\"${coutDir}/${iname}_truespot_slurm.out\\"');
    fprintf(masterScript, ' \\"${myChannelScript}\\"');
    fprintf(masterScript, '" >> "${myCellsegScript}"\n');
    fprintf(masterScript, '\techo -e "fi\\n" >> "${myCellsegScript}"\n');

end

%Image job
fprintf(masterScript, '\n\techo -e "if [ -s \\"${ipath}\\" ]; then" >> "${submitScript}"\n');
%fprintf(masterScript, '\techo -e "\\tif [ -s \\"${quantResFile}\\" ]; then" >> "${submitScript}"\n');
%fprintf(masterScript, '\techo -e "\\t\\techo -e \\"Quant data already found! Skipping...\\"" >> "${submitScript}"\n');
%fprintf(masterScript, '\techo -e "\\telse" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\tchmod 770 \\"${myCellsegScript}\\"" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "\\tsbatch');
fprintf(masterScript, ' --job-name=\\"TSCS_${fname}\\"');
fprintf(masterScript, ' --cpus-per-task=%d', CPUS_PER_JOB_CELLSEG);
fprintf(masterScript, ' --time=%d:00:00', HR_PER_JOB_CELLSEG);
fprintf(masterScript, ' --mem=%dg', RAM_GB_PER_JOB_CELLSEG);
fprintf(masterScript, ' --error=\\"${ioutDir}/${fname}_ts_cellseg_slurm.err\\"');
fprintf(masterScript, ' --out=\\"${ioutDir}/${fname}_ts_cellseg_slurm.out\\"');
fprintf(masterScript, ' \\"${myCellsegScript}\\"');
fprintf(masterScript, '" >> "${submitScript}"\n');
%fprintf(masterScript, '\techo -e "\\tfi" >> "${submitScript}"\n');
fprintf(masterScript, '\techo -e "fi\\n" >> "${submitScript}"\n\n');

fprintf(masterScript, 'done < ${imageListPath}\n\n');

%Generate a post-processing script (one to submit, one that does
%submission)
[~, outdirName, ~] = fileparts(OUT_DIR);
fprintf(masterScript, '\npostJobScript="${outputDir}/procRes.sh"\n');
fprintf(masterScript, 'postJobSubmitScript=\"${outputDir}/doProcRes.sh\"\n');
fprintf(masterScript, 'postJobMatLogQCPath="${outputDir}/procResMATQC.log"\n');
fprintf(masterScript, 'postJobMatLogDumpPath="${outputDir}/procResMATDump.log"\n');
fprintf(masterScript, 'postJobOutPath="${outputDir}/procRes.out"\n');
fprintf(masterScript, 'postJobErrPath="${outputDir}/procRes.err"\n');
fprintf(masterScript, 'echo -e "#!/bin/bash\\n" > "${postJobScript}"\n');
fprintf(masterScript, 'echo -e "module load %s" >> "${postJobScript}"\n', MATLAB_MODULE_NAME);
fprintf(masterScript, 'echo -e "matlab -nodisplay -nosplash -logfile \\"${postJobMatLogQCPath}\\"');
fprintf(masterScript, ' -r \\"cd ''%s/src'';', TRUESPOT_DIR);
fprintf(masterScript, ' Main_QCSummary(''-input'', ''${outputDir}'');');
fprintf(masterScript, ' quit;\\"" >> "${postJobScript}"\n');
fprintf(masterScript, 'echo -e "\\nmatlab -nodisplay -nosplash -logfile \\"${postJobMatLogDumpPath}\\"');
fprintf(masterScript, ' -r \\"cd ''%s/src'';', TRUESPOT_DIR);
fprintf(masterScript, ' Main_DumpQuantResults(''-input'', ''${outputDir}'');');
fprintf(masterScript, ' quit;\\"" >> "${postJobScript}"\n');
fprintf(masterScript, 'echo -e "#!/bin/bash\\n" > "${postJobSubmitScript}"\n');
fprintf(masterScript, 'echo -e "chmod 770 \\"${postJobScript}\\"" >> "${postJobSubmitScript}"\n');
fprintf(masterScript, 'echo -e "sbatch');
fprintf(masterScript, ' --job-name=\\"PostRes_%s\\"', outdirName);
fprintf(masterScript, ' --cpus-per-task=%d', CPUS_PER_JOB_POSTRES);
fprintf(masterScript, ' --time=%d:00:00', HR_PER_JOB_POSTRES);
fprintf(masterScript, ' --mem=%dg', RAM_GB_PER_JOB_POSTRES);
fprintf(masterScript, ' --error=\\"${postJobErrPath}\\"');
fprintf(masterScript, ' --out=\\"${postJobOutPath}\\"');
fprintf(masterScript, ' \\"${postJobScript}\\"');
fprintf(masterScript, '" >> "${postJobSubmitScript}"\n');
fprintf(masterScript, 'chmod 770 "${postJobSubmitScript}"\n');

fclose(masterScript);
