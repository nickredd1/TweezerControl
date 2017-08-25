numTweezers=10;
loadingProb=0.5;

%Define initial array
array0=ones(1,numTweezers);

%Define randomly occupied array
array1=double(rand(1,numTweezers)>loadingProb);

%Define final defect-free array
array2=sort(array1,'descend');

%%
%Compute movement array
idx=1:numTweezers;
mov12=array1.*idx-cumsum(array1);
mov12(array1==0)=nan;

%%
samplerate=512e6;
dt=1/samplerate;

f0=85e6;
df=1e6;
phase0=2*pi*rand(1,numTweezers);

freqArray=f0+df*(linspace(1,numTweezers,numTweezers)-(numTweezers+1)/2);

%s0
T0=1e-3;
t=linspace(1,numSamples,numSamples)*dt;

wfm=struct();
wfm.fun='@(j) wfm.amp(j)*sin(2*pi*wfm.freq(j)*t+wfm.phase(j))';
wfm.freq=freqArray;
wfm.amp=ones(1,numTweezers);
wfm.phase=phase0;
wfm.signals=arrayfun(eval(wfm.fun),1:numel(wfm.freq),'UniformOutput',false); %compute
wfm.signal=sum(cell2mat(wfm.signals'),1); %sum
%wfm.signal=wfm.signal/max(wfm.signal); %normalize
wfm0=wfm;

%s01 adiabatically ramp down the amplitude of the empty tweezers
T01=1e-3;
numSamples=samplerate*T01;
t=linspace(1,numSamples,numSamples)*dt;

%s01
wfm=struct();
wfm.fun='@(j) wfm.amp(j)*(1-(1-array1(j))*t/T01).*sin(2*pi*wfm.freq(j)*t+wfm.phase(j))';
wfm.freq=freqArray;
wfm.amp=ones(1,numTweezers);
wfm.phase=phase0;
wfm.signals=arrayfun(eval(wfm.fun),1:numTweezers,'UniformOutput',false); %compute
wfm.signal=sum(cell2mat(wfm.signals'),1); %sum
wfm01=wfm;

%s1
wfm=struct();
wfm.fun='@(j) wfm.amp(j)*sin(2*pi*wfm.freq(j)*t+wfm.phase(j))';
wfm.freq=freqArray;
wfm.amp=array1;
wfm.phase=phase0;
wfm.signals=arrayfun(eval(wfm.fun),1:numTweezers,'UniformOutput',false); %compute
wfm.signal=sum(cell2mat(wfm.signals'),1); %sum
wfm1=wfm;

%s12
T12=1e-3;
fun='@(j) chirp(t,freqArray(j),T12,freqArray(j-mov12(j)),''linear'',pi/2)';
s12=arrayfun(eval(fun),idx(~isnan(mov12)),'UniformOutput',false); %compute
s12=sum(cell2mat(s12'),1);

%s2
wfm=struct();
wfm.fun='@(j) wfm.amp(j)*sin(2*pi*wfm.freq(j)*t+wfm.phase(j))';
wfm.freq=freqArray;
wfm.amp=array2;
wfm.phase=phase0;
wfm.signals=arrayfun(eval(wfm.fun),1:numTweezers,'UniformOutput',false); %compute
wfm.signal=sum(cell2mat(wfm.signals'),1); %sum
wfm2=wfm;


%% Plot
t01=1e-3;
tAOD=4e-6; %acoustic wave period
NOVERLAP=t01/tAOD;
WINDOW=8*2^nextpow2(NOVERLAP);
F=WINDOW;

s=[wfm0.signal,wfm01.signal,s12,wfm2.signal];
figure();
spectrogram(s,WINDOW,NOVERLAP,F,samplerate,'yaxis')
ylim([80,90])
