classdef UniformArrayManager < GUIManager
    %UNIFORMARRAYMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type = GUIType.UniformArray;
        
        NumTweezers
        
        NumActiveTweezers
        
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
        
        LastTimestamp
    end
    
    
    methods
        function obj = UniformArrayManager(application)
            obj = obj@GUIManager(application);
            obj.GUI = UniformArrayGUI;
            obj.Handles = obj.GUI.Children;
            obj.PreAmpPowerData = zeros(1, 500);
            obj.PostAmpPowerData = zeros(1, 500);
            obj.MonitoringPower = false;
            obj.LastTimestamp = 0;
%             dir = uigetdir;
%             GUIManager.FilePath = dir;
%             set(obj.Handles(1), 'String', ['File Path: ', dir]);
        end
        
        function discreteWFM = tweeze(obj)
            % shorthands
            handles = obj.Handles;
            numTweezers = obj.NumTweezers;
            numActiveTweezers = obj.NumActiveTweezers;
            chAmp = obj.ChAmp;
            % Convert frequency separation to Hz
            freqSep = obj.FreqSep * 10^3;
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
            controls = double(zeros(1, length(freqs)));
            controls(1, 1:numActiveTweezers) = 1.0;
            controls = circshift(controls,...
                floor((numTweezers - numActiveTweezers)/2));
            t = double((1:awg.NumMemSamples)/awg.SamplingRate);
            discreteWFM = Waveform(lambda, freqs, controls, amps,...
                phases, t);
            
            % Output created Waveform object
            awg.output(discreteWFM);
        end
        
        function startTweezing(obj)
            discreteWFM = obj.tweeze();

            % get awg
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            % get spectrum analyzer
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            % get camera
            cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
            
            handles = obj.Handles;
            periodHandle = handles(13);
            spectrumAxes1 = handles(14);
            spectrumAxes2 = handles(12);
            
            % Take sample image from basler to show tweezers
            if (ishandle(obj.ImageFigure))
                figure(obj.ImageFigure);
%                 axes(obj.PictureAxes1)
%                 [success, image, timestamp] = cam.capture();
%                 imshow(image)
%                 title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
                
                axes(obj.PictureAxes2)
                [success, image, timestamp] = cam.capture();
                obj.LastTimestamp = timestamp;
                imshow(image)
                title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
            else 
            	obj.ImageFigure = figure('Name', 'Images');
%                 obj.PictureAxes1 = axes('Position', [0,.55, 1, .4])
%                 [success, image, timestamp] = cam.capture();
%                 imshow(image)
%                 title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
                
                obj.PictureAxes2 = axes('Position', [0,.05, 1, .9]);
                [success, image, timestamp] = cam.capture();
                obj.LastTimestamp = timestamp;
                imshow(image)
                title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
            end
            
            % Calculate theoretical power spectrum of waveform
            axes(spectrumAxes1)
            NFFT = length(discreteWFM.Signal);
            Fs = awg.SamplingRate;
            margin = 1.5 * 10^6;
            % Impedance of load, should be 50 ohms but 90 seems to fit the
            % theoretical power spectrum to the real power spectrum better
            R = 85; 
            leftBound = discreteWFM.Freqs(1,1) - margin;
            rightBound = discreteWFM.Freqs(1, end) + margin;
            sa.StartFreq = leftBound / 10^6;
            sa.EndFreq = rightBound / 10^6;
            pauseTime = 3 + floor(sa.EndFreq - sa.StartFreq) * .1;
            
            f = Fs/2*[-1:2/NFFT:1-2/NFFT];
            % Take what is essentially a DFFT, making sure to give it the
            % exact sampling rate of the awg
            pxx =(fftshift(fft(discreteWFM.Signal * obj.ChAmp / 1000 ...
                , NFFT))/ NFFT);
            pxx = 10*log10((abs(pxx).^2)/R * 1000);
            [pk, lc] = findpeaks(pxx, f, 'MinPeakHeight', -50);
            % Plot on a log scaleWW
            plot(f, pxx, lc, pk, 'x')
            if (~isempty(pk))
                text(obj.CenterFreq * 10^6 , pk(1) + 20,...
                    sprintf('Peak: %d', floor(pk(1, 1))));
            else
                text(obj.CenterFreq * 10^6 , 20, sprintf('No Peaks'));
            end
            
            axis([leftBound, rightBound, -100, 40])
            grid
            title('Theoretical Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
            pause(1)
            
            % Plot waveform
            axes(periodHandle)
            plot(discreteWFM.TimeSteps,  discreteWFM.Signal);
            grid
            title('Waveform Period')
            xlabel('Time (S)')
            ylabel('Amplitude')
            
            
            % Get and plot power spectrum
            spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq, ...
                obj.Attenuation, pauseTime);
            axes(spectrumAxes2)
            [pk, lc] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakHeight', -50 + obj.Attenuation/3);
            plot(spec(2,:), spec(1,:), lc, pk, 'x')
            if (~isempty(pk))
                text(obj.CenterFreq * 10^6 , pk(1) + 20,...
                    sprintf('Peak: %d', floor(pk(1, 1))));
            else
                text(obj.CenterFreq * 10^6 , 20, sprintf('No Peaks'));
            end
            axis([leftBound, rightBound, -100, 40])
            grid
            title('Real Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
        end
        
        function stopTweezing(obj)
            temp = obj.NumActiveTweezers;
            obj.NumActiveTweezers = 0;
            
            discreteWFM = obj.tweeze();
            handles = obj.Handles;
            periodHandle = handles(13);
            spectrumAxes1 = handles(14);
            spectrumAxes2 = handles(12);
            
            % get awg
            awg = obj.Application.getDevice(DeviceType.SpectrumAWG, 0);
            % get spectrum analyzer
            sa = obj.Application.getDevice(DeviceType.RigolSA, 0);
            % get camera
            cam = obj.Application.getDevice(DeviceType.BaslerCamera, 0);
            
            
            % Take sample image from basler to show tweezers
            if (ishandle(obj.ImageFigure))
                figure(obj.ImageFigure);
                
                axes(obj.PictureAxes2)
                [success, image, timestamp] = cam.capture();
                imshow(image)
                title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
            else 
            	obj.ImageFigure = figure('Name', 'Images');
                
                obj.PictureAxes2 = axes('Position', [0,.05, 1, .9]);
                [success, image, timestamp] = cam.capture();
                imshow(image)
                title(sprintf('Tweezer Image (Basler #%d)', cam.Index))
            end
            
            
            
            % Calculate theoretical power spectrum of waveform
            axes(spectrumAxes1)
            NFFT = length(discreteWFM.Signal);
            Fs = awg.SamplingRate;
            margin = 1.5 * 10^6;
            % Impedance of load, should be 50 ohms but 90 seems to fit the
            % theoretical power spectrum to the real power spectrum better
            R = 85; 
            leftBound = discreteWFM.Freqs(1,1) - margin;
            rightBound = discreteWFM.Freqs(1, end) + margin;
            sa.StartFreq = leftBound / 10^6;
            sa.EndFreq = rightBound / 10^6;
            pauseTime = 3 + floor(sa.EndFreq - sa.StartFreq) * .1;
            
            f = Fs/2*[-1:2/NFFT:1-2/NFFT];
            % Take what is essentially a DFFT, making sure to give it the
            % exact sampling rate of the awg
            pxx =(fftshift(fft(discreteWFM.Signal * obj.ChAmp / 1000 ...
                , NFFT))/ NFFT);
            pxx = 10*log10((abs(pxx).^2)/R * 1000);
            [pk, lc] = findpeaks(pxx, f, 'MinPeakHeight', -50);
            % Plot on a log scaleWW
            plot(f, pxx, lc, pk, 'x')
            if (~isempty(pk))
                text(obj.CenterFreq * 10^6 , pk(1) + 20,...
                    sprintf('Peak: %d', floor(pk(1, 1))));
            else
                text(obj.CenterFreq * 10^6 , 20, sprintf('No Peaks'));
            end
            
            axis([leftBound, rightBound, -100, 40])
            grid
            title('Theoretical Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
            pause(1)
            
            % Plot waveform
            axes(periodHandle)
            plot(discreteWFM.TimeSteps,  discreteWFM.Signal);
            grid
            title('Waveform Period')
            xlabel('Time (S)')
            ylabel('Amplitude')
            
            
            % Get and plot power spectrum
            spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq, ...
                obj.Attenuation, pauseTime);
            axes(spectrumAxes2)
            [pk, lc] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakHeight', -50 + obj.Attenuation/3);
            plot(spec(2,:), spec(1,:), lc, pk, 'x')
            if (~isempty(pk))
                text(obj.CenterFreq * 10^6 , pk(1) + 20,...
                    sprintf('Peak: %d', floor(pk(1, 1))));
            else
                text(obj.CenterFreq * 10^6 , 20, sprintf('No Peaks'));
            end
            
            axis([leftBound, rightBound, -100, 40])
            grid
            title('Real Power Spectrum')
            xlabel('Frequency (Hz)')
            ylabel('Power (dBm)')
            obj.NumActiveTweezers = temp;
        end
        
        function monitor(obj)
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
                        plot(obj.PreAmpPowerData(1,:), 'Parent', set1Plot)
                        title('Pre Amp Power', 'Parent', set1Plot)
                        plot(obj.PostAmpPowerData(1,:), 'Parent', set2Plot)
                        title('Post Amp Power', 'Parent', set2Plot)
                        
                        if (ishandle(pictureAxes))
                            % Take sample image from basler to show tweezers
                            [success, image, timestamp] = cam.capture();
                            if (success)
                                framerate = 1/(timestamp - obj.LastTimestamp);
                                imshow(image, 'Parent', pictureAxes)
                                title(sprintf(['Tweezer Image (Basler #%d, '...
                                    'FPS: %0.1f)'], cam.Index, framerate),...
                                    'Parent', pictureAxes)
                                obj.LastTimestamp = timestamp;
                            end
                        end
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
        
        % Setter function for number of tweezers
        function set.NumActiveTweezers(obj, num)
            if (isnumeric(num) && num >= 0 && num <= obj.NumTweezers)
                obj.NumActiveTweezers = floor(num);
            else 
                fprintf(['Error: expected integer >= 0 and <= %d.'...
                    'Received:\n'], obj.NumTweezers);
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
            if (isnumeric(num) && num >= 0 && mod(num * 10^3, sep) == 0)
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

