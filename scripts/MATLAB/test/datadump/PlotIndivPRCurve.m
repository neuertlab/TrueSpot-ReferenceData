
function PlotIndivPRCurve(rstruct, color, linewidth, linetype)

if isfield(rstruct, 'performance_trimmed')
    x = rstruct.performance_trimmed{:, 'sensitivity'};
    y = rstruct.performance_trimmed{:, 'precision'};
elseif isfield(rstruct, 'performance')
    x = rstruct.performance{:, 'sensitivity'};
    y = rstruct.performance{:, 'precision'};
elseif isfield(rstruct, 'benchmarks')
    if isfield(rstruct.benchmarks, 'BH')
        bstruct = rstruct.benchmarks.BH;
    elseif isfield(rstruct.benchmarks, 'BHImaris')
        bstruct = rstruct.benchmarks.BHImaris;
    end
    if isfield(bstruct, 'performance_trimmed')
        x = bstruct.performance_trimmed{:, 'sensitivity'};
        y = bstruct.performance_trimmed{:, 'precision'};
    elseif isfield(bstruct, 'performance')
        x = bstruct.performance{:, 'sensitivity'};
        y = bstruct.performance{:, 'precision'};
    end
else
    return;
end

plot(x, y, 'LineStyle', linetype, 'LineWidth', linewidth, 'Color', color);

end