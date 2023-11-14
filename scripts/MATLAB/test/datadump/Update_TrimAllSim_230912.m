%

function analysis = Update_TrimAllSim_230912(analysis, radius)

    %Adds xy border of 7 pix to bf, rs, and db runs as well.
    %HB
    if isfield(analysis, 'results_hb')
        analysis.results_hb = applyXYTrim(analysis.results_hb, radius, analysis.image_dims);
        spot_table = getSpotTable(analysis.results_hb);
        analysis.results_hb = runstats(analysis.results_hb, spot_table, analysis.results_hb.threshold);
    end

    %BF
    if isfield(analysis, 'results_bf')
        analysis.results_bf = applyXYTrim(analysis.results_bf, radius, analysis.image_dims);
        spot_table = getSpotTable(analysis.results_bf);
        analysis.results_bf = runstats(analysis.results_bf, spot_table, analysis.results_bf.threshold);
    end

    %RS
    if isfield(analysis, 'results_rs')
        analysis.results_rs = applyXYTrim(analysis.results_rs, radius, analysis.image_dims);
        spot_table = getSpotTable(analysis.results_rs);
        analysis.results_rs = runstats(analysis.results_rs, spot_table, 0);
    end

    %DB
    if isfield(analysis, 'results_db')
        analysis.results_db = applyXYTrim(analysis.results_db, radius, analysis.image_dims);
        spot_table = getSpotTable(analysis.results_db);
        analysis.results_db = runstats(analysis.results_db, spot_table, 0);
    end

    %DBAlt
    if isfield(analysis, 'results_db_simmdl')
        analysis.results_db_simmdl = applyXYTrim(analysis.results_db_simmdl, radius, analysis.image_dims);
        spot_table = getSpotTable(analysis.results_db_simmdl);
        analysis.results_db_simmdl = runstats(analysis.results_db_simmdl, spot_table, 0);
    end

end

function spot_table = getSpotTable(rstruct)
    spot_table = [];
    if ~isfield(rstruct, 'performance'); return; end

    tcount = size(rstruct.performance, 1);
    spot_table = NaN(tcount, 2);

    spot_table(:,1) = rstruct.performance{:, 'thresholdValue'};
    spot_table(:,2) = rstruct.performance{:, 'spotCount'};
end

function rstruct = applyXYTrim(rstruct, radius, dims)
    if ~isfield(rstruct, 'performance'); return; end

    X = dims.x;
    Y = dims.y;
    Z = dims.z;

    x_min = radius + 1;
    x_max = X - radius;
    y_min = radius + 1;
    y_max = Y - radius;

    rstruct.x_min = x_min;
    rstruct.x_max = x_max;
    rstruct.y_min = y_min;
    rstruct.y_max = y_max;

    xx = rstruct.callset{:,'isnap_x'};
    x_pass = and(xx >= x_min, xx <= x_max);
    yy = rstruct.callset{:,'isnap_y'};
    y_pass = and(yy >= y_min, yy <= y_max);

    z_min = 1;
    z_max = Z;
    if isfield(rstruct, 'z_min')
        z_min = rstruct.z_min;
    end
    if isfield(rstruct, 'z_max')
        z_max = rstruct.z_max;
    end

    zz = rstruct.callset{:,'isnap_z'};
    z_pass = and(zz >= z_min, zz <= z_max);
    all_pass = and(x_pass, y_pass);
    all_pass = and(all_pass, z_pass);

    rstruct.callset{:,'is_trimmed_out'} = ~all_pass;
end

function rstruct = runstats(rstruct, spot_table, th_val)

    if nargin < 3; th_val = 0; end

    call_table = rstruct.callset;
    vec_istrimmed = table2array(call_table(:,'is_trimmed_out'));
    vec_intsreg = table2array(call_table(:,'in_truth_region'));
    vec_isreal = table2array(call_table(:,'is_true'));
    vec_dropth = table2array(call_table(:,'dropout_thresh'));

    any_trimmed = nnz(vec_istrimmed) > 0;
    
    th_count = size(spot_table,1);
    res_untrimmed = ImageResults.initializeResTable(th_count);
    res_trimmed = table.empty();

    thval_tbl = array2table(double(spot_table(:,1)));
    res_untrimmed(:,'thresholdValue') = thval_tbl;

    if any_trimmed
        res_trimmed = ImageResults.initializeResTable(th_count);
        res_trimmed(:,'thresholdValue') = thval_tbl;
    else
        %Clean trimmed struct if it is present
        if isfield(rstruct, 'performance_trimmed')
            rstruct = rmfield(rstruct, 'performance_trimmed');
        end
        if isfield(rstruct, 'pr_auc_trimmed')
            rstruct = rmfield(rstruct, 'pr_auc_trimmed');
        end
        if isfield(rstruct, 'fscore_peak_trimmed')
            rstruct = rmfield(rstruct, 'fscore_peak_trimmed');
        end
        if isfield(rstruct, 'fscore_autoth_trimmed')
            rstruct = rmfield(rstruct, 'fscore_autoth_trimmed');
        end
    end

    sc_all = NaN(th_count,2);
    tp_all = NaN(th_count,2);
    fp_all = NaN(th_count,2);
    fn_all = NaN(th_count,2);
    for t = 1:th_count
        th = spot_table(t,1);
        pos_vec = (vec_dropth >= th) & vec_intsreg;
        tp_vec = pos_vec & vec_isreal;
        fp_vec = pos_vec & ~vec_isreal;
        fn_vec = (vec_dropth < th) & vec_intsreg & vec_isreal;

        tp_all(t,1) = nnz(tp_vec);
        fp_all(t,1) = nnz(fp_vec);
        fn_all(t,1) = nnz(fn_vec);
        sc_all(t,1) = nnz(pos_vec);

        %Repeat for trimmed, if applicable
        if any_trimmed
            pos_vec = (vec_dropth >= th) & vec_intsreg & ~vec_istrimmed;
            neg_vec = (vec_dropth < th) & vec_intsreg & ~vec_istrimmed;
            tp_vec = pos_vec & vec_isreal;
            fp_vec = pos_vec & ~vec_isreal;
            fn_vec = neg_vec & vec_isreal;

            tp_all(t,2) = nnz(tp_vec);
            fp_all(t,2) = nnz(fp_vec);
            fn_all(t,2) = nnz(fn_vec);
            sc_all(t,2) = nnz(pos_vec);
        end
    end

    %Let's speed up the easy calculations...
    res_untrimmed(:, 'spotCount') = array2table(uint32(sc_all(:,1)));
    res_untrimmed(:, 'true_pos') = array2table(uint32(tp_all(:,1)));
    res_untrimmed(:, 'false_pos') = array2table(uint32(fp_all(:,1)));
    res_untrimmed(:, 'false_neg') = array2table(uint32(fn_all(:,1)));

    recall = tp_all(:,1) ./ (tp_all(:,1) + fn_all(:,1));
    precision = tp_all(:,1) ./ (tp_all(:,1) + fp_all(:,1));
    fscores = (2 .* precision .* recall) ./ (precision + recall);
    pr_auc = RNAUtils.calculateAUC(recall, precision);
    peak_fscore = max(fscores, [], 'all');
    res_untrimmed(:, 'sensitivity') = array2table(recall);
    res_untrimmed(:, 'precision') = array2table(precision);
    res_untrimmed(:, 'fScore') = array2table(fscores);
    if any_trimmed
        res_trimmed(:, 'spotCount') = array2table(uint32(sc_all(:,2)));
        res_trimmed(:, 'true_pos') = array2table(uint32(tp_all(:,2)));
        res_trimmed(:, 'false_pos') = array2table(uint32(fp_all(:,2)));
        res_trimmed(:, 'false_neg') = array2table(uint32(fn_all(:,2)));

        recall = tp_all(:,2) ./ (tp_all(:,2) + fn_all(:,2));
        precision = tp_all(:,2) ./ (tp_all(:,2) + fp_all(:,2));
        fscores = (2 .* precision .* recall) ./ (precision + recall);
        pr_auc_trim = RNAUtils.calculateAUC(recall, precision);
        peak_fscore_trim = max(fscores, [], 'all');
        res_trimmed(:, 'sensitivity') = array2table(recall);
        res_trimmed(:, 'precision') = array2table(precision);
        res_trimmed(:, 'fScore') = array2table(fscores);
    end

    th_idx = 0;
    if th_val > 0
        th_idx = RNAUtils.findThresholdIndex(th_val, spot_table(:,1).');
    end

    %Save to output struct
    rstruct.performance = res_untrimmed;
    rstruct.pr_auc = pr_auc;
    rstruct.fscore_peak = peak_fscore;
    if th_idx > 0
        rstruct.fscore_autoth = res_untrimmed{th_idx, 'fScore'};
    end
    if any_trimmed
        rstruct.performance_trimmed = res_trimmed;
        rstruct.pr_auc_trimmed = pr_auc_trim;
        rstruct.fscore_peak_trimmed = peak_fscore_trim;
        if th_idx > 0
            rstruct.fscore_autoth_trimmed = res_trimmed{th_idx, 'fScore'};
        end
    end

    rstruct.timestamp = datetime();

end