classdef (Abstract) Device < handle
    %DEVICE Summary of this class goes here
    %   Parent class representing Device object. All devices used by
    %   the TweezerControl program are Devices and thus must descend from
    %   the Device class. Note that the Device class shouldn't be
    %   explicitly instantiated--just it's descendants--as it is an
    %   Abstract class
    
    properties 
        % Boolean value representing if device was discovered 
        Discovered
        
        % Boolean value representing if device was initialized 
        Initialized
        
        % Index of device object--each device of a specific type must have
        % a unique index!
        Index
        
        % Enumeration object representing type of device (Enumeration class
        % defined as DeviceType.m)
        Type
    end
    
    methods
        % Setter for index property of device. Includes error checking for 
        % input argument 
        function setIndex(obj, index)
            if (isnumeric(index) && index >= 0)
                obj.Index = uint16(index);
            else 
                fprintf(['Error: expected nonnegative integer variable'...
                    'for index. No device of type %s was created.\n' ...
                    'Received:'], obj.Type)
                disp(index)
                return;
            end 
        end
        
    end
    methods (Abstract)
        % Abstract method for displaying the respective device's
        % information--note that each subclass of Device necessarily must 
        % define its own displayDeviceInfo() method, as it is abstract
        displayDeviceInfo(obj)
        
        % Abstract method for shutting down the device object; should
        % include any logic or code required to shutdown the device via
        % software (i.e., releasing/deleting the handle and any claimed
        % system resources) such that if necessary, the device may be
        % recreated or reinitialized without error in the future
        shutdownDevice(obj)
    end
end

