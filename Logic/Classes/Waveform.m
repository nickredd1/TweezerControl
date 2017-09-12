classdef Waveform
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
        
        % Array of binary (0 or 1) scalars that control the on/off state of
        % each fundamental frequency
        Controls
        
        % Scalar (0-1) that scales the overall amplitude of the discretized
        % signal
        Lambda
        
        % Discretized signal calculated during the construction of a
        % waveform object
        Signal
    end
    
    methods
        function obj = Waveform(lambda, freqs, controls, amps, phases, t)
            obj.Freqs = double(freqs);
            obj.Amps = double(amps);
            obj.Phases = double(phases);
            obj.Controls = double(controls);
            obj.NumFreqs = length(freqs);
            obj.NumSteps = length(t);
            
             % Make sure freqs, amps, and phases are all arrays of equal
            % length
            if ~((obj.NumFreqs == length(amps)) ...
                    && (obj.NumFreqs == length(phases)) &&...
                    obj.NumFreqs == length(controls))
                fprintf(['Error: expected Freqs, Amps, Controls, and'...
                    'Phases to '...
                    'be equal length arrays.\n'])
                return;
            end
            
            % Compute discretized period of Waveform, ensuring to sum all
            % of the frequency components properly
            signals = zeros(obj.NumFreqs, obj.NumSteps);
            
            for i = 1:obj.NumFreqs
                signals(i,1:obj.NumSteps) = controls(1, i) ...
                    * amps(1, i) * sin(2*pi*freqs(1, i)*t + phases(1, i));
            end
            
            % Calculate the square root of the sum of the magnitude squared
            % for the array of amplitudes provided
            sumAmps = 0.0;
            for i = 1:length(amps)
                sumAmps = sumAmps + abs(amps(1, i))^2;
            end
            
            % Scale waveform such that each frequency component contributes
            % equally to the amplitude of the composite waveform. In this
            % case we take into account the sum of the amplitudes and the
            % number of frequency components
            if (size(signals, 1) > 1)
                signals = sum(signals);
            end
            signals = signals/(sqrt(obj.NumFreqs) * sqrt(sumAmps));
            signals = signals * lambda;
            obj.Signal = signals;
        end
        
        % Helper function for setting controls of Waveform object
        function obj = set.Controls(obj, controls)
            if (isnumeric(controls) && ~isempty(controls))
                % Make sure we have double array
                obj.Controls = double(controls);
            else 
                fprintf(['Error: expected numeric array of integers '...
                    'for Controls.\n' ...
                    'Received:'])
                disp(controls)
                return;
            end
        end
        
        % Helper function for setting controls of Waveform object
        function obj = set.Lambda(obj, lambda)
            if (isnumeric(lambda) && ~isempty(lambda))
                % Make sure we have double array
                obj.Lambda = double(lambda);
            else 
                fprintf(['Error: expected scalar '...
                    'for Lambda.\n' ...
                    'Received:'])
                disp(lambda)
                return;
            end
        end
        
        
        % Helper function for setting frequencies of Waveform object
        function obj = set.Freqs(obj, freqs)
            if (isnumeric(freqs) && ~isempty(freqs))
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
        function obj = set.Amps(obj, amps)
            if (isnumeric(amps) && ~isempty(amps))
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
        function obj = set.Phases(obj, phases)
            if (isnumeric(phases) && ~isempty(phases))
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

