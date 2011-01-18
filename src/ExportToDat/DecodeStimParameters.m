clear 
clc
CMDisconnect_ProFusionEEG4
% get data path
% CompumedicsRootDir = '\\a40193\SVHM_EEG1';
CompumedicsRootDir = 'Z:\';
CompumedicsFolder = uigetdir('CompumedicsRootDir', 'Pick the Recorded Data Folder');


[Fs, NChs, NumDataSegs, SegStartTime, SegDurn] = CMConnect_ProFusionEEG4(CompumedicsFolder);

% [SampleRate, TotalChs, NumDataSegs, SegStartTime, SegDurn] = CMConnect_ProFusionEEG4(FilePath)

HighLevelCh = 37;
TriggerCh = 33;
StimCh = 1;

[FsDec, x] = Get_Data_ProFusionEEG4([TriggerCh HighLevelCh], SegStartTime(2)+2, 10, 1);

% find the first trigger
SamplesPerStimPar = 10;     % for 10kHz
TrigI = find(x(:,2)>0.01,1,'first') + floor(SamplesPerStimPar/2);        % find the trigger signal on the BP trigger channel
TrigLevel = x(TrigI,2)

if TrigLevel > 0.065        %Data stream written because of Wendyl, Manual/Matlab therapy or probing delivery
    % use this index to start reading the stimulation parameters
    
    CurrentIndex = TrigI + SamplesPerStimPar;    % add the extra SamplesPerStimPar because the first index of the MUX is zeros.
    StimPar = zeros(1,15);

    for n=1:16
        StimPar(n) = x(CurrentIndex-10,2);
        CurrentIndex = CurrentIndex + SamplesPerStimPar;
    end

    CurMin = 0;
    CurMax = 1;         % milli Amps
    CurMult1 = 0.1;
    CurMult2 = 1;
    CurMult3 = 10;   

    PWMin = 0;
    PWMax = 100;        % micro seconds
    PWMult1 = 0.1;
    PWMult2 = 1;
    PWMult3 = 10;

    TherapyFreqMin = 0;
    TherapyFreqMax = 10;
    TherapyFreqMult1 = 1;
    TherapyFreqMult2 = 10;
    TherapyFreqMult3 = 100;

    TherapyLengthMin = 0;
    TherapyLengthMax = 50;      % ms
    TherapyLengthMult1 = 1;
    TherapyLengthMult2 = 10;
    TherapyLengthMult3 = 100;

    QuantSize = 63;
    BitMask = uint8(QuantSize);

    % ~~~~~~~
    z = StimPar(1);
    Settings.WhiteCh = StimPar(1)+1;
    Settings.BlueCh = StimPar(2)+1;
    Settings.RedCh = StimPar(3)+1;
    Settings.YellowCh = StimPar(4)+1;

    % ~~~~~~~
    BlueWhiteCurrentByte = uint8(StimPar(5));
    QBlueWhiteCur = bitand(BlueWhiteCurrentByte,BitMask);       % grab the six lowest bits
    BlueWhiteCurMult =  bitshift(BlueWhiteCurrentByte,-6);      % grab the two highest bits   
    BlueWhiteCurrent = (double(QBlueWhiteCur)/QuantSize)*(CurMax-CurMin);
    Settings.BlueWhiteCurTotal = 10^(double(BlueWhiteCurMult))*0.1*BlueWhiteCurrent;

    % ~~~~~~~
    RedYellowCurrentByte = uint8(StimPar(6));
    QRedYellowCur = bitand(RedYellowCurrentByte,BitMask);       % grab the six lowest bits
    RedYellowCurMult =  bitshift(RedYellowCurrentByte,-6);      % grab the two highest bits   
    RedYellowCurrent = (double(QRedYellowCur)/QuantSize)*(CurMax-CurMin);
    Settings.RedYellowCurTotal = 10^(double(RedYellowCurMult))*0.1*RedYellowCurrent;

    % ~~~~~~~
    BlueWhitePWByte = uint8(StimPar(7));
    QBlueWhitePW = bitand(BlueWhitePWByte,BitMask);       % grab the six lowest bits
    BlueWhitePWMult =  bitshift(BlueWhitePWByte,-6);      % grab the two highest bits   
    BlueWhitePW = (double(QBlueWhitePW)/QuantSize)*(PWMax-PWMin);
    Settings.BlueWhitePWTotal = 10^(double(BlueWhitePWMult))*0.1*BlueWhitePW;

    % ~~~~~~~ RY Pulse Width
    RedYellowPWByte = uint8(StimPar(8));
    QRedYellowPW = bitand(RedYellowPWByte,BitMask);       % grab the six lowest bits
    RedYellowPWMult =  bitshift(RedYellowPWByte,-6);      % grab the two highest bits   
    RedYellowPW = (double(QRedYellowPW)/QuantSize)*(PWMax-PWMin);
    Settings.RedYellowPWTotal = 10^(double(RedYellowPWMult))*0.1*RedYellowPW;

    % ~~~~~~~ Therapy Frequency
    TherapyFreqByte = uint8(StimPar(9));
    QTherapyFreq = bitand(TherapyFreqByte,BitMask);       % grab the six lowest bits
    TherapyFreqMult =  bitshift(TherapyFreqByte,-6);      % grab the two highest bits   
    TherapyFreq = (double(QTherapyFreq)/QuantSize)*(TherapyFreqMax-TherapyFreqMin);
    Settings.TherapyFreqTotal = 10^(double(TherapyFreqMult))*TherapyFreq;

    % ~~~~~~~ Therapy Length
    TherapyLengthByte = uint8(StimPar(10));
    QTherapyLength = bitand(TherapyLengthByte,BitMask);       % grab the six lowest bits
    TherapyLengthMult =  bitshift(TherapyLengthByte,-6);      % grab the two highest bits   
    TherapyLength = (double(QTherapyLength)/QuantSize)*(TherapyLengthMax-TherapyLengthMin);
    Settings.TherapyLengthTotal = 10^(double(TherapyLengthMult))*TherapyLength;

    % ~~~~~~~ Stim Mode
    StimModeByte = uint8(StimPar(11));
    Settings.ClosedLoopOnOff = bitget(StimModeByte,6);                  % bit 0 is bit 1 in MATLAB
    Settings.WBEnable = bitget(StimModeByte,5);
    Settings.RYEnable = bitget(StimModeByte,4);
    Settings.ApAsEnable = bitget(StimModeByte,3);                        % aperiodic asynchronous
    Settings.ApSEnable = bitget(StimModeByte,2);                         % aperiodic synchronous
    Settings.PSEnable = bitget(StimModeByte,1);                          % periodic synchronous

    % ~~~~~~~ Function Stimulation / Probe Mode
    ProbeFuncModeByte = uint8(StimPar(15));
    Settings.FunctionalMappingOnOff = bitget(StimModeByte,4);                  
    Settings.ProbeEnable = bitget(StimModeByte,3);
    Settings.ProbeOn = bitget(StimModeByte,2);
    Settings.ProbeMode = bitget(StimModeByte,1);                        

    % ~~~~~~~ Probe Frequency
    ProbeFreqByte = uint8(StimPar(14));                         % this will be an index to a lookup table
    ProbeFreqLookup1 = [0.3322259 10 20 100];                   % lookup table depending on the mode (freq response or normal)
    ProbeFreqLookup2 = [3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ...
        22 24 26 28 30 33 36 40 44 48 52 57 63 70];
    if Settings.ProbeMode == 0
        Settings.ProbeFreq = ProbeFreqLookup1(ProbeFreqByte+1);
    else
        Settings.ProbeFreq = ProbeFreqLookup2(ProbeFreqByte+1);
    end

    % ~~~~~~~ Number of Probes per Iteration
    NProbesByte = uint8(StimPar(12));                           % this will be an index to a lookup table
    NProbesLookup1 = [5 10 100 200];                            % lookup table depending on the mode (freq response or normal)
    NProbesLookup2 = [2*ProbeFreqLookup2(1:7) ProbeFreqLookup2(8:32)];
    if Settings.ProbeMode == 0      % normal mode = 0
        Settings.NProbes = NProbesLookup1(NProbesByte+1);
    else
        Settings.NProbes = NProbesLookup2(NProbesByte+1);     
    end

    % ~~~~~~~ Inter Probing Interval
    InterProbeIntervalByte = uint8(StimPar(13));                % this will be an index to a lookup table
    ProbeIPILookup1 = [3.01 4.01 600.01 900.01];                % lookup table
    ProbeIPILookup2 = [3.01*ones(1,7) 2.01*ones(1,25)];
    if Settings.ProbeMode == 0      % normal mode = 0
        Settings.NProbes = NProbesLookup1(InterProbeIntervalByte+1);
    else
        Settings.NProbes = NProbesLookup2(ProbeFreqByte+1);     % here we use the Frequency byte on purpose
    end
    
    % display results to the command line
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Settings   
    
elseif (TrigLevel < 0.065) && (TrigLevel > 0.005)
    RespLevel = {'None', 'Unsure', 'Small', 'High'};
    RespType = {'Free Label', 'N/A', 'Somatosensory', 'Motor', 'Hallucination', 'Speech', 'Auditory', 'Visual'};
    RespArea = {'Free Label', 'N/A', 'Hand', 'Arm', 'Leg', 'Foot', 'Face', 'Tongue'};
    
    % ~~~~~~~ Response Level
    %Only evaluate in the absence of a BP trigger
    RespByte = uint8(x(TrigI+SamplesPerStimPar/2,3));
    QRespLevel = bitand(RespByte,uint8(3));
    RespLevelStr = RespLevel(QRespLevel+1)
    QRespType = bitshift(bitand(RespByte,uint8(28)),-2); 
    RespTypeStr = RespType(QRespType+1)
    QRespArea = bitshift(RespByte,-5); 
    RespAreaStr = RespArea(QRespArea+1)
else
    disp('No trigger no found')
end
