classdef Application < handle
    %APPLICATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Array holding objects representing the different devices used in
        % the program. All such devices will be represented by their own
        % separate class. In this manner, we can dynamically track devices
        % discovered during the application initialization process 
        Devices
        
        % Boolean variable representing the verbosity of the program. For
        % example, with each device that is initialized, when verbose=true
        % we would print the device information to the terminal.
        Verbose
        
        % Variable representing the serial numbers of Basler Ace Cameras
        % actively connected via USB to the host computer
        BaslerCameraSerialNumbers = ['21995112';'22179845'];
        
        % Variable holding handles to all figures and elements of UI layer
        Handles
        
    end
    
    methods
        function obj = Application(verbosity, handles)
            obj.Verbose = verbosity;
            obj.Handles = handles;
            % Initialize device array, which holds objects representing
            % devices available to the program
            obj.Devices = [];
            
            % Use helper function to query and gather devices that are
            % available to the program currently
            obj.discoverDevices();
        end
        
        function plotChannelAmplitude(obj, handles)
            set1Plot = handles.PreAmpPowerAxes;
            set2Plot = handles.PostAmpPowerAxes;
            sa = obj.getDevice(DeviceType.RigolSA, 0);
            awg = obj.getDevice(DeviceType.SpectrumAWG, 0);
            spacing = double(500 * 10^3);
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
                spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq);
                [pks, locs] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakDistance', span / 10,...
                'MinPeakHeight', -40);
                data1(1,i) = 10^(pks(1)/10);
                data1(2,i) = set1(1, i);
                data1(2,i)
            end
            axes(set1Plot)
            plot(data1(2,:), data1(1,:))
            
            for i = 1:length(set2)
                awg.changeAmplitude(set2(1, i));
                pause(.5)
                spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq);
                [pks, locs] = findpeaks(spec(1,:), spec(2,:),...
                'MinPeakDistance', span / 10,...
                'MinPeakHeight', -40);
                data2(1,i) = 10^(pks(1)/10);
                data2(2,i) = set2(1, i);
                data2(2,i)
            end
            axes(set2Plot)
            plot(data2(2,:), data2(1,:))
            
            
        end
        function outputNumTweezers(obj, handles, numTweezers,...
                chAmp, freqSep, centerFreq, lambda)
            % Get plot axes handles
            periodHandle = handles.PeriodAxes;
            spectrumAxes1 = handles.PowerSpectrumAxes1;
            spectrumAxes2 = handles.PowerSpectrumAxes2;
            
            % Setup awg
            awg = obj.getDevice(DeviceType.SpectrumAWG, 0);
            awg.changeAmplitude(chAmp);
            
            % Convert to Hz
            centerFreq = centerFreq * 10^6;
            
            % Setup spectrum analyzer
            sa = obj.getDevice(DeviceType.RigolSA, 0);
            
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
            leftBound = freqs(1,1) - margin;
            rightBound = freqs(1, length(freqs)) + margin;
            sa.StartFreq = leftBound / 10^6;
            sa.EndFreq = rightBound / 10^6;
            
            % Take what is essentially a DFFT, making sure to give it the
            % exact sampling rate of the awg
            [pxx,f] = periodogram(discreteWFM.Signal * ...
                awg.ChAmps(1) / 1000 , [], NFFT, Fs, 'power');
            
            % Plot on a log scale
            plot(f, 10*log10(pxx))
            axis([leftBound, rightBound, -100, 10])
            title('Theoretical Power Spectrum')
            pause(1)
            
            % Plot waveform
            axes(periodHandle)
            plot(t,  discreteWFM.Signal);
            title('Waveform Period')
            
            % Output created Waveform object
            awg.output(discreteWFM);
            pause(5)
            
            % Get and plot power spectrum
            spec = sa.getPowerSpectrum(sa.StartFreq, sa.EndFreq);
            axes(spectrumAxes2)
            plot(spec(2,:), spec(1,:))
            axis([leftBound, rightBound, -100, 10])
            title('Real Power Spectrum')
        end
        
        % Begins a loop that essentially takes pictures and displays them
        % to the PictureAxis handle of the GUI object. This loop stops when
        % stopLiveView() is called by the Application object--in this
        % manner, we can concurrently begin and end the live view 
        function beginLiveView(obj)
            if (obj.LiveViewOn == false)
                obj.LiveViewOn = true;
                if (isa(obj.getDevice(DeviceType.BaslerCamera, 0), 'Device'))
                     while obj.LiveViewOn == true
                         % Capture image, save success and timestamp
                         [success, image, timestamp] = obj.getDevice(...
                         DeviceType.BaslerCamera, 0).capture();
                         imshow(image, 'Parent', obj.Handles.PictureAxis)
                         
                         % Pause approximately 1 period of 14 FPS so that
                         % we don't overload the camera
                         pause(0.07)
                         % Set timestamp on GUI if handle is available
                         if (isvalid(obj.Handles.TimestampText))
                             set(obj.Handles.TimestampText,'String',...
                             sprintf('Timestamp: %f', timestamp)); 
                         end
                         
                         % Set timestamp on GUI if handle is available
                         if (isvalid(obj.Handles.BrightestPixelText))
                             set(obj.Handles.BrightestPixelText,'String',...
                             sprintf('Brightest Pixel: %d', max(max(image)))); 
                         end
                         
                         %obj.plotTweezerLocation(image);
                     end
                 end
            end
        end
        
        function plotTweezerLocation(obj, image)
            width = obj.getDevice(DeviceType.BaslerCamera, 0).Width;
            height = obj.getDevice(DeviceType.BaslerCamera, 0).Height;
            offsetx = obj.getDevice(DeviceType.BaslerCamera, 0).OffsetX;
            offsety = obj.getDevice(DeviceType.BaslerCamera, 0).OffsetY;
            %Binarize
            I = imbinarize(image, 0.1);
            
            %remove noise
            minNumPixels=40;
            I = imclose(I,strel('disk',8)); %close gaps
            I = bwareaopen(I,minNumPixels); %suppress objects with <minNumPixels
            I = imclose(I,strel('disk',30)); %close gaps
            I = imfill(I,'holes'); %fill holes
            
            %find boundaries
            [B,L]=bwboundaries(I,'noholes');
            
            %find centroid
            L = bwlabel(I);
            stat = regionprops(L,'centroid','area');
            if (size(stat,1) ~= 0)
                x = [];
                y = [];
                for (i = 1:size(stat,1))
                    x = [x, round(stat(1).Centroid(1))];
                    y = [y, round(stat(1).Centroid(2))];
                end
                plot(x, y,'*', 'Parent', obj.Handles.PlotAxis)
            end
            
        end
        
        % Stops the LiveView acquisition loop
        function stopLiveView(obj)
            obj.LiveViewOn = false;
        end
        % -----------------HELPER FUNCTIONS--------------------------------
        % Define Image ROI for a BaslerCamera object of a specific index
        function defineImageROI(obj, index)
            axes(obj.Handles.PictureAxis);
            rect = getrect;
            rect = uint32(rect);
            cam = obj.getDevice(DeviceType.BaslerCamera, index);
            if(isa(cam, 'Device'))
                cam.Width = rect(3);
                cam.Height = rect(4);
                cam.OffsetX = rect(1);
                cam.OffsetY = rect(2);
            end
        end
        
        % Reset Image ROI for a BaslerCamera object of a specific index
        function resetImageROI(obj, index)
            cam = obj.getDevice(DeviceType.BaslerCamera, index);
            if(isa(cam, 'Device'))
                cam.resetSensor();
            end
        end
        
        function value = getDevice(obj, type, index)
            value = [];
            for i = 1:length(obj.Devices)
                if (obj.Devices(1,i).Type == type &&...
                        obj.Devices(1,i).Index == index)
                    value = obj.Devices(1,i);
                end
            end
        end
        
        function shutdownDevices(obj)
            for i = 1:length(obj.Devices)
                obj.Devices(i).shutdownDevice();
            end
        end
        
        % Add devices to Application Devices array
        function discoverDevices(obj)
            serials = obj.BaslerCameraSerialNumbers;
 
            % Attempt to discover Spectrum AWG
            obj.addDevice(DeviceType.SpectrumAWG, '');
            
            % Attempt to discover Basler Camera 1 with the defined serial
            % numbers provided
            %obj.addDevice(DeviceType.BaslerCamera, serials);
            
            obj.addDevice(DeviceType.RigolSA, '');
        end
        
        % Helper function for finding the number of devices of a given type
        % in the Devices array of the application object
        function numDevices = findNumDevices(obj, type)
            numDevices = 0;
            for i = 1:numel(obj.Devices)
                if (obj.Devices(i).Type == type)
                    numDevices = numDevices + 1;
                end
            end
        end
        
        % Helper function for adding a device to the active devices of the
        % application. Includes code for displaying the device information
        % to the DeviceTable uitable of the UI layer.
        function addDevice(obj, type, serialNumbers)
            newDevice = 0;
            % We force that the index of each new device be calculated from
            % the number of already existing devices of that type. This
            % way, all the indices for a given type of device are
            % sequential. Start indexing at 0 due to Windows conventions
            index = obj.findNumDevices(type);    
            
            % Switch through Device types, making sure to pass verbosity
            % and index
            switch type
                case DeviceType.SpectrumAWG
                    newDevice = SpectrumAWG(index, obj.Verbose);
                case DeviceType.BaslerCamera
                    newDevice = BaslerCamera(...
                        index, obj.Verbose, serialNumbers);
                case DeviceType.AndorCamera
                    newDevice = AndorCamera(index, obj.Verbose);
                case DeviceType.NIDAQ
                    newDevice = NIDAQ(index, obj.Verbose);
                case DeviceType.NewfocusPicomotor
                    newDevice = NewfocusPicomotor(index, obj.Verbose);
                case DeviceType.RigolSA
                    newDevice = RigolSA(index, obj.Verbose);
                otherwise
                    fprintf(['Error: Device Type not recognized. '...
                             'No device added.\nReceived:'])
                    disp(type)
                    return;
            end
            
            % Add new device to active devices array of application object
            % if it was  initialized properly.
            if (newDevice.Initialized)
                obj.Devices = [obj.Devices, newDevice];
                
                % Add device to DeviceTable if it was successfully
                % initialized, first making sure to format the DeviceTable
                % entry appropriately 
                newRow = cell(1,4);
                
                newRow{1,1} = char(newDevice.Type);
                newRow{1,2} = int2str(newDevice.Index);
                newRow{1,3} = int2str(newDevice.Initialized);
                newRow{1,4} = int2str(newDevice.Verbose);
                oldData = get(obj.Handles.DeviceTable, 'Data');
                newData = [oldData; newRow];
                set(obj.Handles.DeviceTable, 'Data', newData);
                
                if obj.Verbose == true
                    disp('New Device:')
                    newDevice.displayDeviceInfo();
                end
            end
        end
        
        % Setter method for Verbose variable of application object
        function set.Verbose(obj, verbosity)
            % If verbose == true, then various commandline outputs will be
            % used throughout the appplication layer for debugging puposes
            if (islogical(verbosity))
                obj.Verbose = verbosity;
            else 
                fprintf(['Error: expected boolean variable.'...
                    ' Application layer not created.\nReceived:\n'])
                disp(verbosity)
                return;
            end
        end
    end
end

