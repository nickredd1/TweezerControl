classdef SpectrumAWG < Device
    %SpectrumAWG Summary of this class goes here
    %   Class representing SepctrumAWG object. Any sort of communcation
    %   between the physical Spectrum AWG device installed in the user's
    %   computer environment and the TweezerControl application is done
    %   through the SpectrumAWG device object.
    
    properties
        SamplingRate
    end
    
    methods
        % Constructor for SpectrumAWG object; attempts to discover and
        %   initialize the first Spectrum AWG that is discovered by the
        %   program
        %
        % index: index of device of type SpectrumAWG; all indices for
        %   devices of a specific type should be unique; start the indexing
        %   at 0 for all devices
        function obj = SpectrumAWG(index)
            % Set device type using DeviceType enumeration class
            obj.Type = DeviceType.SpectrumAWG;
 
             % temp
            obj.Discovered = false;
            obj.Initialized = false;
            
            % Use setter for the index input argument, inherited from the
            % Device class
            obj.setIndex(index);
        end
        
        function displayDeviceInfo(obj)
            disp(obj.Index)
        end
        
        function shutdownDevice(obj)
            disp(obj.Index)
        end
    end
    
end

