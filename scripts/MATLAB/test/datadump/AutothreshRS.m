%
%%

function thval = AutothreshRS(rstruct, idims)
try
    thval = 0;
    callset = TrimCallsetEdges(rstruct, idims);
    
    if isempty(callset); return; end
    
    if isfield(rstruct, 'performance')
        all_th = rstruct.performance{:, 'thresholdValue'}';
    else
        all_th = unique(callset{:, 'dropout_thresh'})';
        all_th = all_th(find(all_th > 0));
    end
    
    T = size(all_th, 2);
    spot_table = zeros(T, 2);
    spot_table(1:T, 1) = 1:T;
    
    for t = 1:T
        spot_table(t, 2) = nnz(callset{:, 'dropout_thresh'} >= all_th(t));
    end
    
    threshold_results = RNAThreshold.runDefaultParameters(spot_table, []);
    if ~isempty(threshold_results)
        if(threshold_results.threshold > 0)
            thval = all_th(threshold_results.threshold);
        end
    end
catch ME
    thval = 0;
end
end