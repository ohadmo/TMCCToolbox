function mainScript()

    dirName     = 'C:\Users\Dan\Documents\תואר שני\תזה\data\הקלטות\raw data\rainbow\pre\';
    xlsFileName = 'C:\Users\Dan\Documents\תואר שני\תזה\data\הקלטות\raw data\R01 Subject characteristics.xls';
    [xlsFileData celldata] = xlsread(xlsFileName);
    save xlsData.mat xlsFileData celldata
    stophere = 1;
    currentDir = pwd;
    cd(dirName);
    dirs = dir('*.wav');
    cd(currentDir);
    windowSize = 0.02; %audio window in seconds
    overlap = 0.5;
    %doPlot = 1;
    doPlot = 0;
    zc = [];
    pitchPos = [];
    pitchVal = [];
    energy = [];
    labels = [];
    dataPoints = [];
    for i=1:length(dirs)
        [label] = extractLabel(dirs(i).name, xlsFileData, celldata);
        if isempty(label)
            continue;
        end
        currFile = [dirName dirs(i).name];
        %1 second = Fs bytes of y
        [y, Fs] = wavread(currFile);
        timeIndexes = 2^ nextpow2(round(Fs * windowSize));

        [audioWindow] = audioParting(y', timeIndexes, overlap);
        %load audioWindow.mat;
        a = sin(-2*pi:0.01:2*pi);
        %a = [0 1 2 -1 0 1 2 3 -4 -3 0];
    %     audioWindow = Centalize(a);
        [zc] = computeZeroCrossing(a);
    %     audioWindow = Centalize(audioWindow);
    %     [zc] = computeZeroCrossing(audioWindow);
        [meany,stdy,skewy,kurty] = computeZeroCrossing2(audioWindow, Fs);
        [pitchPos pitchVal] = pitch_detect(audioWindow,Fs);
        [energy] = computeEnergy(audioWindow);
        [mfccVal] = runMFCC(audioWindow,Fs,timeIndexes);
        timeOrder = 1:length(energy);

        %[timeOrder subjectID gender deseaseStage]
        label = [timeOrder' repmat(label, length(timeOrder),1)];

        if doPlot
            subplot(4,1,1); plot(zc); title('ZC');
            subplot(4,1,2); plot(pitchPos); title('pitch positions');
            subplot(4,1,3); plot(pitchVal); title('pitch amplitide');
            subplot(4,1,4); plot(energy); title('short time energy');
        end
        %[zc,pitchPos,pitchVal,energy,meany,stdy,skewy,kurtosisy,
        % MFCC*some number, timeOrder,subjectID,gender,deseaseStage]
        %dataPoints = [dataPoints ; zc pitchPos pitchVal energy meany stdy ...
        %                            skewy kurty mfccVal label];
        dataPoints = [dataPoints ; zc pitchPos pitchVal energy meany stdy ...
                                   mfccVal label];
        stopHere = 1;
    end
    %save data2.mat dataPoints
    save data3.mat dataPoints %dataPoints doesn't include skewy & kurty
    stopHere = 1;
end

function [audioWindow] = audioParting(y, timeIndexes, overlap)
    audioWindow = [];
    jump = round(timeIndexes*overlap);
    hammingWindow = hamming(timeIndexes)';
    for i = 1:jump:length(y)-timeIndexes-1
        %multiply by hamming window
        audioWindow = [audioWindow ; y(i:i+timeIndexes-1).*hammingWindow];
    end
end

function [centeredAudio] = Centalize(audioWindow)
    centeredAudio = audioWindow-repmat(mean(audioWindow,2),1,size(audioWindow,2));
end


function [label] = extractLabel(fileName, xlsFileData, celldata)
    ind1 = strfind(fileName, 'S'); 
    ind2 = strfind(fileName(ind1:end), ' ');
    subjectID = str2num(fileName(ind1+1:ind1+ind2-1));
    rowIndx = find(xlsFileData(:,1)==subjectID);
    if isempty(rowIndx)
        label = [];
        return;
    end
    gender = xlsFileData(rowIndx,2);
    deseaseStage = xlsFileData(rowIndx,7);
    label = [subjectID gender deseaseStage];
    stopHere = 1; 
end




function [zc] = computeZeroCrossing(audioWindow)
    shiftedAndMulted = sign(audioWindow .* [zeros(size(audioWindow,1),1) audioWindow(:,1:end-1)]);
    shiftedAndMulted(shiftedAndMulted == 1) = 0;
    shiftedAndMulted(shiftedAndMulted == -1) = 1;
    b = sign(audioWindow);
    b(b == 0) = -2;
    b(b == -1) = 0;
    b(b == 1) = 0;
    % zc = sum(shiftedAndMulted,2)/(size(audioWindow,2)/2);
    zc = sum(shiftedAndMulted,2) + (sum(b,2)/-2);
end

function [pitchPos pitchVal] = pitch_detect(audioWindow, fs) %Q6
    if nargin < 2
        fs=8e3;
    end
    if size(audioWindow,1)>1
        pitchPos = [];
        pitchVal = [];
        for i = 1:size(audioWindow,1)
            Frame = audioWindow(i,:);
            r=xcorr(Frame); %auto-correlation on the frame
            %the pitch is between 50 - 400 Hz
            maxF=round(fs/50);
            minF=round(fs/400);
            r=r(length(Frame):end);%symetric
            pitchPos = [pitchPos ; find(r==max(r(minF:maxF)))];%find the first max value
            pitchVal = [pitchVal ; r(pitchPos(end))];
        end
    else
        r=xcorr(audioWindow); %auto-correlation on the frame
        %the pitch is between 50 - 400 Hz
        maxF=fs/50;
        minF=fs/400;
        r=r(length(audioWindow):end);%symetric
        pitchPos = find(r==max(r(minF:maxF)));%find the first max value
        PitchVal = r(pitchPos);
    end
end

function energy = computeEnergy(audioWindow)
    energy = (sum((audioWindow.^2),2))/size(audioWindow,2);
end


function [meany,stdy,skewy,kurty] = computeZeroCrossing2(audioWindow, fs)
    %Alex have researched that nbin should be 25
    meany = zeros(size(audioWindow,1),1);
    stdy = zeros(size(audioWindow,1),1);
    skewy = zeros(size(audioWindow,1),1);
    kurty = zeros(size(audioWindow,1),1);
    
    for i = 1: size(audioWindow,1)
        [y yhist ybin]=zcstat(audioWindow(i,:), 25, fs, 0);

        meany(i) = mean(y);
        stdy(i) = std(y);
        skewy(i) = skewness(y);
        kurty(i) = kurtosis(y);
    end
end

%mfcc will activate a bunch of filter on the audio
%mfcc extracts mfcc features
function [mfccVal] = runMFCC(audioWindow,Fs,timeIndexes)
    %creating the mfcc filters
    filtersNum = 26;
    filterOrder = timeIndexes;
    n_coeff = 26;
    mfccFilterBank = melfb(filtersNum, filterOrder,Fs);
    %we use rectWin (=ones) because the window is already multiplied 
    %by hamming window
    mfccVal = mfcc2(audioWindow',rectwin(timeIndexes),mfccFilterBank,n_coeff)';
end