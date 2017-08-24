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
        function obj = SpectrumAWG(index)
            
            % Set device type using DeviceType enumeration class
            obj.Type = DeviceType.SpectrumAWG;
 
             % temp
            obj.Discovered = false;
            obj.Initialized = false;
            
            % Error checking for input argument
            if (isnumeric(index) && index >= 0)
                obj.Index = uint16(index);
            else 
                fprintf('Error: expected nonnegative integer variable. Received: \n')
                disp(index)
            end  
            
        end
        
        function displayDeviceInfo(obj)
            disp(obj.Index);
        end
    end
    
end

