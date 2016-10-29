function surf1(subjectID,inputDevice,exptDevice,w,test_tag)

% ====================
% DEFAULTS
% ====================

%% Paths %%
basedir = pwd;
datadir = fullfile(basedir, 'data');
screendir = fullfile(basedir, 'stimuli');
stimdir = fullfile(basedir, 'stimuli/surf1');
designdir = fullfile(basedir, 'designs');
utilitydir = fullfile(basedir, 'ptb-utilities');
addpath(utilitydir)

%% Text %%
theFont='Arial';    % default font
theFontSize=46;     % default font size
fontwrap=42;        % default font wrapping (arg to DrawFormattedText)

%% Timing %%
pdur = 1.75;   % max duration of photo (s)

%% Response Keys %%
trigger = KbName('5%');
valid_keys = {'1!' '2@' '3#' '4$'};

% ====================
% END DEFAULTS
% ====================

%% Print Title %%
script_name='-- Image Observation Test --'; boxTop(1:length(script_name))='=';
fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)

if nargin==0

    %% Get Subject ID %%
    subjectID = ptb_get_input_string('\nEnter subject ID: ');

    %% Setup Input Device(s) %%
    inputDevice = ptb_get_resp_device('Choose Participant Response Device'); % input device
    exptDevice = ptb_get_resp_device('Choose Experimenter Response Device'); % input device

    %% Initialize Screen %%
    w = ptb_setup_screen(0,250,theFont,theFontSize); % setup screen

end
resp_set = ptb_response_set(valid_keys); % response set
screenres = w.res(3:4); % screen resolution

%% Initialize Logfile (Trialwise Data Recording) %%
d=clock;
logfile=sprintf('sub%s_surf1.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

%% Load Design and Setup Seeker Variable %%
load([designdir filesep 'surf1_design.mat'])
ntrials = length(Seeker(:,1));
Seeker(:,6:8) = 0;
for i = 1:length(Seeker)
    if Seeker(i,3)==2
        Seeker(i,3)=0;
    end
end
totalTime = round(Seeker(end,5) + pdur + 6);
display(totalTime)

%% SEEKER column key %%
% 1 - trial #
% 2 - condition (1=HH, 2=HM, 3=HD, 4=LH, 5=LM, 6=LD)
% 3 - correct response (0=No Press, 1=Press)
% 4 - slide # (corresponds to order in stimulus dir)
% 5 - scheduled stimulus onset
% 6 - (added above) actual stimulus onset (s)
% 7 - (added above) actual response [0 if NR]
% 8 - (added above) response time (s) [0 if NR]

%% Load Stimuli %%
DrawFormattedText(w.win,'LOADING','center','center',w.white,fontwrap);
Screen('Flip',w.win);
stimFiles = files([stimdir filesep '*jpg']);
for i = 1:length(Seeker(:,4))
    slideName{i} = stimFiles{Seeker(i,4)};
    slideTex{i} = Screen('MakeTexture',w.win,imread(slideName{i}));
end
instructTex = Screen('MakeTexture', w.win, imread([screendir filesep 'surf1_instructions.jpg']));
fixTex = Screen('MakeTexture', w.win, imread([screendir filesep 'fixation.jpg']));
reminderTex = Screen('MakeTexture', w.win, imread([screendir filesep 'motion_reminder.jpg']));

% ====================
% START TASK
% ====================

%% Present Instructions %%
Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

%% Present Motion Reminder %%
KbWait(exptDevice);
Screen('FillRect', w.win, w.black); Screen('Flip',w.win); WaitSecs(.25);
Screen('DrawTexture',w.win,reminderTex); Screen('Flip',w.win);

%% Wait for Trigger to Start %%
DisableKeysForKbCheck([]);
secs=KbTriggerWait(trigger,inputDevice);
anchor=secs;

%% End here if just running Test %%
if exist('test_tag','var') && test_tag, return, end

%% Loop Over Trials %%
try

    for t = 1:ntrials

        %% Present Fixation %%
        Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);

        %% Present Blank and Prepare Photo Stimulus While Waiting %%
        Screen('DrawTexture',w.win,slideTex{t});
        WaitSecs('UntilTime', anchor + Seeker(t,5));

        %% If a Repeat, Look for Response %%
        Screen('Flip',w.win);
        onset = GetSecs;
        Seeker(t,6) = onset - anchor;
        Screen('DrawTexture',w.win, fixTex);
        if Seeker(t,3)
            resp = [];
            [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, pdur);
            offset = GetSecs;
            Screen('Flip',w.win);
            if isempty(resp)
                [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, .45);
                rt = rt+pdur;
            end
            if ~isempty(resp)
                Seeker(t,7) = str2num(resp(1));
                Seeker(t,8) = rt;
            end
        else
            WaitSecs('UntilTime', anchor + Seeker(t,5) + pdur);
            Screen('Flip',w.win);
        end

        %% Save Data to Logfile
        fprintf(fid,[repmat('%d\t',1,size(Seeker,2)) '\n'],Seeker(t,:));

    end

    %% Wait Until End %%
    WaitSecs('UntilTime', anchor + totalTime);

catch

    Screen('CloseAll');
    Priority(0);
    ShowCursor;
    psychrethrow(psychlasterror);

end

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('surf1_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([datadir filesep outfile], 'subjectID', 'Seeker', 'slideName');
catch
	fprintf('couldn''t save %s\n saving to surf1.mat\n',outfile);
	save surf1
end;

if nargin==0
    %% Exit %%
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
end


