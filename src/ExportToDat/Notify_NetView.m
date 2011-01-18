% --------------------------------------------------------------------
% Notify
% An event from the device driver

% NOTIFY_CONNECTED              1   // not currently used
% NOTIFY_DATA                   2   // a data packet is ready
% NOTIFY_CONNECTED_NO_CONFIG	3	// device has connected, requesting configuration
% NOTIFY_IMPEDANCE_READY        4   // impedance data is ready
% NOTIFY_LOST_PKTS              5   // data packets have been lost
function Notify_NetView(varargin)

global gInterface                  % global pointer to the COM Device Interface
global gInterfaceExt               % global pointer to the COM Device Interface Extensions.
global gBlocksPerSecond            % SynAmps2 has 10 blocks per second, i.e. sends 0.1s chunks of data.
global gSamplesPerChannelPerBlock  % array of samples per channel per data block
global gDisplayData                % global for storing current data to be displayed
global gbDataReady                 % flag to stop re-display of same data, set to true after new data has arrived
global gSampleRate                 % global specification of the sample rate.
%--------------------------------------------------------------------------
global gUpdateCount % These parameters are used to accumulate the 0.1 s of
global gAccumCount  % data chunks that NetView sends to Matlab into 0.5 s
global gAccumData   % data segments.
global gCellData
global gBuffer      % global declaration for the double buffer index.
%--------------------------------------------------------------------------
global gChannelsRequired           % Global specification for the total number of device channels.
global gTotalChannels              % stores the total number of device channels
global gStrConfigFile              % Global declaration of the configuration file name.

switch varargin{3}  % nEvent
    case 1  % NOTIFY_CONNECTED
        disp('NOTIFY_CONNECTED');
        % not used yet
    case 2  % NOTIFY_DATA
%         tic
        % data is ready to be retrieved from the device
        deviceData = invoke(gInterfaceExt, 'ReadDataEx');
%         toc_Notify = toc;
%         disp('toc_Notify=')
%         disp(toc_Notify)
        % data is an array of floats.
        % The array contains one 'block' of data.  Each block
        % represents a fraction of a second, the call BloackPerSecond
        % tells how many of these blocks make up one second's worth of
        % data.
        % All channels with a sample rate greater than 0 are present
        % sequentially in the array, ie: all the samples representing
        % Channel 1 are at the start of the array, followed by all the
        % samples for channel 2, ...
        % the number of samples for each channel is determined by:
        % Sample_rate_of_channel / blocks_per_second

        % Split the array into individual channel components.
        if length(deviceData) == gTotalChannels * gSamplesPerChannelPerBlock + 1 % Just to check that the correct amount of data points has been received.
%             disp(length(deviceData))
            for m = 1:size(gChannelsRequired,2)
                start_sample = 2 + (gChannelsRequired(1,m) - 1) * gSamplesPerChannelPerBlock; % Start at index 2, because the first element is the duration of the array (not always implemented as it is not essential).
                end_sample = gChannelsRequired(1,m) * gSamplesPerChannelPerBlock + 1;
                gAccumData(:,m) = deviceData(start_sample:end_sample)';
            end
        else
            disp('An incorrect amount of data points was received.')
            disp(['Expecting a total number of ' num2str(gTotalChannels) ' device channels,'])
            disp(['sample rate of ' num2str(gSampleRate) ' Hz,'])
            disp('at 10 blocks per second (i.e. 0.1 s chunks of data) for SynAmps2:')
            disp(['( ' num2str(gTotalChannels) ' x ' num2str(gSampleRate) ' / 10 ) + 1 = ' num2str(gTotalChannels * gSamplesPerChannelPerBlock + 1) ' sample points per data ready cycle.'])
            disp('which should equal to length(deviceData) =')
            disp(length(deviceData))
            disp('gChannelsRequired =')
            disp(size(gChannelsRequired,2))
        end
        %------------------------------------------------------------------
        % Accumulate the 0.1 s worth of data to make up the update data
        % width, for example, 0.5 s window would correspond to 5
        % cycles of data accumulation.
        gCellData{gAccumCount,gBuffer} = gAccumData;
        if gAccumCount < gUpdateCount
            gAccumCount = gAccumCount + 1;
        elseif gAccumCount == gUpdateCount
            gAccumCount = 1;
            gDisplayData = cell2mat(gCellData(:,gBuffer));
            % new data is now ready for display
            gbDataReady = true;
            if gBuffer == 1
                gBuffer = 2;
            elseif gBuffer == 2
                gBuffer = 1;
            end
%             toc_AccumData = toc;
%             disp('toc_AccumData=')
%             disp(toc_AccumData)
%             tic
%             disp('Size of gDisplayData=')
%             disp(size(gDisplayData))
        end
        %------------------------------------------------------------------
    case 3  % NOTIFY_CONNECT_NO_CONFIG
        % device has connected, but needs to be configured.
        % send it a configuration XML string or loop through all the
        % Channel objects and configure them individually
%         device = gServer.invoke('ICmpDevice');

        % open the configuration file - should add a GUI to allow user
        % to select file
        %             global strConfigFile;
%         strConfigFile = 'SynAmps2_5kHz.xml';
        [fileConfig, message] = fopen(gStrConfigFile, 'r');
        if(fileConfig < 0)
            disp(message);
        else
            % read in the string
            strConfiguration = '';
            while feof(fileConfig) == 0
                tline = fgetl(fileConfig);
                % concatenate the strings
%                 strConfiguration = [strConfiguration, tline];
                strConfiguration = cat(2,strConfiguration,tline);
            end

            % send the configuration to the device
            disp('Sending configuration...')
%             device.Configuration = strConfiguration;
            gInterface.Configuration = strConfiguration;
            
            % Specify the setup information: sample rates,
            % blockspersecond...
            gBlocksPerSecond = 10; % SynAmps2 has 10 blocks per second, i.e. sends 0.1s chunks of data.
            gDisplayData = [];
            gSamplesPerChannelPerBlock = gSampleRate/gBlocksPerSecond; % Sample rate / gBlocksPerSecond

            % and finally, enable the data stream
            invoke(gInterface, 'EnableData', true);
            
            % Initialise the accumulation counter.
            gAccumCount = 1;
            gCellData = cell(gUpdateCount,2);
            gAccumData = zeros(gSamplesPerChannelPerBlock,size(gChannelsRequired,2));
            gBuffer = 1; % Initialise to buffer 1 for storing data.
            
            % close the file handle
            fclose(fileConfig);
        end
    case 4  % NOTIFY_IMPEDANCE_READY
        disp('NOTIFY_IMPEDANCE_READY')
    case 5 % NOTIFY_LOST_PKTS
        disp('NOTIFY_LOST_PKTS')
    otherwise   % error, don't know what to do with other types
end
%end % OnNotify

