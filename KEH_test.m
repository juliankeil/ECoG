%% 1. Clear all
clear all
close all
clc

%% 2. Set basics

% 2.1. Set Data Directory
indata{1} = dir('E:\ECoG\Raw\DW001\KO171120_160637_2.BDF');
indata{2} = dir('E:\ECoG\Raw\A0058\a0058.BDF');
indir = 'E:\ECoG\Raw\';

% 2.2. Set Output Directory
outdir = 'E:\ECoG\Preproc\';

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
   EEG_raw = pop_readbdf([filename], [], 70, 67'); % Read in section of data
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
   cfg.trialdef.eventvalue=[40, 33, 41, 49]; % 40 is A1V0, 33 is A0V1, 49 is sifi
   cfg.trialdef.prestim=1; % Seconds before the stimulus
   cfg.trialdef.poststim=1; % Seconds after the stimulus

   dat.cfg.trl=trialfun_KEH(cfg); % define trials based on these settings
end

%% 5. Redefinetrial
cfg = [];
cfg.trl = dat.cfg.trl;

dat_trl = ft_redefinetrial(cfg,dat);

%%
cfg = [];
cfg.viewmode = 'vertical';
ft_databrowser([],dat_trl);

%%
vis = find(dat_trl.trialinfo == 33);
aud = find(dat_trl.trialinfo == 40);
sifi = find(dat_trl.trialinfo == 41);

cfg = [];
cfg.trials = vis;
ERP_v = ft_timelockanalysis(cfg,dat_trl);

cfg.trials = aud;
ERP_a = ft_timelockanalysis(cfg,dat_trl);

cfg.trials = sifi;
ERP_s = ft_timelockanalysis(cfg,dat_trl);

cfg = [];
cfg.baseline = [-1 1];
cfg.channel = 1:66;

ERP_bl_v = ft_timelockbaseline(cfg,ERP_v);
ERP_bl_a = ft_timelockbaseline(cfg,ERP_a);
ERP_bl_s = ft_timelockbaseline(cfg,ERP_s);

cfg = [];
cfg.channel = 27;
figure;ft_singleplotER(cfg,ERP_bl_v,ERP_bl_a,ERP_bl_s);

cfg = [];
cfg.operation = 'x1-(x2+x3)';
cfg.parameter = 'avg';
ERP_bl_add = ft_math(cfg,ERP_bl_s,ERP_bl_v,ERP_bl_a);

cfg = [];
cfg.channel = 27;
figure;ft_singleplotER(cfg,ERP_bl_add);
%%

cfg=[];
cfg.channel = 1:66;
cfg.method='wavelet';
cfg.output='pow'; % output parameter
cfg.foi=[3:3:150];
cfg.toi=[-.5:.01:.5];
cfg.width = 5;
cfg.pad='nextpow2';

cfg.trials = vis;
WLT_trl_v=ft_freqanalysis(cfg,dat_trl);
cfg.trials = aud;
WLT_trl_a=ft_freqanalysis(cfg,dat_trl);
cfg.trials = sifi;
WLT_trl_s=ft_freqanalysis(cfg,dat_trl);

cfg = [];
cfg.channel = 27;
cfg.baseline = [-.5 0];
cfg.baselinetype = 'db';
cfg.zlim = [- 5 5];

figure;ft_singleplotTFR(cfg,WLT_trl_v);
figure;ft_singleplotTFR(cfg,WLT_trl_a);
figure;ft_singleplotTFR(cfg,WLT_trl_s);
%% Search Triggers and Latencies
for i = 1:length(EEG_raw.event)
trig(i) =  EEG_raw.event(i).type;
end

for i = 1:length(EEG_raw.event)
lat(i) =  EEG_raw.event(i).latency;
end

plot(lat,trig,'*');