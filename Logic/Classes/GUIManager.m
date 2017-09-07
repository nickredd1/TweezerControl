classdef GUIManager
    %GUIMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Reference to GUI object
        GUI
        
        % Handles of theGUI represented by GUIManager object
        Handles
    end
    
    % Define Abstract properties such that we force subclasses to redefine
    % them
    properties (Abstract = true)
        Type
    end
    
    methods
        function obj = GUIManager(gui, handles)
            obj.GUI = gui;
            obj.Handles = handles;
        end
        
        function shutdownManager(obj)
            close(obj.GUI)
        end
    end
    
end

