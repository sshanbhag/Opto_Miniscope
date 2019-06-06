%------------------------------------------------------------------
% Script to test stimuli
%------------------------------------------------------------------
% - will use Calibration IO circuit and function
%------------------------------------------------------------------

%------------------------------------------------------------------
%------------------------------------------------------------------
% Setup
%------------------------------------------------------------------
%------------------------------------------------------------------

MAX_ATTEN = 120;
L = 1;
R = 2;

%------------------------------------------------------------------
% Load Calibration Data
%------------------------------------------------------------------
test.calpath = 'C:\TytoLogy\Experiments\WAVs';
test.calfile = 'LCY-C-4K-100K-1V-20dBatten_29May19.cal';
cfile = fullfile(test.calpath, test.calfile);
if ~exist(cfile, 'file')
	error('%s: Calibration file %s not found!', mfilename, ...
						cfile);
else
	% load the calibration data
	fprintf('Loading calibration data from %s\n', cfile);
	caldata = load_cal_and_smooth(cfile, 10);
end

%------------------------------------------------------------------
% Calibration Test Settings
%------------------------------------------------------------------
fprintf('Test settings\n');
% use defaults from Calibrate as a start
test = Calibrate_init('INIT_ULTRA');

% modify as needed
test.Fmin = 4000;
test.Fmax = 95000;
test.Fstep = 200;
test.Reps = 3;

test.AttenType = 'VARIED';
test.MinLevel = 45;
test.MaxLevel = 50;
test.AttenStep = 2;
test.AttenFixed = 60;
test.AttenStart = 90; 

test.MicGainL_dB = 40;
test.MicGainR_dB = 40;
test.MicSenseL = 1;
test.MicSenseR = 1;
test.frfileL = [];
test.frfileR = [];
test.UseFR = 1;

test.ISI = 100; 
test.Duration = 150;
test.Delay = 10;
test.Ramp = 5;
test.DAlevel = 5;

test.AcqDuration = 200;
test.SweepPeriod = test.AcqDuration + 10;
test.TTLPulseDur = 1;
test.HPFreq = 3800;
test.LPFreq = 97000;


% Microphone and conversion to dB settings
%	Note that cal.Fs will need to be reset once TDT hardware is initialized
test.MicGainL_dB = 0;
test.MicGainR_dB = 0;
% reshape
test.RefMicSens = [test.MicSenseL test.MicSenseR];
test.MicGain_dB = [test.MicGainL_dB test.MicGainR_dB];
% pre-compute some conversion factors:
% Volts to Pascal factor
test.VtoPa = test.RefMicSens.^-1;
% mic gain factor
test.MicGain = 10.^(test.MicGain_dB./20);

%------------------------------------------------------------------
% Use MTwav_settings for now
%------------------------------------------------------------------
run C:\TytoLogy\Experiments\Opto\Scripts\MTwav_settings;


%------------------------------------------------------------------
% Hardware Settings
%------------------------------------------------------------------
% use Calibrate_init to get settings, using RZ6_200K
TDT = Calibrate_init('RZ6_200K');


%------------------------------------------------------------------
%------------------------------------------------------------------
%% Initialize Hardware
%------------------------------------------------------------------
%------------------------------------------------------------------

%------------------------------------------------------------------
% Initialize the TDT devices
%------------------------------------------------------------------
% display message
fprintf('Initializing TDT\n')
% make iodev structure
iodev.Circuit_Path = TDT.Circuit_Path;
iodev.Circuit_Name = TDT.Circuit_Name;
iodev.Dnum = TDT.Dnum; 
% initialize RX* 
tmpdev = TDT.RXinitFunc('GB', TDT.Dnum); 
iodev.C = tmpdev.C;
iodev.handle = tmpdev.handle;
iodev.status = tmpdev.status;
% initialize attenuators
if strcmpi(TDT.AttenMode, 'PA5')
	% initialize PA5 attenuators (left = 1 and right = 2)
	PA5L = TDT.PA5initFunc('GB', 1);
	PA5R = TDT.PA5initFunc('GB', 2);
end
% load circuit
iodev.rploadstatus = TDT.RPloadFunc(iodev); 
% start circuit
TDT.RPrunFunc(iodev);
% check status
iodev.status = TDT.RPcheckstatusFunc(iodev);
% Query the sample rate from the circuit 
iodev.Fs = TDT.RPsamplefreqFunc(iodev);
% store in test struct
test.Fs = iodev.Fs;

%------------------------------------------------------------------
% Set up TDT parameters
%------------------------------------------------------------------
TDT.TDTsetFunc(iodev, test); 

%------------------------------------------------------------------
% Set up filtering
%------------------------------------------------------------------
% update bandpass filter for processing the data
% Nyquist frequency
fnyq = iodev.Fs / 2;
% passband definition
fband = [test.HPFreq test.LPFreq] ./ fnyq;
% filter coefficients using a 3rd order Butterworth bandpass filter
[fcoeffb, fcoeffa] = butter(3, fband, 'bandpass');

%------------------------------------------------------------------
% set the start and end bins for the calibration
% ignore onset/offset ramps for calculation of rms and db SPL
%------------------------------------------------------------------
% io function overrides Delay setting to 0 so this is no longer correct
% start_bin = ms2bin(test.Delay + test.Ramp, iodev.Fs);
start_bin = ms2bin(test.Ramp, iodev.Fs);
if start_bin < 1
	start_bin = 1;
end
end_bin = start_bin + ms2bin(test.Duration - 2*test.Ramp, iodev.Fs);
zerostim = syn_null(test.Duration, iodev.Fs, 1);  % make zeros for both channels
outpts = length(zerostim);
acqpts = ms2bin(test.AcqDuration, iodev.Fs);

%------------------------------------------------------------------
%------------------------------------------------------------------
%% Do things
%------------------------------------------------------------------
%------------------------------------------------------------------
figure

test.Level = 50;

%------------------------------------------------------------------
%% test noise using example from Calibrate_test
%------------------------------------------------------------------
% synthesize noise
% stim = synmonosine(cal.Duration, iodev.Fs, freq, caldata.DAscale, caldata);
stim = synmononoise_fft(	test.Duration, ...
											iodev.Fs, ...
											test.Fmin, ...
											test.Fmax, ...
											1, ...
											caldata);
stim = caldata.DAscale * normalize(stim);
S = zeros(2, length(stim));
S(1, :) = stim;
S(2, :) = zeros(size(stim));
S = sin2array(S, test.Ramp, iodev.Fs);
% plot the stim array
tvec = (1000/iodev.Fs).*(0:(acqpts-1));
stimvecP = 0 * tvec;
delay_samples = ms2bin(test.Delay, test.Fs);
duration_samples = ms2bin(test.Duration, test.Fs);
% this was original code, but RZ6calibration_io sets delay to 0...
% stimvecP( (delay_samples + 1) : (delay_samples + duration_samples) ) = ...
% 						S(1, :);
% updated
stimvecP(1:duration_samples) = S(1, :);
subplot(311);
plot(tvec, stimvecP);
% figure out attenuation value 
stim_rms = rms(stim);
atten_val(1) = figure_mono_atten_noise(test.Level, stim_rms, caldata);
atten_val(2) = MAX_ATTEN;
fprintf('rms: %.4f max: %.4f, atten: %.2f\n', ...
					stim_rms, max(stim), atten_val(1));


%% set attenuation 
TDT.setattenFunc(iodev, atten_val);

% play the sound;
[resp, rate] = TDT.ioFunc(iodev, S, acqpts);
% filter raw data
resp{1} = filtfilt(fcoeffb, fcoeffa, sin2array(resp{1}, 1, iodev.Fs));
% plot the response
subplot(312)
plot(tvec, resp{1}, 'g');
% determine the magnitude of the response/leak
pmag = rms(resp{1}(start_bin:end_bin));
% adjust for the gain of the preamp (for non-calibration mics, this is
% inaccurate!!!!!)
pmag = pmag / test.MicGain(1);
% store the data in arrays
noisemags = dbspl( test.VtoPa * pmag );
% show calculated values
fprintf('\t\tresp rms: %.4f dbSPL: %.4f\n', pmag, dbspl(test.VtoPa(1)*pmag));

dbAx = subplot(313);
[~, ~, test.rVals] = plotSignalAnddB(resp{1}, 10, test.Fs, ...
													'dBSPL', test.VtoPa(1), ...
													'signalname', 'noise');
	

%------------------------------------------------------------------
%------------------------------------------------------------------
%% Shut down hardware
%------------------------------------------------------------------
%------------------------------------------------------------------
if strcmpi(TDT.AttenMode, 'PA5')
	TDT.PA5closeFunc(PA5L);
	TDT.PA5closeFunc(PA5R);
end
TDT.RPcloseFunc(iodev);
