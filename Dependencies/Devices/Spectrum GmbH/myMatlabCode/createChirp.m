samplerate=512e6;
freqResolution=0.5e6; %Hz
memSamples=samplerate*1/freqResolution; %must be a factor of 1024
t=(1:memSamples)/samplerate;

%Start with linear chirps
t = 0:1/1e3:2;
y = chirp(t,0,1,250);

figure();
spectrogram(y,256,250,256,1e3,'yaxis');

%%
samplerate=512e6;
dnu=5e6;
nu0=80e6; %initial frequency
nu1=nu0+dnu; %final frequency
t01=1e-3; %sweep time
dt=1/samplerate;
numSamples=samplerate*t01;
t=linspace(1,numSamples,numSamples)*dt;

s0=sin(2*pi*nu0*t);
s1=sin(2*pi*nu1*t);
s01=chirp(t,nu0,t01,nu1,'linear',pi/2);

tAOD=4e-6; %acoustic wave period
NOVERLAP=t01/tAOD;
WINDOW=8*2^nextpow2(NOVERLAP);
F=WINDOW;

s=[s0,s01,s1];
figure();
spectrogram(s,WINDOW,NOVERLAP,F,samplerate,'yaxis')
ylim([60,110])
