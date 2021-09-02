% Some quick code to plot SPM12 ERP/F with error shading.
%   Jason Taylor - 12/05/2021 - jason.taylor@manchester.ac.uk

% Filename, conditions, etc.
fname   = 'apMcbdspmeeg_run_01_sss.mat';
chanlab = 'EEG070';
condlab = 'Famous';

% Load data & extract epochs
D = spm_eeg_load(fname);
d = selectdata(D,chanlab,[],condlab);

% Alt: Good trials only
% d = selectdata(D,chanlab,[],[]);
% ind_cond = indtrial(D,condlab,'GOOD');
% d = d(:,:,ind_cond);

% Compute average and SD (or SEM)
dm = squeeze(mean(d,3));
%ds = std(d,0,3); % SD
ds = std(d,0,3)/sqrt(size(d,3)); % SEM
t = D.time*1000;

% Define region to be shaded
hi = dm+ds;
lo = dm-ds;
a = [t t(end:-1:1)]';
b = [hi lo(end:-1:1)]';
    
% Plot shaded error region:
figure; 
fill(a,b,'b','facecolor',[.7 .7 .7],'edgecolor',[.7 .7 .7],'linewidth',1,'facealpha',.5)
hold on; 
% Plot mean:
plot(t,dm,'k','linewidth',2);
axis tight
