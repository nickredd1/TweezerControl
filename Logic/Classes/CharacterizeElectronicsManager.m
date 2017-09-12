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
        
        MonitoringPower
        
        PreAmpPowerData
        
        PostAmpPowerData
        
        Attenuation
    end
    
    methods
        function obj = CharacterizeElectronicsManager(application)
            obj = obj@GUIManager(application);
            obj.GUI = CharacterizeElectronicsGUI;
            obj.Handles = obj.GUI.Children;
            obj.MonitoringPower = false;
            
            obj.PreAmpPowerData = zeros(1, 500);
            obj.PostAmpPowerData = zeros(1, 500);
        end
        
        function characterizeDACs(obj)
            nidaq = obj.Application.getDevice(DeviceType.NIDAQ, 0);
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            set1 = (80:10:480);
            set2 = (420:10:2500);
            attenuation = obj.Attenuation;
            pauseTime = .5;
            numTweezers = 5;
            numFreqs = 1;
            data1 = zeros(4, numTweezers * length(set1));
            data2 = zeros(4, numTweezers * length(set2));
                
            while numFreqs < 32
                obj.NumTweezers = numFreqs;
                discreteWFM = obj.tweeze();
                
                sa.StartFreq = (discreteWFM.Freqs(1,1) / 10^6) - .3; 
                sa.EndFreq = (discreteWFM.Freqs(1,end) / 10^6) + .3; 
                span = sa.EndFreq - sa.StartFreq;
                pauseTime = .5 + .5 * floor(span);
                for i = 1:length(set1)
                    awg.changeAmplitude(set1(1, i));
                    power = sa.getPeakPower(sa.StartFreq, sa.EndFreq,...
                        attenuation, pauseTime);
                    
                    volts = zeros(1,20);
                    for k = 1:length(volts)
                        temp = nidaq.sampleInputs();
                        volts(1,k) = temp(1,1);
                    end
                    volts = mean(volts);
                    data1(1, (numFreqs-1) * length(set1) + i)= power;
                    data1(2, (numFreqs-1) * length(set1) + i)= volts;
                    data1(3, (numFreqs-1) * length(set1) + i)= set1(1, i);
                    data1(4, (numFreqs-1) * length(set1) + i)= numFreqs;
                end
                
                for i = 1:length(set2)
                    awg.changeAmplitude(set2(1, i));
                    power = sa.getPeakPower(sa.StartFreq, sa.EndFreq,...
                        attenuation, pauseTime);
                    volts = zeros(1,20);
                    for k = 1:length(volts)
                        temp = nidaq.sampleInputs();
                        volts(1,k) = temp(1,1);
                    end
                    volts = mean(volts);
                    data2(1,(numFreqs-1) * length(set2) + i) = power;
                    data2(2,(numFreqs-1) * length(set2) + i) = volts;
                    data2(3,(numFreqs-1) * length(set2) + i) = set2(1, i);
                    data2(4,(numFreqs-1) * length(set2) + i) = numFreqs;
                end
                numFreqs = numFreqs * 2;
            end
            figure
            subplot(2,2,1) 
            stem3(data1(3,:), data1(4,:), data1(1,:))
            
            title(['RF Power (dBm) vs Channel Amplitude (mVp)'...
                'for Low Gain Channel'])
            
            subplot(2,2,2) 
            stem3(data1(3,:), data1(4,:), data1(2,:))
            zlim([1 1.1])
            title(['RF Power (V) vs Channel Amplitude (mVp)'...
                'for Low Gain Channel'])
            
            subplot(2,2,3) 
            stem3(data2(3,:), data2(4,:), data2(1,:))
            title(['RF Power (dBm) vs Channel Amplitude (mVp)'...
                'for High Gain Channel'])
            
            subplot(2,2,4) 
            stem3(data2(3,:), data2(4,:), data2(2,:))
            zlim([1 1.1])
            title(['RF Power (V) vs Channel Amplitude (mVp)'...
                'for High Gain Channel'])
            
            savefig(['C:\Users\Endres Lab\Box Sync\EndresLab\Projects\'...
                'Optical trapping and imaging\Experiment\Figures\AWG'...
                '\Power vs Channel Amplitude.fig']);
        end
        
        function plotChannelAmplitude(obj)
            set1Plot = obj.Handles(8);
            set2Plot = obj.Handles(7);
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            
            sa.StartFreq = 84.9;
            sa.EndFreq = 85.1;
            span = sa.EndFreq - sa.StartFreq;
            set1 = (80:10:480);
            set2 = (420:10:2500);
            attenuation = 30;
            pauseTime = .5;
            data1 = zeros(2, length(set1));
            data2 = zeros(2, length(set2));
            
            for i = 1:length(set1)
                awg.changeAmplitude(set1(1, i));
                spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq,...
                    attenuation, pauseTime);
                [pks, locs] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakDistance', span / 10,...
                'MinPeakHeight', -10);
                data1(1,i) = pks(1);
                data1(2,i) = set1(1, i);
            end
            figure
            subplot(1,2,1) 
            plot(data1(2,:), data1(1,:))
            title(['Power (dBm) vs Channel Ampltiude'...
                '(mVp) for Low Gain Channel'])
            for i = 1:length(set2)
                awg.changeAmplitude(set2(1, i));
                spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq,...
                    attenuation, pauseTime);
                [pks, locs] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakDistance', span / 10,...
                'MinPeakHeight', -10);
                data2(1,i) = pks(1);
                data2(2,i) = set2(1, i);
            end
            subplot(1,2,2) 
            plot(data2(2,:), data2(1,:))
            title(['Power (dBm) vs Channel Ampltiude'...
                '(mVp) for High Gain Channel'])
            
            savefig(['C:\Users\Endres Lab\Box Sync\EndresLab\Projects\'...
                'Optical trapping and imaging\Experiment\Figures\AWG'...
                '\Power vs Channel Amplitude.fig']);
        end
        
        function discreteWFM = tweeze(obj)
            % shorthands
            handles = obj.Handles;
            numTweezers = obj.NumTweezers;
            chAmp = obj.ChAmp;
            freqSep = obj.FreqSep;
            centerFreq = obj.CenterFreq;
            lambda = obj.Lambda;
            
            % Setup awg
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            awg.changeAmplitude(chAmp);
            
            % Convert to Hz
            centerFreq = centerFreq * 10^6;
            
            % Condition on number of tweezers
            if (numTweezers == 1)
                freqs = [centerFreq];
            else
                numTweezers = double(numTweezers);
                freqs = centerFreq + freqSep * ...
                double(linspace(-(numTweezers-1)/2, ...
                (numTweezers-1)/2,numTweezers));
            end
            
            % Create waveform object from given data with random phases
            % such that we attempt to avoid nonliner frequency mixing and
            % interference
            amps = double(ones(1,length(freqs)));
            phases = 2 * pi * rand(1, length(freqs));
            controls = double(ones(1, length(freqs)));
            t = double((1:awg.NumMemSamples)/awg.SamplingRate);
            discreteWFM = Waveform(lambda, freqs, controls, amps,...
                phases, t);
            
            % Output created Waveform object
            awg.output(discreteWFM);
        end
        
        function startTweezing(obj)
            % shorthands
            handles = obj.Handles;
            numTweezers = obj.NumTweezers;
            chAmp = obj.ChAmp;
            freqSep = obj.FreqSep;
            centerFreq = obj.CenterFreq;
            lambda = obj.Lambda;
            % Attenuation from various RF components in system
            attenuation = obj.Attenuation;
            % Get plot axes handles
            periodHandle = handles(9);
            spectrumAxes1 = handles(10);
            spectrumAxes2 = handles(6);
            
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
            
            % Create waveform object from given data with random phases
            % such that we attempt to avoid nonliner frequency mixing and
            % interference
            amps = double(ones(1,length(freqs)));
            phases = 2 * pi * rand(1, length(freqs));
            controls = double(ones(1, length(freqs)));
%             load(['C:\Users\Endres Lab\Box Sync\EndresLab\Projects\'...
%                 'Optical trapping and imaging\Experiment\Scripts\'...
%                 'createUniformTweezers\Data\uniform_waveform_51tweezers']...
%                 , 'wfm');
%             amps = lambda * (wfm.amp');
%             freqs = wfm.freq;
%             phases = wfm.phase;
            
            t = double((1:awg.NumMemSamples)/awg.SamplingRate);
            discreteWFM = Waveform(lambda, freqs, controls, amps,...
                phases, t);
            
            % Calculate theoretical power spectrum of waveform
            axes(spectrumAxes1)
            NFFT = length(discreteWFM.Signal);
            Fs = awg.SamplingRate;
            margin = 1.5 * 10^6;
            % Impedance of load, should be 50 ohms but 90 seems to fit the
            % theoretical power spectrum to the real power spectrum better
            R = 85; 
            leftBound = freqs(1,1) - margin;
            rightBound = freqs(1, length(freqs)) + margin;
            sa.StartFreq = leftBound / 10^6;
            sa.EndFreq = rightBound / 10^6;
            pauseTime = 3 + floor(sa.EndFreq - sa.StartFreq) * .1;
            
            f = Fs/2*[-1:2/NFFT:1-2/NFFT];
            % Take what is essentially a DFFT, making sure to give it the
            % exact sampling rate of the awg
%             [pxx,f] = periodogram(discreteWFM.Signal * ...
%                 awg.ChAmps(1) / 1000 , [], NFFT, Fs, 'power');
            pxx =(fftshift(fft(discreteWFM.Signal * obj.ChAmp / 1000 ...
                , NFFT))/ NFFT);
            pxx = 10*log10((abs(pxx).^2)/R * 1000);
            pxx = pxx;
            [pk, lc] = findpeaks(pxx, f, 'MinPeakHeight', -50);
            % Plot on a log scaleWW
            plot(f, pxx, lc, pk, 'x')
            text(obj.CenterFreq * 10^6 , pk(1) + 20,...
                sprintf('Peak: %d', floor(pk(1, 1))));
            
            axis([leftBound, rightBound, -100, 40])
            grid
            title('Theoretical Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
            pause(1)
            
            % Plot waveform
            axes(periodHandle)
            plot(t,  discreteWFM.Signal);
            grid
            title('Waveform Period')
            xlabel('Time (S)')
            ylabel('Amplitude')
            
            % Output created Waveform object
            awg.output(discreteWFM);
            
            % Get and plot power spectrum
            spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq, ...
                attenuation, pauseTime);
            axes(spectrumAxes2)
            [pk, lc] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakHeight', -50 + attenuation/3);
            plot(spec(2,:), spec(1,:), lc, pk, 'x')
            text(obj.CenterFreq * 10^6 , pk(1) + 20,...
                sprintf('Peak: %d', floor(pk(1, 1))));
            
            axis([leftBound, rightBound, -100, 40])
            grid
            title('Real Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
        end
        
        function stopTweezing(obj)
            % shorthands
            handles = obj.Handles;
            numTweezers = obj.NumTweezers;
            chAmp = obj.ChAmp;
            freqSep = obj.FreqSep;
            centerFreq = obj.CenterFreq;
            lambda = obj.Lambda;
            attenuation = obj.Attenuation;
            
            %attenuation 
            % Get plot axes handles
            periodHandle = handles(9);
            spectrumAxes1 = handles(10);
            spectrumAxes2 = handles(6);
            
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
            amps = double(ones(1,length(freqs)));
            phases = double(zeros(1,length(freqs)));
            controls = double(ones(1,length(freqs)));
            t = double((1:awg.NumMemSamples)/awg.SamplingRate);
            discreteWFM = Waveform(lambda, freqs, controls, amps,...
                phases, t);
            
            % Calculate theoretical power spectrum of waveform
            axes(spectrumAxes1)
            NFFT = length(discreteWFM.Signal);
            Fs = awg.SamplingRate;
            margin = 1.5 * 10^6;
            % Impedance of load
            R = 85; 
            leftBound = freqs(1,1) - margin;
            rightBound = freqs(1, length(freqs)) + margin;
            sa.StartFreq = leftBound / 10^6;
            sa.EndFreq = rightBound / 10^6;
            f = Fs/2*[-1:2/NFFT:1-2/NFFT];
            pauseTime = 3 + floor(sa.EndFreq - sa.StartFreq) * .1;
            % Take what is essentially a DFFT, making sure to give it the
            % exact sampling rate of the awg
%             [pxx,f] = periodogram(discreteWFM.Signal * ...
%                 awg.ChAmps(1) / 1000 , [], NFFT, Fs, 'power');
            pxx =(fftshift(fft(discreteWFM.Signal * obj.ChAmp / 1000 ...
                , NFFT))/ NFFT);
            pxx = 10*log10((abs(pxx).^2)/R * 1000);
            % Plot on a log scaleWW
            plot(f, pxx)
            axis([leftBound, rightBound, -100, 40])
            title('Theoretical Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
            pause(1)
            
            % Plot waveform
            axes(periodHandle)
            plot(t,  discreteWFM.Signal);
            title('Waveform Period')
            xlabel('Time (S)')
            ylabel('Amplitude')
            
            % Stop output of AWG
            awg.output(discreteWFM);
            
            % Get and plot power spectrum
            spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq,...
                attenuation, pauseTime);
            axes(spectrumAxes2)
            plot(spec(2,:), spec(1,:))
            axis([leftBound, rightBound, -100, 40])
            title('Real Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
        end
        
        function monitorPower(obj)
            if (~obj.MonitoringPower)
                obj.MonitoringPower = true;
                nidaq = obj.Application.getDevice(DeviceType.NIDAQ, 0);
                set1Plot = obj.Handles(8);
                set2Plot = obj.Handles(7);
                while(obj.MonitoringPower)
                    voltages = nidaq.sampleInputs();
                    obj.PreAmpPowerData = circshift(...
                        obj.PreAmpPowerData, -1, 2);
                    obj.PostAmpPowerData = circshift(...
                        obj.PostAmpPowerData, -1, 2);
                    obj.PreAmpPowerData(1, end) = voltages(1, 1);
                    obj.PostAmpPowerData(1, end) = voltages(1, 2);

                    pause(.1)
                    axes(set1Plot)
                    plot(obj.PreAmpPowerData(1,:))
                    title('Pre Amp Power')
                    axes(set2Plot)
                    plot(obj.PostAmpPowerData(1,:))
                    title('Post Amp Power')
                end
            else
                obj.MonitoringPower = false;
            end
            
        end
    end
    
    methods
        % Setter function for number of tweezers
        function set.NumTweezers(obj, num)
            if (isnumeric(num) && num >= 1)
                obj.NumTweezers = floor(num);
            else 
                fprintf('Error: expected integer >= 1. Received:\n');
                disp(num)
            end
        end

        % Setter function for channel amplitude of awg
        function set.ChAmp(obj, num)
            if (isnumeric(num) && num >= 80 && num <= 1400)
                obj.ChAmp = floor(num);
            else 
                fprintf(['Error: expected integer >= 80 and <= 1400.'...
                    'Received:\n']);
                disp(num)
            end
        end        
        
        % Setter function for frequency separation of awg
        function set.FreqSep(obj, num)
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            sep = awg.FreqRes;
            % Make sure we have the frequency separation as a multiple of
            % the frequency resolution of the awg, or else the waveform
            % period will NOT have a smooth/continuous period
            if (isnumeric(num) && num >= 0 && mod(num, sep) == 0)
                obj.FreqSep = num;
            else 
                fprintf(['Error: expected integer multiple of %d.'...
                    'Received:\n'], sep);
                disp(num)
            end
        end
        
        % Setter function for center frequency of awg
        function set.CenterFreq(obj, num)
            if (isnumeric(num) && num >= 50 && num <= 110)
                obj.CenterFreq = num;
            else 
                fprintf(['Error: expected integer >= 50 and <= 110'...
                    'Received:\n']);
                disp(num)
            end
        end
        
        % Setter function for center frequency of awg
        function set.Lambda(obj, num)
            if (isnumeric(num) && num >= 0 && num <= 1)
                obj.Lambda = num;
            else 
                fprintf(['Error: expected float >= 0 and <= 1'...
                    'Received:\n']);
                disp(num)
            end
        end
    end
end

