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
            
            % Create the CameraHandle
            obj.CameraHandle = Basler.Pylon.Camera();
            
            % Open the camera
            obj.CameraHandle.Open();
            
            methods(obj.CameraHandle.Parameters)
            % Define camera parameters
             methods(obj.CameraHandle.Parameters.Item(...
                 'Height'))
             
             obj.Height = 100;
             obj.Width = 100;
             obj.OffsetX = 100;
             obj.OffsetY = 100;
             % temp
            obj.Initialized = false;
            obj.shutdownDevice();
        end
        
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
                fprintf(['Error: expected an integer height < '...
                    '%d and > %d. Received:\n'], min, max);
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
                fprintf(['Error: expected an integer width < '...
                    '%d and > %d. Received:\n'], min, max);
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
                    '%d and > %d. Received:\n'], min, max);
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
                    '%d and > %d. Received:\n'], min, max);
                disp(offsety)
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
        % ------------------END GETTER FUNCTIONS---------------------------
        
        % Get image from BaslerCamera object, given
        function [success, image] = getImage(obj)
            if (obj.CameraHandle.IsOpen)
                timeout=int32(500); % 500
                
                % Initialize acquisition
                obj.CameraHandle.StreamGrabber.Start();
                grabResult=obj.CameraHandle.StreamGrabber.RetrieveResult(...
                    timeout, Basler.Pylon.TimeoutHandling.ThrowException);
                obj.CameraHandle.StreamGrabber.Stop();

                % Convert pixel buffer data to uint8 image
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
            % Delete BaslerCamera so that we can open it up again
            obj.CameraHandle.Close();
            disp('BaslerCamera stopped')
        end
    end
    
end

