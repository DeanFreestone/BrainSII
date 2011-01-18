function [FsDec DataChDec Error] = Get_Data_ProFusionEEG4(ChsReq,StartTime,Duration,DecFactor,InterpExtrap)

global DataReader gSampleRate gTotalChs gSegDataTime
%--------------------------------------------------------------------------
% Check that the user has not requested more data than the data reader
% limit. % The limit was set at 10,000,000 in CMEEGStudyV4-1_0.dll
% (2009-07-15) and will be increased to 50,000,000 in the next build.
NumSamples = Duration * gSampleRate;
TotalSamplePts = NumSamples * gTotalChs;
if TotalSamplePts > 1e7 
    disp('User requested more than the 10,000,000 data points limit')
    return
end
%--------------------------------------------------------------------------
NumChsReq = length(ChsReq);
FsDec = gSampleRate/DecFactor;
%--------------------------------------------------------------------------
% Check that the requested data is within the segment data times, so that
% it doesn't corrupt the data file, which then has to be repaired by
% ProFusionEEG4.
StartSample = floor(StartTime * gSampleRate) + 1;
%----------------------------------------------------------------------
% Note that at 5000 Hz sampling rate, the sampling interval is 0.0002s.
% If 0 <= StartTime < 0.0002, then StartSample = 1.
% If 0.0002 <= StartTime < 0.0004, then StartSample = 2.
% If 0.0004 <= StartTime < 0.0006, then StartSample = 3, etc.
%----------------------------------------------------------------------
EndSample = StartSample + NumSamples - 1;
SegDataSamples = gSegDataTime * gSampleRate;
if SegDataSamples ~= floor(SegDataSamples)
    disp('SegDataSamples contains non-integer values!')
    return
end
NumDataSegments = size(gSegDataTime,1);
StartSample_in_DataSegment = 0;
EndSample_in_DataSegment = 0;
OverTwoDataSegments = false;
% Work out which data segment(s) that the data requested by the user lies
% in.
for DataSegment_Index = 1:NumDataSegments
    if StartSample >= SegDataSamples(DataSegment_Index,1) && StartSample <= SegDataSamples(DataSegment_Index,2)
        StartSample_in_DataSegment = DataSegment_Index;
    end
    if EndSample >= SegDataSamples(DataSegment_Index,1) && EndSample <= SegDataSamples(DataSegment_Index,2)
        EndSample_in_DataSegment = DataSegment_Index;
    end
end
% Work out which case of lost data packets it is.
if (StartSample_in_DataSegment == EndSample_in_DataSegment) && StartSample_in_DataSegment % then there is no lost data packet.
%     StartSample = StartSample;
%     EndSample = EndSample;
    Error = false;
elseif StartSample_in_DataSegment == 0 && EndSample_in_DataSegment % then there are lost data packets at the start.
    StartSample = SegDataSamples(EndSample_in_DataSegment,1);
%     EndSample = EndSample;
    Error = true; % disp('Start of the requested data is outside the range of the data segment!')
elseif EndSample_in_DataSegment == 0 && StartSample_in_DataSegment % then there are lost data packets at the end.
%     StartSample = StartSample
    EndSample = SegDataSamples(StartSample_in_DataSegment,2);
    Error = true; % disp('End of the requested data is outside the range of the data segment!')
elseif StartSample_in_DataSegment ~= EndSample_in_DataSegment % then there are lost data packets in the middle.
    StartSample2 = SegDataSamples(EndSample_in_DataSegment,1);
    EndSample2 = EndSample; % This line of code has to be before "EndSample = SegDataSamples(StartSample_in_DataSegment,2);" to ensure that the original EndSample is stored.
    NumSamples_2ndSeg = EndSample2 - StartSample2 + 1;
    OverTwoDataSegments = true;
    Error = true; % disp('Middle of the requested data is outside the range of the data segment!')
%     StartSample = StartSample;
    EndSample = SegDataSamples(StartSample_in_DataSegment,2);
elseif StartSample_in_DataSegment == 0 && EndSample_in_DataSegment == 0 % then there is no data. All data packets were lost.
    DataChDec = zeros(Duration*FsDec,NumChsReq);
    Error = true; % disp('Requested data is completely outside the range of the data segment!')
    return
end
%--------------------------------------------------------------------------
% Working out the indices for the DataCh data array.
DataCh = zeros(NumSamples,NumChsReq);
NumSamples_1stSeg = EndSample - StartSample + 1;
if StartSample_in_DataSegment == EndSample_in_DataSegment % then there is no lost data packet.
    DataCh_StartSample = 1;
    DataCh_EndSample = NumSamples;
elseif StartSample_in_DataSegment == 0 && EndSample_in_DataSegment % then there are lost data packets at the start.
    DataCh_EndSample = NumSamples;
    DataCh_StartSample = DataCh_EndSample - NumSamples_1stSeg + 1;
elseif EndSample_in_DataSegment == 0 && StartSample_in_DataSegment % then there are lost data packets at the end.
    NumSamples_1stSeg = NumSamples_1stSeg - 1; % Can't work out exactly why, but NumSamples_1stSeg seems to be 1 sample too many and causes the data reader to crach and corrupt the data file.
    DataCh_StartSample = 1;
    DataCh_EndSample = NumSamples_1stSeg;
elseif StartSample_in_DataSegment ~= EndSample_in_DataSegment % then there are lost data packets in the middle.
    NumSamples_1stSeg = NumSamples_1stSeg - 1; % Can't work out exactly why, but NumSamples_1stSeg seems to be 1 sample too many and causes the data reader to crach and corrupt the data file.
    DataCh_StartSample = 1;
    DataCh_EndSample = NumSamples_1stSeg;
    DataCh_EndSample2 = NumSamples;
    DataCh_StartSample2 = DataCh_EndSample2 - NumSamples_2ndSeg + 1;
end
%--------------------------------------------------------------------------
% Get the data using the Compumedics Data Reader (DLL).
Data = DataReader.SGetDataEx(StartSample,NumSamples_1stSeg,false);
if OverTwoDataSegments
    Data2 = DataReader.SGetDataEx(StartSample2,NumSamples_2ndSeg,false);
end
%--------------------------------------------------------------------------
% Separate the one dimensional data arrays (Data and Data2) into a two
% dimensional data array (DataCh) in which each channel corresponds to a
% column.
for n = 1:NumChsReq
    Data_StartSample = 1 + (ChsReq(n) - 1) * NumSamples_1stSeg;
    Data_EndSample = ChsReq(n) * NumSamples_1stSeg;
    DataCh(DataCh_StartSample:DataCh_EndSample,n) = Data(Data_StartSample:Data_EndSample);
    if OverTwoDataSegments
        Data_StartSample2 = 1 + (ChsReq(n) - 1) * NumSamples_2ndSeg;
        Data_EndSample2 = ChsReq(n) * NumSamples_2ndSeg;
        DataCh(DataCh_StartSample2:DataCh_EndSample2,n) = Data2(Data_StartSample2:Data_EndSample2);
    end
end
%--------------------------------------------------------------------------
% Interpolate or extrapolate the lost data packets.
if (StartSample_in_DataSegment ~= EndSample_in_DataSegment) && InterpExtrap  % if there are lost data packets and the user specified that interpolation/extrapolation is needed.
    if StartSample_in_DataSegment == 0 && EndSample_in_DataSegment % then there are lost data packets at the start.
        DataCh(1:DataCh_StartSample-1,:) = ones(DataCh_StartSample-1,1)*DataCh(DataCh_StartSample,:);
    elseif EndSample_in_DataSegment == 0 && StartSample_in_DataSegment % then there are lost data packets at the end.
        DataCh(DataCh_EndSample+1:end,:) = ones(NumSamples - DataCh_EndSample,1)*DataCh(DataCh_EndSample,:);
    elseif StartSample_in_DataSegment ~= EndSample_in_DataSegment % then there are lost data packets in the middle.
        for n = 1:NumChsReq
            DataCh(DataCh_EndSample+1:DataCh_StartSample2-1,n) = interp1([DataCh_EndSample DataCh_StartSample2],[DataCh(DataCh_EndSample,n) DataCh(DataCh_StartSample2,n)],DataCh_EndSample+1:DataCh_StartSample2-1,'linear');
        end
    end
end
%--------------------------------------------------------------------------
% Checking the decimation factor.
if DecFactor == 0
    DecFactor = 1;
end
% Decimate the data.
if DecFactor ~= 1
    DataChDec = zeros(Duration*FsDec,NumChsReq);
    for n = 1:NumChsReq
        DataChDec(:,n) = decimate(DataCh(:,n),DecFactor);
    end
elseif DecFactor == 1
    DataChDec = DataCh;
end