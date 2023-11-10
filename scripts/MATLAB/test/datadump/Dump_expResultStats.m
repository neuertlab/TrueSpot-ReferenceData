%
%%

%RECALL is maximum recall
%IMGNAME GROUP_A GROUP_B HB_RECALL HB_AUC HB_FSCORE BF_RECALL BF_AUC
%BF_FSCORE RS_RECALL RS_AUC DB_RECALL DB_AUC

function Dump_expResultStats(outputFile, analysis)

    if isempty(outputFile); return; end
    if isempty(analysis); return; end

    %Determine if skip.
    %Skip if sim or no truthset.
    if startsWith(analysis.imgname, 'sim')
        return;
    elseif startsWith(analysis.imgname, 'rsfish_sim')
        return;
    end

    if ~isfield(analysis, 'exprefset')
        return;
    end

    fprintf('>> Analyzing %s...\n', analysis.imgname);

    fprintf(outputFile, '%s\t', analysis.imgname);

    %Determine groups
    printGroups(outputFile, analysis);

    printHBRes(outputFile, analysis);
    printBFRes(outputFile, analysis);
    printRSRes(outputFile, analysis);
    printDBRes(outputFile, analysis);

    fprintf(outputFile, '\n');
end

function printHBRes(outputFile, analysis)

    if isfield(analysis, 'results_hb')
        %Look for results BH
        resStruct = analysis.results_hb;
        if isfield(analysis.results_hb, 'truthset_BH')
            resStruct = analysis.results_hb.truthset_BH;
        end
        printRes(outputFile, resStruct, true, true);
    else
        fprintf(outputFile, 'NaN\tNaN\tNaN\t');
    end

end

function printBFRes(outputFile, analysis)

    if isfield(analysis, 'results_bf')
        %Look for results BH
        resStruct = analysis.results_bf;
        if isfield(analysis.results_bf, 'truthset_BH')
            resStruct = analysis.results_bf.truthset_BH;
        end
        printRes(outputFile, resStruct, true, true);
    else
        fprintf(outputFile, 'NaN\tNaN\tNaN\t');
    end

end

function printRSRes(outputFile, analysis)

    if isfield(analysis, 'results_rs')
        %Look for results BH
        resStruct = analysis.results_rs;
        if isfield(analysis.results_rs, 'truthset_BH')
            resStruct = analysis.results_rs.truthset_BH;
        end
        printRes(outputFile, resStruct, false, true);
    else
        fprintf(outputFile, 'NaN\tNaN\t');
    end

end

function printDBRes(outputFile, analysis)

    if isfield(analysis, 'results_db')
        %Look for results BH
        resStruct = analysis.results_db;
        if isfield(analysis.results_db, 'truthset_BH')
            resStruct = analysis.results_db.truthset_BH;
        end
        printRes(outputFile, resStruct, false, false);
    else
        fprintf(outputFile, 'NaN\tNaN');
    end

end

function printRes(outputFile, resStruct, inclFScore, endTab)

    if isempty(resStruct)
        fprintf(outputFile, 'NaN\tNaN');
        if inclFScore
            fprintf(outputFile, '\tNaN');
        end
        if endTab; fprintf(outputFile, '\t'); end
        return;
    end

    if isfield(resStruct, 'performance_trimmed')
        max_recall = max(resStruct.performance_trimmed{:,'sensitivity'}, [], 'all');
        fprintf(outputFile, '%f\t', max_recall);
        fprintf(outputFile, '%f', resStruct.pr_auc_trimmed);
        if inclFScore
            fprintf(outputFile, '\t%f', resStruct.fscore_autoth_trimmed);
        end
    elseif isfield(resStruct, 'performance')
        max_recall = max(resStruct.performance{:,'sensitivity'}, [], 'all');
        fprintf(outputFile, '%f\t', max_recall);
        fprintf(outputFile, '%f', resStruct.pr_auc);
        if inclFScore
            fprintf(outputFile, '\t%f', resStruct.fscore_autoth);
        end
    else
        fprintf(outputFile, 'NaN\tNaN');
        if inclFScore
            fprintf(outputFile, '\tNaN');
        end
    end

    if endTab; fprintf(outputFile, '\t'); end

end

function printGroups(outputFile, analysis)
    if startsWith(analysis.imgname, 'sim_')
        fprintf(outputFile, 'SimBig\tSimBig\t');
    elseif startsWith(analysis.imgname, 'simvar_')
        fprintf(outputFile, 'SimVar\tSimVar\t');
    elseif startsWith(analysis.imgname, 'simvarmass_')
        if contains(analysis.imgname, 'CY5L')
            fprintf(outputFile, 'SimCY5L\tSimCY5L\t');
        elseif contains(analysis.imgname, 'TMRL')
            fprintf(outputFile, 'SimTMRL\tSimTMRL\t');
        else
            fprintf(outputFile, 'SimVar1000\tSimVar1000\t');
        end
    elseif startsWith(analysis.imgname, 'mESC4d_')
        if endsWith(analysis.imgname, 'AF594')
            fprintf(outputFile, 'Tsix_AF594\tmESC4d_Tsix\t');
        elseif endsWith(analysis.imgname, 'CY5')
            fprintf(outputFile, 'Xist_CY5\tXist_Hi\t');
        end
    elseif startsWith(analysis.imgname, 'scrna_')
        if endsWith(analysis.imgname, 'STL1')
            fprintf(outputFile, 'CTT1_CY5_Smpl\tCTT1_CY5_Smpl\t');
        elseif endsWith(analysis.imgname, 'CTT1')
            fprintf(outputFile, 'STL1_TMR_Smpl\tSTL1_TMR_Smpl\t');
        end
    elseif startsWith(analysis.imgname, 'sctc_')
        tcnameinfo = Parse_sctcImgName(analysis.imgname);
        if tcnameinfo.Channel == 1
            fprintf(outputFile, 'CTT1_CY5\tCTT1_');
        else
            fprintf(outputFile, 'STL1_TMR\tSTL1_');
        end

        fprintf(outputFile, 'E%dR%d_%02dmin\t', tcnameinfo.Exp, tcnameinfo.Rep, tcnameinfo.TimePointMin);
    elseif startsWith(analysis.imgname, 'mESC_loday')
        if endsWith(analysis.imgname, 'Tsix')
            fprintf(outputFile, 'Tsix_TMR\tTsix_loday\t');
        elseif endsWith(analysis.imgname, 'Xist')
            fprintf(outputFile, 'Xist_CY5\t');
            if contains(analysis.imgname, 'D1')
                fprintf(outputFile, 'Xist_Hi\t');
            else
                fprintf(outputFile, 'Xist_Lo\t');
            end
        end
    elseif startsWith(analysis.imgname, 'scprotein_')
        fprintf(outputFile, 'scprotein\t');
        if contains(analysis.imgname, 'Msb2')
            fprintf(outputFile, 'Msb2\t');
        else
            fprintf(outputFile, 'Opy2\t');
        end
    elseif startsWith(analysis.imgname, 'histonesc_')
        if endsWith(analysis.imgname, 'Tsix')
            fprintf(outputFile, 'Tsix_TMR\tTsix_wHist\t');
        elseif endsWith(analysis.imgname, 'Xist')
            fprintf(outputFile, 'Xist_CY5\t');
            if contains(analysis.imgname, 'D2')
                fprintf(outputFile, 'Xist_Hi\t');
            else
                fprintf(outputFile, 'Xist_Lo\t');
            end
        elseif endsWith(analysis.imgname, 'Histone')
            fprintf(outputFile, 'Histone_AF488\t');
            if contains(analysis.imgname, 'D2')
                if contains(analysis.imgname, 'H3K36me3')
                    fprintf(outputFile, 'H3K36me3_D2\t');
                else
                    fprintf(outputFile, 'H3K4me2_D2\t');
                end
            else
                if contains(analysis.imgname, 'H3K36me3')
                    fprintf(outputFile, 'H3K36me3_D0\t');
                else
                    fprintf(outputFile, 'H3K4me2_D0\t');
                end
            end
        end
    elseif startsWith(analysis.imgname, 'ROI0')
        if endsWith(analysis.imgname, 'GFP')
            fprintf(outputFile, 'HeLa_GFP\tHeLa_GFP\t');
        elseif endsWith(analysis.imgname, 'CY5')
            fprintf(outputFile, 'HeLa_CY5\tHeLa_CY5\t');
        end
    elseif startsWith(analysis.imgname, 'rsfish_')
        if startsWith(analysis.imgname, 'rsfish_sim_')
            fprintf(outputFile, 'Preibisch_sim\tPreibisch_sim\t');
        else
            fprintf(outputFile, 'Preibisch_celegans\tPreibisch_celegans\t');
        end
    end
end