classdef SpectrumAWG < Device
    %SpectrumAWG Summary of this class goes here
    %   Class representing SepctrumAWG object. Any sort of communcation
    %   between the physical Spectrum AWG device installed in the user's
    %   computer environment and the TweezerControl application is done
    %   through the SpectrumAWG device object.
    
    properties
        % Set device type using DeviceType enumeration class
        Type = DeviceType.SpectrumAWG;
        
        % Sampling rate of AWG in S/s (Samples per second). Use default
        % value of 512*10^6 S/s; must be a multiple of 1024 (2^10).
        SamplingRate = 512e6;
        
        % Helper map to use label names for AWG errors. We use default
        % settings by calling spcMCreateErrorMap() which does everything
        % for us.
        ErrorMap = spcMCreateErrorMap();
        % Helper map to use label names for AWG registers. We use default
        % settings by calling spcMCreateRegMap() which does everything
        % for us.
        RegMap = spcMCreateRegMap();
        
        % Resolution of output frequency in Hz. We use default value of
        % 50 kHz as this has proven effective up until now.
        FreqRes = 50e3;
        
        % Boolean variable representing whether or not clock output of AWG
        % is enabled (true) or disabled (false). Default value is false as
        % we don't care about the physical clock output of the AWG.
        ClockOutput = false;
        
        % Boolean variable representing whether or not trigger output is
        % enabled
        TriggerOutput = false;
        
        % Array of reference amplitudes for each channel in mVp, or
        % milivolts from peak to 0 mV reference (NOT mVpp). We use default
        % value of 800 mVp as this has been used up until now as the
        % standard.
        ChAmps = [800, 800, 800, 800];
        
        % Number of samples per sequence. Follows the equation
        % NumMemSamples = SamplingRate / FreqRes. NumMemSamples must be a
        % multiple of 1024 (2^10).
        NumMemSamples = 10240;
        
        % Handle to SpectrumAWG card that driver functions use to keep
        % track of a software-realized AWG card. (This is basically a
        % pointer)
        CardHandle
        
    end
    
    methods
        % Constructor for SpectrumAWG object; attempts to discover and
        %   initialize the first Spectrum AWG that is discovered by the
        %   program
        %
        % index: index of device of type SpectrumAWG; all indices for
        %   devices of a specific type should be unique; start the indexing
        %   at 0 for all devices
        function obj = SpectrumAWG(index, verbosity)
            obj = obj@Device(index, verbosity);
            
            % Init card and store infos and handle in CardHandle, using
            % passed index as the card index to use (starts indexing at 0
            % probably?)
            [success, obj.CardHandle] = spcMInitCardByIdx (obj.Index);
            
            % Set discovered and initialized based on the success variable
            % returned from spcMInitCardByIdx(). Uses property setting
            % method of Device class
            obj.Discovered = success;
            obj.Initialized = success;
            
            % If device was not succesfully discovered and initialized,
            % then print error message to terminal and return
            if ~(obj.Discovered && obj.Initialized)
                spcMErrorMessageStdOut (obj.CardHandle, ...
                    ['Error: Could not open Spectrum card.'...
                    'Device not created \n'], true);
                return;
            end
            
            % Set SampleRate and internal PLL with clock output determined
            % by the SpectrumAWG property ClockOutput
            [success, obj.CardHandle] = ...
                spcMSetupClockPLL (obj.CardHandle, obj.SamplingRate,...
                obj.ClockOutput); 
            if (success == false)
                spcMErrorMessageStdOut (obj.CardHandle, ...
                    'Error: spcMSetupClockPLL:\n\t', true);
                return;
            end
            
            % If verbose == true, print out the sampling rate
            if (obj.Verbose)
                fprintf ('\nAWG Sampling rate set to %.1f MHz\n',...
                obj.CardHandle.setSamplerate / 1e6);
            end
            
            % Set software trigger with trigger output determined by the
            % SpectrumAWG property TriggerOutput
            [success, obj.CardHandle] = ...
                spcMSetupTrigSoftware (obj.CardHandle, obj.TriggerOutput); 
            if (success == false)
                spcMErrorMessageStdOut (obj.CardHandle,...
                    'Error: spcMSetupTrigSoftware:\n\t', true);
                return;
            end
            
            % Program all output channels 
            for i=0 : obj.CardHandle.maxChannels-1
                % Setup output channels with their defined amplitudes
                % (i.e., ChAmps), 0 mV offset, filter = 0, Stop Mode equal
                % to RegMap('SPCM_STOPLVL_ZERO'), doubleOut disabled and
                % differential disabled
                [success, obj.CardHandle] = ...
                    spcMSetupAnalogOutputChannel(obj.CardHandle,...
                    i, obj.ChAmps(i+1), 0, 0,...
                    obj.RegMap('SPCM_STOPLVL_ZERO'), 0, 0); 
                if (success == false)
                    spcMErrorMessageStdOut(obj.CardHandle,...
                        'Error: spcMSetupInputChannel:\n\t', true);
                    return;
                end
            end
            
            % ----------------------------TEMP-----------------------------
            obj.shutdownDevice();
        end
        
        function displayDeviceInfo(obj)
            % Extend inherited displayDeviceInfo() function
            displayDeviceInfo@Device(obj);
            
            % Use device function to print card info to terminal
            cardInfoText = spcMPrintCardInfo (obj.CardHandle);
            fprintf ('%s\n', cardInfoText)
        end
        
        function shutdownDevice(obj)
            disp('Shutting down SpectrumAWG device')
            % Delete AWG so that we can open it up again
            spcMCloseCard (obj.CardHandle);
            disp('AWG stopped')
        end
    end
    
end

