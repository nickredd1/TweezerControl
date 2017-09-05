classdef NIDAQ < Device
    %BASLERCAMERA Summary of this class goes here
    %   Class representing NIDAQ object. Any sort of communcation
    %   between the physical NI DAQ installed in the user's
    %   computer environment and the TweezerControl application is done
    %   through the NIDAQ device object.
    
    properties
        % Set device type using DeviceType enumeration class
        Type = DeviceType.NIDAQ;
        
        % DAQ Session object that holds all of the data from the NI driver,
        % which we shall use to add voltage measuring channels and take
        % measurements
        DAQSession
    end
    
    methods
        % Constructor for NIDAQ object
        function obj = NIDAQ(index, verbosity)
            % Call Superclass constructor firt to avoid redundancies
            obj = obj@Device(index, verbosity);
            
            % Start session using daq library provided by MATLAB 
            obj.DAQSession = daq.createSession('ni');
            
            % Add differential analog input channels AI0 and AI1, which at
            % this point are connected to our Preamp Power Meter and
            % Postamp Power Meter, respectively
            addAnalogInputChannel(obj.DAQSession,'Dev1', 0, 'Voltage');
            addAnalogInputChannel(obj.DAQSession,'Dev1', 1, 'Voltage');
            
            % Set the sampling rate to the highest possible value
            obj.DAQSession.Rate = obj.DAQSession.RateLimit(2);
            
            % At this point, the DAQ has been successfully initialized
            obj.Initialized = true;
        end
        
        % Return 1 X M array containing voltage samples from all
        % M initialized Analog inputs
        function voltages = sampleInputs(obj)
            voltages = obj.DAQSession.inputSingleScan;
        end
        
        % Display device info (inherited from Device class)
        function displayDeviceInfo(obj)
            % Extend inherited displayDeviceInfo() function
            displayDeviceInfo@Device(obj);
            
            % Use provided device info readout from driver 
            disp(obj.DAQSession)
        end
        
        % Shutdown device (inherited from Device class)
        function shutdownDevice(obj)
            % Clear DAQSession object so that it is removed
            clear obj.DAQSession
            if (obj.Verbose)
                disp('NIDAQ stopped')
            end
        end
    end
    
end

