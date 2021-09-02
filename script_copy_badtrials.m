% Quick script to apply bad trials from one SPM12 MEEG file to another. 
%  (jt 01/Sep/21)

%% Parameters

% Filenames and output prefix:
fname_arts      = ls('apbfMICA_*.mat'); % EDIT ME
fname_noarts    = ls('MICA_*.mat'); % EDIT ME
prefix_out      = 'icopied_'; % EDIT ME if you like


%% Begin

% Load and check:
D_arts = spm_eeg_load(fname_arts);
bads = badtrials(D_arts);
fprintf('\n\nFile %s has %d bad trials\n',D_arts.fname,length(bads));

D_noarts = spm_eeg_load(fname_noarts);
if any(badtrials(D_noarts))
    error('Bad trials found where they should not be!:\n %s',fname_noarts);
end

% Apply bad trials and save under new filename:
fname_out = [prefix_out fname_noarts];

D = copy(D_noarts,fname_out);
D = badtrials(D,bads,1);
D.save;
fprintf('\n\nFile %s NOW has %d bad trials\n\n',D.fname,length(badtrials(D)));

