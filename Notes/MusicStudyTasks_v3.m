%% MUSIC STUDY FUNCTIONAL MRI TASKS
% Script Written by: Kevin Japardi
% Last Modified: 10/28/2016

%% LIMB SCALE TASK
% 6 Performance Blocks: 3 Scale and 3 Improv (1 minute per block)
% 5 Rest Blocks (20 seconds each) (old version: 30 seconds)

% AUDIO: 120 bpm Metronome
% Audio File Name: 06_Metronome_Beat_120_BPM.wav

% TOTAL TIME: 7 minutes and 45 seconds

%% LIMB JAZZ TASK
% 10 Performance Blocks: 5 Melody and 5 Improv (1 minute per block)
% 9 Rest Blocks (20 seconds each)

% AUDIO: Jamey Aebersold Vol 57 Minor Blues in All Keys, C Minor Blues
% Audio File Name: 01_C_Minor_Blues_segment1.wav (spliced from original music file)

% TOTAL TIME: 13 minutes

%% CLEAR CURRENT WORKSPACE
close all;
clear all;

%% SCRIPT DETAILS
script = struct('name', 'MusicStudyTasks_v2.m', 'revisionDate', '10/28/2016', 'PsychtoolboxVersion', PsychtoolboxVersion, 'matlabVersion', version, 'currentDate', datestr(now, 'mmmm dd, yyyy HH:MM:SS.FFF AM'));
script.path = which(script.name);

%% SCRIPT INPUTS
design.subjectID = input('Enter Subject ID: ', 's');
type = input('Scan [1] or Test[2]: ');
task = input('Scale Task [1] or Jazz Task [2]: ');

%% TASK PARAMETERS
var = struct('fonttype', 'Helvetica', 'fontsize', 60, 'abs_start', []);
flip = [];

%% TASK ORDER
if task == 1 % LIMB SCALE TASK
    design.task = 'scale';
    cnames = {'Scale', 'Improv'};
    design.wavfile = 'MusicStim/06_Metronome_Beat_120_BPM.wav';
    
    fprintf('Six Randomization Possibilities\n');
    design.randnum = input('Enter Randomization Number: ');
elseif task == 2 % LIMB JAZZ TASK
    design.task = 'jazz';
    cnames = {'Melody', 'Improv'};
    design.wavfile = 'MusicStim/01_C_Minor_Blues_segment1.wav';
    
    fprintf('Thirteen Randomization Possibilities\n');
    design.randnum = input('Enter Randomization Number: ');
end

if type == 2 % TEST
    design.trials = [1 0 2];
    design.timing = [8 4 8];
else
    load('randlist.mat');
    design.trials = trialrand{task}(design.randnum,:);

    design.timing = trialrand{task}(1,:);
    design.timing(design.timing ~= 0) = 60;
    design.timing(design.timing == 0) = 20;
end

for n = 1:length(design.trials)
    if design.trials(n) == 0
        design.list{n} = 'Rest';
    else
        design.list(n) = cnames(design.trials(n));
    end
end
clear trialrand cnames;

%% INITIALIZE SOUND + LOAD MUSIC FILE (.wav)
InitializePsychSound;

if str2num(script.matlabVersion(14:17)) < 2012
    [y, freq] = wavread(design.wavfile);
else
    [y, freq] = audioread(design.wavfile);
end

wavedata = y';
nrchannels = size(wavedata,1); % # of rows == # of channels

% Set to 2 channels if only 1 channel exists
if nrchannels < 2
    wavedata = [wavedata ; wavedata];
    nrchannels = 2;
end

% Open the default audio device [], with default mode [] (==Only playback),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of freq and nrchannels sound channels.
pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
PsychPortAudio('FillBuffer', pahandle, wavedata);

%% TRIGGER & BUTTON INFO
KbName('UnifyKeyNames');
FlushEvents('keyDown');

TRKey1 = KbName('5'); % TR signal key 932
TRKB = KbName('5%');  % Keyboard TR (Mac)

%% HID_PROBE
% If a scan, choose the FORP Button Box.
% If a behavioral test, choose the MAC keyboard.

subj = ['subject ' design.subjectID];
[device, device_name] = hid_probe(subj);
design.hid_probe_info = [device, device_name];

try
    %% INITIALIZE SCREEN
    
    if length(Screen('Screens')) == 2
        screens = 1;
    else
        screens = 0;
    end
    
    Screen('Preference', 'VisualDebugLevel', 1);

    [w, rect] = Screen('OpenWindow', screens, 0, []);
    HideCursor;

    black = BlackIndex(w);
    white = WhiteIndex(w);

    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    Screen('TextFont', w, var.fonttype);
    Screen('TextSize', w, var.fontsize - 15);
    DrawFormattedText(w, 'Waiting for scanner to start...', 'center', 'center', white);
    Screen('Flip',w);

    while 1
        [keyIsDown, var.abs_start, keyCode] = KbCheck(-1);
        if keyCode(TRKey1) || keyCode(TRKB)
            break;
        end
    end
    DisableKeysForKbCheck(KbName('5'));

    %% RUNNING THE TASK
    Screen('TextSize', w, var.fontsize);
    DrawFormattedText(w, '10', 'center', 'center', white);
    flip.screens(1) = Screen('Flip', w, var.abs_start);    
    
    for n = 9:-1:1
        DrawFormattedText(w, num2str(n), 'center', 'center', white);
        flip.screens(1) = Screen('Flip', w, var.abs_start + 2*(10-n));
    end
    
    DrawFormattedText(w, design.list{1}, 'center', 'center', white);
    flip.screens(1) = Screen('Flip', w, var.abs_start + 20);

    var.audiotiming(1) = PsychPortAudio('Start', pahandle, 0, 0, 1, []);
    audiostat(:,1) = PsychPortAudio('GetStatus', pahandle);
    WaitSecs(design.timing(1) - 0.25);
    PsychPortAudio('Stop', pahandle);
    
    for n = 2:length(design.trials)
        Screen('TextSize', w, var.fontsize);
        DrawFormattedText(w, design.list{n}, 'center', 'center', white);
        flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + design.timing(n-1));
        
        if design.trials(n) ~= 0
            var.audiotiming(n) = PsychPortAudio('Start', pahandle, 0, 0, 1, []);
            audiostat(:,1) = PsychPortAudio('GetStatus', pahandle);
            WaitSecs(design.timing(n) - 0.25);
            PsychPortAudio('Stop', pahandle);
        end
    end

    Screen('TextSize',w, var.fontsize - 15);
    DrawFormattedText(w, 'Task Complete', 'center', 'center', white);
    Screen('Flip', w, flip.screens(end) + design.timing(end));
    WaitSecs(4);
    flip.screens = flip.screens - var.abs_start;
    var.audiotiming(var.audiotiming ~= 0) = var.audiotiming(var.audiotiming ~= 0) - var.abs_start;
    
    PsychPortAudio('Close', pahandle); % Close audio device
    Screen('CloseAll');

    % Saving Data
    save(['Data/BIGC_', design.subjectID, '_', design.task, '_', datestr(now,30), '.mat'], 'script', 'design', 'var', 'flip');

catch
    Screen('CloseAll');
    PsychPortAudio('Close', pahandle);
    fprintf('Script Did Not Work\n');
end





