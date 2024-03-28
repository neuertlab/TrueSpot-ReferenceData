%
%%

function Main_Bigfish2Mat(input_dir, output_path)
    addpath('./core');
    addpath('./test');
    
    versionStr = "2024.03.28.00";
    fprintf("Main_Bigfish2Mat | Version %s\n", versionStr);
    
% ========================== Read Summary File ==========================
    fprintf("Parsing Big-FISH run summary...\n");
    summary_file_path = [input_dir filesep 'summary.txt'];
    if ~isfile(summary_file_path)
        return;
    end
	[zmin, zmax, bfthresh] = BigfishCompare.readSummaryTxt(summary_file_path);
	fprintf("Z Range: %d - %d\n", zmin, zmax);
	fprintf("BF Threshold: %d\n", bfthresh);
    
% ========================== Import CSVs ==========================

    %Check if import needed...
    filepath = [output_path '_callTable.mat'];
    fprintf("Checking for %s ...\n", filepath);
    if isfile(filepath)
        finfo = who('-file', filepath);
        if ~isempty(find(ismember(finfo, 'call_table'),1))
            fprintf("Call table already found. No import needed!\n");
            return;
        end
    end

    fprintf("Importing Big-FISH output...\n");
	%[~, ~] = BigfishCompare.importBigFishCsvs(input_dir, output_path, zmin);
    BigfishCompare.importBigFishCsvs(input_dir, output_path, zmin, []); %TODO New version of func takes idims!
    
% ========================== Test ==========================

    filepath = [output_path '_spotTable.mat'];
    if isfile(filepath)
        load(filepath, 'spot_table');
        st_count = size(spot_table,1);
        fprintf("CHECK PASSED: Spot table contains entries for %d threshold values.\n", st_count);
        clear spot_table;
    else
        fprintf("CHECK FAILED: Spot table file was not correctly exported.\n");
        return;
    end

    filepath = [output_path '_callTable.mat'];
    if isfile(filepath)
        load(filepath, 'call_table');
        s_count = size(call_table,1);
        fprintf("CHECK PASSED: Call table contains entries for %d spots.\n", s_count);
        clear call_table;
    else
        fprintf("CHECK FAILED: Coordinate table file was not correctly exported.\n");
        return;
    end
    
%     filepath = [output_path '_coordTable.mat'];
%     if isfile(filepath)
%         load(filepath, 'coord_table');
%         ct_count = size(coord_table,1);
%         fprintf("CHECK PASSED: Coord table contains entries for %d threshold values.\n", ct_count);
%         clear coord_table;
%     else
%         fprintf("CHECK FAILED: Coordinate table file was not correctly exported.\n");
%         return;
%     end
%     
%     if st_count == ct_count
%         fprintf("CHECK PASSED: Spot and coordinate table sizes match.\n");
%     else
%         fprintf("CHECK FAILED: Spot and coordinate table sizes do not match!\n");
%     end
    
end