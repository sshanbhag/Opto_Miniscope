%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% tone_ratelevel
%-------------------------------------------------------------------------
% vary dB SPL at a single frequency
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------


%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% Set Type of test
%-------------------------------------------------------------------------
% 	'LEVEL'			firing rate vs. stimulus level (dB)
%	`FREQ'			frequency-tuning curve (tones)
%	'FRA'				frequency-response area (tones)
% 	'OPTO'			simple optical stimulation (nothing varies)
% 	'OPTO-xxx'		optical stim, with 'xxx' as variable, where 'xxx' is
% 		'DELAY'			opto stim delay 
% 		'DUR'				opto stim duration
% 		'AMP'				opto stim amplitude
% 						or some combination of these
%-------------------------------------------------------------------------
test.Type = 'LEVEL';
test.Name = 'TONE_LEVEL';
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% OPTICAL settings
%-------------------------------------------------------------------------
test.opto.Enable = 0;
test.opto.Delay = 75;
test.opto.Dur = 100;
test.opto.Amp = 3000;
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% Auditory stimulus settings
%-------------------------------------------------------------------------
% signal
test.audio.signal.Type = 'tone';
test.audio.signal.Frequency = 26000;
test.audio.signal.RadVary = 1;
test.audio.Delay = 100;
test.audio.Duration = 100;
% test.audio.Level = [20 40 60 70];
test.audio.Level = 0:10:60;
test.audio.Ramp = 5;
test.audio.Frozen = 0;
test.audio.ISI = 100;

test.Reps = 10;
% test.Reps = 5;
test.Randomize = 1;
test.Block = 0;
test.saveStim = 0;
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% TDT
%-------------------------------------------------------------------------
test.AcqDuration = 250;
test.SweepPeriod = test.AcqDuration + 5;
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% Misc
%-------------------------------------------------------------------------
% adjust test name if opto is ON
 if test.opto.Enable
	test.Name = [test.Name '_optoON'];
end
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
