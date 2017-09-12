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

% Last Modified by GUIDE v2.5 12-Sep-2017 13:18:38

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
data = data.application;
handles.application = data;

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

% --- Executes on button press in PlotChannelAmplitudeButton.
function PlotChannelAmplitudeButton_Callback(hObject, eventdata, handles)
% hObject    handle to PlotChannelAmplitudeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.CharacterizeElectronics);
GUIManager.characterizeDACs();
end


% --- Executes when entered data in editable cell(s) in PropertyTable.
function PropertyTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to PropertyTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.CharacterizeElectronics);
switch eventdata.Indices(1)
    case 1
        num = str2double(eventdata.EditData);
        
        GUIManager.NumTweezers = num;
    case 2
        num = str2double(eventdata.EditData);
        GUIManager.ChAmp = num;
    case 3
        num = str2double(eventdata.EditData);
        GUIManager.FreqSep = num;
    case 4
        num = str2double(eventdata.EditData);
        GUIManager.CenterFreq = num;
    case 5
        num = str2double(eventdata.EditData);
        GUIManager.Lambda = num;
    case 6
        num = str2double(eventdata.EditData);
        GUIManager.Attenuation = num;
end
guidata(hObject, handles);
end


% --- Executes on button press in StartTweezeingButton.
function StartTweezeingButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartTweezeingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.CharacterizeElectronics);
GUIManager.startTweezing();
guidata(hObject, handles);
end

% --- Executes on button press in StopTweezingButton.
function StopTweezingButton_Callback(hObject, eventdata, handles)
% hObject    handle to StopTweezingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.CharacterizeElectronics);

GUIManager.stopTweezing();
end


% --- Executes on button press in MonitorPowerButton.
function MonitorPowerButton_Callback(hObject, eventdata, handles)
% hObject    handle to MonitorPowerButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.CharacterizeElectronics);
GUIManager.monitorPower();
guidata(hObject, handles);
end


% --- Executes during object deletion, before destroying properties.
function CharacterizeElectronicsGUI_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to CharacterizeElectronicsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.CharacterizeElectronics);
if (GUIManager.MonitoringPower)
    GUIManager.monitorPower();
end
guidata(hObject, handles);
end
