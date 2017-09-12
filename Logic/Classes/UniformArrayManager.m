classdef UniformArrayManager < GUIManager
    %UNIFORMARRAYMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type = GUIType.UniformArray;
        
        NumTweezers
        
        ChAmp
        
        FreqSep
        
        CenterFreq
        
        Lambda
        
        PreAmpPowerData
        
        PostAmpPowerData
        
        Attenuation
        
        FilePath
        
        MonitoringPower
        
        ImageFigure
        
        PictureAxes1
        
        PictureAxes2
    end
    
    
    methods
        function obj = UniformArrayManager(application)
            obj = obj@GUIManager(application);
            obj.GUI = UniformArrayGUI;
            obj.Handles = obj.GUI.Children;
            obj.PreAmpPowerData = zeros(1, 500);
            obj.PostAmpPowerData = zeros(1, 500);
            obj.MonitoringPower = false;
%             dir = uigetdir;
%             GUIManager.FilePath = dir;
%             set(obj.Handles(1), 'String', ['File Path: ', dir]);
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
            periodHandle = handles(13);
            spectrumAxes1 = handles(14);
            spectrumAxes2 = handles(12);
            
            % Setup awg
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            awg.changeAmplitude(chAmp);
            
            % Convert to Hz
            centerFreq = centerFreq * 10^6;
            
            % Setup spectrum analyzer
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            
            % Setup camera
            cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
            
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
            
            % Take sample image from basler to show tweezers
            if (ishandle(obj.ImageFigure))
                figure(obj.ImageFigure)
%                 axes(obj.PictureAxes1)
%                 [success, image, timestamp] = cam.capture();
%                 imshow(image)
%                 title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
                
                axes(obj.PictureAxes2)
                [success, image, timestamp] = cam.capture();
                imshow(image)
                title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
            else 
            	obj.ImageFigure = figure('Name', 'Images');
%                 obj.PictureAxes1 = axes('Position', [0,.55, 1, .4])
%                 [success, image, timestamp] = cam.capture();
%                 imshow(image)
%                 title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
                
                obj.PictureAxes2 = axes('Position', [0,.05, 1, .9])
                [success, image, timestamp] = cam.capture();
                imshow(image)
                title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
            end
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
            periodHandle = handles(13);
            spectrumAxes1 = handles(14);
            spectrumAxes2 = handles(12);
            pictureAxes = handles(9);
            
            % Setup awg
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            awg.changeAmplitude(chAmp);
            
            % Convert to Hz
            centerFreq = centerFreq * 10^6;
            
            % Setup spectrum analyzer
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            
            % Setup basler
            cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
            
            % Condition on number of tweezers
            if (numTweezers == 1)
                freqs = [centerFreq];
            else
                numTweezers = double(numTweezers);
                freqs = centerFreq + freqSep * ...
                double(linspace(-(numTweezers-1)/2, ...
                (numTweezers-1)/2,numTweezers));
            end
            
            % Create waveform object with 0 amplitude so we are sure that
            % nothing is output from the awg
            amps = double(zeros(1,length(freqs)));
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
            pauseTime = 3 + floor(sa.EndFreq - sa.StartFreq) * .1;
            f = Fs/2*[-1:2/NFFT:1-2/NFFT];
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
            
            % Take sample image from basler to show tweezers
            axes(pictureAxes)
            [success, image, timestamp] = cam.capture();
            imshow(image)
            title('Tweezer Image')
        end
        
        function monitorPower(obj)
            if (~obj.MonitoringPower)
                obj.MonitoringPower = true;
                nidaq = obj.Application.getDevice(DeviceType.NIDAQ, 0);
                set1Plot = obj.Handles(11);
                set2Plot = obj.Handles(10);
                pictureAxes = obj.PictureAxes2;
                cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
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
                        
                        % Take sample image from basler to show tweezers
                        [success, image, timestamp] = cam.capture();
                        imshow(image, 'Parent', pictureAxes)
                        title(sprintf('Tweezer Image (Basler #%d)',...
                            cam.Index), 'Parent', pictureAxes)
                end
            else
                obj.MonitoringPower = false;
                return;
            end
        end
        
        function defineROI(obj)
            pictureAxes = obj.PictureAxes2;
            axes(pictureAxes)
            rect = getrect;
            rect = uint32(rect);
            cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
            if(isa(cam, 'Device'))
                cam.Width = rect(3);
                cam.Height = rect(4);
                cam.OffsetX = rect(1);
                cam.OffsetY = rect(2);
            end
            
            % Take sample image from basler to show tweezers
            [success, image, timestamp] = cam.capture();
            imshow(image)
            title('Tweezer Image')
        end
        
        function resetROI(obj)
            pictureAxes = obj.PictureAxes2;
            axes(pictureAxes)
            cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
            if(isa(cam, 'Device'))
                cam.resetSensor();
            end
            
            % Take sample image from basler to show tweezers
            [success, image, timestamp] = cam.capture();
            imshow(image)
            title('Tweezer Image')
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
            if (isnumeric(num) && num > 0 && num <= 1)
                obj.Lambda = double(num);
            else 
                fprintf(['Error: expected float >= 0 and <= 1'...
                    'Received:\n']);
                disp(num)
            end
        end
    end
    
end

