% this is the function to use to export the probing data from the
% Compumedics files!! DF 12/11/10
function ExtractProbeData(varargin)
% This m file was written to export all the probing data.

% SkipSegment = varargin(1);
%--------------------------------------------------------------------------
% Connect to the Compumedics data file.
clear;clc;
clear global
format long g
CMDisconnect_ProFusionEEG4;
CompumedicsFolder = uigetdir('CompumedicsRootDir', 'Pick the Recorded Data Folder');
[Fs, NChs, NumDataSegs, SegStartTime, SegDurn, StartDateTime, StudyLength] = CMConnect_ProFusionEEG4(CompumedicsFolder);
Ts = 1/Fs;
disp('Number of channels =')
disp(NChs)
disp('Number of data segments =')
disp(NumDataSegs)
disp('Segment start times =')
disp(SegStartTime)
disp('Segment durations =')
disp(SegDurn)
disp('Start date time =')
disp(StartDateTime)
disp('Study length =')
disp(StudyLength)
% pause
%--------------------------------------------------------------------------
% Initialisation.
% Specify the search duration, decimation factor, bipolar channel and
% trigger channel.
SearchDuration = 4;      % 4 seconds.
DecFactor = 1;           % No decimation.

BipolarCh = 65;        
% BipolarCh = 129:137;        % this channel is used to find the stims whtat channels
% TriggerCh = 37;
DataExportTimes = [];        % Initialise with empty array.
DataExportTimesIndex = 0;    % Initialise as 0 to correspond to the above line.
LowerThreshold = 0.1;    % Lower threshold for detecting stims.
UpperThreshold = 0.22;   % Upper threshold for detecting stims.
FirstStimFound = false;

ThreeQuarterSearchDurSamples = 3/4*SearchDuration*Fs;
OneQuarterSearchDur = SearchDuration/4;
m = 0; % Indexes stimulations inside a particular train (of 100 for example).
k = 1; % Indexes trains.

%--------------------------------------------------------------------------
% Go through the data in "SearchDuration" epochs to find the stims.
for SegIndex = 1:NumDataSegs % Go through all the data segments. Ideally, the Compumedics data set should only have 1 data segment.
    
%     if any(SkipSegment == SegIndex)
%         continue
%     end
    disp(['SegIndex = ' num2str(SegIndex)]) 

    % SearchDuration = 4 s, SegDurn(SegIndex) = duration of time in seconds
    % this is the number of loops required for the segment
    DataLoops = floor(SegDurn(SegIndex)/SearchDuration);        
    for DataLoopsIndex = 1:DataLoops
        disp(DataLoopsIndex)
        % Find the "first probe".
        
        StartTime = SegStartTime(SegIndex)+(DataLoopsIndex-1)*SearchDuration;
        EndTime = StartTime + SearchDuration;
        
        [FsDec x] = Get_Data_ProFusionEEG4(BipolarCh,StartTime,SearchDuration,DecFactor,true);

%         [FsDec x] = Get_Data_ProFusionEEG4([BipolarCh TriggerCh],SegStartTime(SegIndex)+(DataLoopsIndex-1)*SearchDuration,SearchDuration,DecFactor);
%         % Plot the bipolar and trigger channels.
%         figure(1);
%         ax(1) = subplot(2,1,1);

%         ax(2) = subplot(2,1,2);
%         plot(x(:,2));
%         ylim([0 10e3])
%         linkaxes(ax,'x');
%         pause;

        % Define time vector.
        t = StartTime:Ts:EndTime-Ts;
%         t = linspace(StartTime, EndTime, length(x));

%         plot(t,detrend(x))
%         drawnow
%         pause
        % Look for stims.
        StimIndexes = (x > LowerThreshold) & (x < UpperThreshold);
%         StimIndexes = sum(StimIndexes,2);
%         StimIndexes = StimIndexes>0;
        StimsFound = t(StimIndexes);
        
        if ~isempty(StimsFound) % #####CASE 1##### Stims are found.
            
            disp('Stims found')
            
            % First stim in window is:
            m = m + 1;
            
            % because the stim freq is ~0.33 Hz there will only be 1 stim
            % in the 4 second window. Therefore, the first threshold
            % crossing can be used as the timestamp.
            StimTime(k,m) = StimsFound(1); % Trains correspond to rows and stims correspond to columns.
            
            if ~FirstStimFound % If FirstStimFound is false (i.e, haven't found the first stim yet), then store the "First Stim".
                DataExportTimesIndex = DataExportTimesIndex + 1; % Increment the DataExportTimes array index and then store the trigger time info.
                DataExportTimes(DataExportTimesIndex,1) = StimTime(k,m);
            end
            
            FirstStimFound = true;          % set the flag high that stims were found

            % Check if it is possible to have any other stims in the window.
            if (StimsFound(1)-t(1)) < OneQuarterSearchDur % If the stim is found less than a quarter of the "SearchDuration" from the start of the epoch.
                % Then it is possible there is another stim in the epoch
                % (in the last quarter of the epoch).
                x2 = x(ThreeQuarterSearchDurSamples:end);
                t2 = t(ThreeQuarterSearchDurSamples:end);
                % Look for a trigger in x2 (second stim).
                StimsFound = t2((x2 > LowerThreshold) & (x2 < UpperThreshold));
                if ~isempty(StimsFound) % Then there is a second stim found.
                    m = m + 1;
                    StimTime(k,m) = StimsFound(1); % Trains correspond to rows and stims correspond to columns.
                end
            end
            
            if DataLoopsIndex == DataLoops % #####CASE 2##### Stims are found AND end of data segment.
                DataExportTimes(DataExportTimesIndex,2) = StimTime(k,m); % No need to increment the DataExportTimes array index, because it is on the same row as the "First Stim".
                FirstStimFound = false;
                m = 0;     % Reset trigger index.
                k = k + 1; % Increment train index.
            end
        
        % stims are not found but firststimfound is true therefore the last window had a stim!    
        elseif FirstStimFound % #####CASE 3##### Stims are not found AND FirstStimFound is TRUE
            % If FirstStimFound is true, then store the "Last Stim".
            DataExportTimes(DataExportTimesIndex,2) = StimTime(k,m); % No need to increment the DataExportTimes array index, because it is on the same row as the "First Stim".
            FirstStimFound = false;
            m = 0;     % Reset trigger index.
            k = k + 1; % Increment train index.
        end
    end
end

% remove the data export times that dont have enough stims in them
% these triggers are most likely to be caused from therapies

StimTimeGreaterThanZero = StimTime>0;
NStimsPerRun = sum(StimTimeGreaterThanZero,2);
NStimsPerRunRequired = 50;
GoodStimRun = NStimsPerRun >= NStimsPerRunRequired;

DataExportTimes = DataExportTimes(GoodStimRun,:);
StimTime = StimTime(GoodStimRun,:);


save(['ProbeInfo_' CompumedicsFolder(findstr(CompumedicsFolder,'\')+1:findstr(CompumedicsFolder,'.eeg')-1)],'DataExportTimes','StimTime','CompumedicsFolder')

% Go through "DataExportTimes" to make sure that "SearchDuration" seconds
% before the "First Stim"  and "SearchDuration" seconds after the "Last
% Stim" is not in between data segments. For example,
% DataSegmentTimes = [51.978 1959.778;
%                   1960.856 3437.856;
%                   6364.456 7628.056];
% DataExportTimes = [231.978  527.978;
%               6364.456 5628.456];
% The second set of stims (6364.456 5628.456) is right at the start of the
% third data segment (6364.456 7628.056), so it is not possible to get the
% "SearchDuration" seconds worth of data prior to the stims.
DataSegmentTimes = [SegStartTime SegStartTime+SegDurn];
for n = 1:size(DataExportTimes,1)
    for m = 1:size(DataSegmentTimes,1)
        if (DataExportTimes(n,1) - SearchDuration) >= DataSegmentTimes(m,1) && (DataExportTimes(n,1)-SearchDuration) <= DataSegmentTimes(m,2)
            DataExportTimes(n,1) = DataExportTimes(n,1)-SearchDuration;
        end
        if (DataExportTimes(n,2)+SearchDuration) >= DataSegmentTimes(m,1) && (DataExportTimes(n,2)+SearchDuration) <= DataSegmentTimes(m,2)
            DataExportTimes(n,2) = DataExportTimes(n,2)+SearchDuration;
        end
    end
end
ExportData

    function ExportData(varargin)
        %--------------------------------------------------------------------------
        % Work out the date string as dateform 0 'dd-mm-yyyy HH:MM:SS' without
        % dashes and colons.
        disp('Number of probing sessions found:')
        disp(['size(DataExportTimes,1) = ' num2str(size(DataExportTimes,1))])

        Dashes = strfind(StartDateTime,'/');
        Spaces = strfind(StartDateTime,' ');
        Colons = strfind(StartDateTime,':');
        AMorPM = strfind(StartDateTime,'M');
        DD = StartDateTime(1:Dashes(1)-1);
        MM = StartDateTime(Dashes(1)+1:Dashes(2)-1);
        YY = StartDateTime(Dashes(2)+1:Spaces(1)-1);
        hh = StartDateTime(Spaces(1)+1:Colons(1)-1);
        mm = StartDateTime(Colons(1)+1:Colons(2)-1);
        ss = StartDateTime(Colons(2)+1:Spaces(2)-1);
        
        AMorPMSwitch = StartDateTime(AMorPM-1:AMorPM);
        
        DD = str2double(DD);
        MM = str2double(MM);
        Months = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
        YY = str2double(YY);
        hh = str2double(hh);
        if strcmp(StartDateTime(AMorPM-1),'P')
            hh = hh + 12;
        end
        mm = str2double(mm);
        ss = str2double(ss);
        switch AMorPMSwitch
            case 'AM'
                FileStartTime_in_secs = hh*3600 + mm*60 + ss;
            case 'PM'
                FileStartTime_in_secs = (hh+12)*3600 + mm*60 + ss;
        end
                

        %--------------------------------------------------------------------------
        % Determine the data duration that has to be extracted and the consequent
        % number of loops to cycle through based on the "SearchDuration".
        ExtractDataDuration = DataExportTimes(:,2) - DataExportTimes(:,1) + (2 * SearchDuration); % i.e., "Last stim" - "First stim" + (2 * SearchDuration).
        ExtractLoops = ExtractDataDuration./SearchDuration;
        SearchSamples = SearchDuration * Fs;
        
        %--------------------------------------------------------------------------
        % Go through all the trigger times found and get "SearchDuration" seconds
        % of data at a time to build up to a data array from the "First stim" to
        % the "Last stim". E.g., Get 4 seconds of data at a time to build up a
        % probing session data array. Write the data array to an ASCII-delimited
        % file.
        for DataExportIndex = 1:size(DataExportTimes,1)               % Go through all the "first stims" found.
            
            % bits for the filename
            % datestr
            % dateform 0 'dd-mmm-yyyy HH:MM:SS' without dashes and colons
            FirstTriggerTime_in_secs = DataExportTimes(DataExportIndex,1) + FileStartTime_in_secs;
            [Day Hrs Mins Secs] = ConvertTime_Sec_To_DHHMMSS(FirstTriggerTime_in_secs);
            DataString = [sprintf('%02.f',DD+Day) Months{MM} num2str(YY) sprintf('%02.f',Hrs) sprintf('%02.f',Mins) sprintf('%02.f',Secs) '.dat'];
            
            TimeVector = ((0:round(ExtractDataDuration(DataExportIndex)*Fs-1))/Fs)';
%             z1 = zeros(round(ExtractDataDuration(DataExportIndex)*Fs),NChs);
%             Data = [TimeVector, z1]; % Initialise data matrix - 300 seconds by NChs channels.
            
            for ExtractIndex = 1:ExtractLoops(DataExportIndex);   % Accumulate 4 seconds worth of data until there is 308 seconds worth.
                [FsDec x] = Get_Data_ProFusionEEG4(1:NChs,DataExportTimes(DataExportIndex,1)+(ExtractIndex-1)*SearchDuration,SearchDuration,DecFactor,false);
                if isempty(x) % This catches data between data segments and just insert zeros into the data array.
                    x = zeros(SearchSamples,NChs);
                end
                
                AppendStartIndex = 1+(ExtractIndex-1)*SearchSamples;
                AppendEndIndex = ExtractIndex*SearchSamples;
                
%                 Data(AppendStartIndex:AppendEndIndex,2:end) = x * 1000; % Dean wants the data in uV.
                
                Data = [TimeVector(AppendStartIndex:AppendEndIndex) x*1000];
                
                dlmwrite(DataString,Data,'-append','precision',20)
            end
            

%             dlmwrite(DataString,Data,'precision',20) % For some reason, dlmwrite introduces error into the TimeVector, e.g. 0.0006 becomes 0.0005999999999999990.
%             clear Data
        end
    end
end
function [Day Hrs Mins Secs] = ConvertTime_Sec_To_DHHMMSS(Time_in_sec)
Day = floor(Time_in_sec/86400);                      % Day
Hrs = floor((Time_in_sec-Day*86400)/3600);           % Hours
Mins = floor((Time_in_sec-Day*86400-Hrs*3600)/60);   % Minutes
Secs = Time_in_sec - Day*86400 - Hrs*3600 - Mins*60; % Seconds
end



% % % % init
% % % flag = 0;
% % % 
% % % 
% % % % start loop
% % % 
% % % 
% % % m=1;  % indexes stimulations inside a particular train (of 100 for example)
% % % k     % indexes trains
% % % 
% % % % read in window of 4 s
% % % % x is the window BP 1 channel (probe trigger)
% % % x = % window
% % % 
% % % % define time vector
% % % t = linspace(StartTime, EndTime, length(x));
% % % 
% % % % look for stims
% % % y = t((x>0.1)&&(x <0.22));
% % % 
% % % if ~isempty(y)              % then there is a stim found
% % %     
% % %     % first stim in window is
% % %     StimTime(m) = t(1);
% % %     m = m+1;
% % %     
% % %     if flag == 0
% % %         FirstStim = StimTime(m);
% % %     end
% % %     
% % %     flag = 1;
% % %     
% % %     
% % %     % check if it is possible to have any other stims in the window
% % %     if t(1) < 1
% % %         
% % %         % then it is possible there is another stim in the window
% % %         x2 = x(3*Fs:end);
% % %         t2 = t(3*Fs:end);
% % %         
% % %         % lookfor a trigger in x2 (second stim
% % %         y = t2((x2>0.1)&&(x2<0.22));
% % %         
% % %         if ~isempty(y)              % then there is a second stim found
% % %             
% % %             StimTime(m) = t2(1);
% % %             m = m+1;
% % %             
% % %         end
% % %         
% % %     end
% % %     
% % % elseif (flag == 1) || (EndOfFile == 1)
% % %     
% % %     flag = 0;
% % %     LastStim = StimTime(m);
% % %     
% % %     % export train into .dat
% % %     
% % %     
% % %     
% % % end