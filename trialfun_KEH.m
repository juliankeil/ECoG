function [trl,event,hdr] = trialfun_KEH(cfg)

event = cfg.dataset.event;

trl=[];

for i=1:length(event);
    %%% Find the Correct Trials
    if ismember(event(i).type,cfg.trialdef.eventvalue);
      % add this to the trl definition
      begsample = event(i).latency - cfg.trialdef.prestim*cfg.dataset.srate;
      endsample = event(i).latency + cfg.trialdef.prestim*cfg.dataset.srate - 1;
      offset = -cfg.trialdef.prestim*cfg.dataset.srate;  %% Beginn der Datenstrecke -> Prä Trigger
      
      trl(end+1, :) = round([begsample endsample offset event(i).type]); 
      
    end % if
end % event
