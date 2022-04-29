function [D,montagefname,montage] = spm_uomeeg_scalpcurrentdensity(S)
%  FORMAT: [D,montagefname,montage] = spm_uomeeg_scalpcurrentdensity(S)
%  
%  Computes surface Laplacian (current density) using FieldTrip's
%  ft_scalpcurrentdensity (hacked to output montage) and applies it using
%  spm_eeg_montage.
% 
%  INPUT: Struct 'S' with fields:
%   S.D            - MEEG object or filename of MEEG object
%   S.montagefname - Filename for output montage (def: montage_Laplace_%s)
%   S.apply        - Apply montage? (1=yes | 0=no) (def: 1)
%   S.newprefix    - Output prefix of data file (if apply) (def: MLaplace_)
%  OUTPUT:
%   D
%   montage        - montage for Laplacian
%   montagefname   - montage filename
%  NOTE:
%   Requires function ft_scalpcurrentdensity_jt.m (hacked to output the montage) 
%   to be in the spm/external/fieldtrip folder.
%
%  spm_uomeeg tools
%  by Jason Taylor (29/04/2022) jason.taylor@manchester.ac.uk
%
%-------------------------------------------------------------------------

% - This requires a hacked version of Field Trip's scalpcurrentdensity function,
%   ft_scalpcurrentdensity_jt.m -- unfortunately, this must be placed in the same
%   directory as the original. Type 'which ft_scalpcurrentdensity' to find out
%   where to copy the modified file.
if isempty(which('ft_scalpcurrentdensity_jt'))
    ftdir = fileparts(which('ft_scalpcurrentdensity'));
    fprintf('\nCannot find ft_scalpcurrentdensity_jt.m !!\n')
    error('ERROR: ft_scalpcurrentdensity_jt.m not found in %s\n',ftdir);
end

%% Load SPM-format data file:
D = spm_eeg_load(S.D);
[~,fstem] = fileparts(D.fname);
try montagefname = S.montagefname;
catch, montagefname = sprintf('montage_Laplace_%s.mat',fstem);
end
try apply = S.apply;
catch, apply = 1;
end
if apply
    try newprefix = S.newprefix; catch, newprefix = 'MLaplace_'; end
end

fprintf('\n\n');
fprintf('++ %s\n',datestr(now));
fprintf('++ RUNNING spm_uomeeg_scalpcurrentdensity ON %s\n',D.fname);
if apply
    fprintf('++ OUTPUT prefix: %s\n',newprefix);
end

%% Compute Laplace transform weights:

eeginds = indchantype(D,'EEG');

% Convert to fieldtrip format:
data = spm2fieldtrip(D);

% hack(!) to get rid of non-EEG channels:
chkeep = intersect(1:74,indchantype(D,'EEG'));
data.label = data.label(chkeep);
data.trial = data.trial(1);
data.trial{1} = data.trial{1}(chkeep,:);
data.time = data.time(1);
data.trialinfo = data.trialinfo(1);
data.elec.chanpos = data.elec.chanpos(chkeep,:);
data.elec.chantype = data.elec.chantype(chkeep);
data.elec.chanunit = data.elec.chanunit(chkeep);
data.elec.elecpos = data.elec.elecpos(chkeep,:);
data.elec.label = data.elec.label(chkeep);
try data.elec.tra = data.elec.tra(chkeep,chkeep); catch; end

% Create Laplace montage:
cfg = [];
cfg.method         = 'spline';
cfg.trials         = 'all';

[~,montage] = ft_scalpcurrentdensity_jt(cfg,data);
montage.labelorg = montage.labelold;
montage = rmfield(montage,'labelold');
%[~,~,eeginds_interp] = intersect(eegchans,data.elec.label,'stable');
% ^ added to align indices in repair and tra! (jt 21/Aug/2019)
%   Thanks to Emily Pye and Nayab Begum for finding this bug.

%tra = eye(length(indchantype(D,'EEG')));
%tra(eeginds_bad,:) = 0;
%tra(eeginds_bad,eeginds) = repair(eeginds_interp,:);
% ^ edited to align indices in repair and tra! (jt 21/Aug/2019)

% Save as montage file:
%clear montage
%montage.tra = tra;
%montage.labelorg = chanlabels(D);
%montage.labelnew = chanlabels(D);
%montage.labelorg = chanlabels(D,indchantype(D,'EEG'));
%montage.labelnew = chanlabels(D,indchantype(D,'EEG'));
save(montagefname,'montage');

% Plot as scaled image:
spm_figure('Clear','Graphics');
fig = spm_figure('GetWin','Graphics');
imagesc(montage.tra);
title('Surface Laplacian montage');
colormap jet
axis image
xlabel('channel'); ylabel('channel');
set(gca,'xtick',1:D.nchannels); set(gca,'xticklabel',chanlabels(D));
set(gca,'ytick',1:D.nchannels); set(gca,'yticklabel',chanlabels(D));
set(gca,'fontsize',8)
fprintf('++ Surface Laplacian montage written to %s\n',montagefname);
print(fig,'-dpng',sprintf('montage_Laplace_%s.png',fstem));


%% Apply montage:
if apply
    fprintf('++ Applying montage to interpolate bad channel(s)\n')
    
    S=[];
    S.D             = D.fname;
    S.mode          = 'write';
    S.prefix        = newprefix;
    S.montage       = montagefname;
    S.keepothers    = 1;
    S.keepsensors   = 1;
    S.updatehistory = 1;
    
    D = spm_eeg_montage(S);
    
    fprintf('++ Laplace-transformed data saved to %s\n',D.fname);
    
    % Change units to V/m^2 
    D = units(D, eeginds, 'V/m^2');
    save(D);
    
else
    fprintf('++ NOT applying Surface Laplacian montage, per request.\n');
    fprintf('++ (ignore the automatic fieldtrip message above ^)\n');
end

return
