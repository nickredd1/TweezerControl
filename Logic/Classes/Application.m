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
    end
    
    methods
        function obj = Application(verbosity)
            obj.Verbose = verbosity;
            
            % Initialize device array, which holds objects representing
            % devices available to the program
            obj.Devices = [];
            
            % Use helper function to query and gather devices that are
            % available to the program currently
            obj.discoverDevices();
        end
        
        % -----------------HELPER FUNCTIONS--------------------------------
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
        
        function discoverDevices(obj)
            % Attempt to discover Spectrum AWG
            obj.addDevice(DeviceType.SpectrumAWG);
            
            % Attempt to discover Basler Camera
            obj.addDevice(DeviceType.BaslerCamera);
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
        % application. 
        function addDevice(obj, type)
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
                    newDevice = BaslerCamera(index, obj.Verbose);
                case DeviceType.AndorCamera
                    newDevice = AndorCamera(index, obj.Verbose);
                case DeviceType.NIDAQ
                    newDevice = NIDAQ(index, obj.Verbose);
                case DeviceType.NewfocusPicomotor
                    newDevice = NewfocusPicomotor(index, obj.Verbose);
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
                if obj.Verbose == true
                    disp('New Device:')
                    newDevice.displayDeviceInfo();
                end
            end
        end
    end
end

