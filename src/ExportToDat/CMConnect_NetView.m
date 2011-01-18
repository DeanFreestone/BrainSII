function CMConnect_NetView(IPAddress,SampleRate,DecFactor,UpdateWindowInSeconds,ChannelsRequired,TotalChannels,StrConfigFile)
% hObject    handle to FileMenu_Connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global gServer           % Global COM object.
global gInterface        % Gloabl pointer to the COM Interface Device.
global gInterfaceExt     % Global pointer to the COM interface Device Extensions.
global gSampleRate       % Global specification for the sampling rate.
global gDecFactor        % Global specification for the decimation factor.
global gUpdateCount      % Number of counts to accumulate the 0.1 s data to the size of "UpdateWindowInSeconds'.
global gChannelsRequired % Global specification for the channels required.
global gTotalChannels    % Global specification for the total number of device channels.
global gStrConfigFile    % Global declaration of the configuration file name.

gSampleRate = SampleRate;
gDecFactor = DecFactor;
gUpdateCount = UpdateWindowInSeconds/0.1;
gChannelsRequired = ChannelsRequired; % 1 row by n channels of columns.
gTotalChannels = TotalChannels;
gStrConfigFile = StrConfigFile; % gStrConfigFile = 'SynAmps2_5kHz.xml';

% the Device Interface to connect to:
%     strSiestaDevice = 'CMSiestaDev.CmpDevice';
%     strESeriesDevice = 'CMThunda.CmpDevice';
%     strSynamp2Device = 'CMSynamp2.CmpDevice';
%     strSimulatorDevice = 'CMSimDev.CmpDevice';
strNetViewDevice = 'CMNetView.CmpDevice';

% Instantiate the device object - made global so event Notify can use it.
gServer = actxserver(strNetViewDevice);

%----------------------------------------------------------------------
ServerEv = gServer.events; % Lists all the gServer events.
disp(ServerEv)
%----------------------------------------------------------------------

% register for event notifications
registerevent(gServer, 'Notify_NetView')

%----------------------------------------------------------------------
ServerRegEv = gServer.eventlisteners; % Just to check that the DataReady event has been registered.
disp(ServerRegEv)
%----------------------------------------------------------------------

% Connect to the specific device, but only if a connect string has been supplied.
% The connection String is different for different device types, example:

% 	% Siesta: IP address serial no. (space separated)
% 	strSiestaConnect = '10.255.0.102 2146';
%
% 	% E-Series: Serial no.
% 	strESeriesConnect = '397';
%
% 	% Synamp2 - no connection string required
% 	strSynamp2Connect = '';

% NetView:
% App has asked to connect to a remote device.
% The connect string contains the IP address of the device and the document id
% bstrConnectDevice =	"xxx.xxx.xxx.xxx  y"
%						eg "10.0.0.2 1"
%	xx	IP address
%	y	document id
strNetViewConnect = [IPAddress ' 1'];

% connect
gInterface = gServer.invoke('ICmpDevice');
invoke(gInterface, 'Connect', strNetViewConnect);
gInterfaceExt = gServer.invoke('ICmpDeviceExtensions');

% end FileMenu_Connect_Callback