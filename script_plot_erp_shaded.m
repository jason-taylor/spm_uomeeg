% Some quick code to plot SPM12 ERP/F with error shading.
%   Jason Taylor - 12/05/2021 - jason.taylor@manchester.ac.uk

%% Parameters

% File name:
fname   = 'effMdspmeeg_run_01_sss.mat';

% Channel:
chanlab = 'EEG070';

% Error statistic:
err_stat = 'sem'; % sem or std

% Conditions:
condlabs = {
    'Famous'
    'Scrambled'
};

% Plot colours (per condition):
pcols = {
    [0 0 1] % blue
    [1 0 0] % red
};

% Fill colours (per condition):
fcols = {
    [.7 .7 1]
    [1 .7 .7]
};


%% Load data & extract epochs (loop over conditions)

D = spm_eeg_load(fname);
t = D.time*1000;

figure;

for cl=1:length(condlabs)
    condlab=condlabs{cl};
    pcol=pcols{cl};
    fcol=fcols{cl};
    
    d = selectdata(D,chanlab,[],condlab);
    
    % Alt: Good trials only
    % d = selectdata(D,chanlab,[],[]);
    % ind_cond = indtrial(D,condlab,'GOOD');
    % d = d(:,:,ind_cond);
    
    % Compute average and SD (or SEM)
    dm = squeeze(mean(d,3));
    switch err_stat
        case 'sem'
            ds = std(d,0,3)/sqrt(size(d,3)); % SEM
        case 'std'
            ds = std(d,0,3); % SD
    end
    
    % Define region to be shaded
    hi = dm+ds;
    lo = dm-ds;
    a = [t t(end:-1:1)]';
    b = [hi lo(end:-1:1)]';
    
    % Plot shaded error region:
    fill(a,b,'b','facecolor',fcol,'edgecolor',fcol,'linewidth',1,'facealpha',.5)
    hold on;
    % Plot mean:
    plot(t,dm,'-','color',pcol,'linewidth',2);
    axis tight

end
