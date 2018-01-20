%% 1. Clear all
clear all
close all
clc

%% 2. Set basics

% 2.1. Set Data Directory
indata = dir('E:\ECoG\Raw\DW001\KO171120_160637_2.BDF');
indir = 'E:\ECoG\Raw\DW001\';

% 2.2. Set Output Directory
outdir = 'E:\ECoG\Raw\DW001\';

%% 3. Loop Data, load and filter

% 3.1. Filter and Sampling-Settings
hpfreq = 1;
lpfreq = 200;
notchfreq = 50; % /- 1 Hz
plotResponse = 0; % Don't plot Filter response
downsamplefreq = 600;

% 3.2. Use EEGLab to read in the data, filter and downsample
for v = 1:length(indata)
   filename = indata(v).name;

   % 3.2.1. Load Data
   EEG_raw = pop_readbdf([indir filename], [], 70, 67'); % Read in section of data
   EEG_raw = pop_rmbase( EEG_raw, []); % Remove Mean of each channel
   EEG_raw.data = double(EEG_raw.data);

   % 3.2.2. Filter
   EEG_filt = pop_eegfiltnew(EEG_raw,hpfreq,[],[],[],[],plotResponse); % Filter separately
   EEG_filt = pop_eegfiltnew(EEG_filt,[],lpfreq,[],[],[],plotResponse); % for different transition bands
   EEG_filt = pop_eegfiltnew(EEG_filt,notchfreq-1,notchfreq+1,[],1,[],plotResponse);

   % 3.2.3. Downsample
   EEG_filt = pop_resample(EEG_filt, downsamplefreq);
   EEG_filt = pop_saveset(EEG_filt,'filename',[filename,'_filt'],'filepath',outdir,'savemode','onefile','version','7.3');

   % 3.2.4. Export to FT
   dat = eeglab2fieldtrip(EEG_filt,'preprocessing','none');

   %% 4. Define the trials based on triggers

   % 4.1. Build trl-Structure to define trials
   cfg=[];
   cfg.dataset=EEG_filt;
   cfg.trialdef.eventvalue=[49];
   cfg.trialdef.prestim=1; % Seconds before the stimulus
   cfg.trialdef.poststim=1; % Seconds after the stimulus

   dat.cfg.trl=trialfun_KEH(cfg); % define trials based on these settings
end

%% 5. Redefinetrial
cfg = [];
cfg.trl = dat.cfg.trl;

dat_trl = ft_redefinetrial(cfg,dat);

%%
ft_databrowser([],dat_trl);

%%
cfg = [];
ERP = ft_timelockanalysis(cfg,dat_trl);

cfg = [];
cfg.baseline = [-1 1];
cfg.channel = 1:66;

ERP_bl = ft_timelockbaseline(cfg,ERP);

cfg = [];
cfg.channel = 27;
figure;ft_singleplotER(cfg,ERP_bl);
%%

cfg=[];
cfg.channel = 1:66;
cfg.method='wavelet';
cfg.output='pow'; % output parameter
cfg.foi=[3:3:150];
cfg.toi=[-.5:.05:.5];
cfg.width = 5;
cfg.pad='nextpow2';

WLT_trl=ft_freqanalysis(cfg,dat_trl);

cfg = [];
cfg.channel = 27;
cfg.baseline = [-.5 0];
cfg.baselinetype = 'db';

figure;ft_singleplotTFR(cfg,WLT_trl);

%% Search Triggers and Latencies
for i = 1:length(EEG_raw.event)
trig(i) =  EEG_raw.event(i).type;
end

for i = 1:length(EEG_raw.event)
lat(i) =  EEG_raw.event(i).latency;
end

plot(lat,trig,'*');
