%
%%

function thval = AutothreshRS(rstruct, idims)
try
    thval = 0;
    callset = TrimCallsetEdges(rstruct, idims);
    
    if isempty(callset); return; end
    
    spot_table = AnalysisFiles.callset2SpotcountTable(callset);
    all_th = spot_table(:,1)';
    T = size(spot_table,1);
    spot_table(1:T,1) = 1:T;
    
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