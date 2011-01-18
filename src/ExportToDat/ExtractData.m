function ExtractData
% This m file was written to extract all the data corresponding to the
% probing.

clear;clc;
clear global
format long g
CMDisconnect_ProFusionEEG4;
% CompumedicsFolder = uigetdir('CompumedicsRootDir', 'Pick the Recorded Data Folder');
load TriggerInfo
disp('Number of probing sessions found:')
disp(['size(TriggerInfo,1) = ' num2str(size(TriggerInfo,1))])
[Fs, NChs, NumDataSegs, SegStartTime, SegDurn, StartDateTime, StudyLength] = CMConnect_ProFusionEEG4(CompumedicsFolder);

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
FileStartTime_in_secs = hh*3600 + mm*60 + ss;

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


SearchDuration = 4;      % 4 seconds.
ProbeDuration = 300;     % 3 seconds by 100 probes.
DecFactor = 1;           % No decimation.

ExtractDataDuration = ProbeDuration+2*SearchDuration; % i.e., 300 + 2*4;
ExtractLoops = ExtractDataDuration/SearchDuration;    % 308/4 = 77;
SearchSamples = SearchDuration*Fs;                    % 4*5000 = 20000;
for TriggersFoundIndex = 1:size(TriggerInfo,1)               % Go through all the "first markers" found.
    TimeVector = ((0:ExtractDataDuration*Fs-1)/Fs)';
    Data = [TimeVector, zeros(ExtractDataDuration*Fs,NChs)]; % Initialise data matrix - 300 seconds by NChs channels.
    for ExtractIndex = 1:ExtractLoops;                       % Accumulate 4 seconds worth of data until there is 308 seconds worth.
        [FsDec x] = Get_Data_ProFusionEEG4(1:NChs,TriggerInfo(TriggersFoundIndex,1)+(ExtractIndex-1)*SearchDuration,SearchDuration,DecFactor,true);
        if isempty(x)
            x = zeros(SearchSamples,NChs);
        end
        Data(1+(ExtractIndex-1)*SearchSamples:ExtractIndex*SearchSamples,2:end) = x * 1000; % Dean wants the data in uV.
    end
    % datestr
    % dateform 0 'dd-mmm-yyyy HH:MM:SS' without dashes and colons
    FirstTriggerTime_in_secs = TriggerInfo(TriggersFoundIndex,1) + FileStartTime_in_secs;
    [Day Hrs Mins Secs] = ConvertTime_Sec_To_DHHMMSS(FirstTriggerTime_in_secs);
    DataString = [sprintf('%02.f',DD+Day) Months{MM} num2str(YY) sprintf('%02.f',Hrs) sprintf('%02.f',Mins) sprintf('%02.f',Secs) '.dat'];
    dlmwrite(DataString,Data,'precision',20) % For some reason, dlmwrite introduces error into the TimeVector, e.g. 0.0006 becomes 0.0005999999999999990.

end
end
function [Day Hrs Mins Secs] = ConvertTime_Sec_To_DHHMMSS(Time_in_sec)
Day = floor(Time_in_sec/86400);                      % Day
Hrs = floor((Time_in_sec-Day*86400)/3600);           % Hours
Mins = floor((Time_in_sec-Day*86400-Hrs*3600)/60);   % Minutes
Secs = Time_in_sec - Day*86400 - Hrs*3600 - Mins*60; % Seconds
end
