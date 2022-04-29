function [D,montagefname,montage] = spm_uomeeg_currentdensity(S)
%  FORMAT: [D,montagefname,montage] = spm_uomeeg_currentdensity(S)
%  
%  Computes surface Laplacian (current density) using FieldTrip's
%  ft_currentdensity (hacked to output montage) and applies it using
%  spm_eeg_montage.
% 
%  INPUT: Struct 'S' with fields:
%   S.D            - MEEG object or filename of MEEG object
%   S.montagefname - Filename for output montage
%   S.newprefix    - Output prefix of data file
%  OUTPUT:
%   D
%   montage        - montage for Laplacian
%   montagefname   - montage filename
%  NOTE:
%   Requires function ft_currentdensity_jt.m (hacked to output the montage) 
%   to be in the spm/external/fieldtrip folder.
%
%  spm_uomeeg tools
%  by Jason Taylor (29/04/2022) jason.taylor@manchester.ac.uk
%
%-------------------------------------------------------------------------

% - This requires a hacked version of Field Trip's currentdensity function,
%   ft_currentdensity_jt.m -- unfortunately, this must be placed in the same
%   directory as the original. Type 'which ft_currentdensity' to find out
%   where to copy the modified file.
if isempty(which('ft_currentdensity_jt'))
    ftdir = fileparts(which('ft_currentdensity'));
    fprintf('\nCannot find ft_currentdensity_jt.m !!\n')
    error('ERROR: ft_currentdensity_jt.m not found in %s\n',ftdir);
end

%% Load SPM-format data file:
D = spm_eeg_load(S.D);
[~,fstem] = fileparts(D.fname);
try montagefname = S.montagefname;
catch, montagefname = sprintf('montage_bcinterp_%s.mat',fstem);
end
try newprefix = S.newprefix; 
catch, newprefix = 'MLaplace_'; 
end

fprintf('\n\n');
fprintf('++ %s\n',datestr(now));
fprintf('++ RUNNING spm_uomeeg_currentdensity ON %s\n',D.fname);
fprintf('++ OUTPUT prefix: %s\n',newprefix);


%% Compute Laplace transform weights:

eeginds = indchantype(D,'EEG');
eegchans = chanlabels(D,eeginds);

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
    %cfg.order          = 4;
    %cfg.missingchannel = {};
    %cfg.neighbours     = [];
    cfg.trials         = 'all';
    %cfg.lambda         = 1e-5;
    
    [~,montage] = ft_currentdensity_jt(cfg,data);
    %[~,~,eeginds_interp] = intersect(eegchans,data.elec.label,'stable');
    % ^ added to align indices in repair and tra! (jt 21/Aug/2019)
    %   Thanks to Emily Pye and Nayab Begum for finding this bug.
    
    tra = eye(length(indchantype(D,'EEG')));
    %tra(eeginds_bad,:) = 0;
    %tra(eeginds_bad,eeginds) = repair(eeginds_interp,:);
    % ^ edited to align indices in repair and tra! (jt 21/Aug/2019)
    
    % Save as montage file:
    clear montage
    montage.tra = tra;
    %montage.labelorg = chanlabels(D);
    %montage.labelnew = chanlabels(D);
    montage.labelorg = chanlabels(D,indchantype(D,'EEG'));
    montage.labelnew = chanlabels(D,indchantype(D,'EEG'));
    save(montagefname,'montage');
    xlabel('channel'); ylabel('channel');
    set(gca,'xtick',1:D.nchannels); set(gca,'xticklabel',chanlabels(D));
    set(gca,'ytick',1:D.nchannels); set(gca,'yticklabel',chanlabels(D));
    set(gca,'fontsize',8)
    fprintf('++ Bad-channel interpolation montage written to %s\n',montagefname);
    
    % Plot as scaled image:
    spm_figure('Clear','Graphics');
    fig = spm_figure('GetWin','Graphics');
    imagesc(montage.tra);
    colormap jet
    axis image
    
    title('Bad-channel interpolation montage');
    print(fig,'-dpng',sprintf('montage_badchan_interp_%s.png',fstem));

    
    %% Apply montage?:
    
    if fixbads
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
        
        % Remove 'bad' label from any interpolated channels:
        D = badchannels(D,eeginds_bad,0);
        D.save;
        fprintf('++ Interpolated data saved to %s\n',D.fname);
        
    else
        fprintf('++ NOT applying bad-channel interpolation montage, per request.\n');
        fprintf('++ (ignore the automatic fieldtrip message above ^)\n');
    end

else
    fprintf('++ No bad channels found! No montage will be written.\n');
    if fixbads
        fprintf('++ No interpolated data saved.\n');
    end
    montage = [];
    montagefname = [];
end

return
