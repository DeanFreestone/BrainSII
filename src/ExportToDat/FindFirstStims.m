% This m file was written to find all the first stims.

clear;clc;
clear global
format long g
CMDisconnect_ProFusionEEG4;
CompumedicsFolder = uigetdir('CompumedicsRootDir', 'Pick the Recorded Data Folder');
[Fs, NChs, NumDataSegs, SegStartTime, SegDurn, StartDateTime, StudyLength] = CMConnect_ProFusionEEG4(CompumedicsFolder);
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

SearchDuration = 3; % 4;      % 4 seconds.
ProbeDuration = 300;     % 3 seconds by 100 probes.
SkipForward_nLoops = 75; % Once the first trigger is found, skip forward in the data by about ProbeDuration/SearchDuration loops.
SkipForward = false;     % SkipForward status.
DecFactor = 1;           % No decimation.
BipolarCh = 129;
TriggerCh = 128+9;
TriggerInfo = [];        % Initialise with empty array.
TriggerInfoIndex = 0;    % Initialise as 0 to correspond to the above line.

for SegIndex = 1:NumDataSegs
    disp('SegIndex =')
    disp(SegIndex)
    DataLoops = floor(SegDurn(SegIndex)/SearchDuration);
    for DataLoopsIndex = 1:DataLoops
%         disp('DataLoopsIndex =')
        disp(DataLoopsIndex)
        % If SkipForward is on, then start counting down SkipForward_nLoops
        % and skip to the next for loop. Once the count down reaches zero,
        % set SkipForward to false and resume searching for the "first
        % triggers".
        if SkipForward
            SkipForward_nLoops = SkipForward_nLoops - 1;
            if SkipForward_nLoops == 0
                SkipForward = false;
            end
            continue
        end
        % Find the "first markers".
        [FsDec x] = Get_Data_ProFusionEEG4([BipolarCh TriggerCh],SegStartTime(SegIndex)+(DataLoopsIndex-1)*SearchDuration,SearchDuration,DecFactor);

        % Plot the bipolar and trigger channels.
%         figure(1);
%         ax(1) = subplot(2,1,1);
%         plot(x(:,1));
%         ax(2) = subplot(2,1,2);
%         plot(x(:,2));
%         linkaxes(ax,'x');
%         pause;

%         Triggered = find((x(:,1) > 0.1),1,'first');
        Triggered = find((x(:,2) > 10),1,'first');
        TriggerTime = Triggered/Fs;
        if ~isempty(Triggered)
            
            % Plot the bipolar and trigger channels, if a trigger is found.
%             disp('Triggered =')
%             disp(Triggered)
%             ax(1) = subplot(2,1,1);
%             plot(x(:,1));
%             ax(2) = subplot(2,1,2);
%             plot(x(:,2));
%             linkaxes(ax,'x');
%             pause
            
%             button = questdlg('Is it a trigger?','Check the trigger.','Yes','No','Break','No');
%             if strcmp(button,'Yes') % If the user has checked theat the trigger is ok, then...
                TriggerInfoIndex = TriggerInfoIndex + 1; % Increment the TriggerInfo array index and then store the trigger time info.
                TriggerInfo(TriggerInfoIndex,1) = SegStartTime(SegIndex)+(DataLoopsIndex-1)*SearchDuration + TriggerTime - SearchDuration;
                SkipForward = true;
                SkipForward_nLoops = 60;
%             elseif strcmp(button,'Break')
%                 break
%             end
%         elseif isempty(Triggered)
%             disp('Empty.')
        end
    end
end

save TriggerInfo TriggerInfo CompumedicsFolder
save(['TriggerInfo_' CompumedicsFolder(findstr(CompumedicsFolder,'\')+1:findstr(CompumedicsFolder,'.eeg')-1)],'TriggerInfo','CompumedicsFolder')

%     % find the first trigger
%     SamplesPerStimPar = 10;     % for 5kHz
%     TrigI = find(x(:,2)>0.01,1,'first') + floor(SamplesPerStimPar/2);        % find the trigger signal on the BP trigger channel
%     TrigLevel = x(TrigI,2);
%     if ~isempty(TrigLevel)
%         if TrigLevel > 0.065        %Data stream written because of Wendyl, Manual/Matlab therapy or probing delivery
%             % use this index to start reading the stimulation parameters
% 
%             ax(1) = subplot(2,1,1);
%             plot(x(:,1));
%             ax(2) = subplot(2,1,2);
%             plot(x(:,2));
%             linkaxes(ax,'x');
%             pause
%             
%             CurrentIndex = TrigI + SamplesPerStimPar;    % add the extra SamplesPerStimPar because the first index of the MUX is zeros.
%             StimPar = zeros(1,15);
% 
%             for n=1:16
%                 StimPar(n) = x(CurrentIndex-10,2);
%                 CurrentIndex = CurrentIndex + SamplesPerStimPar;
%             end
% 
%             CurMin = 0;
%             CurMax = 1;         % milli Amps
%             CurMult1 = 0.1;
%             CurMult2 = 1;
%             CurMult3 = 10;
% 
%             PWMin = 0;
%             PWMax = 100;        % micro seconds
%             PWMult1 = 0.1;
%             PWMult2 = 1;
%             PWMult3 = 10;
% 
%             TherapyFreqMin = 0;
%             TherapyFreqMax = 10;
%             TherapyFreqMult1 = 1;
%             TherapyFreqMult2 = 10;
%             TherapyFreqMult3 = 100;
% 
%             TherapyLengthMin = 0;
%             TherapyLengthMax = 50;      % ms
%             TherapyLengthMult1 = 1;
%             TherapyLengthMult2 = 10;
%             TherapyLengthMult3 = 100;
% 
%             QuantSize = 63;
%             BitMask = uint8(QuantSize);
% 
%             % ~~~~~~~
%             z = StimPar(1);
%             Settings.WhiteCh = StimPar(1)+1;
%             Settings.BlueCh = StimPar(2)+1;
%             Settings.RedCh = StimPar(3)+1;
%             Settings.YellowCh = StimPar(4)+1;
% 
%             % ~~~~~~~
%             BlueWhiteCurrentByte = uint8(StimPar(5));
%             QBlueWhiteCur = bitand(BlueWhiteCurrentByte,BitMask);       % grab the six lowest bits
%             BlueWhiteCurMult =  bitshift(BlueWhiteCurrentByte,-6);      % grab the two highest bits
%             BlueWhiteCurrent = (double(QBlueWhiteCur)/QuantSize)*(CurMax-CurMin);
%             Settings.BlueWhiteCurTotal = 10^(double(BlueWhiteCurMult))*0.1*BlueWhiteCurrent;
% 
%             % ~~~~~~~
%             RedYellowCurrentByte = uint8(StimPar(6));
%             QRedYellowCur = bitand(RedYellowCurrentByte,BitMask);       % grab the six lowest bits
%             RedYellowCurMult =  bitshift(RedYellowCurrentByte,-6);      % grab the two highest bits
%             RedYellowCurrent = (double(QRedYellowCur)/QuantSize)*(CurMax-CurMin);
%             Settings.RedYellowCurTotal = 10^(double(RedYellowCurMult))*0.1*RedYellowCurrent;
% 
%             % ~~~~~~~
%             BlueWhitePWByte = uint8(StimPar(7));
%             QBlueWhitePW = bitand(BlueWhitePWByte,BitMask);       % grab the six lowest bits
%             BlueWhitePWMult =  bitshift(BlueWhitePWByte,-6);      % grab the two highest bits
%             BlueWhitePW = (double(QBlueWhitePW)/QuantSize)*(PWMax-PWMin);
%             Settings.BlueWhitePWTotal = 10^(double(BlueWhitePWMult))*0.1*BlueWhitePW;
% 
%             % ~~~~~~~ RY Pulse Width
%             RedYellowPWByte = uint8(StimPar(8));
%             QRedYellowPW = bitand(RedYellowPWByte,BitMask);       % grab the six lowest bits
%             RedYellowPWMult =  bitshift(RedYellowPWByte,-6);      % grab the two highest bits
%             RedYellowPW = (double(QRedYellowPW)/QuantSize)*(PWMax-PWMin);
%             Settings.RedYellowPWTotal = 10^(double(RedYellowPWMult))*0.1*RedYellowPW;
% 
%             % ~~~~~~~ Therapy Frequency
%             TherapyFreqByte = uint8(StimPar(9));
%             QTherapyFreq = bitand(TherapyFreqByte,BitMask);       % grab the six lowest bits
%             TherapyFreqMult =  bitshift(TherapyFreqByte,-6);      % grab the two highest bits
%             TherapyFreq = (double(QTherapyFreq)/QuantSize)*(TherapyFreqMax-TherapyFreqMin);
%             Settings.TherapyFreqTotal = 10^(double(TherapyFreqMult))*TherapyFreq;
% 
%             % ~~~~~~~ Therapy Length
%             TherapyLengthByte = uint8(StimPar(10));
%             QTherapyLength = bitand(TherapyLengthByte,BitMask);       % grab the six lowest bits
%             TherapyLengthMult =  bitshift(TherapyLengthByte,-6);      % grab the two highest bits
%             TherapyLength = (double(QTherapyLength)/QuantSize)*(TherapyLengthMax-TherapyLengthMin);
%             Settings.TherapyLengthTotal = 10^(double(TherapyLengthMult))*TherapyLength;
% 
%             % ~~~~~~~ Stim Mode
%             StimModeByte = uint8(StimPar(11));
%             Settings.ClosedLoopOnOff = bitget(StimModeByte,6);                  % bit 0 is bit 1 in MATLAB
%             Settings.WBEnable = bitget(StimModeByte,5);
%             Settings.RYEnable = bitget(StimModeByte,4);
%             Settings.ApAsEnable = bitget(StimModeByte,3);                        % aperiodic asynchronous
%             Settings.ApSEnable = bitget(StimModeByte,2);                         % aperiodic synchronous
%             Settings.PSEnable = bitget(StimModeByte,1);                          % periodic synchronous
% 
%             % ~~~~~~~ Function Stimulation / Probe Mode
%             ProbeFuncModeByte = uint8(StimPar(15));
%             Settings.FunctionalMappingOnOff = bitget(StimModeByte,4);
%             Settings.ProbeEnable = bitget(StimModeByte,3);
%             Settings.ProbeOn = bitget(StimModeByte,2);
%             Settings.ProbeMode = bitget(StimModeByte,1);
% 
%             % ~~~~~~~ Probe Frequency
%             ProbeFreqByte = uint8(StimPar(14));                         % this will be an index to a lookup table
%             ProbeFreqLookup1 = [0.3322259 10 20 100];                   % lookup table depending on the mode (freq response or normal)
%             ProbeFreqLookup2 = [3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ...
%                 22 24 26 28 30 33 36 40 44 48 52 57 63 70];
%             if Settings.ProbeMode == 0
%                 Settings.ProbeFreq = ProbeFreqLookup1(ProbeFreqByte+1);
%             else
%                 Settings.ProbeFreq = ProbeFreqLookup2(ProbeFreqByte+1);
%             end
% 
%             % ~~~~~~~ Number of Probes per Iteration
%             NProbesByte = uint8(StimPar(12));                           % this will be an index to a lookup table
%             NProbesLookup1 = [5 10 100 200];                            % lookup table depending on the mode (freq response or normal)
%             NProbesLookup2 = [2*ProbeFreqLookup2(1:7) ProbeFreqLookup2(8:32)];
%             if Settings.ProbeMode == 0      % normal mode = 0
%                 Settings.NProbes = NProbesLookup1(NProbesByte+1);
%             else
%                 Settings.NProbes = NProbesLookup2(NProbesByte+1);
%             end
% 
%             % ~~~~~~~ Inter Probing Interval
%             InterProbeIntervalByte = uint8(StimPar(13));                % this will be an index to a lookup table
%             ProbeIPILookup1 = [3.01 4.01 600.01 900.01];                % lookup table
%             ProbeIPILookup2 = [3.01*ones(1,7) 2.01*ones(1,25)];
%             if Settings.ProbeMode == 0      % normal mode = 0
%                 Settings.NProbes = NProbesLookup1(InterProbeIntervalByte+1);
%             else
%                 Settings.NProbes = NProbesLookup2(ProbeFreqByte+1);     % here we use the Frequency byte on purpose
%             end
% 
%             % display results to the command line
%             % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%             Settings
% 
%         elseif (TrigLevel < 0.065) && (TrigLevel > 0.005)
%             RespLevel = {'None', 'Unsure', 'Small', 'High'};
%             RespType = {'Free Label', 'N/A', 'Somatosensory', 'Motor', 'Hallucination', 'Speech', 'Auditory', 'Visual'};
%             RespArea = {'Free Label', 'N/A', 'Hand', 'Arm', 'Leg', 'Foot', 'Face', 'Tongue'};
% 
%             % ~~~~~~~ Response Level
%             %Only evaluate in the absence of a BP trigger
%             RespByte = uint8(x(TrigI+SamplesPerStimPar/2,3));
%             QRespLevel = bitand(RespByte,uint8(3));
%             RespLevelStr = RespLevel(QRespLevel+1)
%             QRespType = bitshift(bitand(RespByte,uint8(28)),-2);
%             RespTypeStr = RespType(QRespType+1)
%             QRespArea = bitshift(RespByte,-5);
%             RespAreaStr = RespArea(QRespArea+1)
%         else
%             disp('No trigger no found')
%         end
%     end