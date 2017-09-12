function varargout = UniformArrayGUI(varargin)
% UNIFORMARRAYGUI MATLAB code for UniformArrayGUI.fig
%      UNIFORMARRAYGUI, by itself, creates a new UNIFORMARRAYGUI or raises the existing
%      singleton*.
%
%      H = UNIFORMARRAYGUI returns the handle to a new UNIFORMARRAYGUI or the handle to
%      the existing singleton*.
%
%      UNIFORMARRAYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UNIFORMARRAYGUI.M with the given input arguments.
%
%      UNIFORMARRAYGUI('Property','Value',...) creates a new UNIFORMARRAYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UniformArrayGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UniformArrayGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UniformArrayGUI

% Last Modified by GUIDE v2.5 12-Sep-2017 14:47:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UniformArrayGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @UniformArrayGUI_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT


% --- Executes just before UniformArrayGUI is made visible.
function UniformArrayGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to UniformArrayGUI (see VARARGIN)

% Choose default command line output for UniformArrayGUI
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


% --- Outputs from this function are returned to the command line.
function varargout = UniformArrayGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in StartTweezingButton.
function StartTweezingButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartTweezingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.startTweezing();
guidata(hObject, handles);
end

% --- Executes on button press in StopTweezingButton.
function StopTweezingButton_Callback(hObject, eventdata, handles)
% hObject    handle to StopTweezingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.stopTweezing();
guidata(hObject, handles);
end


% --- Executes when entered data in editable cell(s) in PropertyValueTable.
function PropertyValueTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to PropertyValueTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
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


% --- Executes during object deletion, before destroying properties.
function UniformArrayGUI_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to UniformArrayGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
guidata(hObject, handles);
end


% --- Executes on button press in FilePathButton.
function FilePathButton_Callback(hObject, eventdata, handles)
% hObject    handle to FilePathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dir = uigetdir;
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.FilePath = dir;
set(handles.FilePathText, 'String', ['File Path: ', dir]);
end


% --- Executes on button press in MonitorPowerButton.
function MonitorPowerButton_Callback(hObject, eventdata, handles)
% hObject    handle to MonitorPowerButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.monitorPower();
end

% --- Executes on button press in UniformizeButton.
function UniformizeButton_Callback(hObject, eventdata, handles)
% hObject    handle to UniformizeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.uniformize();
end


% --- Executes on button press in DefineROIButton.
function DefineROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to DefineROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.defineROI();
end

% --- Executes on button press in ResetROIButton.
function ResetROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to ResetROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIManager = handles.application.getManager(...
    GUIType.UniformArray);
GUIManager.resetROI();
end