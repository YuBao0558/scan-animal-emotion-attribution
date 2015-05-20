function run_all_tasks(test_tag)
if nargin==0, test_tag=0; end

%===============================================================
% change to study directory
%===============================================================
studyDIR = pwd; cd(studyDIR)
dataDIR = [studyDIR filesep 'data'];
utilityDIR = [studyDIR filesep 'utilities'];
addpath(utilityDIR)

%===============================================================
% start by getting necessary inputs
%===============================================================

% get subject ID
subjectID=input('\nEnter subject ID: ','s');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ','s');
end;

% Participant input device (inputDevice)
subdevice_string='- Choose PARTICIPANT Device -'; boxTop(1:length(subdevice_string))='-';
fprintf('\n%s\n%s\n%s\n',boxTop,subdevice_string,boxTop)
[inputDevice usageName product] = hid_probe;

% Experimenter input device (exptDevice)
subdevice_string='- Choose EXPERIMENTER Device -'; boxTop(1:length(subdevice_string))='-';
fprintf('\n%s\n%s\n%s\n',boxTop,subdevice_string,boxTop)
[exptDevice usageName2 product2] = hid_probe;

% Setup window
w = ptb_setup_screen(0,250,'Arial',54); % setup screen

% check screen resolution
screenres = w.res(3:4); % screen resolution
correctres = [1024 768];
if mean(ismember(screenres,correctres))<1
    fprintf('\n\n\n\n\tScreen resolution must be set to 1024 x 768\n\n\n\n');
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
    return
end

%===============================================================
% run studies & button box tests sequentially
%===============================================================
 
% display message
display_message('Your session will begin shortly. During your session, please do your best to keep your head still, especially while the scanner is running.',w.win,exptDevice)

% test button box
inputDevice = hid_get(usageName,product);
bbtester(inputDevice,w.win)

% ----------------------
% surf 1
% ----------------------
display_message('The first test will be the Image Observation Test (7 minutes). You will see instructions in a moment.',w.win,exptDevice) % message
inputDevice = hid_get(usageName,product);
surf1(subjectID,inputDevice,exptDevice,w,test_tag)  

% ----------------------
% ava
% ----------------------
display_message('You are done with the Image Observation Test. Up next is the Why/How Test (15 minutes). You will see instructions in a moment.',w.win,exptDevice) % message
inputDevice = hid_get(usageName,product);
ava_practice(subjectID,inputDevice,w,test_tag);
inputDevice = hid_get(usageName,product);
ava(subjectID, inputDevice, exptDevice, w, test_tag)          % task
display_message('You are done with the Why/How Test. Up next is a 4 minute anatomical scan. During the scan, relax and keep your head still.',w.win,exptDevice) % message

% ----------------------
% surf 2
% ----------------------
display_message('The last test is a Photo Judgment Test (16 minutes). You will see instructions in a moment.',w.win,exptDevice) % message
inputDevice = hid_get(usageName,product);
surf2(subjectID,inputDevice,exptDevice,w,test_tag)  
display_message('Your session is complete. We will be with you in just a moment.',w.win,exptDevice) % message

%===============================================================
% Close Screen
%===============================================================
Screen('CloseAll');
Priority(0);
ShowCursor;

% move logfiles into data directory
movefile('*.log',dataDIR)


