classdef Application < handle
    %APPLICATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Array holding objects representing the different devices used in
        % the program. All such devices will be represented by their own
        % separate class. In this manner, we can dynamically track devices
        % discovered during the application initialization process 
        AvailableDevices
    end
    
    methods
        function obj = Application()
            % Use helper function to query and gather devices that are
            % available to the program currently
            obj.discoverAvailableDevices();
            
            
        end
        
        function discoverAvailableDevices(obj)
            obj.AvailableDevices = [];
            
            
        end
    end
    
end

