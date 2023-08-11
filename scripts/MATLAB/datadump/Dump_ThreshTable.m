%
%%

function Dump_ThreshTable(outputFile, analysis)

    if isempty(outputFile); return; end
    if isempty(analysis); return; end

    fprintf(outputFile, '%s\t', analysis.imgname);

    %Determine groups
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

    %Print HB results
    if isfield(analysis, 'results_hb')
        thval = analysis.results_hb.threshold;
        if thval > 0
            fprintf(outputFile, '%d\t', thval);
        else
            fprintf(outputFile, 'NaN\t');
        end

        if thval > 0 & isfield(analysis.results_hb, 'performance')
            thidx = RNAUtils.findThresholdIndex(thval, analysis.results_hb.performance{:, 'thresholdValue'}.');
            if thidx > 0
                sc = analysis.results_hb.performance{thidx, 'spotCount'};
                fprintf(outputFile, '%d\t', sc);
            else
                fprintf(outputFile, 'NaN\t');
            end
        else
            fprintf(outputFile, 'NaN\t');
        end

        if isfield(analysis.results_hb, 'fscore_autoth')
            fprintf(outputFile, '%f\t', analysis.results_hb.fscore_autoth);
        else
            fprintf(outputFile, 'NaN\t');
        end
    else
        fprintf(outputFile, 'NaN\tNaN\tNaN\t');
    end

    %Print BF results
    if isfield(analysis, 'results_bf')
        if isfield(analysis.results_bf, 'threshold')
            thval = analysis.results_bf.threshold;
            if thval > 0
                fprintf(outputFile, '%d\t', thval);
            else
                fprintf(outputFile, 'NaN\t');
            end

            if thval > 0 & isfield(analysis.results_bf, 'performance')
                thidx = RNAUtils.findThresholdIndex(thval, analysis.results_bf.performance{:, 'thresholdValue'}.');
                if thidx > 0
                    sc = analysis.results_bf.performance{thidx, 'spotCount'};
                    fprintf(outputFile, '%d\t', sc);
                else
                    fprintf(outputFile, 'NaN\t');
                end
            else
                fprintf(outputFile, 'NaN\t');
            end

            if isfield(analysis.results_bf, 'fscore_autoth')
                fprintf(outputFile, '%f', analysis.results_bf.fscore_autoth);
            else
                fprintf(outputFile, 'NaN');
            end
        else
            fprintf(outputFile, 'NaN\tNaN\tNaN');
        end
    else
        fprintf(outputFile, 'NaN\tNaN\tNaN');
    end


    fprintf(outputFile, '\n');
end