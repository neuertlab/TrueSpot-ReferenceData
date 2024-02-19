%
%%

addpath('./core');
filepath = ['.' filesep 'core' filesep 'ths_presets.mat'];

%Sensitive +3
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.018;
preset_struct.ttune_winsz_incr = 0.006;
%preset_struct.ttune_fit_strat = 0;
%preset_struct.ttune_reweight_fit = false;
%preset_struct.ttune_fit_to_log = true;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_use_rawcurve = true;
preset_struct.ttune_thweight_med = 0.0;
preset_struct.ttune_thweight_fit = 1.0;
preset_struct.ttune_thweight_fisect = 0.0;
preset_struct.ttune_std_factor = 0.0;
presets(7) = preset_struct;

%Sensitive +2
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
%preset_struct.ttune_fit_strat = 0;
%preset_struct.ttune_reweight_fit = false;
%preset_struct.ttune_fit_to_log = true;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_use_rawcurve = false;
preset_struct.ttune_thweight_med = 0.0;
preset_struct.ttune_thweight_fit = 1.0;
preset_struct.ttune_thweight_fisect = 0.0;
preset_struct.ttune_std_factor = 0.0;
presets(6) = preset_struct;

%Sensitive +1
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
% preset_struct.ttune_fit_strat = 0;
% preset_struct.ttune_reweight_fit = false;
% preset_struct.ttune_fit_to_log = true;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_thweight_med = 0.25;
preset_struct.ttune_thweight_fit = 0.5;
preset_struct.ttune_thweight_fisect = 0.25;
preset_struct.ttune_std_factor = 0.0;
presets(5) = preset_struct;

%Default
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.042;
preset_struct.ttune_winsz_incr = 0.006;
% preset_struct.ttune_fit_strat = 0;
% preset_struct.ttune_reweight_fit = false;
% preset_struct.ttune_fit_to_log = true;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_thweight_med = 0.25;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.75;
preset_struct.ttune_std_factor = 0.0;
presets(4) = preset_struct;

%Specific +1
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.012;
preset_struct.ttune_winsz_max = 0.042;
preset_struct.ttune_winsz_incr = 0.006;
% preset_struct.ttune_fit_strat = 0;
% preset_struct.ttune_reweight_fit = false;
% preset_struct.ttune_fit_to_log = true;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
%preset_struct.ttune_std_factor = 1.0;
presets(3) = preset_struct;

%Specific +2
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.012;
preset_struct.ttune_winsz_max = 0.042;
preset_struct.ttune_winsz_incr = 0.006;
% preset_struct.ttune_fit_strat = 0;
% preset_struct.ttune_reweight_fit = false;
% preset_struct.ttune_fit_to_log = true;
%preset_struct.ttune_use_diffcurve = true;
preset_struct.ttune_log_mode = 1;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
%preset_struct.ttune_std_factor = 2.0;
presets(2) = preset_struct;

%Specific +3
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.018;
preset_struct.ttune_winsz_max = 0.048;
preset_struct.ttune_winsz_incr = 0.006;
% preset_struct.ttune_fit_strat = 0;
% preset_struct.ttune_reweight_fit = false;
% preset_struct.ttune_fit_to_log = true;
preset_struct.ttune_use_diffcurve = true;
preset_struct.ttune_log_mode = 1;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
%preset_struct.ttune_std_factor = 2.0;
presets(1) = preset_struct;

save(filepath, 'presets');