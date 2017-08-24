classdef Application < handle
    %APPLICATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Array holding objects representing the different devices used in
        % the program. All such devices will be represented by their own
        % separate class. In this manner, we can dynamically add 
        Devices
    end
    
    methods
        function obj = Application()
            % Define devices array
            obj.Devices = [];
            
            % Create and add devices to device array with appropriate
            % error handling 
        end
    end
    
end

