classdef BaslerCamera < Device
    %BASLERCAMERA Summary of this class goes here
    %   Class representing BaslerCamera object. Any sort of communcation
    %   between the physical Basler Camera installed in the user's
    %   computer environment and the TweezerControl application is done
    %   through the BaslerCamera device object.
    
    properties
        
    end
    
    methods
        % Constructor for BaslerCamera object; attempts to discover and
        %   initialize the first Basler Camera that is discovered by the
        %   program
        %
        % index: index of device of type BaslerCamera; all indices for
        %   devices of a specific type should be unique; start the indexing
        %   at 0 for all devices
        function obj = BaslerCamera(index)
            % Set device type using DeviceType enumeration class
            obj.Type = DeviceType.BaslerCamera;
 
             % temp
            obj.Discovered = false;
            obj.Initialized = false;
            
            % Use setter for the index input argument, inherited from the
            % Device class
            obj.setIndex(index);
        end
        
        function displayDeviceInfo(obj)
            % Extend inherited displayDeviceInfo() function
            displayDeviceInfo@Device(obj);
        end
        
        function shutdownDevice(obj)
            disp('shutting down')
        end
    end
    
end

