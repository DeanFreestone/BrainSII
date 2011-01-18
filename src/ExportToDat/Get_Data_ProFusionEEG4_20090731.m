function [FsDec DataChDec] = Get_Data_ProFusionEEG4(ChsReq,StartTime,Duration,DecFactor)

global DataReader gSampleRate gTotalChs

%--------------------------------------------------------------------------
% Check that the user has not requested more data than the data reader
% limit. % The limit was set at 10,000,000 in CMEEGStudyV4-1_0.dll
% (2009-07-15) and will be increased to 50,000,000 in the next build.
TotalSamplePts = Duration * gSampleRate * gTotalChs;
if TotalSamplePts > 1e7 
    disp('User requested more than the 10,000,000 data points limit')
    return
end

%--------------------------------------------------------------------------
% Checking the decimation factor.
if DecFactor == 0
    DecFactor = 1;
end
FsDec = gSampleRate/DecFactor;
if FsDec ~= round(FsDec)
    disp('The specified decimation factor results in a sampling rate that is not an integer!')
    disp('FsDec =')
    disp(FsDec)
    return
end

%--------------------------------------------------------------------------
StartSample = ceil(StartTime * gSampleRate) + 1;
clear StartTime
NumberOfSamples = Duration * gSampleRate;

Data = DataReader.SGetDataEx(StartSample, NumberOfSamples, false);
clear StartSample

NumChsReq = length(ChsReq);
DataChDec = zeros(FsDec*Duration,NumChsReq);

for n = 1:NumChsReq
    StartSample = 1 + (ChsReq(n) - 1) * NumberOfSamples;
    EndSample = ChsReq(n) * NumberOfSamples - (DecFactor - 1);
    DataChDec(:,n) = Data(StartSample:DecFactor:EndSample);
end

clear NumberOfSamples NumChsReq StartSample EndSample Data