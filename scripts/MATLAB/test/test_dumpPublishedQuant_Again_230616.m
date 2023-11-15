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

% ========================== Paths ==========================

InputDir = [ImgProcDir filesep 'tables'];
OutputDir = [ImgProcDir filesep 'tables'];

% ========================== Loop ==========================

outpath = [OutputDir filesep 'LiNeuert_sctc.csv'];
outfile = fopen(outpath, 'w');
fprintf(outfile, 'EXP,REP,CH,TIME,CELLNO,TOTAL,NUC\n');

for exp = 1:2
    for rep = 1:3
        inpath = [InputDir filesep 'Results_Exp' num2str(exp) '_rep' num2str(rep) '.mat'];
        
        if ~isfile(inpath); continue; end

        load(inpath, 'Cells', 'RNA_CY5', 'RNA_TMR', 'timepoints');
        tpcount = min(size(timepoints, 2), size(Cells, 2));

        for tpi = 1:tpcount
            %CY5
            cell_count = Cells(tpi);
            time_min = timepoints(tpi);
            for c = 1:cell_count
                fprintf(outfile, '%d,%d,1,%d,%d,', exp, rep, time_min, c);
                fprintf(outfile, '%d,', RNA_CY5.tot(c, tpi));
                fprintf(outfile, '%d\n', RNA_CY5.nuc(c, tpi));
            end

            %TMR
            for c = 1:cell_count
                fprintf(outfile, '%d,%d,2,%d,%d,', exp, rep, time_min, c);
                fprintf(outfile, '%d,', RNA_TMR.tot(c, tpi));
                fprintf(outfile, '%d\n', RNA_TMR.nuc(c, tpi));
            end
        end

        clear Cells RNA_CY5 RNA_TMR timepoints
    end
end

fclose(outfile);