function surf2(subjectID,inputDevice,exptDevice,w,test_tag)

% ====================
% DEFAULTS
% ====================

%% Paths %%
basedir = pwd;
datadir = fullfile(basedir, 'data');
stimdir = fullfile(basedir, 'stimuli/surf2');
screendir = fullfile(basedir, 'stimuli');
practicedir = fullfile(basedir, 'stimuli/surf2_practice');
designdir = fullfile(basedir, 'designs');
utilitydir = fullfile(basedir, 'ptb-utilities');
addpath(utilitydir)

%% Text %%
theFont='Arial';    % default font
theFontSize=54;     % default font size
fontwrap=42;        % default font wrapping (arg to DrawFormattedText)

%% Timing %%
qdur = 1.35; % duration of question (s)
pdur = 1.5;   % max duration of photo (s)
betweendur = .15; % duration of blank screen between question & photo (s)

%% Response Keys %%
trigger = KbName('5%');
valid_keys = {'1!' '2@' '3#' '4$'};
start_keys = {'1!'};

% ====================
% END DEFAULTS
% ====================

%% Print Title %%
script_name='-- Photo Judgment Test --'; boxTop(1:length(script_name))='=';
fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)

if nargin==0

    %% Get Subject ID %%
    subjectID = ptb_get_input_string('\nEnter subject ID: ');

    %% Setup Input Device(s) %%
    inputDevice = ptb_get_resp_device('Choose Participant Response Device'); % input device
    exptDevice = ptb_get_resp_device('Choose Experimenter Response Device'); % input device

end

%% Check for Existing Logfile %%
log = files(['log_surf2*' subjectID '*txt']);
if ~isempty(log)
    tmp = log{1};
    [path name ext] = fileparts(tmp);
    exdata = load(tmp);
    tmpidx = find(exdata(:,9)>0);
    exdata = exdata(1:tmpidx(end),:);
    idx = strfind(name,'design');
    design = str2num(name(idx+length('design')));
    load([designdir filesep 'surf2_designs.mat'])
    Seeker = allSeeker{design};
    continueflag = ptb_get_input_string('\nContinue from last response? (1=Yes, 2=No) ');
    if continueflag
        lastonset = exdata(end,8);
        Seeker(:,6) = Seeker(:,6) - lastonset;
        Seeker(:,7:10) = 0;
        Seeker(:,7) = Seeker(:,6) + qdur + betweendur;
        totalTime = round(Seeker(end,6) + pdur + 6);
        Seeker(1:tmpidx(end),:) = exdata;
        ntrials = length(Seeker(:,1));
    else
        Seeker(:,7:10) = 0;
        Seeker(:,7) = Seeker(:,6) + qdur;
        totalTime = round(Seeker(end,7) + pdur + 6);
        Seeker(1:tmpidx(end),:) = exdata;
        ntrials = length(Seeker(:,1)) - length(exdata(:,1));
    end
else
    %% Load Design and Setup Seeker Variable %%
    load([designdir filesep 'surf2_designs.mat'])
    randidx = randperm(length(allSeeker));
    design = randidx(1);
    Seeker = allSeeker{randidx(1)};
    ntrials = length(Seeker(:,1));
    Seeker(:,7:10) = 0;
    Seeker(:,7) = Seeker(:,6) + qdur + betweendur;
    totalTime = round(Seeker(end,7) + pdur + 6);
end
display(totalTime)

%% Initialize Logfile (Trialwise Data Recording) %%
d=clock;
logfile=sprintf('log_surf2_sub%s_design%d_ava.txt',subjectID,design);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;

if nargin==0
    %% Initialize Screen %%
    w = ptb_setup_screen(0,250,theFont,theFontSize); % setup screen
end
resp_set = ptb_response_set(valid_keys); % response set
resp_set_start = ptb_response_set(start_keys);
%% Font Size %%
Screen('TextSize',w.win,theFontSize);

%% SEEKER column key %%
% 1 - trial #
% 2 - condition (1=HH, 2=HM, 3=HD, 4=LH, 5=LM, 6=LD)
% 3 - correct (normative) response (1=Yes, 2=No)
% 4 - slide # (corresponds to order in stimulus dir)
% 5 - question # (corresponds to order in 'qstim', defined in design.mat)
% 6 - scheduled question onset
% 7 - (added above) scheduled photo onset
% 8 - (added above) actual stimulus onset (s)
% 9 - (added above) actual response [0 if NR]
% 10 - (added above) response time (s) [0 if NR]

%% Load Stimuli %%
DrawFormattedText(w.win,'LOADING','center','center',w.white,fontwrap);
Screen('Flip',w.win);
stimFiles = files([stimdir filesep '*jpg']);
for i = 1:length(Seeker(:,4))
    slideName{i} = stimFiles{Seeker(i,4)};
    slideTex{i} = Screen('MakeTexture',w.win,imread(slideName{i}));
end
instructTex = Screen('MakeTexture', w.win, imread([screendir filesep 'surf2_instructions.jpg']));
fixTex = Screen('MakeTexture', w.win, imread([screendir filesep 'fixation.jpg']));
reminderTex = Screen('MakeTexture', w.win, imread([screendir filesep 'motion_reminder.jpg']));

%% Load Practice Stimuli %%
practiceFiles = files([practicedir filesep '*.jpg']);
for i = 1:length(practiceFiles)
    slidePrac{i} = Screen('MakeTexture',w.win,imread(practiceFiles{i}));
end
pracQs = {'gazing up?' 'looking at the camera?' 'baring teeth?'};

%% Get Coordinates for Centering Questions
for q = 1:length(qstim)
    [xpos(q) ypos(q)] = ptb_center_position(qstim{q},w.win);
end

% ====================
% START TASK
% ====================

%% Present Instructions %%
Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

%% Wait for User to Start %%
[resp rt] = ptb_get_resp(inputDevice, resp_set_start);

%% Practice! %%
try

    for t = 1:3

        %% Present Fixation %%
        Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);

        %% Prepare Quesiton Stimulus While Waiting %%
        idx = cellstrfind(qstim, pracQs{t});
        Screen('DrawText',w.win,pracQs{t},xpos(idx),ypos(idx));
        WaitSecs(2);

        %% Present Question Stimulus and Prepare Blank Screen While Waiting %%
        Screen('Flip',w.win);
        Screen('FillRect', w.win, w.black);
        WaitSecs(qdur);

        %% Present Blank and Prepare Photo Stimulus While Waiting %%
        Screen('Flip',w.win);
        Screen('DrawTexture',w.win,slidePrac{t});
        WaitSecs(betweendur);

        %% Present Photo Stimulus and Wait for Response %%
        Screen('Flip',w.win);
        Screen('DrawTexture',w.win, fixTex);
        resp = [];
        [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, pdur);

        %% Present Fixation and Listen a Little Longer for a Response %%
        Screen('Flip',w.win);
    end

catch

    Screen('CloseAll');
    Priority(0);
    ShowCursor;
    psychrethrow(psychlasterror);

end

WaitSecs(2);
Screen('FillRect', w.win, w.black); Screen('Flip',w.win); WaitSecs(.1);

%% Actual Task Beginning %%
DrawFormattedText(w.win,'The real test will begin in a moment.','center','center',w.white,fontwrap); Screen('Flip',w.win);

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

        %% Prepare Quesiton Stimulus While Waiting %%
        qidx = Seeker(t,5); % index for question (to qstim)
        Screen('DrawText',w.win,qstim{qidx},xpos(qidx),ypos(qidx));
        WaitSecs('UntilTime', anchor + Seeker(t,6));

        %% Present Question Stimulus and Prepare Blank Screen While Waiting %%
        Screen('Flip',w.win);
        Screen('FillRect', w.win, w.black);
        WaitSecs('UntilTime', anchor + Seeker(t,7) - betweendur);

        %% Present Blank and Prepare Photo Stimulus While Waiting %%
        Screen('Flip',w.win);
        Screen('DrawTexture',w.win,slideTex{t});
        WaitSecs('UntilTime', anchor + Seeker(t,7));

        %% Present Photo Stimulus and Wait for Response %%
        Screen('Flip',w.win);
        onset = GetSecs;
        Seeker(t,8) = onset - anchor;
        Screen('DrawTexture',w.win, fixTex);
        resp = [];
        [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, pdur);
        offset = GetSecs;

        %% Present Fixation and Listen a Little Longer for a Response %%
        Screen('Flip',w.win);
        if isempty(resp)
            [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, .75);
            rt = rt+pdur;
        end
        if ~isempty(resp)
            Seeker(t,9) = str2num(resp(1));
            Seeker(t,10) = rt;
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
outfile=sprintf('surf2_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([datadir filesep outfile], 'subjectID', 'Seeker', 'slideName', 'qstim');
catch
	fprintf('couldn''t save %s\n saving to surf2.mat\n',outfile);
	save surf2
end;

if nargin==0
    %% Exit %%
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
end


