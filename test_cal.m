
calpath = 'C:\TytoLogy\Experiments\CalData';
calfile = 'Optorig_20171022_TDT3981_4k-91k_5V_cal.mat';

caldata = load_cal(fullfile(calpath, calfile));

freq = 10000;
dur = 100;
level = 90;

[Smag, ~] = get_cal(freq, caldata.freq(1, :), ...
									caldata.mag(1, :), ...
									caldata.phase(1, :));
[Smag_corr, ~] = get_cal(freq, caldata.freq(1, :), ...
									caldata.maginv(1, :), ...
									caldata.phase(1, :));
fprintf('Smag: %.4f MinDB: %.4f Smag_corr: %.4f Smag_corrdb: %.4f\n', ...
				Smag, caldata.mindbspl(1), Smag_corr, db(Smag_corr));

stim = synmonosine(	dur, 190000, ...
									freq, ...
									caldata.DAscale, ...
									caldata);

AttenL = figure_mono_atten(level, rms(stim), caldata);
fprintf('level: %.2f rms: %.4f rmsdb: %.4f Atten: %.2f\n', ...
				level, rms(stim), ...
				db(caldata.cal.VtoPa(1).*rms(stim)), AttenL);