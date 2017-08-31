classdef NewfocusPicomotor < Device
    %NEWFOCUSPICOMOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Set device type using DeviceType enumeration class
        Type = DeviceType.NewfocusPicomotor;
        
        % .NET assembly created from Newfocus Picomotor driver files
        NETAssembly
    end
    
    methods
        function obj = NewfocusPicomotor(index, verbose)
            % Call Superclass constructor firt to avoid redundancies
            obj = obj@Device(index, verbosity);
            
            % Get driver dll for Newfocus picomotor and create an assembly 
            % out of it
            dllName=['C:\Users\Endres Lab\Desktop\TweezerControl\'...
                'Dependencies\Devices\Newfocus Picomotor'...
                'actuator\Drivers\CmdLib.dll'];
            
            obj.NETAssembly = NET.addAssembly(dllName);
            
            %Define parameters
            motor=int8(1); %Motor axis number (1-4)
            stepsPerSec=int16(50); %velocity 100
            stepsPerSec2=int16(2000); %acceleration 5000

            %Construct cmdlib object
            logging=false(1); %create txt file to log information about the device
            msecDelayForDiscovery=int16(5000);
            deviceKey=repmat(char(0),1,2^8);
            cmdlib=NewFocus.Picomotor.CmdLib8742(logging,msecDelayForDiscovery,deviceKey);

            %Get deviceKey
            deviceKey=repmat(char(0),1,2^8);
            deviceKey=cmdlib.GetFirstDeviceKey();

            %Set parameters (Velocity, Acceleration)
            [success]=cmdlib.SetVelocity(deviceKey, motor, stepsPerSec);
            [success]=cmdlib.SetAcceleration(deviceKey, motor, stepsPerSec2);
        end
    end
    
end

