classdef (Abstract) Device < handle & matlab.mixin.Heterogeneous
    %DEVICE Summary of this class goes here
    %   Parent class representing Device object. All devices used by
    %   the TweezerControl program are Devices and thus must descend from
    %   the Device class. Note that the Device class shouldn't be
    %   explicitly instantiated--just it's descendants--as it is an
    %   Abstract class. We inherit also from matlab.mixin.Heterogeneous to
    %   allow for us to create heterogenous arrays of different objects
    
    properties 
        % Boolean variable representing the verbosity of the device. For
        % example, with each device that is initialized, when verbose = true
        % we would print the device information to the terminal.
        Verbose
        
        % Boolean value representing if device was initialized 
        Initialized
        
        % Index of device object--each device of a specific type must have
        % a unique index!
        Index
    end
    
    properties (Abstract = true)
        % Enumeration object representing type of device (Enumeration class
        % defined as DeviceType.m). We force this to be an abstract
        % property as this forces the subclass to redefine the property,
        % creating a consistent type definition across all subclasses
        % (without having to set the property in the Constructor)
        Type
    end
    
    methods
        % Constructor for device object. This constructor is never
        % explicitly used, but it is called in all of the subclass
        % constructors to initially set up the common input arguments.
        function obj = Device(index, verbosity)
            % Use setter for the index input argument
            obj.Index = index;
            
            % Use setter for the verbosity input argument
            obj.Verbose = verbosity;
        end
        
        % Setter for Verbose property of device. Includes error checking
        % for input argument.
        function set.Verbose(obj, verbosity)
            % If verbose == true, then various commandline outputs will be
            % used throughout the appplication layer for debugging puposes
            if (islogical(verbosity))
                obj.Verbose = verbosity;
            else 
                fprintf(['Error: expected boolean variable.'...
                    '\nReceived:\n'])
                disp(verbosity)
                return;
            end
        end
        
        % Setter for index property of device. Includes error checking for 
        % input argument. Start indexing at 0 because Windows begins
        % indexing at 0 for all connected devices 
        function set.Index(obj, index)
            if (isnumeric(index) && index >= 0)
                obj.Index = uint16(index);
            else 
                fprintf(['Error: expected nonnegative integer variable '...
                    'for Index.\n' ...
                    'Received:'])
                disp(index)
                return;
            end 
        end
        
        % Setter for initialized property of device. Includes error checking for 
        % input argument 
        function set.Initialized(obj, initialized)
            if (islogical(initialized))
                obj.Initialized = initialized;
            else 
                fprintf(['Error: expected boolean variable '...
                    'for Initialized.\n' ...
                    'Received:'])
                disp(initialized)
                return;
            end 
        end
        
        
        % Method for displaying the respective device's
        % information--note that each subclass of Device should
        % individually extend this method such that each device can add its
        % own relevant device information
        function displayDeviceInfo(obj)
            fprintf('Type: %s\n', obj.Type)
            fprintf('Index: %d\n', obj.Index)
            fprintf('Initialized: %d\n', obj.Initialized)
            fprintf('\n')
        end
        
    end
    methods (Abstract)
        % Abstract method for shutting down the device object; should
        % include any logic or code required to shutdown the device via
        % software (i.e., releasing/deleting the handle and any claimed
        % system resources) such that if necessary, the device may be
        % recreated or reinitialized without error in the future
        shutdownDevice(obj)
        
    end
end

