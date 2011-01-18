function [SampleRate, TotalChs, NumDataSegs, SegStartTime, SegDurn] = CMConnect_ProFusionEEG4(FilePath)

global gIStudy DataReader gSampleRate gTotalChs
%--------------------------------------------------------------------------
% Load Study Interface (ACTUALLY, it is a COM Server in Matlab, not an
% interface).
gIStudy = actxserver('CMEEGStudyV4.Study');
%--------------------------------------------------------------------------
% Open the study.
gIStudy.Open(FilePath,0) % File path name, e.g., 'C:\Documents and Settings\Administrator\Desktop\ProFusionEEG4SDKForPersyst\DemoStudies\Demo.eeg'.
%--------------------------------------------------------------------------
% Determine the sampling rate and the number of channels in the study.
SampleRate = gIStudy.get('EEGSampleRate');
gSampleRate = SampleRate;
IChannels = gIStudy.get('Channels');
TotalChs = IChannels.count;
clear IChannels
gTotalChs = TotalChs;
%--------------------------------------------------------------------------
% Determine how many data segments there are in the study.
IDataSegs = gIStudy.get('DataSegments');
NumDataSegs = IDataSegs.count; % A data segment is like a 'Block' in TDT.
% The data segments' start times are all referenced to a single time point.
% That is, the second data segment's start time is always later than the
% first data segment's start time plus the first data segment's duration.
%--------------------------------------------------------------------------
% Create the Data Reader (Interface).
DataReader = gIStudy.CreateDataReader;
%--------------------------------------------------------------------------
% Determine the start time and duration for each data segment.
SegStartTime = zeros(NumDataSegs,1);
SegDurn = zeros(NumDataSegs,1);
for IndexSeg = 1:NumDataSegs  % A data segment is sort of like a 'Block' in TDT.
    ISeg = IDataSegs.Item(IndexSeg);
    SegStartTime(IndexSeg) = ISeg.Time;
    SegDurn(IndexSeg) = ISeg.Duration;
end
clear IDataSegs IndexSeg ISeg