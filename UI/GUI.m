function varargout = GUI(varargin)
% GUI MATLAB code for GUI.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI

% Last Modified by GUIDE v2.5 31-Aug-2017 18:21:29

% Add application layer objects to our workspace so that we may communicate
% through the application layer. Note that all classes from the various
% directories MUST be manually added to path or else MATLAB will not be
% able to use them within the workspace!
addpath 'Logic\Classes'
addpath 'Dependencies\Devices\Spectrum GmbH\SpcmMatlabDriver\spcm_DrvPackage'
addpath 'Dependencies\Devices\Spectrum GmbH\SpcmMatlabDriver\spcm_LibPackage'

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_OutputFcn, ...
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

% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI (see VARARGIN)
% Choose default command line output for GUI
handles.output = hObject;

% Initialize Application Layer with verbose = true
handles.application = Application(true, handles);

% *********VERY IMPORTANT: Updates handles structure with the updates
% defined during this specific function block. Without calling guidata
% below, all changes to the GUI's handles made by the Application object
% will NOT be saved! 
guidata(hObject, handles);

end

% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end



% --- Executes during object creation, after setting all properties.
function DeviceTable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DeviceTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'Data',cell(0));
end



function NumberOfTweezersEdit_Callback(hObject, eventdata, handles)
% hObject    handle to NumberOfTweezersEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NumberOfTweezersEdit as text
%        str2double(get(hObject,'String')) returns contents of NumberOfTweezersEdit as a double
numTweezers = uint32(str2double(get(hObject,'String')));
handles.NumberOfTweezersText.String = ...
    sprintf('Number of Tweezers: %d', numTweezers);
end

% --- Executes during object creation, after setting all properties.
function NumberOfTweezersEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumberOfTweezersEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in DefineROIButton.
function DefineROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to DefineROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.application.defineImageROI(0);
end

% --- Executes on button press in ResetROIButton.
function ResetROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to ResetROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.application.resetImageROI(0);
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Shutdown devices via application layer
handles.application.shutdownDevices();
end
