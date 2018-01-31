%% 1. Clear all
clear all
close all
clc

%% 2. Set basics

% 2.1. Set Data Directory
indata(1) = dir('E:\ECoG\Raw\DW001\KO171120_160637_2.BDF');
intrig(1) = 70;
inref(1) = 67; 
indata(2) = dir('E:\ECoG\Raw\A0058\a0058.BDF');
intrig(2) = 54;
inref(2) = 52;


indir{1} = 'E:\ECoG\Raw\DW001\';
indir{2} = 'E:\ECoG\Raw\A0058\';

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
   % 3.2.1. Load Data
   EEG_raw = pop_readbdf([indir{v} indata(v).name], [], intrig(v), inref(v)'); % Read in section of data
   EEG_raw = pop_rmbase( EEG_raw, []); % Remove Mean of each channel
   EEG_raw.data = double(EEG_raw.data);

   % 3.2.2. Filter
   EEG_filt = pop_eegfiltnew(EEG_raw,hpfreq,[],[],[],[],plotResponse); % Filter separately
   EEG_filt = pop_eegfiltnew(EEG_filt,[],lpfreq,[],[],[],plotResponse); % for different transition bands
   EEG_filt = pop_eegfiltnew(EEG_filt,notchfreq-1,notchfreq+1,[],1,[],plotResponse);

   % 3.2.3. Downsample and Save
   EEG_filt = pop_resample(EEG_filt, downsamplefreq);
   EEG_filt = pop_saveset(EEG_filt,'filename',[indata(v).name],'filepath',outdir,'savemode','onefile','version','7.3');
end
%% Load Preprocessed Data
for v = 1:length(indata)
   EEG_filt = pop_loadset('filename',[indata(v).name(1:end-4),'.set'],'filepath',outdir); 
   % 3.2.4. Export to FT
   dat{v} = eeglab2fieldtrip(EEG_filt,'preprocessing','none');
   dat{v}.event = EEG_filt.event;
   dat{v}.elec.unit = 'mm';
   %% 4. Define the trials based on triggers

   % 4.1. Build trl-Structure to define trials
   cfg=[];
   cfg.dataset=dat{v};
   cfg.trialdef.eventvalue=[40, 33, 41, 49]; % 40 is A1V0, 33 is A0V1, 49 is sifi
   cfg.trialdef.prestim=1; % Seconds before the stimulus
   cfg.trialdef.poststim=1; % Seconds after the stimulus

   dat{v}.cfg.trl=trialfun_KEH(cfg); % define trials based on these settings
end

%% Post-Processing
for v = 1:length(dat); % Set for Dataset
    %% 5. Redefinetrial
    cfg = [];
    cfg.trl = dat{v}.cfg.trl;

    dat_trl{v} = ft_redefinetrial(cfg,dat{v});

%     %% Some Plotting
%     cfg = [];
%     cfg.viewmode = 'vertical';
%     ft_databrowser([],dat_trl{v});

    %%
    vis{v} = find(dat_trl{v}.trialinfo == 33);
    aud{v} = find(dat_trl{v}.trialinfo == 40);
    sifi{v} = find(dat_trl{v}.trialinfo == 41);

    cfg = [];
    cfg.trials = vis{v};
    ERP_v{v} = ft_timelockanalysis(cfg,dat_trl{v});

    cfg.trials = aud{v};
    ERP_a{v} = ft_timelockanalysis(cfg,dat_trl{v});

    cfg.trials = sifi{v};
    ERP_s{v} = ft_timelockanalysis(cfg,dat_trl{v});

    cfg = [];
    cfg.baseline = [-1 1];
    cfg.channel = {'all','-EKG','-REF','-Trigger1'};%1:66;

    ERP_bl_v{v} = ft_timelockbaseline(cfg,ERP_v{v});
    ERP_bl_a{v} = ft_timelockbaseline(cfg,ERP_a{v});
    ERP_bl_s{v} = ft_timelockbaseline(cfg,ERP_s{v});

    cfg = [];
    cfg.operation = 'x1-(x2+x3)';
    cfg.parameter = 'avg';
    ERP_bl_add{v} = ft_math(cfg,ERP_bl_s{v},ERP_bl_v{v},ERP_bl_a{v});
end
    
%%
for v = 1
    
    % Find the Channel with the strongest superadditive response (A1V1 - (A1 + V1))
%     figure;
%     for i = 1:size(ERP_bl_s{2}.avg,1)
% 
%         subplot(10,6,i); plot(ERP_bl_s{2}.time,ERP_bl_s{2}.avg(i,:));
%         title(i)
%     end

    for c = 1:(size(ERP_bl_add{v}.avg,1)-3)
        [val(c) time(c)] = min(ERP_bl_add{v}.avg(c));
    end
    [minval(v) minchan(v)] = min(val);

    cfg = [];
    cfg.channel = minchan(v);
    figure;ft_singleplotER(cfg,ERP_bl_v{v},ERP_bl_a{v},ERP_bl_s{v});

    cfg = [];
    cfg.channel = minchan(v);
    figure;ft_singleplotER(cfg,ERP_bl_add{v});

end

%%
for v = 1:length(dat);
    cfg=[];
    cfg.method='wavelet';
    cfg.output='pow'; % output parameter
    cfg.foi=[3:3:150];
    cfg.toi=[-.5:.01:.5];
    cfg.width = 5;
    cfg.pad='nextpow2';

    cfg.trials = vis{v};
    WLT_trl_v{v}=ft_freqanalysis(cfg,dat_trl{v});
    cfg.trials = aud{v};
    WLT_trl_a{v}=ft_freqanalysis(cfg,dat_trl{v});
    cfg.trials = sifi{v};
    WLT_trl_s{v}=ft_freqanalysis(cfg,dat_trl{v});
end

%%
for v = 1:2;
    cfg = [];
    cfg.channel = minchan(v);
    cfg.baseline = [-.5 -.1];
    cfg.baselinetype = 'db';
    cfg.zlim = [-5 5];

    figure;
    subplot(3,1,1);ft_singleplotTFR(cfg,WLT_trl_v{v});
    subplot(3,1,2);ft_singleplotTFR(cfg,WLT_trl_a{v});
    subplot(3,1,3);ft_singleplotTFR(cfg,WLT_trl_s{v});
end
%% Search Triggers and Latencies
for i = 1:length(EEG_raw.event)
trig(i) =  EEG_raw.event(i).type;
end

for i = 1:length(EEG_raw.event)
lat(i) =  EEG_raw.event(i).latency;
end

plot(lat,trig,'*');