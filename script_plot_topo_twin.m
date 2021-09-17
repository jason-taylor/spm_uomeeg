% Quick code to plot single time-window-averaged topographies from 
% SPM12 MEEG data. (jt 01/Feb/2021)

%% Parameters

% Filename, time window, condition:
fname   = 'Merged_CG_erp_nback.mat';
twin    = [300 500]; % (ms) start and end of time-window
cond    = 'target1 CG_erp_nback';

% % Uncomment to plot the array on a solid green topography:
% twin    = [];
% cond    = [];

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
if isempty(twin) && isempty(cond)
    md = zeros(length(eeginds),1);
else
    d = selectdata(D,eeglabs,twin/1000,cond);
    md = squeeze(mean(d,2));
end

% Plot topography:
fig = figure('color','w');
opts.f = fig; % use new figure
spm_eeg_plotScalpData(md,eegpos,eeglabs,opts);

% Give it a title:
if isempty(twin) && isempty(cond)
    colorbar off
else
    title(sprintf('Topography of %s (%d-%dms)',strrep(cond,'_',' '),twin));
end

% Save it? -- uncomment to save!
if isempty(twin) && isempty(cond)
    saveas(fig,'EEGarray.fig','fig');
    saveas(fig,'EEGarray.png','png');
else
    saveas(fig,sprintf('Topo_%s_%d-%dms.fig',strrep(cond,' ','_'),twin),'fig');
    saveas(fig,sprintf('Topo_%s_%d-%dms.png',strrep(cond,' ','_'),twin),'png');
end
