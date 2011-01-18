function [SampleRate, TotalChs, NumDataSegs, SegStartTime, SegDurn] = TEST_ReadData_ProFusionEEG4

CMDisconnect_ProFusionEEG4
% FilePath = 'D:\210509_1525_sz.eeg';
% FilePath = 'D:\220509_0800_sz.eeg';
% FilePath = 'D:\220509_1900_sz.eeg';
% FilePath = 'D:\220509_1900_sz_retry.eeg';
FilePath = 'D:\260509_0806_sz.eeg';
% FilePath = 'D:\260509_1800_sz.eeg';
[SampleRate, TotalChs, NumDataSegs, SegStartTime, SegDurn] = CMConnect_ProFusionEEG4(FilePath);
Duration = 10; % Request 1s duration of data.
Loops = floor(SegDurn(1)/Duration);
for n = 1:Loops
    [FsDec Data] = Get_Data_ProFusionEEG4(1:137,SegStartTime(1)+(n-1)*Duration,Duration,1);
    pause(0.1)
    subplot(2,2,1)
    plot(Data(:,1))
    title(n,'fontsize',20)
    subplot(2,2,2)
    plot(Data(:,64))
    subplot(2,2,3)
    plot(Data(:,128))
    subplot(2,2,4)
    plot(Data(:,137))
end