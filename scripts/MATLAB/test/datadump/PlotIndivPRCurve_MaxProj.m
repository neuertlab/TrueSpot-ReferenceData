function PlotIndivPRCurve_MaxProj(rstruct, color, linewidth, linetype, zMin, zMax)

if zMin < 1
    minZstr = '1';
else
    minZstr = num2str(zMin);
end

if zMax < 1
    maxZstr = 'Z';
else
    maxZstr = num2str(zMax);
end
mipFieldName = ['mip_' minZstr '_' maxZstr];

if isfield(rstruct, mipFieldName)
    mipStruct = rstruct.(mipFieldName);
else
    return;
end

if isfield(mipStruct, 'performance_trimmed')
    x = mipStruct.performance_trimmed{:, 'sensitivity'};
    y = mipStruct.performance_trimmed{:, 'precision'};
elseif isfield(mipStruct, 'performance')
    x = mipStruct.performance{:, 'sensitivity'};
    y = mipStruct.performance{:, 'precision'};
elseif isfield(mipStruct, 'benchmarks')
    if isfield(mipStruct.benchmarks, 'BH')
        bstruct = mipStruct.benchmarks.BH;
    elseif isfield(mipStruct.benchmarks, 'BHImaris')
        bstruct = mipStruct.benchmarks.BHImaris;
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