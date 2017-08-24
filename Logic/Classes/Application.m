classdef Application < handle
    %APPLICATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Array holding objects representing the different devices used in
        % the program. All such devices will be represented by their own
        % separate class. In this manner, we can dynamically track devices
        % discovered during the application initialization process 
        Devices
        
        % Boolean variable
        Verbose
    end
    
    methods
        function obj = Application(verbosity)
            % Use helper function to query and gather devices that are
            % available to the program currently
            obj.discoverDevices();
            
            % If verbose == true, then various commandline outputs will be
            % used throughout the appplication layer for debugging puposes
            if (islogical(verbosity))
                obj.Verbose = verbosity;
            else 
                fprintf('Error: expected boolean variable. Received: \n')
                disp(verbosity)
            end
        end
        
        function discoverDevices(obj)
            obj.Devices = [];
            
            % Attempt to discover Spectrum AWG, passing index 0 to it as it
            % is the first (and only) SpectrumAWG device
            newAWG = SpectrumAWG(0);
            
            % If newAWG was discovered and initialized, add it to Devices
            % array. If verbose is on, then display its device information
            if ((newAWG.Discovered && newAWG.Initialized) == true)
                obj.Devices = [obj.Devices, newAWG];
                if obj.Verbose == true
                    newAWG.displayDeviceInfo();
                end
            end
        end
    end
end

