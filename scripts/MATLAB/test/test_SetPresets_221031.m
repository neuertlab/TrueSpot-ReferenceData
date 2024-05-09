%
%%

addpath('./core');
filepath = ['.' filesep 'core' filesep 'ths_presets.mat'];
i = 11;

%Sensitive +5
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 0;
preset_struct.ttune_use_rawcurve = true;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.5;
preset_struct.ttune_thweight_fisect = 0.0;
preset_struct.ttune_std_factor = -1.0;
presets(i) = preset_struct;
i = i - 1;

%Sensitive +4
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 0;
preset_struct.ttune_use_rawcurve = true;
preset_struct.ttune_thweight_med = 0.25;
preset_struct.ttune_thweight_fit = 0.75;
preset_struct.ttune_thweight_fisect = 0.0;
preset_struct.ttune_std_factor = -0.5;
presets(i) = preset_struct;
i = i - 1;

%Sensitive +3
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 0;
preset_struct.ttune_use_rawcurve = true;
preset_struct.ttune_thweight_med = 0.1;
preset_struct.ttune_thweight_fit = 0.9;
preset_struct.ttune_thweight_fisect = 0.0;
preset_struct.ttune_std_factor = 0;
presets(i) = preset_struct;
i = i - 1;

%Sensitive +2
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_use_rawcurve = false;
preset_struct.ttune_thweight_med = 0.15;
preset_struct.ttune_thweight_fit = 0.85;
preset_struct.ttune_thweight_fisect = 0.0;
preset_struct.ttune_std_factor = 0.0;
presets(i) = preset_struct;
i = i - 1;

%Sensitive +1
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.036;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_thweight_med = 0.25;
preset_struct.ttune_thweight_fit = 0.5;
preset_struct.ttune_thweight_fisect = 0.25;
preset_struct.ttune_std_factor = 0.0;
presets(i) = preset_struct;
i = i - 1;

%Default
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.006;
preset_struct.ttune_winsz_max = 0.042;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_thweight_med = 0.25;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.75;
preset_struct.ttune_std_factor = 0.0;
presets(i) = preset_struct;
i = i - 1;

%Specific +1
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.012;
preset_struct.ttune_winsz_max = 0.042;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 2;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
preset_struct.ttune_std_factor = 0.0;
presets(i) = preset_struct;
i = i - 1;

%Specific +2
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 3;
preset_struct.ttune_winsz_max = 21;
preset_struct.ttune_winsz_incr = 3;
preset_struct.ttune_use_diffcurve = false;
preset_struct.ttune_log_mode = 1;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
preset_struct.ttune_std_factor = 0.0;
presets(i) = preset_struct;
i = i - 1;

%Specific +3
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.012;
preset_struct.ttune_winsz_max = 0.048;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_use_diffcurve = true;
preset_struct.ttune_log_mode = 1;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
preset_struct.ttune_std_factor = 0.0;
presets(i) = preset_struct;
i = i - 1;

%Specific +4
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.012;
preset_struct.ttune_winsz_max = 0.048;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_log_mode = 1;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
preset_struct.ttune_std_factor = 0.5;
presets(i) = preset_struct;
i = i - 1;

%Specific +5
preset_struct = RNAThreshold.genPresetStruct();
preset_struct.ttune_winsz_min = 0.012;
preset_struct.ttune_winsz_max = 0.048;
preset_struct.ttune_winsz_incr = 0.006;
preset_struct.ttune_use_diffcurve = true;
preset_struct.ttune_log_mode = 1;
preset_struct.ttune_thweight_med = 0.5;
preset_struct.ttune_thweight_fit = 0.0;
preset_struct.ttune_thweight_fisect = 0.5;
preset_struct.ttune_std_factor = 1.0;
presets(i) = preset_struct;
i = i - 1;

save(filepath, 'presets');