
% create a GUI for epoching data from the exported compumedics files

function EpochProbeDataGUI(varargin)

clc
clear
close all

FS = 8;
ControlColor = 'white';



% this is the full GUI figure
DataEpocher_fig = figure('Name','Probe Epoch',...
    'NumberTitle','off',...
    'units','normalized',...
    'Position',[0 .035 1 .9],...
    'toolbar','figure',...
    'menubar','none',...
    'color',ControlColor);

Top = 0.9;
LeftControls = 0.91;
RightControls = 0.001;
WidthControl = 0.08;
HeightControl = 0.025;      % starting top

Bottom = 0.02;
Height = 1-Bottom;
Ax = axes('parent',DataEpocher_fig,...
        'units', 'normalized',...
        'position', [0.081 Bottom 0.82 Height]);

Top = Top-HeightControl;
uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'find *.dat file',...
    'callback',@GetDataFile);            % this callback runs the gui to create a new montage    
    
% set/get the file where the *.dat file is
Top = Top-HeightControl;
pathname = '/Users/dean/Documents/PhD/Probe Analysis/Compumedics Data/UBET_Probe_DAT';
filename = '*.dat filename';        % declare this here to make it a global
DataFileAndPath = [pathname '/' filename];
TextBox_filename = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', filename,...
    'backgroundcolor',ControlColor);
% set/get the file where the stim times are stored
% this should be a mat file in the same folder

% view data to identify bad channels, need to be able to scroll through it
% this will be a file that is about 1GB in size
% view it in 10 second blocks

% use a back-ground high-lighter to show where stims occur

% use a tick box to identify bad channels





    function GetDataFile(varargin)
        [filename pathname] = uigetfile(pathname,'*.dat');
        set(TextBox_filename,'string',filename)
    end
end