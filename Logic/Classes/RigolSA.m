classdef RigolSA < Device
    %RIGOLSA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Define device type using enumeration class
        Type = DeviceType.RigolSA
        
        % Visa USB object
        VISAUSB
        
        % Buffer size of VISA-USB object
        BufferSize
        
        % Resolution bandwidth
        RBW
        
        % Units of frequencies
        Units
        
        % Start frequency of scan (in the units defined above)
        StartFreq
        
        % End frequency
        EndFreq
        
        % Number of samples taken during each power spectrum from Rigol SA
        NumSamples = 601;
    end
    
    methods
        function obj = RigolSA(index, verbosity)
            obj = obj@Device(index, verbosity);
            obj.VISAUSB = visa('ni',...
                'USB0::0x1AB1::0x0960::DSA8A180300057::INSTR');
            obj.BufferSize = 2^16;
            obj.VISAUSB.InputBufferSize = obj.BufferSize;
            
            % Open the VISA object created
            fopen(obj.VISAUSB);

            %Query ID string
            fprintf(obj.VISAUSB, '*IDN?' );
            [idn, ~, msg] = fread(obj.VISAUSB, obj.VISAUSB.InputBufferSize);
            disp(char(idn)')

            % Resolution bandwidth (default is 1 MHz)
            obj.RBW = 3000.0; 
            fprintf(obj.VISAUSB,[':sens:band:res ',num2str(obj.RBW)]);

            % Setting frequency range with [start,end]
            % Setting the start and end frequencies
            obj.Units = 'MHz';
            obj.StartFreq = 50;
            obj.EndFreq = 120;
            fprintf(obj.VISAUSB, [':sens:freq:star ', ...
                num2str(obj.StartFreq),obj.Units]);
            fprintf(obj.VISAUSB, [':sens:freq:stop ', ...
                num2str(obj.EndFreq),obj.Units]);

            obj.Initialized = true;
            % %% Setting the unit for amplitude
            % specParameters.ampunit='dBm'; %default is dBm for log unit
            % % can also change to lin unit, e.g. V, W, or other log units DBMV, DBUV
            % fprintf(DSA815,[':unit:pow ',specParameters.ampunit]);
            % 
        end
        
        % Obtain noise floor for power integration
        function noisefl = calculateNoiseFloor(obj)
            iter = 20;
            noise=zeros(1,20);
            for j=1:iter
                % Read data (in ASCII)
                fprintf(obj.VISAUSB, ':trac:data? trace1' );
                % num of data points depends on bufferSize
                [data, len, msg]= fread(obj.VISAUSB, obj.BufferSize); 

                % Converting data format to double
                % Output is in ASCII, must use char to convert
                % eliminate the first cell which indicates data size
                data = strsplit(char(data)',','); 
                temp1 = strsplit(char(data(1))); 
                temp2 = strtrim(data(2:end));

                tempdata = [strtrim(temp1(2)),temp2];
                s = size(tempdata);
            
                data = zeros(1,s(2));
            
                for i = 1:s(2)
                   num = str2num(char(tempdata(i)));
                   data = num;
                end
            
                noise(1,j) = mean(data);
            end

            noisefl = mean(noise);
        end
        
        % Gets power spectrum from Spectrum Analyzer
        function spectrum = getPowerSpectrum(obj, start, last)
            obj.StartFreq = start;
            obj.EndFreq = last;
            fprintf(obj.VISAUSB, [':sens:freq:star ', ...
                num2str(obj.StartFreq), obj.Units]);
            fprintf(obj.VISAUSB, [':sens:freq:stop ', ...
                num2str(obj.EndFreq), obj.Units]);
            
            % Read data (in ASCII)
            fprintf(obj.VISAUSB, ':trac:data? trace1' );
            [data, len, msg] = fread(obj.VISAUSB, obj.BufferSize); 
            
            % Converting data format to double
            % Output is in ASCII, must use char to convert
            % eliminate the first cell which indicates data size
            data = strsplit(char(data)',','); 
            temp1 = strsplit(char(data(1))); 
            temp2 = strtrim(data(2:end));

            tempdata = [strtrim(temp1(2)), temp2];
            s = size(tempdata);

            data = zeros(2, s(2));

            for i = 1:s(2)
               num = str2double(char(tempdata(i)));
               data(1, i) = num;
            end
            
            switch obj.Units
                case 'MHz'
                    startFreq = obj.StartFreq * 10^6;
                    endFreq = obj.EndFreq * 10^6;
                    data(2, :) = linspace(startFreq, endFreq, ...
                        obj.NumSamples);
            end
            spectrum = data;
        end
        
        function displayDeviceInfo(obj)
            % Extend inherited displayDeviceInfo() function
            displayDeviceInfo@Device(obj);
        end
        
        function shutdownDevice(obj)
            % Close VISA-USB object
            fclose(obj.VISAUSB);
            if(obj.Verbose)
                disp('RigolSA shutdown')
            end
        end
    end
    
end

