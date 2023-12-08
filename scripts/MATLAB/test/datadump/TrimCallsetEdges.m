%
%%

function callset = TrimCallsetEdges(rstruct, idims)
    callset = rstruct.callset;

    xmin = 1; ymin = 1; zmin = 1;
    xmax = idims.x;
    ymax = idims.y;
    zmax = idims.z;
    
    if isfield(rstruct, 'x_min'); xmin = rstruct.x_min; end
    if isfield(rstruct, 'x_max'); xmax = rstruct.x_max; end
    if isfield(rstruct, 'y_min'); ymin = rstruct.y_min; end
    if isfield(rstruct, 'y_max'); ymax = rstruct.y_max; end
    if isfield(rstruct, 'z_min'); zmin = rstruct.z_min; end
    if isfield(rstruct, 'z_max'); zmax = rstruct.z_max; end
    
    calls_full = rstruct.callset;
    x_okay = and(calls_full{:, 'isnap_x'} >= xmin, calls_full{:, 'isnap_x'} <= xmax);
    y_okay = and(calls_full{:, 'isnap_y'} >= ymin, calls_full{:, 'isnap_y'} <= ymax);
    z_okay = and(calls_full{:, 'isnap_z'} >= zmin, calls_full{:, 'isnap_z'} <= zmax);
    keep_rows = find(x_okay & y_okay & z_okay);
    
    if isempty(keep_rows)
        callset = [];
        return;
    end

    callset = callset(keep_rows, :);
end