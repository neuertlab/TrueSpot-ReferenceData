%
%%
function Dump_JustCoords_231128(analysis, output_path)

if isempty(analysis); return; end
if isempty(output_path); return; end

if isfield(analysis, 'results_hb')
    coords_hb = getResCoords(analysis.results_hb, analysis.image_dims);
else
    coords_hb = [];
end
    
if isfield(analysis, 'results_bf')
    coords_bf = getResCoords(analysis.results_bf, analysis.image_dims);
else
    coords_bf = [];
end

if isfield(analysis, 'results_rs')
    rs_th = estThValRS(analysis.results_rs);
    coords_rs = getResCoords(analysis.results_rs, analysis.image_dims, rs_th);
else
    rs_th = 0;
    coords_rs = [];
end

if isfield(analysis, 'results_db')
    coords_db = getResCoords(analysis.results_db, analysis.image_dims, 0.95);
else
    coords_db = [];
end

if isfield(analysis, 'results_db_simmdl')
    coords_dbalt = getResCoords(analysis.results_db_simmdl, analysis.image_dims, 0.95);
else
    coords_dbalt = [];
end

image_name = analysis.imgname;
voxel_dims = analysis.voxel_dims;
save(output_path, 'image_name', 'voxel_dims', 'coords_hb', 'coords_bf', 'coords_rs', 'coords_db', 'coords_dbalt', 'rs_th', '-v7.3');

end

function thval = estThValRS(rstruct)

    if isfield(rstruct, 'performance_trimmed')
        pertbl = rstruct.performance_trimmed;
    elseif isfield(rstruct, 'performance')
        pertbl = rstruct.performance;
    else
        pertbl = [];
    end

    if ~isempty(pertbl)
        %Find max fscore
        [~, maxidx] = max(pertbl{:, 'fScore'}, [], 'all', 'omitnan');
        thval = pertbl{maxidx, 'thresholdValue'};
    else
        %Just use the mode of the dropoutthresh (max of absdiff curve...)
        thmode = mode(rstruct.callset{:, 'dropout_thresh'}, 'all');
        thval = thmode + 0.0001;
    end

end

function coord_tbl = getResCoords(rstruct, idims, thval)

if nargin < 3; thval = 0; end

%1. Filter out those outside trim range
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
    coord_tbl = [];
    return;
end
calls_full = calls_full(keep_rows, :);

%2. Filter out those below threshold
if isfield(rstruct, 'threshold'); thval = rstruct.threshold; end
keep_rows = find(calls_full{:, 'dropout_thresh'} >= thval);
if isempty(keep_rows)
    coord_tbl = [];
    return;
end
calls_full = calls_full(keep_rows, :);

%3. Strip down to just desired fields
varNames = {'x', 'y', 'z', 'intensity'};
varTypes = {'uint16' 'uint16' 'uint16' 'uint16'};
row_count = size(calls_full, 1);
col_count = size(varNames, 2);
coord_tbl = table('Size', [row_count col_count], 'VariableTypes',varTypes, 'VariableNames',varNames);

coord_tbl(:,'x') = calls_full(:, 'isnap_x');
coord_tbl(:,'y') = calls_full(:, 'isnap_y');
coord_tbl(:,'z') = calls_full(:, 'isnap_z');
coord_tbl(:,'intensity') = calls_full(:, 'intensity');

end