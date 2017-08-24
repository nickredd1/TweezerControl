classdef Device < handle
    %DEVICE Summary of this class goes here
    %   Parent class representing Device object. All devices used by
    %   the TweezerControl program are Devices and thus must descend from
    %   the Device class. Note that the Device class shouldn't be
    %   explicitly instantiated, just it's descendants
    
    properties
        % Boolean value representing if device was discovered 
        Discovered
        
        % Boolean value representing if device was initialized 
        Initialized
        
        % Enumeration object representing type of device (Enumeration class
        % defined as DeviceType.m)
        Type
    end
    
end

