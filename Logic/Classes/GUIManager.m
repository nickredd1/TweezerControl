classdef GUIManager < handle & matlab.mixin.Heterogeneous
    %GUIMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Reference to application so that we can control the devices it
        % maintains
        Application
        
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
        function obj = GUIManager(application)
            obj.Application = application;
        end
        
        function shutdownManager(obj)
            if (ishandle(obj.GUI))
                close(obj.GUI)
            end
        end
    end
    
end

