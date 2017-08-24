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
        function obj = SpectrumAWG()
            % Set device type using DeviceType enumeration class
            obj.Type = DeviceType.SpectrumAWG;
            
            obj.Discovered = false;
            obj.Initialized = false;
        end
    end
    
end

