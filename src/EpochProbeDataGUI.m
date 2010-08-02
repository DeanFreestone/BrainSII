
% created by Dean Freestone 27/07/2010
% create a GUI for epoching data from the exported compumedics files


% to do list
% ~~~~~
% add control for size of grid
% add control for smoothing and filter
% need to add invisibility or checks so things are done in order
% need to make button go red when their function has finished

function EpochProbeDataGUI(varargin)

clc
clear
close all

RawData = [];           % this is the data that will be loaded from the data file
NChannels = 32;
NSamples = [];
% t = [];
RelativeStimTimes = [];
DiffElectrodeIndexes = [];      % for the differential montage
StimNumber = 1;
NStims = 100;
GoodEpochIndex = true(1,NStims);            % this index is used to accept or reject epochs
NStimsRejected = 0;
Fs = 5e3;       % sampling rate in Hz
% FS = 8;
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
LeftControls = 0.8;
% RightControls = 0.001;
WidthControl = 0.17;
HeightControl = 0.027;      % starting top

% this is the plot area
Bottom = 0.02;
Height = 1-Bottom;
Left = 0.081;
Width = 0.7;
Ax = axes('parent',DataEpocher_fig,...
        'units', 'normalized',...
        'position', [Left Bottom Width Height]);
axis off

uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'find *.dat file',...
    'callback',@GetDataFile);    
    
% set/get the file where the *.dat file is
Top = Top-HeightControl;
dat_pathname = '/Users/dean/Documents/PhD/Probe Analysis/Compumedics Data/UBET_Probe_DAT';
dat_filename = '*.dat filename';        % declare this here to make it a global
dat_FileAndPath = [dat_pathname '/' dat_filename];
TextBox_dat_filename = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', dat_filename,...
    'backgroundcolor',ControlColor);

Top = Top-HeightControl;
FileNumber = num2str(0);
TextBox_dat_FileNumber = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', ['file number: ' FileNumber],...
    'backgroundcolor',ControlColor);

% this should be a mat file in the same folder
Top = Top-2*HeightControl;
uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'find *.mat file',...
    'callback',@GetMatFile);    
    
% set/get the file where the *.dat file is
Top = Top-2*HeightControl;
mat_pathname = '/Users/dean/Documents/PhD/Probe Analysis/Compumedics Data/UBET_Probe_DAT';
mat_filename = '*.mat filename';        % declare this here to make it a global
% mat_DataFileAndPath = [mat_pathname '/' mat_filename];
TextBox_mat_filename = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl 2*HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', mat_filename,...
    'backgroundcolor',ControlColor);

Top = Top-2*HeightControl;
uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'load data',...
    'callback',@LoadData); 

Top = Top-1*HeightControl;
DataStatusMessage = 'data not loaded';
DataStatusText = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', DataStatusMessage,...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
NSamplesText = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', '',...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
NChannelsText = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', '',...
    'backgroundcolor',ControlColor);

Top = Top-2*HeightControl;
uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'offset for plot (y axis)',...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
Offset = 0.3;                                           % initialise the offset
OffsetEntry = uicontrol('style','edit', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string',num2str(Offset),...
    'callback',@SetOffset);

Top = Top-2*HeightControl;
uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'maximum channel for plot',...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
MaxPlotChannel = 32;                                % initialize the number of channels to plot
MaxPlotChEdit = uicontrol('style','edit', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string',num2str(MaxPlotChannel),...
    'callback',@SetMaxPlotCh);

Top = Top-2*HeightControl;
uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl/2 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'pre-stim time',...
    'backgroundcolor',ControlColor);

uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls+WidthControl/2 Top WidthControl/2 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'post-stim time',...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
StartTime = 1;
TimeStartEntry = uicontrol('style','edit', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl/2 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string',num2str(StartTime),...
    'callback',@SetStartTime);

EndTime = 2;
TimeEndEntry = uicontrol('style','edit', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls+WidthControl/2 Top WidthControl/2 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string',num2str(EndTime),...
    'callback',@SetEndTime);

% view data to identify bad channels, need to be able to scroll through it
% this will be a file that is about 1GB in size
% view it in 10 second blocks
Top = Top-2*HeightControl;
uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'plot data',...
    'callback',@PlotData);   

Top = Top-1*HeightControl;
StimIndexDisplayString = ['stim ' num2str(StimNumber) ' of ' num2str(NStims) ' (0 rejected)'];
StimNumberTextBox = uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', StimIndexDisplayString,...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl/3 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'backward',...
    'callback',@StimBackward);   

StimRejectButton = uicontrol('style','togglebutton', ...
    'units', 'normalized', ...
    'position', [LeftControls+WidthControl/3 Top WidthControl/3 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'REJECT',...
    'callback',@StimReject);  

uicontrol('style','pushbutton', ...
    'units', 'normalized', ...
    'position', [LeftControls+2*WidthControl/3 Top WidthControl/3 HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'forward',...
    'callback',@StimForward);

% use a background high-lighter to show where stims occur

% use a tick box to identify bad channels
MaximumPossibleNChannels = 128;
NoiseyChTickBox = zeros(1,MaximumPossibleNChannels);
NoiseyChIndex = zeros(1,MaximumPossibleNChannels);
TickOffset = 2*Height/(4+MaxPlotChannel-1);
TickBoxesLeft = Left - 0.05;
TickBoxWidth = 0.1;
TickBoxHeight = HeightControl;
HeightOfTickBoxes = [linspace(Bottom+TickOffset,Bottom+Height-TickOffset,MaxPlotChannel)...
    -TickBoxHeight/2 -1*ones(1,MaximumPossibleNChannels-MaxPlotChannel)];

for nn=1:MaximumPossibleNChannels
    if nn <= MaxPlotChannel
        NoiseyChTickBox(nn) = uicontrol('style','checkbox',...
            'units', 'normalized', ...
            'position', [TickBoxesLeft HeightOfTickBoxes(nn) TickBoxWidth TickBoxHeight], ...
            'HorizontalAlignment','center', ...
            'parent', DataEpocher_fig, ...
            'string', ['Ch' num2str(nn)],...
            'callback',@TickBoxFunction);
    else
        NoiseyChTickBox(nn) = uicontrol('style','checkbox',...
            'units', 'normalized', ...
            'position', [TickBoxesLeft HeightOfTickBoxes(nn) TickBoxWidth TickBoxHeight], ...
            'HorizontalAlignment','center', ...
            'parent', DataEpocher_fig, ...
            'string', ['Ch' num2str(nn)],...
            'visible','off',...
            'callback',@TickBoxFunction);
    end
end

Top = Top-2*HeightControl;
uicontrol('style','text', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 'samples about stimulation',...
    'backgroundcolor',ControlColor);

Top = Top-1*HeightControl;
SamplesAboutStim = 6;                   % the number of samples to remove centerer at the stimulation
SamplesAboutStimEdit = uicontrol('style','edit', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string',num2str(SamplesAboutStim),...
    'callback',@SetSamplesAboutStim);

Top = Top-1*HeightControl;
RemoveStimArtifactButton = uicontrol('style','pushbutton', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string','remove stim artifact',...
    'callback',@RemoveStimArtifact);

Top = Top-1*HeightControl;
SmoothAndFilterButton = uicontrol('style','pushbutton', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string','smooth and filter',...
    'callback',@SmoothAndFilter);

Top = Top-1*HeightControl;
DecimateButton = uicontrol('style','pushbutton', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string','decimate',...
    'callback',@Decimate);

% move to differential reference
Top = Top-2*HeightControl;
RereferenceOnOff = 0;
RereferenceToggle = uicontrol('style','togglebutton', ...
    'units', 'normalized', ...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string', 're-reference',...
    'value',RereferenceOnOff,...
    'callback',@Rereference);

Top = Top-1*HeightControl;
uicontrol('style','pushbutton', ...
    'BackgroundColor', 'white', ...
    'units', 'normalized',...
    'position', [LeftControls Top WidthControl HeightControl], ...
    'HorizontalAlignment','center', ...
    'parent', DataEpocher_fig, ...
    'string','export pre-processed data',...
    'callback',@Decimate);

MaxDiffCombo = 150;             % maximum number of possible differential pairs
LabelOffset = 2*Height/(4+MaxDiffCombo-1);
HeightDiffCHLabel = linspace(Bottom+LabelOffset,Bottom+Height-LabelOffset,MaxDiffCombo)-TickBoxHeight/2;
for nn=1:MaximumPossibleNChannels
    DiffChannelLabels(nn) = uicontrol('style','text',...
        'units', 'normalized', ...
        'position', [TickBoxesLeft HeightDiffCHLabel(nn) TickBoxWidth TickBoxHeight], ...
        'HorizontalAlignment','center', ...
        'parent', DataEpocher_fig, ...
        'string', '',...
        'BackgroundColor', 'white',...
        'visible','off');
end

% ~~~~~~~~~~~~~~~~~~    
% here are the callback functions
% ~~~~~~~~~~~~~~~~~~

    function GetDataFile(varargin)
        [dat_filename dat_pathname] = uigetfile('*.dat','Pick a data (.dat) file',dat_pathname);
        dat_FileAndPath = [dat_pathname '/' dat_filename];
        set(TextBox_dat_filename,'string',dat_filename)
        files = dir(dat_pathname);
        files = files(3:end-1);
        length(files)
        for n=1:length(files)
            if strcmp(dat_filename,files(n).name)
                FileNumber = n;
            end
        end
        set(TextBox_dat_FileNumber,'string',['file number: ' num2str(FileNumber)])
    end

    function GetMatFile(varargin)
        [mat_filename mat_pathname] = uigetfile('*.mat','Pick the .mat file',dat_pathname);
        mat_FileAndPath = [mat_pathname '/' mat_filename];
        set(TextBox_mat_filename,'string',mat_filename)
        ProbeInfo = load(mat_FileAndPath);
        StartTimeOfDatFile = ProbeInfo.DataExportTimes(FileNumber,1);
        RelativeStimTimes = ProbeInfo.StimTime(FileNumber,:)-StartTimeOfDatFile;
        NStims = length(RelativeStimTimes(RelativeStimTimes>0));         % might need to make a conditipo 
        GoodEpochIndex = true(1,NStims);            % this index is used to accept or reject epochs
    end

    function LoadData(varargin)
        DataStatusMessage = 'loading data';
        set(DataStatusText,'string',DataStatusMessage)
        tic
        RawData = load(dat_FileAndPath);
        toc
%         t = RawData(:,1);
        RawData = RawData(:,2:end);          % need to change this to be specified
        NSamples = size(RawData,1);
        NChannels = size(RawData,2);
        set(NChannelsText,'string',['NChannels = ' num2str(NChannels)])
        set(NSamplesText,'string',['NSamples = ' num2str(NSamples)])
        DataStatusMessage = 'data loaded';
        set(DataStatusText,'string',DataStatusMessage)
%         disp('writing data')
%         assignin('base','RawData',RawData)
    end

    function SetEndTime(varargin)
        EndTime = str2double(get(TimeEndEntry,'string'));
    end
    
    function SetStartTime(varargin)
        StartTime = str2double(get(TimeStartEntry,'string'));
    end

    function SetOffset(varargin)
        Offset = str2double(get(OffsetEntry,'string'));
        PlotData()
    end

    function PlotData(varargin)
        
        StartPlotTime = floor(RelativeStimTimes(StimNumber)*Fs-(StartTime*Fs-1));
        EndPlotTime = floor((RelativeStimTimes(StimNumber)+EndTime)*Fs);
        NSamples4Plot = (EndTime+StartTime)*Fs;
        
        if RereferenceOnOff
            PlotChannels = 1:size(DiffElectrodeIndexes,1);
            NPlotChannels = length(PlotChannels);
            temp = zeros(NSamples4Plot,NPlotChannels);
            for n=1:NPlotChannels
                temp(:,n) = RawData(StartPlotTime:EndPlotTime,DiffElectrodeIndexes(n,1)) ...
                    - RawData(StartPlotTime:EndPlotTime,DiffElectrodeIndexes(n,2));
            end


        else
            % get the number of channels to plot
            PlotChannels = 1:MaxPlotChannel;
            NPlotChannels = length(PlotChannels);
            
            % take data window
            temp = RawData(StartPlotTime:EndPlotTime,PlotChannels);
        end
        
        % create the offset
        OffsetVector = 0:Offset:Offset*(NPlotChannels-1);
        OffsetMatrix = repmat(OffsetVector,NSamples4Plot,1);

        % demean data
        ZeroMeanRawData = temp - repmat(mean(temp,1),NSamples4Plot,1);       % make data zero mean

        OffsetData = ZeroMeanRawData+OffsetMatrix;
            
        % plot it
        if RereferenceOnOff
            plot(OffsetData,'k','parent',Ax)
        else
            plot(OffsetData(:,~NoiseyChIndex(1:NPlotChannels)),'k','parent',Ax), hold(Ax,'on')
            plot(OffsetData(:,logical(NoiseyChIndex(1:NPlotChannels))),'r','parent',Ax), hold(Ax,'off')
        end
        axis off
        yMin = -2*Offset;
        yMax = Offset*(NPlotChannels+1);
        ylim([yMin yMax])

        % draw a patch around the stimulation artifact
        xPatchStart = StartTime*Fs+3;
        xPatchEnd = StartTime*Fs+4 + SamplesAboutStim;
        patch([xPatchStart xPatchEnd xPatchEnd xPatchStart xPatchStart],[yMin yMin yMax yMax yMin],...
            'g','facealpha',0.5,'edgecolor','none')
        
    end

    function TickBoxFunction(varargin)
        for n=1:MaximumPossibleNChannels
            NoiseyChIndex(n) = get(NoiseyChTickBox(n),'value');
            % find out if channels is noisey
            % get the value of all the tick boxes
        end
        PlotData()
    end

    function StimBackward(varargin)
        if StimNumber > 1
            StimNumber = StimNumber-1;
        end
        if GoodEpochIndex(StimNumber)
            set(StimRejectButton,'backgroundcolor','white','value',0,'foregroundcolor','black')
        else
            set(StimRejectButton,'backgroundcolor','red','value',1,'foregroundcolor','red')
        end
        StimIndexDisplayString = ['stim ' num2str(StimNumber) ' of ' num2str(NStims) ' ( ' num2str(NStimsRejected) ' rejected)'];
        set(StimNumberTextBox,'string',StimIndexDisplayString)
        PlotData()
    end

    function StimReject(varargin)
        if logical(get(StimRejectButton,'value'))
            GoodEpochIndex(StimNumber) = false;
            set(StimRejectButton,'backgroundcolor','red','foregroundcolor','red')
            NStimsRejected = sum(~GoodEpochIndex);
            StimIndexDisplayString = ['stim ' num2str(StimNumber) ' of ' num2str(NStims) ' ( ' num2str(NStimsRejected) ' rejected)'];
            set(StimNumberTextBox,'string',StimIndexDisplayString)
        else
            GoodEpochIndex(StimNumber) = true;
            set(StimRejectButton,'backgroundcolor','white','foregroundcolor','black')
            NStimsRejected = sum(~GoodEpochIndex);
            StimIndexDisplayString = ['stim ' num2str(StimNumber) ' of ' num2str(NStims) ' ( ' num2str(NStimsRejected) ' rejected)'];
            set(StimNumberTextBox,'string',StimIndexDisplayString)
        end
    end

    function StimForward(varargin)
        if StimNumber < 100
            StimNumber = StimNumber+1;
        end
        if GoodEpochIndex(StimNumber)
            set(StimRejectButton,'backgroundcolor','white','value',0,'foregroundcolor','black')
        else
            set(StimRejectButton,'backgroundcolor','red','value',1,'foregroundcolor','red')
        end
        StimIndexDisplayString = ['stim ' num2str(StimNumber) ' of ' num2str(NStims) ' ( ' num2str(NStimsRejected) ' rejected)'];
        set(StimNumberTextBox,'string',StimIndexDisplayString)
        PlotData()
    end

    function SetMaxPlotCh(varargin)
        MaxPlotChannel = str2double(get(MaxPlotChEdit,'string'));
        
        % now need to adjust the tick boxes
        TickOffset = 2*Height/(4+MaxPlotChannel-1);

        HeightOfTickBoxes = [linspace(Bottom+TickOffset,Bottom+Height-TickOffset,MaxPlotChannel)-TickBoxHeight/2 -1*ones(1,MaximumPossibleNChannels-MaxPlotChannel)];

        for n=1:MaximumPossibleNChannels
            if n <= MaxPlotChannel
                
                set(NoiseyChTickBox(n),'position', [TickBoxesLeft HeightOfTickBoxes(n) TickBoxWidth TickBoxHeight], ...
                    'string', ['Ch' num2str(n)],...
                    'visible','on')
            else
                set(NoiseyChTickBox(n),...
                    'visible','off')
            end
        end
        PlotData()
    end

    function SetSamplesAboutStim(varargin)
        SamplesAboutStim = str2double(get(SamplesAboutStimEdit,'string'));
        PlotData()
    end

% this function needs to be called when the number of plot channels changes
% or the noisy channels change
    function Rereference(varargin)
        
        GoodElectrodeCombos = {};
        DiffElectrodeIndexes = [];
        
        RereferenceOnOff = get(RereferenceToggle,'value');
        if RereferenceOnOff == 1        % than it has been turned on or is on
            ElectrodeRows = 4;
            ElectrodeCols = 8;
            ElectrodeComboIndex = 1;                    % this index the list of good electrode combos
            AllElectrodes = 1:MaxPlotChannel; 
            GoodElectrodeCombos = {'0'};
            NoisyElectrodes = AllElectrodes(logical(NoiseyChIndex));
            for n=1:MaxPlotChannel

                if ~ismember(n,NoisyElectrodes)
                    for m=1:4

                        % find the differential montage in a clock-wise fashion
                        % from the right to bottom to left to top.

                        % need to know if there is an electrode to the right
                        % or if n is a multiple of ElectrodeCols

                        if m==1                                                 % electrode to the right
                            SecondElectrode = n+1;
                            % check if it is a good electrode
                            if ~ismember(SecondElectrode,NoisyElectrodes)
                                % check if we are on the left of the grid
                                if mod(n,ElectrodeCols)                         % this is zero if we are at the end of a row

                                    % check if electrode combo has been used
                                    ElectrodeCombo = [num2str(n) '-' num2str(SecondElectrode)];
                                    FlippedElectrodeCombo = [num2str(SecondElectrode) '-' num2str(n)];

                                    if (sum(strcmp(GoodElectrodeCombos,ElectrodeCombo)) == 0) ...
                                            && (sum(strcmp(GoodElectrodeCombos,FlippedElectrodeCombo)) == 0)

                                        % than we can use it
                                        GoodElectrodeCombos{ElectrodeComboIndex} = [num2str(n) '-' num2str(SecondElectrode)];
                                        DiffElectrodeIndexes(ElectrodeComboIndex,:) = [n, SecondElectrode];
                                        ElectrodeComboIndex = ElectrodeComboIndex+1;
                                    end
                                end
                            end

                        elseif m ==2                                        % electrode below
                            SecondElectrode = n+ElectrodeCols;
                            % check if it is a good electrode
                            if ~ismember(SecondElectrode,NoisyElectrodes)
                                % check if we are on the bottom of the grid
                                if n<=(ElectrodeRows-1)*ElectrodeCols                         % this is zero if we are at the bottom row

                                    % check if electrode combo has been used
                                    ElectrodeCombo = [num2str(n) '-' num2str(SecondElectrode)];
                                    FlippedElectrodeCombo = [num2str(SecondElectrode) '-' num2str(n)];

                                    if (sum(strcmp(GoodElectrodeCombos,ElectrodeCombo)) == 0) ...
                                            && (sum(strcmp(GoodElectrodeCombos,FlippedElectrodeCombo)) == 0)

                                        % than we can use it
                                        GoodElectrodeCombos{ElectrodeComboIndex} = [num2str(n) '-' num2str(SecondElectrode)];
                                        DiffElectrodeIndexes(ElectrodeComboIndex,:) = [n, SecondElectrode];
                                        ElectrodeComboIndex = ElectrodeComboIndex+1;
                                    end
                                end
                            end      

                        elseif m ==3                                        % electrode left
                            SecondElectrode = n-1;
                            % check if it is a good electrode
                            if ~ismember(SecondElectrode,NoisyElectrodes)
                                % check if we are on the left of the grid
                                if mod(n-1,ElectrodeCols)                         % this is zero if we are at the bottom row

                                    % check if electrode combo has been used
                                    ElectrodeCombo = [num2str(n) '-' num2str(SecondElectrode)];
                                    FlippedElectrodeCombo = [num2str(SecondElectrode) '-' num2str(n)];

                                    if (sum(strcmp(GoodElectrodeCombos,ElectrodeCombo)) == 0) ...
                                            && (sum(strcmp(GoodElectrodeCombos,FlippedElectrodeCombo)) == 0)

                                        % than we can use it
                                        GoodElectrodeCombos{ElectrodeComboIndex} = [num2str(n) '-' num2str(SecondElectrode)];
                                        DiffElectrodeIndexes(ElectrodeComboIndex,:) = [n, SecondElectrode];
                                        ElectrodeComboIndex = ElectrodeComboIndex+1;
                                    end
                                end
                            end
                        elseif m == 4                                        % electrode above
                            SecondElectrode = n-ElectrodeCols;
                            % check if it is a good electrode
                            if ~ismember(SecondElectrode,NoisyElectrodes)
                                % check if we are on the left of the grid
                                if n>ElectrodeCols                         % this is zero if we are at the bottom row

                                    % check if electrode combo has been used
                                    ElectrodeCombo = [num2str(n) '-' num2str(SecondElectrode)];
                                    FlippedElectrodeCombo = [num2str(SecondElectrode) '-' num2str(n)];

                                    if (sum(strcmp(GoodElectrodeCombos,ElectrodeCombo)) == 0) ...
                                            && (sum(strcmp(GoodElectrodeCombos,FlippedElectrodeCombo)) == 0)

                                        % than we can use it
                                        GoodElectrodeCombos{ElectrodeComboIndex} = [num2str(n) '-' num2str(SecondElectrode)];                                    
                                        DiffElectrodeIndexes(ElectrodeComboIndex,:) = [n, SecondElectrode];
                                        ElectrodeComboIndex = ElectrodeComboIndex+1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        
        % here we need to set the channel labels for diff if the button is down
            for n=1:MaximumPossibleNChannels
                set(NoiseyChTickBox(n),'visible','off');
            end
            MaxDiffCombo = length(GoodElectrodeCombos);
            LabelOffset = 2*Height/(4+MaxDiffCombo-1);
            HeightDiffCHLabel = linspace(Bottom+LabelOffset,Bottom+Height-LabelOffset,MaxDiffCombo)-TickBoxHeight/2;
            for n=1:MaxDiffCombo
                set(DiffChannelLabels(n),'string',GoodElectrodeCombos{n},...
                    'position',[TickBoxesLeft HeightDiffCHLabel(n) 0.03 TickBoxHeight/2],...
                    'visible','on',...
                    'BackgroundColor', 'white',...
                    'fontsize',8)
            end
            PlotData()
        else  
            
        % if the button is up we need to set the labels to the tick boxes
            for n=1:MaxDiffCombo
                set(DiffChannelLabels(n),...
                    'visible','off')
            end
            for n =1:MaxPlotChannel
                set(NoiseyChTickBox(n),'visible','on')
            end
            PlotData()
        end
    end

    function RemoveStimArtifact(varargin)
        disp('dont press twice')
        Samples2Remove = [];
        for n=1:length(RelativeStimTimes)
            Samples2Remove = [Samples2Remove floor(RelativeStimTimes(n)*Fs+3:RelativeStimTimes(n)*Fs+3+SamplesAboutStim)];
        end
        
        AllIndexes = 1:NSamples;
        GoodIndexes = ~ismember(AllIndexes,Samples2Remove);         % this is a logical to index good samples
        for n=1:NChannels
            GoodDataPoints = RawData(GoodIndexes,n);
            IndexesOfGoodDataPoints = AllIndexes(GoodIndexes);
            RawData(:,n) = interp1(IndexesOfGoodDataPoints, GoodDataPoints, AllIndexes);
        end
        set(RemoveStimArtifactButton,'visible','off')
        PlotData()
    end

    function SmoothAndFilter(varargin)
        
        % first smooth data using a moving average filter
        WindowSize = 5;
        tic
        for n=WindowSize+1:NSamples
            RawData(n,:) = mean(RawData(n-WindowSize:n,:),1);
        end
        toc
        LPFilterOrder = 100;
        LPFiltCutOff = 100;     % Hz
        Wn = LPFiltCutOff/(Fs/2);
        b = fir1(LPFilterOrder,Wn);
        
        RawData = flipud(filtfilt(b,1,flipud(RawData)));
        
        set(SmoothAndFilterButton,'visible','off')

        PlotData()
    end

    function Decimate(varargin)
        RawData = RawData(1:5:NSamples,:);
        Fs = 1e3;
        set(DecimateButton,'visible','off')
        PlotData()
    end
        
end