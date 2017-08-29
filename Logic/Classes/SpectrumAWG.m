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
                    'spcMInitCardByIdx: \n\t'], true);
                return;
            end
            
            % Set SampleRate and internal PLL with clock output determined
            % by the SpectrumAWG property ClockOutput
            [success, obj.CardHandle] = ...
                spcMSetupClockPLL (obj.CardHandle, obj.SamplingRate,...
                obj.ClockOutput); 
            if (~success)
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
            if (~success)
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
                if (~success)
                    spcMErrorMessageStdOut(obj.CardHandle,...
                        'Error: spcMSetupInputChannel:\n\t', true);
                    return;
                end
            end
            
            % Divide memory in 2 segments and begin the process of setting
            % up Replay Sequence modes, starting with segment 0 (Step 1)
            [success, obj.CardHandle] = spcMSetupModeRepSequence(...
                obj.CardHandle, 0, 1, 2, 0);
            if (~success)
                spcMErrorMessageStdOut (obj.CardHandle,...
                    'Error: spcMSetupModeRepSequence:\n\t', true);
                return;
            end
            
            % Set up segment 0 with the correct number of samples for the
            % size of the segment (Step 2)
            error = spcm_dwSetParam_i32(...
                obj.CardHandle.hDrv, ...
                obj.RegMap('SPC_SEQMODE_WRITESEGMENT'), 0);
            if (logical(error))
                spcMErrorMessageStdOut (obj.CardHandle,...
                    ['Error: spcm_dwSetParam_i32'...
                    '(SPC_SEQMODE_WRITESEGMENT):\n\t'], true);
                return;
            end
            
            error = spcm_dwSetParam_i32(...
                obj.CardHandle.hDrv, ...
                obj.RegMap('SPC_SEQMODE_SEGMENTSIZE'), obj.NumMemSamples);
            if (logical(error))
                spcMErrorMessageStdOut (obj.CardHandle,...
                    ['Error: spcm_dwSetParam_i32'...
                    '(SPC_SEQMODE_SEGMENTSIZE):\n\t'], true);
                return;
            end
            
            % Output temp waveform (Step 3)
            tempSignal = zeros(1,obj.NumMemSamples);
            errorCode = spcm_dwSetData (obj.CardHandle.hDrv, 0,...
                obj.NumMemSamples, 1, 0, tempSignal);
            
            % Set sequence steps (Step 4)
            % Input args: step, nextStep, segment, loops, condition
            % For Condition: 0 => End loop always, 1 => End loop on 
            % trigger, 2 => End sequence
            spcMSetupSequenceStep (obj.CardHandle, 0, 0, 0, 1, 0);
           
            % Create mask for command: Start Card and Enable Trigger
            commandMask = bitor (obj.RegMap('M2CMD_CARD_START'),...
                obj.RegMap('M2CMD_CARD_ENABLETRIGGER'));
            
            % Initiate created command
            errorCode = spcm_dwSetParam_i32(obj.CardHandle.hDrv,...
                obj.RegMap('SPC_M2CMD'), commandMask);
            
            % Check errorCode for anything fishy
            obj.checkError(errorCode);
            
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
        
        % Helper function for checking error codes returned from spectrum 
        % AWG functions
        function checkError(obj, errorCode)
            if (errorCode ~= 0)
                [success, obj.CardHandle] = ...
                    spcMCheckSetError(errorCode, obj.CardHandle);
                if errorCode == obj.ErrorMap('ERR_TIMEOUT')
                    errorCode = spcm_dwSetParam_i32(obj.CardHandle.hDrv,...
                        obj.RegMap('SPC_M2CMD'),...
                        obj.RegMap('M2CMD_CARD_STOP'));
                    fprintf('OK\n ................... replay stopped\n');
                else
                    spcMErrorMessageStdOut(obj.CardHandle,...
                        ['Error: spcm_dwSetParam_i32/'...
                        'spcm_dwGetParam_i32:\n'], true);
                    return;
                end
            end
        end
        
        % Updates the SpectrumAWG object with a Waveform object wfm, which
        % contains a pre-computed discretized signal.
        function update(obj, wfm)
            % Make sure we are receiving a Waveform object
            if ~(isa(wfm,Waveform))
                fprintf('Error: expected a Waveform object. Received:\n');
                disp(wfm)
            end
            
            % Get currentStep
            [errorCode, currentStep] = spcm_dwGetParam_i32(...
                obj.CardHandle.hDrv, ...
                349950);  % 349950 = SPC_SEQMODE_STATS
            nextStep=bitxor(currentStep,1);
            % Check errorCode for anything fishy
            obj.checkError(errorCode);
            
            % Update segment
            errorCode = spcm_dwSetParam_i32 (obj.CardHandl.hDrv,...
                obj.RegMap('SPC_SEQMODE_WRITESEGMENT'), nextStep);
            obj.checkError(errorCode);
            
            errorCode = spcm_dwSetParam_i32 (obj.CardHandl.hDrv,...
                obj.RegMap('SPC_SEQMODE_SEGMENTSIZE'), obj.NumMemSamples);
            obj.checkError(errorCode);
            
            % set new waveform
            errorCode = spcm_dwSetData (obj.CardHandle.hDrv, 0,...
                obj.NumMemSamples, 1, 0, wfm.Signal);
            obj.checkError(errorCode);
        end
        
    end
    
end

