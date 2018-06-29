function [D,bads,corrfname] = spm_uomeeg_findbadchans(S)
% Identify and mark as bad any channels with a sub-threshold correlation
% with its N nearest neighbours. 
%  FORMAT: [D,bads] = spm_uomeeg_findbadchans(S)
%  INPUT: Struct 'S' with fields:
%   S.D            - MEEG object or filename of MEEG object
%   S.thresh       - NN correlation z-score threshold (default: -3)
%   S.nNN          - Number of nearest neighbours to consider (def: 3)
%
%  OUTPUT: 
%   D              - data with bad chans marked bad (also saved)
%   bads           - indices of bad channels
%   corrfname      - filename output (correlations, means, zscores)
%
%  spm_uomeeg tools ** HIGHLY EXPERIMENTAL **
%  by Jason Taylor (09/Mar/2018) jason.taylor@manchester.ac.uk

% *Base it on z-score instead of r thresh?

%--------------------------------------------------
% This function looks for correlations between each channel and its 3
% nearest neighbours, which should generally be high because of the spatial
% smoothness of EEG. It goes through iterations of removing a single bad
% channel, then choosing the 3 NNs for each channel omitting those
% previously labelled bad (because it's not fair to expect a high
% correlation with a bad channel). 

% Check inputs:
try thresh = S.thresh;     catch, thresh = -3;  end
try nNN = S.nNN;           catch, nNN = 3;      end

% Load SPM-format data file:
D = spm_eeg_load(S.D);
[~,fstem] = fileparts(D.fname);

fprintf('\n\n');
fprintf('++ %s\n',datestr(now));
fprintf('++ RUNNING spm_uomeeg_findbadchans ON %s\n',D.fname);
fprintf('++ USING: thresh = %g\tnNN = %d\n',thresh,nNN);


%% Find bad channels

% Note: includes those already labelled as 'bad'
% (but they will still be marked bad in the end)
goods = indchantype(D,'EEG');

% Initialise:
zcnnm = -Inf; i=0; bads=[];
allcnnm={}; allR={}; allz={};

while min(zcnnm)<thresh
    i=i+1; % iterate
    fprintf('++ Iteration %d ... ',i);
    % Get correlations:
    d = selectdata(D,chanlabels(D,goods),[],[]);
    R = corrcoef(reshape(d,size(d,1),size(d,2)*size(d,3))');
    allR{i} = R;
    % Get NNs:
    pos = D.coor2D(goods)';
    [idx,dist] = knnsearch(pos,pos,'dist','euclidean','k',nNN+1);
    % Get NN correlations for each channel:
    cnn = [];
    for c=1:length(goods)
        jind=idx(c,[2:nNN+1]); % +1 skips self!
        cnn(c,:) = R(c,jind);
    end
    cnnm = mean(cnn,2); % mean over NNs
    allcnnm{i} = cnnm;
    zcnnm = (cnnm-mean(cnnm))/std(cnnm);
    allz{i} = zcnnm;
    % Plot topography, histogram:
    %     spm_eeg_plotScalpData(cnnm,pos,D.chanlabels(goods));
    %     set(gca,'clim',[0 .6]);
    %     colormap gray
    %     title(sprintf('Iteration %d',i));
    %      figure; hist(cnnm,[.05:.05:.95]); title(sprintf('Iteration %d',i));
    %     drawnow
    if min(zcnnm)<thresh
        ind = find(zcnnm==min(zcnnm));
        bads(i) = goods(ind);
        goods = setdiff(goods,bads(i));
        fprintf('MinZ: %.2f (r=%.2f)\tBad: %s\n',zcnnm(ind),cnnm(ind),char(D.chanlabels(bads(i))));
    else
        %fprintf('No corr<%.2f: DONE.\n',thresh)
        fprintf('No Zcorr<%.2f: DONE.\n',thresh)
    end
end
fprintf('++ Found %d bad channels.\n',length(bads));

% Add (to existing) any new bad channels:
if any(bads)
    D = badchannels(D,bads,1);
    D.save;
end

% Save correlation matrixes and mean nn correlation vectors (per iteration)
savefname = sprintf('badchan_correlations_%s',fstem);
save(savefname,'allR','allcnnm','allz');

return