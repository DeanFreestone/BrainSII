
clear
clc
close all


Chs = 1:64;

NoisyChannels = [48  16  10  12  36  42   2   3   4   5   7   8   9  13  15  21  ...
    23  24  25  32  33  35  40  41  49  52  54  56  57  60  61];
GoodChs = setdiff(Chs, NoisyChannels);
ProbeFreqLookup = [3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ...
        22 24 26 28 30 33 36 40 44 48 52 57 63 70];

for nn=1:floor(length(GoodChs)/2)
    figure('name',['Channel = ' num2str(GoodChs(nn))],...
        'units','normalized',...
        'position',[0.05, 0.02, 0.9, 0.91]);
    
    for n = 1:length(ProbeFreqLookup)

        FileName = [cd '\ResultsAndSettings\Ch' num2str(GoodChs(nn)) ...
            '\Ch' num2str(GoodChs(nn)) 'Freq' num2str(ProbeFreqLookup(n)) '.mat'];
        load(FileName)

%             take fft of the first 0.5 seconds (bacground)
        BaselineData = ChData(1:500,:);
        BaselineFFT = fft(BaselineData,2048);
        BaselineFFT = abs(BaselineFFT(1:1024,:));

        % take fft of foreground
        if ProbeFreqLookup(n) >= 10
            StartIndex = 1000;
        else
            StartIndex = 2000;
        end
        
        ResponeData = ChData(StartIndex:StartIndex+500,:);
        ResponeFFT = fft(ResponeData,2048);
        ResponeFFT = abs(ResponeFFT(1:1024,:));
        Response = (mean(ResponeFFT,2));
        Background = 20*log10(mean(BaselineFFT,2));
        Difference = Response - Background;

        subplot(8,4,n)
        plot(f(1:150),Response(1:150))
        ylim([0 0.008])
        xlim([0 f(150)])
%         t = linspace(0,0.5,501);
%         plot(t,mean(ResponeData,2) ), axis tight
        title(['Ch: ' num2str(GoodChs(nn)) ' Freq: ' num2str(ProbeFreqLookup(n))])
    end
end


%             subplot(4,8,n)
% % %             plot(f(1:400),20*log10(aveFFT(1:400)))
% %             plot(f(1:200),(aveFFT(1:200)))
%             plot(mean(ChData,2));
%             title(['Frequency = ' num2str(ProbeFreqLookup(n))])
%             axis tight