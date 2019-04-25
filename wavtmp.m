%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% Experiment settings
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% %%% EDIT THESE TO CHANGE EXPERIMENTAL PARAMETERS (reps, ISI, etc.) %%%%
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%-------------------------------------------------------------------------
%----------------------------------------------------------
% Presentation settings - ISI, # reps, randomize, etc.
%----------------------------------------------------------
test.Reps = 10;
test.Randomize = 0;
test.Block = 1;
audio.ISI = 200;
%------------------------------------
% Experiment settings
%------------------------------------
% save output stimuli? (0 = no, 1 = yes)
test.saveStim = 0;
% stimulus levels to test
test.Level = [40 60 80];
% use null stim?
test.NullStim = 1;
% use noise stimulus?
test.NoiseStim = 1;
%------------------------------------
% acquisition/sweep settings
% will have to be adjusted to deal with wav file durations
%------------------------------------
test.AcqDuration = 500;
test.SweepPeriod = test.AcqDuration + 5;

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%% define stimulus (optical, audio) structs
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%------------------------------------
% OPTICAL settings
%	Enable	0 -> optical stim OFF, 1 -> optical stim ON
%	Delay		onset of optical stim from start of sweep (ms)
% 	Dur		duration (ms) of optical stimulus
% 	Amp		amplitude (mV) of optical stim
% 					*** IMPORTANT NOTE ***
% 					This method of amplitude control will only work with the 
% 					Thor Labs fiber-coupled LED driver.
% 					For the Shanghai Dream Laser, output level can only be 
% 					controlled using the rotary potentiometer on the Laser power
% 					supply. If using the Shanghai Dream Laser for stimulation,
% 					set Amp to 5000 millivolts (5 V)
% 
% 	To test a range of values (for Delay, Dur, Amp), use a vector of values
% 	instead of a single number (e.g., [20 40 60] or 20:20:60)
%------------------------------------
% opto.Enable = 1;
% opto.Delay = 100;
% opto.Dur = 100;
% opto.Amp = 250;
opto.Enable = 0;
opto.Delay = 0;
opto.Dur = 200;
opto.Amp = 0;
%------------------------------------
% AUDITORY stimulus settings
%------------------------------------
%------------------------------------
% general audio properties
%------------------------------------
% Delay 
audio.Delay = 100;
% Duration is variable for WAV files - this information
% will be found in the audio.signal.WavInfo
% For now, this will be a dummy value
audio.Duration = 200;
% Level(s) for wav output
audio.Level = 80;
audio.Ramp = 5;
audio.Frozen = 0;
%------------------------------------
% noise signal
%------------------------------------
noise.signal.Type = 'noise';
noise.signal.Fmin = 4000;
noise.signal.Fmax = 80000;
noise.Delay = audio.Delay;
noise.Duration = 100;
noise.Level = 80;
noise.Ramp = 5;
noise.Frozen = 0;
%------------------------------------
% null signal
%------------------------------------
null.signal.Type = 'null';
null.Delay = audio.Delay;
null.Duration = noise.Duration;
null.Level = 0;
%------------------------------------
% WAV
%------------------------------------
audio.signal.Type = 'wav';
audio.signal.WavPath = 'C:\TytoLogy\Experiments\WAVs';
% names of wav files to use as stimuli
WavesToPlay = {	'1-stepUSVwithNLs_adj.wav', ...
						'2-stepUSV_adj.wav', ...
						'chevron_adj.wav', ...
						'chevronwithNLs_adj.wav', ...
						'flat_adj.wav', ...
						'LFH_adj.wav', ...
						'MFV_harmonic_normalized_adj.wav', ...
						'MFV_NL_filtered_normalized_adj.wav', ...
						'MFV_tonal_normalized_adj.wav', ...
						'noisy_adj.wav', ...
					};
% # of wavs
nWavs = length(WavesToPlay);

% and scaling factors (to achieve desired amplitude)
% % % temporarily use 1 as scaling factor - fix after calibration!!!
WavScaleFactors = ones(nWavs, 1);

% max level achievable at given scale factor 
% (determined using FlatWav program)
WavLevelAtScale = [	90.4, ...
							91.75, ...
							90.74, ...
							94.53, ...
							90.04, ...
							99.62, ...
							102.2, ...
							95.61, ...
							102.64, ...
							91.18, ...
						];
% construct wavInfo for desired wav stimuli
[wavInfo, audio.signal.WavFile] = opto_create_wav_stimulus_info( ...
														audio.signal.WavPath, ...
														WavesToPlay, ...
														WavScaleFactors, ...
														WavLevelAtScale);

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%% get list of unique stimuli
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

[stimList, counts] = opto_build_stimList(test, audio, opto, noise, null);



%{

sindex = 0;
for oindex = 1:nOptoStim
	for aindex = 1:nAudioStim
		for lindex = 1:nAudioLevels
			sindex = sindex + 1;
			stimList(sindex).opto.Amp = optovar(oindex);
			% assign audio stim 1 to null
			if (aindex == 1) && (nNullStim > 0)
				stimList(sindex).audio = null;
				% level should already be set to 0 so do nothing re: level
			% assign audio stim 2 to noise
			elseif (aindex == 2) && (nNoiseStim > 0)
				stimList(sindex).audio = noise;
				% assign stimulus level
				stimList(sindex).audio.Level = test.Level(lindex);
			else
				% need to account for aindex offset due to null and noise
				windex = aindex - (nNullStim + nNoiseStim);
				stimList(sindex).audio.signal.WavFile = audiowavvar{windex};
				% assign stimulus level
				stimList(sindex).audio.Level = test.Level(lindex);
			end
		end
	end	
end


%}

