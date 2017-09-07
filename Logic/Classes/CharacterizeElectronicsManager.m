classdef CharacterizeElectronicsManager < GUIManager
    %CHARACTERIZEELECTRONICSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type = GUIType.CharacterizeElectronics;
        
        NumTweezers
        
        ChAmp
        
        FreqSep
        
        CenterFreq
        
        Lambda
    end
    
    methods
        function obj = CharacterizeElectronicsManager(gui, handles)
            obj = obj@GUIManager(gui, handles);
        end
        
    end
    
end

