classdef Waveform < handle
    %WAVEFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Number of tweezers defined in our waveform. There is a one-to-one
        % relation between the number of frequency components and number of
        % tweezers defined in the waveform
        NumTweezers
        
        % Center frequency of tweezers in Hz
        CenterFreq
        
        % Frequency separation of adjacent tweezers in Hz
        TweezerSep
        
        % Array of frequencies composing the waveform in Hz
        Freqs
        
        % Array of aplitudes of frequencies composing the waveform in
        % normalized units (note that these units are likely normalized to
        % the max mVp defined in the SpectrumAWG object
        Amps
        
        % Array of phases of frequencies
        Phases
        
        % Update function
        Func
    end
    
    methods
        function obj = Waveform(numTweezers, tweezerSep, centerFreq, amps, phases, func)
            obj.NumTweezers = numTweezers;
        end
        
        % Helper function for setting number of tweezers. Includes error
        % checking
        function set.NumTweezers(obj, numTweezers)
            if (isnumeric(numTweezers) && numTweezers >= 0)
                obj.NumTweezers = numTweezers;
            else 
                fprintf(['Error: expected nonnegative integer variable '...
                    'for NumTweezers.\n' ...
                    'Received:'])
                disp(numTweezers)
                return;
            end
        end
        
        % Helper function for setting center frequency of Waveform object
        function set.CenterFreq(obj, center)
            if (isnumeric(center) && center >= 0)
                obj.CenterFreq = center;
            else 
                fprintf(['Error: expected nonnegative variable '...
                    'for CenterFreq.\n' ...
                    'Received:'])
                disp(center)
                return;
            end
        end
        
        % Helper function for setting separation of tweezer frequencies of
        % Waveform object
        function set.TweezerSep(obj, sep)
            if (isnumeric(sep) && sep > 0)
                obj.TweezerSep = sep;
            else 
                fprintf(['Error: expected nonzero variable '...
                    'for TweezerSep.\n' ...
                    'Received:'])
                disp(sep)
                return;
            end
        end
        
        
    end
    
end

