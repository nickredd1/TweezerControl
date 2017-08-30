classdef BaslerCamera < Device
    %BASLERCAMERA Summary of this class goes here
    %   Class representing BaslerCamera object. Any sort of communcation
    %   between the physical Basler Camera installed in the user's
    %   computer environment and the TweezerControl application is done
    %   through the BaslerCamera device object.
    
    properties
        % Set device type using DeviceType enumeration class
        Type = DeviceType.BaslerCamera;
        
        % Handle to Camera object (from MATLAB driver)
        CameraHandle
        
        % .NET assembly created from Basler Camera driver files
        NETAssembly
        
    end
    
    properties (Dependent)
        % Various dependent image cropping parameters that, when accesses,
        % always query the Basler Ace Camera model (acA3800-14um) driver 
        % methods. All are in units of pixels
        MaxHeight
       
        MinHeight
        
        MaxWidth
        
        MinWidth
        
        MaxOffsetX
        
        MinOffsetX
        
        MaxOffsetY
        
        MinOffsetY
        
        Height
        
        Width
        
        OffsetX
        
        OffsetY
        % -------------------END IMAGE CROPPING PARAMETERS-----------------
        % Various dependent parameters representing different sensor
        % parameters for the Basler Ace Camera model (acA3800-14um)
        
        % Maximum exposure time for each image in microseconds
        MaxExposureTime
        
        % Minimum exposure time for each image in microseconds
        MinExposureTime
        
        % Exposure time for each image in microseconds
        ExposureTime
        
        % Maximum gain for each image in dB
        MaxGain
        
        % Minimum gain for each image in dB
        MinGain
        
        % Gain for each image in dB
        Gain
        
        % Pixel format
        PixelFormat
    end
    
    methods
        % Constructor for BaslerCamera object; attempts to discover and
        %   initialize the first Basler Camera that is discovered by the
        %   program
        %
        % index: index of device of type BaslerCamera; all indices for
        %   devices of a specific type should be unique; start the indexing
        %   at 0 for all devices

        function obj = BaslerCamera(index, verbosity)
            % Call Superclass constructor firt to avoid redundancies
            obj = obj@Device(index, verbosity);
            
            % Get driver dll for Basler Camera and create an assembly out
            % of it
            dllName=['C:\Users\Endres Lab\Desktop\TweezerControl\'...
                'Dependencies\Devices\Basler Ace camera'...
                '\Drivers\Basler.Pylon.dll'];
            obj.NETAssembly = NET.addAssembly(dllName);
            
            % Use try loop to avoid crashing program if no Basler is found
            % during initialization process
            try 
                
                % Create the CameraHandle
                obj.CameraHandle = Basler.Pylon.Camera('21995112');
                %obj.CameraHandle = Basler.Pylon.Camera('22179845');
                
                
                % Open the camera
                obj.CameraHandle.Open();

                % Set Pixel format to 8bit mono (FOR 12BIT MONO: use 
                % 'Mono12'
                obj.PixelFormat = 'Mono8';
                
                % Set ShutterMode to Rolling
                obj.CameraHandle.Parameters.Item(...
                    'ShutterMode').SetValue('Rolling');
                
                % Set ExposureMode to timed so we can define our own
                % exposure times
                obj.CameraHandle.Parameters.Item(...
                    'ExposureMode').SetValue('Timed');
                
                % Set GainAuto to off so that we may set gain manually
                obj.CameraHandle.Parameters.Item(...
                    'GainAuto').SetValue('Off');
                
                % Reset sensor parameters
                obj.resetSensor();
                
                % At this point, the camera has been succesfully
                % initialized so we may set initialized to true
                obj.Initialized = true;
                
            catch ME
                fprintf('BaslerCamera construction failed. \n');
                obj.Initialized = false;
                if (obj.CameraHandle.IsOpen)
                    obj.shutdownDevice();
                end
            end
             
        end
        
        % Reset sensor parameters to defaults
        function resetSensor(obj)
            obj.Height = obj.MaxHeight - 1;
            obj.Width = obj.MaxWidth - 1;
            obj.Gain = 10;
            obj.ExposureTime = 10000; % 1 ms
        end
        
        % Get image from BaslerCamera object
        function [success, image] = capture(obj)
            if (obj.CameraHandle.IsOpen)
                timeout=int32(500); % 500
                
                % Initialize acquisition
                obj.CameraHandle.StreamGrabber.Start();
                grabResult=obj.CameraHandle.StreamGrabber.RetrieveResult(...
                    timeout, Basler.Pylon.TimeoutHandling.ThrowException);
                obj.CameraHandle.StreamGrabber.Stop();

                % Convert pixel buffer data to uint16 image
                image=vec2mat(uint8(grabResult.PixelData),3840);
                
                % Return success
                success = true;
            else
                success = false;
                image = [];
                fprintf('Warning: camera not open, no image acquired\n');
            end
        end
        
        % Display device info (inherited from Device class)
        function displayDeviceInfo(obj)
            % Extend inherited displayDeviceInfo() function
            displayDeviceInfo@Device(obj);
        end
        
        % Shutdown device (inherited from Device class)
        function shutdownDevice(obj)
            % Release resources
            obj.CameraHandle.Dispose();
            % Delete BaslerCamera so that we can open it up again
            obj.CameraHandle.Close();
            
            if (obj.Verbose)
                disp('BaslerCamera stopped')
            end
        end
    end
    
    % Separate helper functions from more high-level functions
    methods
        
        % ---------------------SETTER FUNCTIONS----------------------------
        % Setter method for setting obj.Height. Includes error checking
        % based on the actual Basler Ace Camera model (acA3800-14um). NOTE:
        % MAKE SURE THAT YOU PASS A SIGNED 64-BIT INTEGER TO SetValue() OR
        % ELSE IT WILL THROW AN ERROR
        function set.Height(obj, height)
            min = obj.MinHeight;
            max = obj.MaxHeight;
            if (isnumeric(height) && ((height > min) && (height < max)))
                obj.CameraHandle.Parameters.Item('Height').SetValue(...
                    int64(height));
            else 
                fprintf(['Error: expected an integer Height < '...
                    '%d and > %d. Received:\n'], max, min);
                disp(height)
            end
        end
        
        % Setter method for setting obj.Width. Includes error checking
        % based on the actual Basler Ace Camera model (acA3800-14um)
        function set.Width(obj, width)
            min = obj.MinWidth;
            max = obj.MaxWidth;
            if (isnumeric(width) && ((width > min) && (width < max)))
                obj.CameraHandle.Parameters.Item('Width').SetValue(...
                    int64(width));
            else 
                fprintf(['Error: expected an integer Width < '...
                    '%d and > %d. Received:\n'], max, min);
                disp(width)
            end
        end
        
        % Setter method for setting obj.OffsetX. Includes error checking
        % based on the actual Basler Ace Camera model (acA3800-14um)
        function set.OffsetX(obj, offsetx)
            min = obj.MinOffsetX;
            max = obj.MaxOffsetX;
            if (isnumeric(offsetx) && ((offsetx > min) && (offsetx < max)))
                obj.CameraHandle.Parameters.Item('OffsetX').SetValue(...
                    int64(offsetx));
            else 
                fprintf(['Error: expected an integer OffsetX < '...
                    '%d and > %d. Received:\n'], max, min);
                disp(offsetx)
            end
        end
        
        % Setter method for setting obj.OffsetY. Includes error checking
        % based on the actual Basler Ace Camera model (acA3800-14um)
        function set.OffsetY(obj, offsety)
            min = obj.MinOffsetY;
            max = obj.MaxOffsetY;
            if (isnumeric(offsety) && ((offsety > min) && (offsety < max)))
                obj.CameraHandle.Parameters.Item('OffsetY').SetValue(...
                    int64(offsety));
            else 
                fprintf(['Error: expected an integer OffsetY < '...
                    '%d and > %d. Received:\n'], max, min);
                disp(offsety)
            end
        end
        
        % Setter method for setting obj.ExposureTime. Includes error 
        % checking based on the actual Basler Ace Camera model 
        % (acA3800-14um)
        function set.ExposureTime(obj, exptime)
            min = obj.MinExposureTime;
            max = obj.MaxExposureTime;
            if (isnumeric(exptime) && ((exptime > min) && (exptime < max)))
                obj.CameraHandle.Parameters.Item(...
                    'ExposureTime').SetValue(int64(exptime));
            else 
                fprintf(['Error: expected an integer ExposureTime < '...
                    '%d and > %d. Received:\n'], max, min);
                disp(exptime)
            end
        end
        
        % Setter method for setting obj.Gain. Includes error 
        % checking based on the actual Basler Ace Camera model 
        % (acA3800-14um)
        function set.Gain(obj, gain)
            min = obj.MinGain;
            max = obj.MaxGain;
            if (isnumeric(gain) && ((gain > min) && (gain < max)))
                obj.CameraHandle.Parameters.Item(...
                    'Gain').SetValue(double(gain));
            else 
                fprintf(['Error: expected an integer Gain < '...
                    '%d and > %d. Received:\n'], max, min);
                disp(gain)
            end
        end
        
        % Setter method for setting obj.PixelFormat. Includes error 
        % checking based on the actual Basler Ace Camera model 
        % (acA3800-14um)
        function set.PixelFormat(obj, format)
            switch format
                case 'Mono8'
                    obj.CameraHandle.Parameters.Item(...
                    'PixelFormat').SetValue(format);
                case 'Mono12'
                    obj.CameraHandle.Parameters.Item(...
                    'PixelFormat').SetValue(format);
                case 'Mono12p'
                    obj.CameraHandle.Parameters.Item(...
                    'PixelFormat').SetValue(format);
                otherwise
                    fprintf(['Error: PixelFormat not recognized.'
                        'Received:\n']);
                    disp(format)
            end
        end
        % --------------------END SETTER FUNCTIONS-------------------------
        % ---------------------GETTER FUNCTIONS----------------------------
        % Getter function abstractions for directly querying the camera for
        % its relevant parameters. Uses methods provided by driver.
        function val = get.MaxHeight(obj)
            val = obj.CameraHandle.Parameters.Item('Height').GetMaximum();
        end
        
        function val = get.MinHeight(obj)
            val = obj.CameraHandle.Parameters.Item('Height').GetMinimum();
        end
        
        function val = get.MaxWidth(obj)
            val = obj.CameraHandle.Parameters.Item('Width').GetMaximum();
        end
        
        function val = get.MinWidth(obj)
            val = obj.CameraHandle.Parameters.Item('Width').GetMinimum();
        end
        
        function val = get.MaxOffsetX(obj)
            val = obj.CameraHandle.Parameters.Item('OffsetX').GetMaximum();
        end
        
        function val = get.MinOffsetX(obj)
            val = obj.CameraHandle.Parameters.Item('OffsetX').GetMinimum();
        end
        
        function val = get.MaxOffsetY(obj)
            val = obj.CameraHandle.Parameters.Item('OffsetY').GetMaximum();
        end
        
        function val = get.MinOffsetY(obj)
            val = obj.CameraHandle.Parameters.Item('OffsetY').GetMinimum();
        end
        
        function val = get.Height(obj)
            val = obj.CameraHandle.Parameters.Item('Height').GetValue();
        end
        
        function val = get.Width(obj)
            val = obj.CameraHandle.Parameters.Item('Width').GetValue();
        end
        
        function val = get.OffsetX(obj)
            val = obj.CameraHandle.Parameters.Item('OffsetX').GetValue();
        end
        
        function val = get.OffsetY(obj)
            val = obj.CameraHandle.Parameters.Item('OffsetY').GetValue();
        end
        
        function val = get.MaxExposureTime(obj)
            val = obj.CameraHandle.Parameters.Item(...
                'ExposureTime').GetMaximum();
        end
        
        function val = get.MinExposureTime(obj)
            val = obj.CameraHandle.Parameters.Item(...
                'ExposureTime').GetMinimum();
        end
        
        function val = get.ExposureTime(obj)
            val = obj.CameraHandle.Parameters.Item(...
                'ExposureTime').GetValue();
        end
        
        function val = get.MaxGain(obj)
            val = obj.CameraHandle.Parameters.Item('Gain').GetMaximum();
        end
        
        function val = get.MinGain(obj)
            val = obj.CameraHandle.Parameters.Item('Gain').GetMinimum();
        end
        
        function val = get.Gain(obj)
            val = obj.CameraHandle.Parameters.Item('Gain').GetValue();
        end
        
        function val = get.PixelFormat(obj)
            val = obj.CameraHandle.Parameters.Item(...
                'PixelFormat').GetValue();
        end
        % ------------------END GETTER FUNCTIONS---------------------------
        
    end
    
end

