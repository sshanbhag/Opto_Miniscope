function H = opto_InitH
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% Opto program
%------------------------------------------------------------------------
% % build overall H struct
%  fH		figure handle for main sweep display
% 	ax		axes handle for main sweeps
% 	pstH	figure handle for peri-stimulus time histogram
% 	pstX	axes handle for peri-stimulus time histogram (usually an array)
% 	rstH	figure handle for raster plots
% 	rstX	axes handle for raster plots (usually an array)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% Input Arguments: none
%
% Output Arguments:
%	H		struct containing settings for opto program
% H = struct(	'constants', constants, ...
% 				'opto', opto, ...
% 				'noise', noise, ...
% 				'tone', tone, ...
% 				'wav', wav, ...
% 				'audio', audio, ...
% 				'block', block, ...
% 				'caldata', caldata, ...
% 				'TDT', TDT, ...
% 				'animal', animal, ...
% 				'TestScript', TestScript, ...
% 				'DefaultOutputDir', DefaultOutputDir, ...
% 				'fH', [], ...
% 				'ax', [], ...
% 				'pstH', [], ...
% 				'pstX', [], ...
% 				'rstH', [], ...
% 				'rstX', []	);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% Sharad Shanbhag 
% sshanbhag@neomed.edu
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% Revisions
%	28 Mar 2017 (SJS):
%		- added constants struct to hold various bits of information
%	17 May 2017 (SJS): added block to hold data for blocked search stimuli
%	12 Jun 2017 (SJS): adding stuff for spike detection, psth plots
%	13 Jun 2017 (SJS): more psth, raster things
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% Some constants
%------------------------------------------------------------------------
% this is a bit of a kludge to get around issue where passing a cell
% array to the struct() command results in a struct array...
tmp = {	'LEVEL', ...
			'FREQ', ...
			'FRA', ...
			'OPTO', ...
			'OPTO-DELAY', ...
			'OPTO-DUR', ...
			'OPTO-AMP', ...
			'STANDALONE' ...
		};
constants = struct(	...
					'TestTypes', [] ...
						);
constants.TestTypes = tmp;
clear tmp

%------------------------------------------------------------------------
% Define the default "stimulus" structs - these will hold the initial
% settings for different stimuli (e.g. opto, tone, wav)
%------------------------------------------------------------------------
% opto -> optical output settings
opto = struct(	'Enable', 0, ...
					'Delay', 0, ...
					'Dur', 100, ...
					'Amp', 50, ...
					'Channel', 10);
% noise -> noise acoustic stimulus
noise = struct(	'Type', 'noise', ...
						'Fmin', 4000, ...
						'Fmax', 80000, ...
						'PeakAmplitude', 1);
% tone -> tone acoustic stimulus
tone = struct(	'Type', 'tone', ...
					'Frequency', 5000, ...
					'RadVary', 1, ...
					'PeakAmplitude', 1);
% wav -> pre-recorded wav file stimulus (e.g., vocalization)
wav = struct(	'Type', 'wav', ...
					'filenm', 'P100_11.wav', ...
					'pathnm', 'C:\TytoLogy\Experiments\Opto', ...
					'isloaded', 0, ...
					'data', [], ...
					'info', [], ...
					'scalef', 0);
% audio is the struct that holds information about the type of 
% acoustic stimulus as well as features common to all types of 
% acoustic stimuli 
audio = struct(	'Signal', 'noise', ...
						'Delay', 100, ...
						'Duration', 200, ...
						'Level', 50, ...
						'Ramp', 1, ...
						'Frozen', 0, ...
						'ISI', 100, ...
						'AttenL', 0, ...
						'AttenR', 120);

%------------------------------------------------------------------------
% Define the block struct which is used to keep track of stimuli
% when using the "Block_Search" search stimulus
%
% Fields of block struct:
% 	CurrentStim		current stimulus index
%	CurrentTone		for tone stimuli
%	CurrentWav		for wav stimuli
% 	CurrentRep		current stimulus rep
% 	Nreps				# of times to repeat each stimulus
%------------------------------------------------------------------------
block.CurrentStim = 1;
block.CurrentTone = 1;
block.CurrentWav = 1;
block.CurrentRep = 1;
block.Nreps = 10;

%------------------------------------------------------------------------
% fake calibration data initially
%------------------------------------------------------------------------
caldata = fake_caldata('Freqs', 3000:1000:96000);

%------------------------------------------------------------------------
% input device
%------------------------------------------------------------------------
TDTPATH = 'C:\TytoLogy\Toolboxes\TDTToolbox\Circuits';
indev = struct(	'hardware', 'RZ5D', ...
						'C', [], ...
						'handle', [], ...
						'status', 0, ...
						'Fs', 50000, ...
						'Circuit_Path', [TDTPATH '\RZ5D'], ...
						'Circuit_Name', 'RZ5D_50k_16In_1Out_FindSpike_zBus.rcx', ...
						'Dnum', 1	);
%------------------------------------------------------------------------
% output device
%------------------------------------------------------------------------
outdev = struct(	'hardware', 'RZ6', ...
						'C', [], ...
						'handle', [], ...
						'status', 0, ...
						'Fs', 200000, ...
						'Circuit_Path', [TDTPATH '\RZ6'], ...
						'Circuit_Name', 'RZ6_2ChannelOutputAtten_zBus', ...
						'Dnum', 1	);
%------------------------------------------------------------------------
% TDT zBus device
%------------------------------------------------------------------------
zBUS.C =[];
zBUS.handle = [];
zBUS.status = 0;
%------------------------------------------------------------------------
% TDT attenuators (not in all setups)
%------------------------------------------------------------------------
PA5L = [];
PA5R = [];

%------------------------------------------------------------------------
% Hardware settings
%------------------------------------------------------------------------
% -- TDT I/O channels ---- default TDT hardware = 'NO_TDT'
channels.OutputChannelL = 1;
channels.OutputChannelR = 2;
channels.nInputChannels = 16;
channels.InputChannels = 1:channels.nInputChannels;
channels.OpticalChannel = 10;
channels.MonitorChannel = 1;
channels.MonitorOutputChannel = 9; 
channels.RecordChannels = num2cell(true(channels.nInputChannels, 1));
channels.nRecordChannels = sum(cell2mat(channels.RecordChannels));
channels.RecordChannelList = find(cell2mat(channels.RecordChannels));

%------------------------------------------------------------------------
% configuration
%------------------------------------------------------------------------
% lock file
config.TDTLOCKFILE = fullfile(pwd, 'tdtlockfile.mat');
config.CONFIGNAME = 'RZ6OUT200K_RZ5DIN';
% function handles
config.ioFunc = @opto_io;
config.TDTsetFunc = @opto_TDTsettings;
config.setattenFunc = @RZ6setatten;
%------------------------------------------------------------------------
% master TDT interface struct
% * sniplen and rmstau set in circuit
%------------------------------------------------------------------------
TDT = struct(	'Enable', 0, ...
					'indev', indev, ...
					'outdev', outdev, ...
					'zBUS', zBUS, ...
					'PA5L', PA5L, ...
					'PA5R', PA5R, ...
					'config', config, ...
					'channels', channels, ...
					'AcqDuration', 1000, ...
					'SweepPeriod', 1005, ...
					'TTLPulseDur', 1, ...
					'CircuitGain', 1000, ...		% gain for TDT circuit
					'MonitorGain', 1000, ...
					'HPEnable', 1, ...				% enable high pass filter
					'HPFreq', 100, ...				% high pass frequency
					'LPEnable', 1, ...				% enable low pass filter
					'LPFreq', 10000, ...				% low pass frequency
					'MonEnable', 0, ...
					'SnipLen', 60, ...				% length of spike snippet samples
					'RMSTau', 1000, ...				% ms for computation of bg RMS
					'TLo', 5, ...						% low spike threshold in std. dev
					'THi', 1000 ...					% hi spike threshold in s.d.
				);
%------------------------------------------------------------------------
% animal information struct
%------------------------------------------------------------------------
animal.Animal = '000';
animal.Unit = '0';
animal.Rec = '0';
animal.Date = TytoLogy_datetime('date');
animal.Time = TytoLogy_datetime('time');
animal.Pen = '0';
animal.AP = '0';
animal.ML = '0';
animal.Depth = '0';
animal.comments = '';

%------------------------------------------------------------------------
% test script and data destination
%------------------------------------------------------------------------
TestScript = fullfile(pwd, 'defaultscript.m');
DefaultOutputDir = 'E:\Data\SJS';

%------------------------------------------------------------------------
% build overall H struct
%  fH		figure handle for main sweep display
% 	ax		axes handle for main sweeps
% 	pstH	figure handle for peri-stimulus time histogram
% 	pstX	axes handle for peri-stimulus time histogram (usually an array)
% 	rstH	figure handle for raster plots
% 	rstX	axes handle for raster plots (usually an array)
%------------------------------------------------------------------------
H = struct(	'constants', constants, ...
				'opto', opto, ...
				'noise', noise, ...
				'tone', tone, ...
				'wav', wav, ...
				'audio', audio, ...
				'block', block, ...
				'caldata', caldata, ...
				'TDT', TDT, ...
				'animal', animal, ...
				'TestScript', TestScript, ...
				'DefaultOutputDir', DefaultOutputDir, ...
				'fH', [], ...
				'ax', [], ...
				'pstH', [], ...
				'pstX', [], ...
				'rstH', [], ...
				'rstX', [], ...
				'hashColor', 'c', ...
				'binSize', 10);
