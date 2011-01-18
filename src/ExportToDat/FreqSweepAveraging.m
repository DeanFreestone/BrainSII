clear
close all
clc

CMDisconnect_ProFusionEEG4
Path = 'F:\Data from RCAS\';
File = '20090524{D1DAD581-CC6B-409A-B0D5-09CAB1B538CC}.eeg';
FilePath = [Path File];
[Fs, NChs, NumDataSegs, SegStartTime, SegDurn] = CMConnect_ProFusionEEG4(FilePath);

ProbeFreqLookup = [3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ...
        22 24 26 28 30 33 36 40 44 48 52 57 63 70];
    
EpochChannel = 137;
TrgChannel = 65;
DecFactor = 1;
Duration = 5;

% read data until the first trigger is found
n=570;
TrigIndex = [];
TrigThresh = 0.11;
while isempty(TrigIndex)
    [FsDec TriggerSig] = Get_Data_ProFusionEEG4(TrgChannel,SegStartTime(1)+n,Duration,DecFactor);
    TrigIndex = find(TriggerSig>TrigThresh,1,'first');
    n=n+5;
end

StartTime = SegStartTime(1) + TrigIndex/Fs + (n - 5) - 0.5;           % time in seconds after seg start time

% skip forward and read the next stim sequence
% by adding 2.5 seconds the next trigger will be the next stim

JumpTime1 = 2.5;                                     % seconds
JumpTime2 = 1.5;
StimReadDuration = 1;                               % seconds, to get the frequency
EpochLength1 = 2.5;
EpochLength2 = 1.5;
Samples2Skip = 90;
TrigWindowSize = 3300;
a=1;b=1;c=1;d=1;e=1;f=1;g=1;h=1;ii=1;jj=1;k=1;l=1;m=1;nn=1;o=1;p=1;
q=1;r=1;s=1;tt=1;u=1;v=1;w=1;x=1;y=1;z=1;aa=1;bb=1;cc=1;dd=1;ee=1;ff=1;

tic

NIterations = 50;
NLoops = NIterations*length(ProbeFreqLookup);
Chs = [1:10 11 13:23 26:35 37:41 43:64];
NChs = length(Chs);
DecimationFactor = 20;

for n=1:NLoops
    
    [FsDec TriggerSig] = Get_Data_ProFusionEEG4(TrgChannel,StartTime,StimReadDuration,DecFactor);   % read 1 second to find first index and freq
    TrigIndex = find(TriggerSig>TrigThresh,1,'first');
    TrigTime = TrigIndex/Fs + StartTime;           % time in seconds after seg start time
    TriggerSig_Temp = TriggerSig(TrigIndex+Samples2Skip:TrigIndex+Samples2Skip+TrigWindowSize);
    TrigIndex2_Temp = find(TriggerSig_Temp>TrigThresh,1,'first');
    TrigIndex2 = TrigIndex2_Temp + TrigIndex + Samples2Skip - 2;
    StimFreq = round(Fs/(TrigIndex2 - TrigIndex));
    if StimFreq < 10   
        [FsDec TempData] = Get_Data_ProFusionEEG4(Chs,TrigTime-0.2,EpochLength1,DecFactor);
        t = linspace(0,EpochLength1,EpochLength1*Fs/DecimationFactor);
    else
        [FsDec TempData] = Get_Data_ProFusionEEG4(Chs,TrigTime-0.2,EpochLength2,DecFactor);
        t = linspace(0,EpochLength2,EpochLength2*Fs/DecimationFactor);
    end
    
    % move to a common average reference
    DetrendedTempData = detrend(TempData);
    CAR = mean(DetrendedTempData,2);
    CAR = CAR(:,ones(1,length(Chs)));
    TempData = detrend(TempData - CAR); 
    
% % find all stimulations and remove from time series via interpolation
%     DiffThresh = 2e-5;
%     DifTempData = [zeros(1,length(Chs)); abs(diff(TempData))];
%     for nnn=1:NChs
%         I_bad = find(DifTempData(:,nnn) > DiffThresh);
%         I_good = find(DifTempData(:,nnn) <= DiffThresh);
%         TempData(I_bad,nnn) = interp1(I_good,TempData(I_good,nnn),I_bad);
%     end
% 
%     Wn = 300/(Fs/2);
%     FiltOrd = 100;
%     B = fir1(FiltOrd,Wn);
%     TempData = filtfilt(B,1,TempData);
    
    % decimate and anti-alias
    TempData = TempData(1:DecimationFactor:end,:);
    FsDec = Fs/DecimationFactor;
    Wn = 200/(FsDec/2);
    FiltOrd = 20;
    B = fir1(FiltOrd,Wn);
    TempData = filtfilt(B,1,TempData);
    
%     plot(t,[zeros(1,length(Chs)); diff(TempData)])
    plot(t,TempData)
    drawnow

%     if StimFreq == 3, Data3(a,:,:) = TempData; a = a+1;
%     elseif StimFreq == 4, Data4(b,:,:) = TempData; b=b+1;
%     elseif StimFreq == 5, Data5(c,:,:) = TempData; c=c+1;
%     elseif StimFreq == 6, Data6(d,:,:) = TempData; d=d+1;
%     elseif StimFreq == 7, Data7(e,:,:) = TempData; e=e+1;
%     elseif StimFreq == 8, Data8(f,:,:) = TempData; f=f+1;
%     elseif StimFreq == 9, Data9(g,:,:) = TempData; g=g+1;
%     elseif StimFreq == 10, Data10(h,:,:) = TempData; h=h+1;
%     elseif StimFreq == 11, Data11(ii,:,:) = TempData; ii=ii+1;
%     elseif StimFreq == 12, Data12(jj,:,:) = TempData; jj=jj+1;
%     elseif StimFreq == 13, Data13(k,:,:) = TempData; k=k+1;
%     elseif StimFreq == 14, Data14(l,:,:) = TempData; l=l+1;
%     elseif StimFreq == 15, Data15(m,:,:) = TempData; m=m+1;
%     elseif StimFreq == 16, Data16(nn,:,:) = TempData; nn=nn+1;
%     elseif StimFreq == 17, Data17(o,:,:) = TempData; o=o+1;
%     elseif StimFreq == 18, Data18(p,:,:) = TempData; p=p+1;
%     elseif StimFreq == 19, Data19(q,:,:) = TempData; q=q+1;
%     elseif StimFreq == 20, Data20(r,:,:) = TempData; r=r+1;
%     elseif StimFreq == 22, Data22(s,:,:) = TempData; s=s+1;
%     elseif StimFreq == 24, Data24(tt,:,:) = TempData; tt=tt+1;
%     elseif StimFreq == 26, Data26(u,:,:) = TempData; u=u+1;
%     elseif StimFreq == 28, Data28(v,:,:) = TempData; v=v+1;
%     elseif StimFreq == 30, Data30(w,:,:) = TempData; w=w+1;   
    if StimFreq == 33, Data33(x,:,:) = TempData; x=x+1;
    elseif StimFreq == 36, Data36(y,:,:) = TempData; y=y+1;
    elseif StimFreq == 40, Data40(z,:,:) = TempData; z=z+1;
    elseif StimFreq == 44, Data44(aa,:,:) = TempData; aa=aa+1;
    elseif StimFreq == 48, Data48(bb,:,:) = TempData; bb=bb+1;
%     elseif StimFreq == 52, Data52(cc,:,:) = TempData; cc=cc+1;
%     elseif (StimFreq == 57) || (StimFreq == 56) || (StimFreq == 58), Data57(dd,:,:) = TempData; dd=dd+1;
%     elseif (StimFreq == 63) || (StimFreq == 62) || (StimFreq == 64), Data63(ee,:,:) = TempData; ee=ee+1;
%     elseif (StimFreq == 70) || (StimFreq == 69) || (StimFreq == 71) , Data70(ff,:,:) = TempData; ff=ff+1;    
    end

    if StimFreq < 10
        StartTime = TrigTime + JumpTime1;
    else
        StartTime = TrigTime + JumpTime2;
    end
    disp([num2str(n) ' of ' num2str(NLoops) ' loops, stim freq = ' num2str(StimFreq)])
    if n==900
        toc
    end
end

