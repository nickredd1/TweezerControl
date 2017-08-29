classdef Waveform < handle
    %WAVEFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Array of frequencies composing the waveform in Hz. Length of
        % array is equal to the number of tweezers in our waveform--same
        % applies for Amps and Phases
        Freqs
        
        % Variable containing the number of frequency components of the
        % waveform object
        NumFreqs
        
        % Variable containing number of steps (i.e., samples) in each
        % discrete waveform period which is calculated during the
        % construction of a waveform object
        NumSteps
        
        % Array of aplitudes of frequencies composing the waveform in
        % normalized units (note that these units are likely normalized to
        % the max mVp defined in the SpectrumAWG object
        Amps
        
        % Array of phases of frequencies
        Phases
        
        % Discretized signal calculated during the construction of a
        % waveform object
        Signal
    end
    
    methods
        function obj = Waveform(freqs, amps, phases, t)
            obj.Freqs = freqs;
            obj.Amps = amps;
            obj.Phases = phases;
            obj.NumFreqs = length(freqs);
            obj.NumSteps = length(t);
            
             % Make sure freqs, amps, and phases are all arrays of equal
            % length
            if ~((obj.NumFreqs == length(amps)) ...
                    && (obj.NumFreqs == length(phases)))
                fprintf(['Error: expected Freqs, Amps, and Phases to '...
                    'be equal length arrays.\n'])
                return;
            end
            
            % Compute discretized period of Waveform, ensuring to sum all
            % of the frequency components properly
            signals = zeros(obj.NumFreqs, obj.NumSteps);
            for i = 1:obj.NumFreqs
                signals(i,1:obj.NumSteps) = ...
                    amps(i)*sin(2*pi*freqs(i)*t + phases(i));
            end
            signals = sum(signals)/obj.NumFreqs;
            
            obj.Signal = signals;
        end
        
        % Helper function for setting frequencies of Waveform object
        function set.Freqs(obj, freqs)
            if (isnumeric(freqs))
                % Make sure we have double array
                obj.Freqs = double(freqs);
            else 
                fprintf(['Error: expected numeric array of frequencies '...
                    'for Freqs.\n' ...
                    'Received:'])
                disp(freqs)
                return;
            end
        end
        
         % Helper function for setting amplitude of Waveform object
        function set.Amps(obj, amps)
            if (isnumeric(amps))
                % Make sure we have double array
                obj.Amps = double(amps);
            else 
                fprintf(['Error: expected numeric array of frequencies '...
                    'for Amps.\n' ...
                    'Received:'])
                disp(amps)
                return;
            end
        end
        
         % Helper function for setting phases of Waveform object
        function set.Phases(obj, phases)
            if (isnumeric(phases))
                % Make sure we have double array
                obj.Phases = double(phases);
            else 
                fprintf(['Error: expected numeric array of phases '...
                    'for Phases.\n' ...
                    'Received:'])
                disp(phases)
                return;
            end
        end
        
    end
    
end

