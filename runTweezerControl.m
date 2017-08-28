% 'Entry point' of the application--all that we need to do is ensure that
% the UI layer is added to path and then we may call GUI.m, which allows us
% to call the GUI

% Add UI Layer to path such that we can instantiate a TweezerGUI object
addpath 'UI'
newGUI = GUI;