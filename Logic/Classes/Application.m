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
        
        % Variable holding all GUI managers
        Managers
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
        
        % Shutdown everything
        function shutdownEverything(obj)
            obj.shutdownDevices();
            obj.shutdownManagers();
        end
        
        % Creates a CharacterizeElectronicsManager object
        function openCharacterizeElectronicsManager(obj)
            newGUIManager = CharacterizeElectronicsManager(obj);
            obj.Managers = [obj.Managers, newGUIManager];
        end
        
        % Creates a UniformArrayManager object
        function openUniformArrayManager(obj)
            newGUIManager = UniformArrayManager(obj);
            obj.Managers = [obj.Managers, newGUIManager];
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
        
        function value = getManager(obj, type)
            value = [];
            for i = 1:length(obj.Managers)
                if (obj.Managers(1,i).Type == type)
                    value = obj.Managers(1,i);
                end
            end
        end
        
        function shutdownDevices(obj)
            for i = 1:length(obj.Devices)
                obj.Devices(i).shutdownDevice();
            end
        end
        
        function shutdownManagers(obj)
            for i = 1:length(obj.Managers)
                obj.Managers(i).shutdownManager();
            end
        end
        
        % Add devices to Application Devices array
        function discoverDevices(obj)
            serials = obj.BaslerCameraSerialNumbers;
 
            % Attempt to discover Spectrum AWG
            obj.addDevice(DeviceType.SpectrumAWG, '');
            
            % Attempt to discover Basler Camera 1 with the defined serial
            % numbers provided
            obj.addDevice(DeviceType.BaslerCamera, serials);
            
            obj.addDevice(DeviceType.RigolSA, '');
            obj.addDevice(DeviceType.NIDAQ, '');
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

