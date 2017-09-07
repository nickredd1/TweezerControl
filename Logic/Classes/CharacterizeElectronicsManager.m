classdef CharacterizeElectronicsManager < GUIManager
    %CHARACTERIZEELECTRONICSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type = GUIType.CharacterizeElectronics;
        
        NumTweezers
        
        ChAmp
        
        FreqSep
        
        CenterFreq
        
        Lambda
    end
    
    methods
        function obj = CharacterizeElectronicsManager(application)
            obj = obj@GUIManager(application);
            obj.GUI = CharacterizeElectronicsGUI;
            obj.Handles = obj.GUI.Children;
        end
        
        function plotChannelAmplitude(obj)
            set1Plot = obj.Handles(7);
            set2Plot = obj.Handles(6);
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            
            sa.StartFreq = 84.9;
            sa.EndFreq = 85.1;
            span = sa.EndFreq - sa.StartFreq;
            set1 = (80:10:480);
            set2 = (420:10:2500);
            
            data1 = zeros(2, length(set1));
            data2 = zeros(2, length(set2));
            
            for i = 1:length(set1)
                awg.changeAmplitude(set1(1, i));
                pause(.5)
                spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq, 0);
                [pks, locs] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakDistance', span / 10,...
                'MinPeakHeight', -40);
                data1(1,i) = 10^(pks(1)/10);
                data1(2,i) = set1(1, i);
            end
            figure
            subplot(1,2,1) 
            plot(data1(2,:), data1(1,:))
            title(['Power (mW) vs Channel Ampltiude'...
                '(mVp) for Low Gain Channel'])
            for i = 1:length(set2)
                awg.changeAmplitude(set2(1, i));
                pause(.5)
                spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq, 0);
                [pks, locs] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakDistance', span / 10,...
                'MinPeakHeight', -40);
                data2(1,i) = 10^(pks(1)/10);
                data2(2,i) = set2(1, i);
            end
            subplot(1,2,2) 
            plot(data2(2,:), data2(1,:))
            title(['Power (mW) vs Channel Ampltiude'...
                '(mVp) for High Gain Channel'])
            
            savefig(['C:\Users\Endres Lab\Box Sync\EndresLab\Projects\'...
                'Optical trapping and imaging\Experiment\Figures\AWG'...
                '\Power vs Channel Amplitude.fig']);
        end
        
        function startTweezing(obj)
            % shorthands
            handles = obj.Handles;
            numTweezers = obj.NumTweezers;
            chAmp = obj.ChAmp;
            freqSep = obj.FreqSep;
            centerFreq = obj.CenterFreq;
            lambda = obj.Lambda;
            
            % Get plot axes handles
            periodHandle = handles(8);
            spectrumAxes1 = handles(9);
            spectrumAxes2 = handles(5);
            
            % Setup awg
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            awg.changeAmplitude(chAmp);
            
            % Convert to Hz
            centerFreq = centerFreq * 10^6;
            
            % Setup spectrum analyzer
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            
            % Condition on number of tweezers
            if (numTweezers == 1)
                freqs = [centerFreq];
            else
                numTweezers = double(numTweezers);
                freqs = centerFreq + freqSep * ...
                double(linspace(-(numTweezers-1)/2, ...
                (numTweezers-1)/2,numTweezers));
            end
            
            % Create waveform object from given data
            amps = lambda * double(ones(1,length(freqs)));
            phases = double(zeros(1,length(freqs)));
            t = double((1:awg.NumMemSamples)/awg.SamplingRate);
            discreteWFM = Waveform(freqs, amps, phases, t);
            
            % Calculate theoretical power spectrum of waveform
            axes(spectrumAxes1)
            NFFT = length(discreteWFM.Signal);
            Fs = awg.SamplingRate;
            margin = 1.5 * 10^6;
            % Impedance of load
            R = 50; 
            leftBound = freqs(1,1) - margin;
            rightBound = freqs(1, length(freqs)) + margin;
            sa.StartFreq = leftBound / 10^6;
            sa.EndFreq = rightBound / 10^6;
            f = Fs/2*[-1:2/NFFT:1-2/NFFT];
            % Take what is essentially a DFFT, making sure to give it the
            % exact sampling rate of the awg
%             [pxx,f] = periodogram(discreteWFM.Signal * ...
%                 awg.ChAmps(1) / 1000 , [], NFFT, Fs, 'power');
            pxx =(fftshift(fft(discreteWFM.Signal * awg.ChAmps(1) / 1000, ...
                NFFT))/ NFFT);
            pxx = 10*log10((abs(pxx).^2)/R * 1000);
            % Plot on a log scaleWW
            plot(f, pxx)
            axis([leftBound, rightBound, -100, 10])
            title('Theoretical Power Spectrum')
            pause(1)
            
            % Plot waveform
            axes(periodHandle)
            plot(t,  discreteWFM.Signal);
            title('Waveform Period')
            
            % Output created Waveform object
            awg.output(discreteWFM);
            pause(10)
            
            % Get and plot power spectrum
            spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq, 0);
            axes(spectrumAxes2)
            plot(spec(2,:), spec(1,:))
            axis([leftBound, rightBound, -100, 10])
            title('Real Power Spectrum')
        end
    end
    
end

