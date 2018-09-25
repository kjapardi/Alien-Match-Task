%% Alien Match Task
% Script Written by: Kevin Japardi
% Last Modified: 9/4/2017
%
% TASK DETAILS
% Run Count: 1P, 1C, 3C, 3P
% Run Time: 234 or 218 seconds (3.9 or 3.633 minutes)
% Rest (15s), Instructions (15s), Task (6s or 4s)
% Rest | Instructions | Task | Rest | Task | Rest | Task | Rest | Task | Rest

clear all;

% Script Variables
script.name = 'AlienMatchTask.m';
script.path = which(script.name);
script.revisionDate = '7/2/2018';
script.PsychtoolboxVersion = PsychtoolboxVersion;
script.matlabVersion = version;

design.currentDate = datestr(now, 'mmmm dd, yyyy HH:MM:SS.FFF AM');
design.hid_probe_info = [];

var.fonttype = 'Helvetica';
var.fontsize = 40;
% var.timing = [15 10]; % Rest/Instructions and Condition

response = [];
flip.screens = [];

% Trigger and Response Button Input
KbName('UnifyKeyNames');
FlushEvents('keyDown');

TRKey1 = KbName('5'); % TR signal key 932
TRKey2 = KbName('6'); % TR signal key 904
TRKB = KbName('5%');  % Keyboard TR (Mac)

allowedKeys = {'1' '1!' '2' '2@'};

%% Script Inputs
design.subjectID = input('Enter Subject ID: ', 's');
design.assignment = input('Enter [C]omprehension or [P]roduction: ', 's');

% Rest/Instructions and Condition
if strcmp(design.assignment, 'C')
    var.timing = [15 6];
elseif strcmp(design.assignment, 'P')
    var.timing = [15 4];
end

% Pre-loading Image Textures
images = dir('Images/Alien/*.jpg');
design.images = {images.name};
clear images;
for n = 1:length(design.images)
    imagecode{n} = imread(['Images/Alien/', design.images{n}]);
end

% Task Instructions
if strcmp(design.assignment, 'C')
    instructions = ['You are going to see two pictures:\n'...
        'one on your left and one on your right.\n\n'...
        'Press the button that is on the side of the picture\n'...
        'that matches the sounds you hear.'];
elseif strcmp(design.assignment, 'P')
    instructions = ['Silently say your bah\n'...
        'so that it matches the picture you see.'];
end

% Image Locations and Trial Order
% 0 = Rest
% 9999 = Instructions
% N = Task Trial
% torder = [0 9999 1 2 3 4 0 5 6 7 8 0 9 10 11 12 0 13 14 15 16 0];
% torder = [0 9999 1 2 3 4 5 6 0 7 8 9 10 11 12 0 13 14 15 16 17 18 0 19 20 21 22 23 24 0];
% torder = [0 9999 1 2 3 4 5 6 7 8 0 9 10 11 12 13 14 15 16 0 17 18 19 20 21 22 23 24 0 25 26 27 28 29 30 31 32 0];

load('taskorder.mat');

if strcmp(design.assignment, 'C')
    idata = order.comp;
    torder = [0 9999 1:6 0 7:12 0 13:18 0 19:24 0];
    imageID = order.image{1};
elseif strcmp(design.assignment, 'P')
    idata = order.prod;
    torder = [0 9999 1:8 0 9:16 0 17:24 0 25:32 0];
    imageID = order.image{2};
end

idata(idata == 0) = 400;
idata(idata == 1) = 200;

for n = 1:16
    if strcmp(design.assignment, 'C')
        imageloc{n} = [256:256:256*4; idata(n,:); (256:256:256*4)+200; idata(n,:) + 200];
        imageloc{n} = bsxfun(@minus, imageloc{n}, repmat([150 175 50 75; 0 0 0 0], 2,1));
    elseif strcmp(design.assignment, 'P')
        imageloc{n} = [256*2:256:256*3; idata(n,:); (256*2:256:256*3)+200; idata(n,:) + 200];
        imageloc{n} = bsxfun(@minus, imageloc{n}, repmat([175 50; 0 0], 2,1));
    end
    
    imageloc{n}(2,imageloc{n}(2,:) == 200) = 100;
    imageloc{n}(2,imageloc{n}(2,:) == 400) = 500;
    imageloc{n}(4,imageloc{n}(4,:) == 400) = 300;
    imageloc{n}(4,imageloc{n}(4,:) == 600) = 700;
end

%% INITIALIZE SOUND + LOAD MUSIC FILE (.wav)
InitializePsychSound;

if strcmp(design.assignment, 'C')
    [y{1}, freq] = audioread('AudioFiles/Instructions_for_Comprehension.mp3');
elseif strcmp(design.assignment, 'P')
    [y{1}, freq] = audioread('AudioFiles/Instructions_for_Production.mp3');
end
y{1} = [y{1}' ; y{1}'];

soundstim = {'bah_high-high.mp3', 'bah_high-low.mp3', 'bah_low_high.mp3', 'bah_low-low.mp3'};
nrchannels = 2; % Set to 2 channels if only 1 channel exists
for n = 1:4
    wavedata{n} = audioread(['AudioFiles/', soundstim{n}]);
    wavedata{n} = [wavedata{n}' ; wavedata{n}'];
end

pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);

%% Setting Up Screen and Response Inputs

% Finding Input Device
% If running a scan, choose the FORP Button Box.
% If a behavioral test, choose the MAC keyboard.
subj = ['subject ' num2str(design.subjectID)];
[device, device_name] = hid_probe(subj);
design.hid_probe_info = [device, device_name];

% Initializing Screen
screens = length(Screen('Screens')) - 1;
Screen('Preference', 'VisualDebugLevel', 1);
w = Screen('OpenWindow', screens, 1); % rect = [0 0 length width]
HideCursor;

black = BlackIndex(w);
white = WhiteIndex(w);

% Starting parameters for image appearance and location
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
[w, rect] = PsychImaging('OpenWindow', w, white);

Screen('TextFont', w, var.fonttype);
Screen('TextSize', w, var.fontsize);
DrawFormattedText(w, 'Waiting for scanner to start...', 'center', 'center', black);
Screen('Flip',w);

% Clear keyboard queue
while KbCheck(-1)
end

while 1
    [keyIsDown, TimePt, keyCode] = KbCheck(-1);
    if ( keyCode(TRKey1) || keyCode(TRKey2) || keyCode(TRKB) )
        disp('Scan Has Begun');
        var.abs_start = TimePt;
        break;
    end
end
DisableKeysForKbCheck([KbName('5'), KbName('6')]);

%% Running Alien Match Task
for n = 1:length(torder)
    if torder(n) == 0 % Rest Interval
        Screen('TextSize', w, var.fontsize);
        DrawFormattedText(w, '+', 'center', 'center', black);
        DrawFormattedText(w, 'Rest Now', 'center', rect(4)*(0.6), black);
        
        if n == 1
            flip.screens(n) = Screen('Flip', w);
        else
            flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(2));
        end

    elseif torder(n) == 9999
        Screen('TextSize', w, var.fontsize);
        DrawFormattedText(w, instructions, 'center', 'center', black);
        PsychPortAudio('FillBuffer', pahandle, y{1});
        flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(1));

        var.audiotiming(1) = PsychPortAudio('Start', pahandle, 0, 0, 1, []);
        audiostat(:,1) = PsychPortAudio('GetStatus', pahandle);

        if strcmp(design.assignment, 'C')
            WaitSecs(10);
        elseif strcmp(design.assignment, 'P')
            WaitSecs(5);
        end
        PsychPortAudio('Stop', pahandle);
        
    else % Task Trial
        tIndex = Screen('MakeTexture', w, imagecode{imageID(torder(n))});
        if strcmp(design.assignment, 'C')
            Screen('DrawTextures', w, repmat(tIndex,1,4), [], imageloc{torder(n)});
            Screen('DrawLine', w, [0 0 0], rect(3)/2, 100, rect(3)/2, 700, 3);
            PsychPortAudio('FillBuffer', pahandle, wavedata{order.answer(torder(n))});
        elseif strcmp(design.assignment, 'P')
            Screen('DrawTextures', w, repmat(tIndex,1,2), [], imageloc{torder(n)});
        end
        
        if torder(n-1) == 0 || torder(n-1) == 9999
            flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(1));
        else
            flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(2));
        end

        if strcmp(design.assignment, 'C')
            var.audiotiming(1) = PsychPortAudio('Start', pahandle, 0, 0, 1, []);
            audiostat(:,1) = PsychPortAudio('GetStatus', pahandle);
            WaitSecs(1.8);
            PsychPortAudio('Stop', pahandle);
            
            while GetSecs() - flip.screens(n) < var.timing(2)
                [secs, key, RT] = GetKeyWithTimeout2(device, allowedKeys, (var.timing(2) - (GetSecs() - flip.screens(n))));
                if ~strcmp(key, 'T')
                    response.time(torder(n)) = secs - var.abs_start;
                    if isstr(key)
                        response.key(torder(n)) = str2num(key(1));
                    else
                        response.key(torder(n)) = key(1);
                    end
                    response.RT(torder(n)) = RT;
                end
            end
        end
    end
end

WaitSecs(var.timing(2));
PsychPortAudio('Close', pahandle);
Screen('CloseAll');
flip.screens = flip.screens - var.abs_start;

% Save Output Data
save(['Data/AlienTask_', design.assignment, '_', num2str(design.subjectID), '.mat'], 'script', 'design', 'var', 'response', 'flip');

    









