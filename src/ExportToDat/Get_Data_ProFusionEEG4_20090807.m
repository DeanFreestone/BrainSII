function [FsDec DataChDec] = Get_Data_ProFusionEEG4(ChsReq,StartTime,Duration,DecFactor)

global DataReader gSampleRate gTotalChs gSegDataTime

%--------------------------------------------------------------------------
% Check that the requested data is within the segment data times, so that
% it doesn't corrupt the data file, which then has to be repaired by
% ProFusionEEG4.
ReqDataWithinRange = false;
for n = 1:size(gSegDataTime,1)
    if StartTime >= gSegDataTime(n,1) && (StartTime + Duration) <= gSegDataTime(n,2)
        ReqDataWithinRange = true;
        break
    end
end
if ~ReqDataWithinRange
    disp('Requested data is outside the range of the data segment!')
    return
end
%--------------------------------------------------------------------------
% Check that the user has not requested more data than the data reader
% limit. % The limit was set at 10,000,000 in CMEEGStudyV4-1_0.dll
% (2009-07-15) and will be increased to 50,000,000 in the next build.
TotalSamplePts = Duration * gSampleRate * gTotalChs;
if TotalSamplePts > 1e7 
    disp('User requested more than the 10,000,000 data points limit')
    return
end
StartSample = ceil(StartTime * gSampleRate) + 1;
NumberOfSamples = Duration * gSampleRate;

Data = DataReader.SGetDataEx(StartSample, NumberOfSamples, false);

NumChsReq = length(ChsReq);
DataCh = zeros(gSampleRate*Duration,NumChsReq);
for n = 1:NumChsReq
    StartSample = 1 + (ChsReq(n) - 1) * NumberOfSamples;
    EndSample = ChsReq(n) * NumberOfSamples;
    DataCh(:,n) = Data(StartSample:EndSample);
end
%--------------------------------------------------------------------------
% Checking the decimation factor.
if DecFactor == 0
    DecFactor = 1;
end
FsDec = gSampleRate/DecFactor;
DataChDec = zeros(gSampleRate*Duration/DecFactor,NumChsReq);
for n = 1:NumChsReq
    DataChDec(:,n) = decimate(DataCh(:,n),DecFactor);
end
%--------------------------------------------------------------------------