% Quick code to plot single time- and frequency-window averaged topographies 
% from SPM12 MEEG time-frequency data. (jt 08/Sep/2021)

%% Parameters

% Filename, time window, condition:
fname   = 'mtf_fcMICA_effMdspmeeg_P105_T1.mat';
twin    = [300 500]; % (ms) start and end of time-window
fwin    = [4 7]; % (Hz) start and end of freq-window
cond    = 'StudiedPrimed';

% Topo options (see spm_eeg_plotScalpData.m)
opts = [];
opts.type      = 'EEG'; % channel type (e.g., 'EEG')
opts.noButtons = 0;     % remove buttons (chan name/pos) from plot? (1|0)
opts.plotpos   = 1;     % plot sensor positions? (1|0)
opts.cbar      = 1;     % add colorbar to plot? (1|0)
%opts.min       = -13;   % min colour limit (value)
%opts.max       = 13;    % max colour limit (value)


%% Do it:

% Load data:
D = spm_eeg_load(fname);

% Get channel info:
eeginds = indchantype(D,'EEG');
eeglabs = chanlabels(D,eeginds);
eegpos = coor2D(D,eeginds);

% Extract data, average over time-window:
d = selectdata(D,eeglabs,fwin,twin/1000,cond);
md = squeeze(mean(mean(d,3),2));

% Plot topography:
fig = figure('color','w');
opts.f = fig; % use new figure
spm_eeg_plotScalpData(md,eegpos,eeglabs,opts);

% Give it a title:
title(sprintf('Topography of %s (%d-%dHz %d-%dms)',strrep(cond,'_',' '),fwin,twin));

% Save it? -- uncomment to save!
%saveas(fig,sprintf('Topo_%s_%d-%dHz_%d-%dms.fig',strrep(cond,' ','_'),fwin,twin),'fig');
%saveas(fig,sprintf('Topo_%s__%d-%dHz_%d-%dms.png',strrep(cond,' ','_'),fwin,twin),'png');
