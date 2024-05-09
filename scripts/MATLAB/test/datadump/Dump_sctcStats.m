%
%%
function Dump_sctcStats(outhandle_struct, analysis, fixed_th_struct)

%Main Table Fields:
%   IMAGENAME EXP REP TIME I_NUM CH THVAL_HB THVAL_BF THSPOTS_HB THSPOTS_BF

%TODO: This has a bug with header labeling!!! THVAL_BF and THSPOTS_HB
%are swapped for only exp images. Remember to update to swap for sim too!

%Cell Table Fields:
%   EXP REP TIME I_NUM CH CELL_NUM THI_HB_TOT THI_BF_TOT...
%Repeat with THR (rep fixed th), THE (exp fixed th), and THC (ch fixed
%thresh)

%Sim Table Fields:
%   IMAGENAME CH ACTUAL_SPOTS THI_HB THI_BF THI_HB_SPOTS THI_BF_SPOTS
%   THF_HB_SPOTS THF_BF_SPOTS
nameokay = false;
if startsWith(analysis.imgname, 'sctc_'); nameokay = true; end
if startsWith(analysis.imgname, 'simvarmass_')
    if contains(analysis.imgname, 'CY5L')
        nameokay = true;
    elseif contains(analysis.imgname, 'TMRL')
        nameokay = true;
    end
end

if ~nameokay; return; end

    if startsWith(analysis.imgname, 'simvarmass')
        %TODO
        simtbl = outhandle_struct.simtbl;
        fprintf(simtbl, '%s\t', analysis.imgname);
        if contains(analysis.imgname, 'CY5L')
            ch = 1;
        else
            ch = 2;
        end
        fprintf(simtbl, '%d\t', ch);

        if isfield(analysis, 'simkey')
            fprintf(simtbl, '%d', size(analysis.simkey, 2));
        else
            fprintf(simtbl, 'NaN');
        end
        
        hb_thi = 0;
        bf_thi = 0;
        if isfield(analysis, 'results_hb')
            if isfield(analysis.results_hb, 'threshold')
                if analysis.results_hb.threshold > 0
                    hb_thi = analysis.results_hb.threshold;
                    fprintf(simtbl, '\t%d', hb_thi);
                else
                    fprintf(simtbl, '\tNaN');
                end
            end
        else
            fprintf(simtbl, '\tNaN');
        end

        if isfield(analysis, 'results_bf')
            if isfield(analysis.results_bf, 'threshold')
                if analysis.results_bf.threshold > 0
                    bf_thi = analysis.results_bf.threshold;
                    fprintf(simtbl, '\t%d', bf_thi);
                else
                    fprintf(simtbl, '\tNaN');
                end
            end
        else
            fprintf(simtbl, '\tNaN');
        end

        if hb_thi > 0 & isfield(analysis, 'results_hb')
            if isfield(analysis.results_hb, 'callset')
                hits = find(analysis.results_hb.callset{:, 'dropout_thresh'} >= hb_thi);
                if ~isempty(hits)
                    fprintf(simtbl, '\t%d', size(hits ,1));
                else
                    fprintf(simtbl, '\t0');
                end
            else
                fprintf(simtbl, '\tNaN');
            end
        else
            fprintf(simtbl, '\tNaN');
        end

        if bf_thi > 0 & isfield(analysis, 'results_bf')
            if isfield(analysis.results_bf, 'callset')
                hits = find(analysis.results_bf.callset{:, 'dropout_thresh'} >= bf_thi);
                if ~isempty(hits)
                    fprintf(simtbl, '\t%d', size(hits ,1));
                else
                    fprintf(simtbl, '\t0');
                end
            else
                fprintf(simtbl, '\tNaN');
            end
        else
            fprintf(simtbl, '\tNaN');
        end

        %Fixed th...
        if isfield(fixed_th_struct, 'exp_fixed_th_hb')
            thval = fixed_th_struct.exp_fixed_th_hb(3, ch);
            if thval > 0
                if isfield(analysis, 'results_hb')
                    if isfield(analysis.results_hb, 'callset')
                        hits = find(analysis.results_hb.callset{:, 'dropout_thresh'} >= thval);
                        if ~isempty(hits)
                            fprintf(simtbl, '\t%d', size(hits ,1));
                        else
                            fprintf(simtbl, '\t0');
                        end
                    else
                        fprintf(simtbl, '\tNaN');
                    end
                else
                    fprintf(simtbl, '\tNaN');
                end
            else
                fprintf(simtbl, '\tNaN');
            end
        else
            fprintf(simtbl, '\tNaN');
        end

        if isfield(fixed_th_struct, 'exp_fixed_th_bf')
            thval = fixed_th_struct.exp_fixed_th_bf(3, ch);
            if thval > 0
                if isfield(analysis, 'results_bf')
                    if isfield(analysis.results_bf, 'callset')
                        hits = find(analysis.results_bf.callset{:, 'dropout_thresh'} >= thval);
                        if ~isempty(hits)
                            fprintf(simtbl, '\t%d', size(hits ,1));
                        else
                            fprintf(simtbl, '\t0');
                        end
                    else
                        fprintf(simtbl, '\tNaN');
                    end
                else
                    fprintf(simtbl, '\tNaN');
                end
            else
                fprintf(simtbl, '\tNaN');
            end
        else
            fprintf(simtbl, '\tNaN');
        end
        

        fprintf(simtbl, '\n');
    else
        sctc_name_info = Parse_sctcImgName(analysis.imgname);

        %------------------ Main Table....
        maintbl = outhandle_struct.maintbl;
        fprintf(maintbl, '%s\t', analysis.imgname);
        fprintf(maintbl, '%d\t', sctc_name_info.Exp);
        fprintf(maintbl, '%d\t', sctc_name_info.Rep);
        fprintf(maintbl, '%d\t', sctc_name_info.TimePointMin);
        fprintf(maintbl, '%d\t', sctc_name_info.ImageRep);
        fprintf(maintbl, '%d\t', sctc_name_info.Channel);

        if isfield(analysis, 'results_hb')
            if isfield(analysis.results_hb, 'threshold')
                if analysis.results_hb.threshold > 0
                    fprintf(maintbl, '%d\t', analysis.results_hb.threshold);
                    if isfield(analysis.results_hb, 'callset')
                        matches = find(analysis.results_hb.callset{:,'dropout_thresh'} >= analysis.results_hb.threshold);
                        if ~isempty(matches)
                            fprintf(maintbl, '%d\t', size(matches, 1));
                        else
                            fprintf(maintbl, 'NaN\t');
                        end
                    else
                        fprintf(maintbl, 'NaN\t');
                    end
                else
                    fprintf(maintbl, 'NaN\tNaN\t');
                end
            else
                fprintf(maintbl, 'NaN\tNaN\t');
            end
        else
            fprintf(maintbl, 'NaN\tNaN\t');
        end

        if isfield(analysis, 'results_bf')
            if analysis.results_bf.threshold > 0
                fprintf(maintbl, '%d\t', analysis.results_bf.threshold);
                if isfield(analysis.results_bf, 'callset')
                    matches = find(analysis.results_bf.callset{:,'dropout_thresh'} >= analysis.results_bf.threshold);
                    if ~isempty(matches)
                        fprintf(maintbl, '%d\n', size(matches, 1));
                    else
                        fprintf(maintbl, 'NaN\n');
                    end
                else
                    fprintf(maintbl, 'NaN\n');
                end
            else
                fprintf(maintbl, 'NaN\tNaN\n');
            end
        else
            fprintf(maintbl, 'NaN\tNaN\n');
        end

        %------------------ Cell Table...
        celltbl = outhandle_struct.celltbl;
        

        %Get number of cells...
        cell_count = 0;
        if isfield(analysis, 'results_hb')
            if isfield(analysis.results_hb, 'callset')
                cell_count = max(analysis.results_hb.callset{:,'cell'}, [], 'all', 'omitnan');
            end
        elseif isfield(analysis, 'results_bf')
            if isfield(analysis.results_bf, 'callset')
                cell_count = max(analysis.results_bf.callset{:,'cell'}, [], 'all', 'omitnan');
            end
        end

        if cell_count > 0
            for c = 1:cell_count

                fprintf(celltbl, '%d\t', sctc_name_info.Exp);
                fprintf(celltbl, '%d\t', sctc_name_info.Rep);
                fprintf(celltbl, '%d\t', sctc_name_info.TimePointMin);
                fprintf(celltbl, '%d\t', sctc_name_info.ImageRep);
                fprintf(celltbl, '%d\t', sctc_name_info.Channel);
                fprintf(celltbl, '%d', c);

                %THI (Using th for individual image)
                if isfield(analysis, 'results_hb')
                    if isfield(analysis.results_hb, 'threshold') & isfield(analysis.results_hb, 'callset')
                        thval = analysis.results_hb.threshold;
                        scount = countCellSpots(thval, c, analysis.results_hb.callset);
                        fprintf(celltbl, '\t%d', scount);
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                if isfield(analysis, 'results_bf')
                    if isfield(analysis.results_bf, 'threshold') & isfield(analysis.results_bf, 'callset')
                        thval = analysis.results_bf.threshold;
                        scount = countCellSpots(thval, c, analysis.results_bf.callset);
                        fprintf(celltbl, '\t%d', scount);
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                %THR (Using average th for rep)
                if isfield(analysis, 'results_hb')
                    if isfield(analysis.results_hb, 'callset')
                        thval = getRepTh(fixed_th_struct, false, sctc_name_info);
                        if thval > 0
                            scount = countCellSpots(thval, c, analysis.results_hb.callset);
                            fprintf(celltbl, '\t%d', scount);
                        else
                            fprintf(celltbl, '\tNaN');
                        end
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                if isfield(analysis, 'results_bf')
                    if isfield(analysis.results_bf, 'callset')
                        thval = getRepTh(fixed_th_struct, true, sctc_name_info);
                        if thval > 0
                            scount = countCellSpots(thval, c, analysis.results_bf.callset);
                            fprintf(celltbl, '\t%d', scount);
                        else
                            fprintf(celltbl, '\tNaN');
                        end
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                %THE (Using average th for exp)
                if isfield(analysis, 'results_hb')
                    if isfield(analysis.results_hb, 'callset')
                        thval = fixed_th_struct.exp_fixed_th_hb(sctc_name_info.Exp, sctc_name_info.Channel);
                        if thval > 0
                            scount = countCellSpots(thval, c, analysis.results_hb.callset);
                            fprintf(celltbl, '\t%d', scount);
                        else
                            fprintf(celltbl, '\tNaN');
                        end
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                if isfield(analysis, 'results_bf')
                    if isfield(analysis.results_bf, 'callset')
                        thval = fixed_th_struct.exp_fixed_th_bf(sctc_name_info.Exp, sctc_name_info.Channel);
                        if thval > 0
                            scount = countCellSpots(thval, c, analysis.results_bf.callset);
                            fprintf(celltbl, '\t%d', scount);
                        else
                            fprintf(celltbl, '\tNaN');
                        end
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                %THC (Using average th for channel)
                if isfield(analysis, 'results_hb')
                    if isfield(analysis.results_hb, 'callset')
                        thval = fixed_th_struct.ch_fixed_th_hb(sctc_name_info.Channel);
                        if thval > 0
                            scount = countCellSpots(thval, c, analysis.results_hb.callset);
                            fprintf(celltbl, '\t%d', scount);
                        else
                            fprintf(celltbl, '\tNaN');
                        end
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                if isfield(analysis, 'results_bf')
                    if isfield(analysis.results_bf, 'callset')
                        thval = fixed_th_struct.ch_fixed_th_bf(sctc_name_info.Channel);
                        if thval > 0
                            scount = countCellSpots(thval, c, analysis.results_bf.callset);
                            fprintf(celltbl, '\t%d', scount);
                        else
                            fprintf(celltbl, '\tNaN');
                        end
                    else
                        fprintf(celltbl, '\tNaN');
                    end
                else
                    fprintf(celltbl, '\tNaN');
                end

                fprintf(celltbl, '\n');
            end
        end

    end

end

function scount = countCellSpots(thval, cellno, callset)
    scount = 0;
    if isempty(callset); return; end
    if thval < 1; return; end
    if cellno < 1; return; end

    rmatches = find((callset{:,'cell'} == cellno) & (callset{:,'dropout_thresh'} >= thval));
    if isempty(rmatches); return; end

    scount = size(rmatches, 1);
end

function thval = getRepTh(fixed_th_struct, is_bf, sctc_name_info)
    thval = 0;
    if sctc_name_info.Exp == 1
        if ~is_bf
            if isfield(fixed_th_struct, 'rep_fixed_th_hb_e1')
                thval = fixed_th_struct.rep_fixed_th_hb_e1(sctc_name_info.Rep, sctc_name_info.Channel);
            end
        else
            if isfield(fixed_th_struct, 'rep_fixed_th_bf_e1')
                thval = fixed_th_struct.rep_fixed_th_bf_e1(sctc_name_info.Rep, sctc_name_info.Channel);
            end
        end
    elseif sctc_name_info.Exp == 2
        if ~is_bf
            if isfield(fixed_th_struct, 'rep_fixed_th_hb_e2')
                thval = fixed_th_struct.rep_fixed_th_hb_e2(sctc_name_info.Rep, sctc_name_info.Channel);
            end
        else
            if isfield(fixed_th_struct, 'rep_fixed_th_bf_e2')
                thval = fixed_th_struct.rep_fixed_th_bf_e2(sctc_name_info.Rep, sctc_name_info.Channel);
            end
        end
    end
end