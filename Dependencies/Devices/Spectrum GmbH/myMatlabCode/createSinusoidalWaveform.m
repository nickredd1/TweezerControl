%createSinusoidalWaveform
%2017-04-03
function [success, cardInfo, signal]=createSinusoidalWaveform(cardInfo) 
samplerate=cardInfo.setSamplerate;
memSamples=cardInfo.setMemsize;
scale=2^14/2-1; %8191

t=(1:memSamples)/samplerate;

wfm=struct();
wfm.fun='@(j) wfm.amp(j)*sin(2*pi*wfm.freq(j)*t+wfm.phase(j))';
wfm.freq=[85]*1e6;
wfm.amp=ones(1,numel(wfm.freq)); %-gausswin(numel(wfm.freq))';
wfm.phase=zeros(1,numel(wfm.freq)); %2*pi*rand(1,numel(wfm.freq));  
wfm.signals=arrayfun(eval(wfm.fun),1:numel(wfm.freq),'UniformOutput',false);
wfm.signal=sum(cell2mat(wfm.signals'),1); %/numel(wfm.signals)
wfm.signal=wfm.signal/max(wfm.signal); %/numel(wfm.signals)

%numel(wfm.freq)

%play audio
% player = audioplayer([wfm.signal,wfm.signal,wfm.signal,wfm.signal,wfm.signal,wfm.signal], 0.1e6);
% play(player);
% 
% figure();
% subplot(2,1,1); plot(t,cell2mat(wfm.signals'));
% subplot(2,1,2); plot(t,wfm.signal,'.-');

%signal=scale*wfm.signal;
signal=scale*wfm.signal;

% figure(); plot(signal);

success=true;
