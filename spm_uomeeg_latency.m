function [ltable] = spm_uomeeg_latency(S)

% Extract time-window averaged data from an 
% SPM12-format data file. Output is a long format table 
% with column headers
%
% Input: 
%   S struct with (optional) subfields:
%       D           - filename (.mat) of SPM12 M/EEG object
%                     OR cell array of filenames 
%                     OR leave blank to be prompted
%       chans       - cell array of channel names (in D.chanlabels)
%       twins       - cell array of start/end times
%       conds       - cell array of condition labels (in D.condlist)
%       pol         - cell array of 'pos' and 'neg' to reflect positive or
%                   negative deflection. Length must equal n twins
%
% Output:
%   ltable    - table of data, long format (will make an option for this
%               eventually)
%            
% Stephen Ball (But mostly Jason's code, really) 29/09/23
%
%% Get params

try fnames = S.D; catch [fnames,dirs] = spm_select(Inf,'mat','Select SPM12 MEEG files',{},pwd); end

if isstr(fnames)
    for i=1:size(fnames,1)
        D{i} = spm_eeg_load(fnames(i,:));
    end
elseif iscell(fnames)
    for i=1:size(fnames)
        D{i} = spm_eeg_load(fnames{i});
    end
end
 
try conds = S.conds; catch, conds = []; end
try twins = S.twins; catch, twins = []; end
try chans = S.chans; catch, chans = []; end
try pol = S.pol;  catch,  pkpol = 'pos'; end

if isempty(conds)
    conds = D{1}.condlist';
end

if isempty(twins)
    switch D{1}.transformtype
        case {'time'}
            twins = {D{1}.time([1 end])*1000};
        case {'TF'}
            error("Wrong data tranform type - must be time domain.")
        otherwise
            twins = {[]};
    end
elseif ~iscell(twins)
    twins = {twins};
end
if isempty(chans)
    chans = D{1}.chanlabels;
elseif ~iscell(chans)
    chans = {chans};
end

% format table
varnames = {'subjectIndex','fileName','all_info','channel','t_win','condition','analysis','value'};
ltable =cell2table(cell(0,length(varnames)),'VariableNames', varnames);

twcolnames{1}='subjectIndex';
twcolnames{2}='fileName';

%% Load data

for d_idx=1:length(D) % why does matlab not have python enumerate equivalent
    for chan_idx=1:length(chans)
        chan = chans{chan_idx};
        for twin_idx=1:length(twins)
            twin = twins{twin_idx};
            pkpol = pol{twin_idx};
            for cond_idx = 1:length(conds)
                cond = conds{cond_idx};
                
                %select data
                d = D{d_idx};
                x = d.time*1000;
                twin_s=twin/1000; %convert to seconds
                y = selectdata(d,chan,[],cond);
        
                % Flip sign if 'neg'
                if strcmpi('neg',pkpol)
                    pkpol = -1;
                elseif strcmpi('pos',pkpol)
                    pkpol = 1;
                end
        
                % Get time-window indices and values:
                inds = x>=twin(1) & x<=twin(2);
                xtwin = x(inds);
                ytwin = pkpol*y(inds);
                yadj = ytwin-min(ytwin);
        
                %% Fractional area latency
                
                %area(xtwin,yadj);
                a = trapz(xtwin,yadj);   
                fa = 0;
                res = x(2)-x(1);
                l1 = twin(1);
                l2 = l1+res;
                while fa<a/2
                    l2 = l2+res;
                    inds = xtwin>=l1 & xtwin<=l2;
                    fa = trapz(xtwin(inds),yadj(inds));
                end
                fal = l2;
                
                %build row
                row = {d_idx,fnames(d_idx,:),sprintf('%s_%d-%d_%s',chan,twin(1),twin(2),cond),chan,sprintf('%d-%dms',twin(1),twin(2)),cond,'FAL',fal};
                ltable = [ltable;row]; %#ok<*AGROW>
            end
        end
    end
    for chan_idx=1:length(chans)
        chan = chans{chan_idx};
        for twin_idx=1:length(twins)
            twin = twins{twin_idx};
            for cond_idx = 1:length(conds)
                    cond = conds{cond_idx};

                    %select data
                    d = D{d_idx};
                    x = d.time*1000;
                    twin_s=twin/1000; %convert to seconds
                    y = selectdata(d,chan,[],cond);
            
                    % Flip sign if 'neg'
                    if strcmpi('neg',pkpol)
                        pkpol = -1;
                    elseif strcmpi('pos',pkpol)
                        pkpol = 1;
                    end
            
                    % Get time-window indices and values:
                    inds = x>=twin(1) & x<=twin(2);
                    xtwin = x(inds);
                    ytwin = pkpol*y(inds);
                    yadj = ytwin-min(ytwin);

        
                %% Peak latency (positive)
                    
                    [pks,lats] = findpeaks(yadj); % requires signal processing toolbox

                    if isempty(pks)
                        [~, pklat] = max(y);
                    elseif length(lats)==1
                        pklat = xtwin(lats);
                        pk = pks;
                    else
                        pk = max(pks);
                        pklat = xtwin(lats(find(pks==pk,1,'first')));
                    end

                row = {d_idx,fnames(d_idx,:),sprintf('%s_%d-%d_%s',chan,twin(1),twin(2),cond),chan,sprintf('%d-%dms',twin(1),twin(2)),cond,'peak_latency',pklat};
                ltable = [ltable;row]; %#ok<*AGROW>
            end
        end
    end
end
end

