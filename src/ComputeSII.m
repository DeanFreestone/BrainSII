
% compute features stimulus indiced interactions

clc
clear
close all

% point this script at the the folder were the pre-processed data lives
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
HomeDir = '/Users/dean/Documents/PhD/Probe Analysis/Compumedics Data/';
PreprocessedDataDir = uigetdir(HomeDir,'Pick Directory of Preprocessed Data');
PreprocessedFiles = dir(PreprocessedDataDir);
PreprocessedFiles = PreprocessedFiles(3:end);

Fs = 1e3;
FilterCutOffs = [1, 20 ; 10, 30 ; 20, 40 ; 30, 50 ; 40, 60 ; 50, 70 ; 60, 80 ; 70, 90 ; 80 99]/(Fs/2);
BPFilterOrder = 20;

AnalysisWindowStart = 1.005;
AnalysisWindowEnd = 1.305;
EdgeEffectTime = 0.5;

StartSample4Window = (AnalysisWindowStart-EdgeEffectTime)*Fs;
EndSample4Window = (AnalysisWindowEnd+EdgeEffectTime)*Fs-1;
NSamplesInWindow = EndSample4Window-StartSample4Window+1;

NSamplesInCutWindow = round((AnalysisWindowEnd-AnalysisWindowStart)*Fs);

% perform measure for each of the files
for n=1:1%length(PreprocessedFiles)
    tic
    % load data
    load([PreprocessedDataDir '/' PreprocessedFiles(n).name])
    
    % cycle through each of the bandwidths
    IP = zeros(size(FilterCutOffs,1),size(PreprocessedData,1),NSamplesInCutWindow,size(PreprocessedData,3));
    PLV = zeros(size(FilterCutOffs,1),size(PreprocessedData,1),size(PreprocessedData,3)^2);
    for nn=1:size(FilterCutOffs,1)
        b = fir1(BPFilterOrder,FilterCutOffs(nn,:));
        
        % cycle through all the stimulations
        for nnn=1:size(PreprocessedData,1)
            CurrentEpoch = squeeze(PreprocessedData(nnn,round(StartSample4Window:EndSample4Window),:));
            BPFiltData = filtfilt(b,1,CurrentEpoch);
            
            % cycle through channels to perform CPT to get IP
            % need to replace what is inside this loop with the CPT.
            IP_temp = zeros(NSamplesInWindow,size(BPFiltData,2));
            for nnnn=1:size(BPFiltData,2)
                IP_temp(:,nnnn) = atan2(imag(hilbert(BPFiltData(:,nnnn))),BPFiltData(:,nnnn));
            end          
            
            % trim data back to the period of interest
            IP_trim = IP_temp(EdgeEffectTime*Fs:end-EdgeEffectTime*Fs-1,:);
            
            % compute the PLV for this stimulation
            m=1;
            for nnnn=1:size(IP_trim,2)
                for nnnnn=1:size(IP_trim,2)
                    
                    IP_diff = IP_trim(:,nnnn) - IP_trim(:,nnnnn);
%                     plot(IP_diff),title(num2str(m)),drawnow,pause(0.1)
                    PLV(nn,nnn,m) = abs(sum(exp(1i*IP_diff)) / NSamplesInCutWindow); % nn indexes freq bands, nnn indexes stimulations, m indexes channel combos
                    m = m+1;
                    
                end
            end
            
            IP(nn,nnn,:,:) = IP_trim;
            
        end
    end
    toc
end

PLVfirst = squeeze(PLV(1,:,:));
for n=272:size(PLVfirst,2)
    hist(PLVfirst(:,n))
    drawnow
    pause
end