function varargout = CharacterizeElectronicsGUI(varargin)
% CHARACTERIZEELECTRONICSGUI MATLAB code for CharacterizeElectronicsGUI.fig
%      CHARACTERIZEELECTRONICSGUI, by itself, creates a new CHARACTERIZEELECTRONICSGUI or raises the existing
%      singleton*.
%
%      H = CHARACTERIZEELECTRONICSGUI returns the handle to a new CHARACTERIZEELECTRONICSGUI or the handle to
%      the existing singleton*.
%
%      CHARACTERIZEELECTRONICSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CHARACTERIZEELECTRONICSGUI.M with the given input arguments.
%
%      CHARACTERIZEELECTRONICSGUI('Property','Value',...) creates a new CHARACTERIZEELECTRONICSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CharacterizeElectronicsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CharacterizeElectronicsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CharacterizeElectronicsGUI

% Last Modified by GUIDE v2.5 06-Sep-2017 16:15:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CharacterizeElectronicsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CharacterizeElectronicsGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before CharacterizeElectronicsGUI is made visible.
function CharacterizeElectronicsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CharacterizeElectronicsGUI (see VARARGIN)

% Choose default command line output for CharacterizeElectronicsGUI
handles.output = hObject;

% Find GUI handle (which is essentially the main GUI)
handles.GUI = findobj('Tag','GUI');

% Get reference to application object
data = guidata(handles.GUI);
handles.application = data.application;

% Update handles structure
guidata(hObject, handles);
end
% UIWAIT makes CharacterizeElectronicsGUI wait for user response (see UIRESUME)
% uiwait(handles.CharacterizeElectronicsGUI);


% --- Outputs from this function are returned to the command line.
function varargout = CharacterizeElectronicsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end



function SetNumberOfTweezersEditText_Callback(hObject, eventdata, handles)
% hObject    handle to SetNumberOfTweezersEditText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SetNumberOfTweezersEditText as text
%        str2double(get(hObject,'String')) returns contents of SetNumberOfTweezersEditText as a double
numTweezers = uint32(str2double(get(hObject,'String')));

handles.application.outputNumTweezers(handles, numTweezers, 1500,...
    500*10^3, 85, .5);
end

% --- Executes during object creation, after setting all properties.
function SetNumberOfTweezersEditText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SetNumberOfTweezersEditText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in PlotChannelAmplitudeButton.
function PlotChannelAmplitudeButton_Callback(hObject, eventdata, handles)
% hObject    handle to PlotChannelAmplitudeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.application.plotChannelAmplitude(handles);
end
