%% audiotest.m

clear all;

% Script Variables
design.hid_probe_info = [];
var.fonttype = 'Helvetica';
var.fontsize = 40;
flip.screens = [];

% Trigger and Response Button Input
KbName('UnifyKeyNames');
FlushEvents('keyDown');

TRKey1 = KbName('5'); % TR signal key 932
TRKB = KbName('5%');  % Keyboard TR (Mac)

load('taskorder.mat');

%% INITIALIZE SOUND + LOAD MUSIC FILE (.wav)
InitializePsychSound;

soundstim = {'bah_high-high.mp3', 'bah_high-low.mp3', 'bah_low_high.mp3', 'bah_low-low.mp3'};
nrchannels = 2; % Set to 2 channels if only 1 channel exists
for n = 1:4
    wavedata{n} = audioread(['AudioFiles/', soundstim{n}]);
    wavedata{n} = [wavedata{n}' ; wavedata{n}'];
end
[~, freq] = audioread(['AudioFiles/', soundstim{n}]);

pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);

%% Setting Up Screen and Response Inputs
% Finding Input Device
[device, device_name] = hid_probe('subject');
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
Screen('Flip', w);

% Clear keyboard queue
while KbCheck(-1)
end

Scanning = 0;
while Scanning ~= 1
    [keyIsDown, TimePt, keyCode] = KbCheck(-1);
    if keyCode(TRKey1) || keyCode(TRKB)
        Scanning = 1; disp('Scan Has Begun');
        var.abs_start = TimePt;
    end
end
DisableKeysForKbCheck(KbName('5'));

try
    for n = 1:4
        Screen('TextSize', w, var.fontsize);
        DrawFormattedText(w, num2str(n), 'center', 'center', black);
        PsychPortAudio('FillBuffer', pahandle, wavedata{n});
        
        if n == 1
            flip.screens(n) = Screen('Flip', w, var.abs_start);
        else
            flip.screens(n) = Screen('Flip', w, flip.screens(n-1) + 4);
        end
        var.audiotiming(n) = PsychPortAudio('Start', pahandle, 0, 0, 1, []);

        audiostat(:,n) = PsychPortAudio('GetStatus', pahandle);
        WaitSecs(1.8);
        PsychPortAudio('Stop', pahandle);
    end

    PsychPortAudio('Close', pahandle); % Close audio device
    Screen('CloseAll');
   
    flip.screens = flip.screens - var.abs_start;
    var.audiotiming2 = var.audiotiming - var.abs_start;
catch
    Screen('CloseAll');
    PsychPortAudio('Close', pahandle);
    fprintf('Script Did Not Work\n');
end





