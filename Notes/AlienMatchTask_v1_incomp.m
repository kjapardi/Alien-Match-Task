%% Alien Match Task
% Script Written by: Kevin Japardi
% Last Modified: 9/4/2017
%
% TASK DETAILS
% Run Count: 1P, 1C, 3C, 3P
% Run Time: 170 seconds (2.833 minutes)
% Rest (15s), Instructions (15s), Task (20s)
% Rest | Instructions | Task | Rest | Task | Rest | Task | Rest | Task | Rest

% Instructions (C or P): We had 4 sec. of rest + 11 sec. of Instructions and 5 sec. of rest + 10 sec. of instructions, depending whether it was a P or C task.

clear all;

% Script Variables
script.name = 'AlienMatchTask.m';
script.path = which(script.name);
script.revisionDate = '4/16/2018';
script.PsychtoolboxVersion = PsychtoolboxVersion;
script.matlabVersion = version;

design.currentDate = datestr(now, 'mmmm dd, yyyy HH:MM:SS.FFF AM');
design.list = {};
design.hid_probe_info = [];

var.fonttype = 'Helvetica';
var.timing = [3 6]; % Rest/Instructions and Condition
% var.timing = [15 20]; % Rest/Instructions and Condition

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
design.assignment = input('Enter Task (1C, 1P, 3C, 3P, Alien): ', 's');

% Pre-loading Image Textures
images = dir(['Images/', design.assignment,'/*.jpg']);
design.images = {images.name};
clear images;
for n = 1:length(design.images)
    imagecode{n} = imread(['Images/', design.assignment, '/', design.images{n}]);
end

% Task Instructions
if ismember(design.assignment, {'1C', '3C'})
    instructions = [...
        'Choose a picture\n'...
        'that matches sounds you hear'];
elseif ismember(design.assignment, {'1P', '3P'})
    instructions = [...
        'Silently say your bah\n'...
        'so that it matches the picture you see'];
elseif ismember(design.assignment, {'Alien'})
    instructions = [...
        'Silently say your bah\n'...
        'so that it matches the picture you see'];
end

% Trial Order
% 0 = Rest (15s)
% 2 = Instructions (15s)
% 1 = Activity A/B (20s)
% torder = [0 2 1 0 1 0 1 0 1 0];
torder = [0 2 1];

% Image Locations
imageloc = [256:256:256*4; [200 400 400 200]; (256:256:256*4)+200; [400 600 600 400]];
imageloc = bsxfun(@minus, imageloc, repmat([100 125 0 25; 0 0 0 0], 2,1));

%% Setting Up Screen and Response Inputs

% Finding Input Device
% If running a scan, choose the FORP Button Box.
% If a behavioral test, choose the MAC keyboard.
subj = ['subject ' num2str(design.subjectID)];
[device, device_name] = hid_probe(subj);
design.hid_probe_info = [device, device_name];

% Initializing Screen
screens = 0;
Screen('Preference', 'VisualDebugLevel', 1);
w = Screen('OpenWindow', screens, 1); % rect = [0 0 length width]
HideCursor;

black = BlackIndex(w);
white = WhiteIndex(w);

% Starting parameters for image appearance and location
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
[w, rect] = PsychImaging('OpenWindow', w, white);

Screen('TextFont', w, var.fonttype);
Screen('TextSize', w, 30);
DrawFormattedText(w, 'Waiting for scanner to start...', 'center', 'center', black);
bflip = Screen('Flip',w);

while KbCheck(-1); end % Clear keyboard queue
Scanning = 0;
while Scanning ~= 1
    [keyIsDown, TimePt, keyCode] = KbCheck(-1);
    if ( keyCode(TRKey1) || keyCode(TRKey2) || keyCode(TRKB) )
        Scanning = 1; disp('Scan Has Begun');
        var.abs_start = TimePt;
    end
end
DisableKeysForKbCheck([KbName('5'), KbName('6')]);

%% Running Alien Match Task
for n = 1:length(torder)
    if torder(n) == 0 % Rest Interval
        Screen('TextSize', w, 30);
        DrawFormattedText(w, '+\n\nRest Now', 'center', 'center', black);
        if n == 1
            flip.screens(n) = Screen('Flip', w);
        else
            flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(2));
        end

    elseif torder(n) == 1 % Task Trial
        tIndex = Screen('MakeTexture', w, imagecode{1});
        Screen('DrawTextures', w, repmat(tIndex,1,4), [], imageloc);
        Screen('DrawLine', w, [0 0 0], rect(3)/2, 200, rect(3)/2, 600, 3);
        flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(1));

        while GetSecs() - flip.screens(n-1) < var.timing(2)
            [secs, key, RT] = GetKeyWithTimeout2(device, allowedKeys, (var.timing(2) - (GetSecs() - flip.screens(n-1))));
            if ~strcmp(key, 'T')
                response.time(n) = secs - var.abs_start;
                if isstr(key)
                    response.key(n) = str2num(key(1));
                else
                    response.key(n) = key(1);
                end
                response.RT(n) = RT;
            end
        end
        
    elseif torder(n) == 2
        Screen('TextSize', w, 30);
        DrawFormattedText(w, instructions, 'center', 'center', black);
        flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + var.timing(1));
    end

    
end

if torder(end) == 0
    WaitSecs(var.timing(1))
elseif torder(end) == 1
    WaitSecs(var.timing(2));
end
Screen('CloseAll');
flip.screens = flip.screens - var.abs_start;

% Save Output Data
save(['Data/', num2str(design.subjectID), '_scandata.mat'], 'script', 'design', 'var', 'response', 'flip');

    









