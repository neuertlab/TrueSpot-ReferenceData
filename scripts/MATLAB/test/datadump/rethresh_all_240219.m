%
%%

function analysis = rethresh_all_240219(analysis, recalculatePerformance)
    imgname = analysis.imgname;
    
    is_sim = false;
    if contains(imgname, 'sim')
        if ~startsWith(imgname, 'simerly_')
            is_sim = true;
        end
    end

    MIDPOINT = 6;

    if is_sim
        preset = MIDPOINT + 2;

        if startsWith(imgname, 'rsfish_sim')
            preset = MIDPOINT + 4;
        end

        analysis = AnalysisFiles.rethresholdSim(analysis, preset, 1, recalculatePerformance);
    else
        preset = MIDPOINT;
%         if startsWith(imgname, 'simerly_')
%             preset = 3;
%         elseif startsWith(imgname, 'histonesc_') & endsWith(imgname, '_Tsix')
%             preset = 2;
%         elseif startsWith(imgname, 'rsfish_')
%             preset = 2;
%         end

        if startsWith(imgname, 'histonesc_')
            if endsWith(imgname, '_Tsix')
                preset = MIDPOINT - 2;
            elseif endsWith(imgname, '_Histone')
                preset = MIDPOINT + 5;
            end
        end

        analysis = AnalysisFiles.rethresholdExp(analysis, preset, 1, recalculatePerformance);
    end

end