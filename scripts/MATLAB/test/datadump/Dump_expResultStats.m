%
%%

%RECALL is maximum recall
%IMGNAME GROUP_A GROUP_B HB_COUNT HB_RECALL HB_AUC HB_FSCORE 
% BF_COUNT BF_RECALL BF_AUC
%BF_FSCORE RS_RECALL RS_AUC DB_RECALL DB_AUC

function Dump_expResultStats(outputFile, analysis, refsetId)

    if isempty(outputFile); return; end
    if isempty(analysis); return; end

    %Determine if skip.
    %Skip if sim or no truthset.
    if startsWith(analysis.imgname, 'sim')
        return;
    elseif startsWith(analysis.imgname, 'rsfish_sim')
        return;
    end

    if ~isfield(analysis, 'refsets')
        return;
    end
    if ~isfield(analysis.refsets, refsetId)
        return;
    end

    fprintf('>> Analyzing %s...\n', analysis.imgname);

    fprintf(outputFile, '%s\t', analysis.imgname);

    %Determine groups
    printGroups(outputFile, analysis);

    printHBRes(outputFile, analysis, refsetId);
    printBFRes(outputFile, analysis, refsetId);
    printRSRes(outputFile, analysis, refsetId);
    printDBRes(outputFile, analysis, refsetId);

    fprintf(outputFile, '\n');
end

function printHBRes(outputFile, analysis, refsetId)

    if isfield(analysis, 'results_hb')
        resStruct = analysis.results_hb;
        printRes(outputFile, resStruct, true, true, analysis.results_hb.threshold, refsetId);
    else
        fprintf(outputFile, 'NaN\tNaN\tNaN\t');
    end

end

function printBFRes(outputFile, analysis, refsetId)

    if isfield(analysis, 'results_bf')
        resStruct = analysis.results_bf;
        printRes(outputFile, resStruct, true, true, analysis.results_bf.threshold, refsetId);
    else
        fprintf(outputFile, 'NaN\tNaN\tNaN\t');
    end

end

function printRSRes(outputFile, analysis, refsetId)

    if isfield(analysis, 'results_rs')
        resStruct = analysis.results_rs;
        printRes(outputFile, resStruct, false, true, 0, refsetId);
    else
        fprintf(outputFile, 'NaN\tNaN\t');
    end

end

function printDBRes(outputFile, analysis, refsetId)

    if isfield(analysis, 'results_db')
        resStruct = analysis.results_db;
        printRes(outputFile, resStruct, false, false, 0, refsetId);
    else
        fprintf(outputFile, 'NaN\tNaN');
    end

end

function printRes(outputFile, resStruct, inclFScore, endTab, thval, refsetId)

    if nargin < 5
        thval = 0;
    end

    if isempty(resStruct) | ~isfield(resStruct, 'benchmarks') | ~isfield(resStruct.benchmarks, refsetId)
        if inclFScore
            fprintf(outputFile, 'NaN\t');
        end
        fprintf(outputFile, 'NaN\tNaN');
        if inclFScore
            fprintf(outputFile, '\tNaN');
        end
        if endTab; fprintf(outputFile, '\t'); end
        return;
    end

    perfStruct = resStruct.benchmarks.(refsetId);

    if isfield(perfStruct, 'performance_trimmed')
        if inclFScore
            thidx = RNAUtils.findThresholdIndex(thval, perfStruct.performance_trimmed{:,'thresholdValue'});
            fprintf(outputFile, '%d\t', perfStruct.performance_trimmed{thidx,'spotCount'});
        end

        max_recall = max(perfStruct.performance_trimmed{:,'sensitivity'}, [], 'all');
        fprintf(outputFile, '%f\t', max_recall);
        fprintf(outputFile, '%f', perfStruct.pr_auc_trimmed);
        if inclFScore
            fprintf(outputFile, '\t%f', perfStruct.fscore_autoth_trimmed);
        end
    elseif isfield(perfStruct, 'performance')
        if inclFScore
            thidx = RNAUtils.findThresholdIndex(thval, perfStruct.performance{:,'thresholdValue'});
            fprintf(outputFile, '%d\t', perfStruct.performance{thidx,'spotCount'});
        end

        max_recall = max(perfStruct.performance{:,'sensitivity'}, [], 'all');
        fprintf(outputFile, '%f\t', max_recall);
        fprintf(outputFile, '%f', perfStruct.pr_auc);
        if inclFScore
            fprintf(outputFile, '\t%f', perfStruct.fscore_autoth);
        end
    else
        if inclFScore
            fprintf(outputFile, 'NaN\t');
        end
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
            fprintf(outputFile, 'TsixE_AF594\tmESC4d_Tsix\t');
        elseif endsWith(analysis.imgname, 'CY5')
            fprintf(outputFile, 'XistE_CY5\tXistE_Hi\t');
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
            fprintf(outputFile, 'TsixE_TMR\tTsix_loday\t');
        elseif endsWith(analysis.imgname, 'Xist')
            fprintf(outputFile, 'XistE_CY5\t');
            if contains(analysis.imgname, 'D1')
                fprintf(outputFile, 'XistE_Hi\t');
            else
                fprintf(outputFile, 'XistE_Lo\t');
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
            fprintf(outputFile, 'TsixI_TMR\tTsix_wHist\t');
        elseif endsWith(analysis.imgname, 'Xist')
            fprintf(outputFile, 'XistI_CY5\t');
            if contains(analysis.imgname, 'D2')
                fprintf(outputFile, 'XistI_Hi\t');
            else
                fprintf(outputFile, 'XistI_Lo\t');
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