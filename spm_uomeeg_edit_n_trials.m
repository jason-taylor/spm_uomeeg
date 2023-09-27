function [D, C] = spm_uomeeg_edit_n_trials(S)
% Function for editing the number of trial in each condition in an SPM
% M/EEG object. This includes introducing a minumum n_trials, a maximum 
% n_trials, and equalising the trial counts between conditions. Rather than
% removing conditions from D.conditions, this function will add
% excess trials to D.badtrials so that they are ignored at averaging. You
% can also add all the bad trials to a placeholder condition
%
%  FORMAT: [D] = spm_uomeeg_edit_n_trials(S)
%  INPUT: Struct 'S' with fields:
%   S.D            - MEEG object or filename of MEEG object
%   S.conds        - (optional) cell array of conditions to include. If used, 
%                       any conditions not included will have all trials
%                       labelled as bad. Useful for if you've stored
%                       incorrect responses as a condition.
%   S.placeholder  - (optional) store bad trials in a placeholder
%                       condition. This helps keep data dimensionality for 
%                       grandaveraging. Default: 1
%   S.max          - (optional) maximum number of trials to reduce to.
%                       conditions with fewer trials than this will not be
%                       changed. Default: n trials in the condition with
%                       fewest not bad trials.                     
%   S.min          - (optional) minimum number of trials to allow in a
%                       condition. If a condition has fewer than S.min
%                       trials, all of it's trials will be labelled as bad.
%                       Default: 20
%   S.method       - (optional) method for removing trials. Either
%                   'uniform' (roughly equal across time) or
%                   'random' (randomly sampled across all trials for that
%                   condition). Default: 'uniform'
%   S.prefix        - (Optional) Default: 'Q'
%
%  OUTPUT: 
%   D              - data with excess trials marked as bad
%   C              - table containing updated trial information
%
%  by Stephen Ball (26/09/2023) stephen.ball-4@manchester.ac.uk


%--------------------------------------------------


% Check inputs:
try to_keep = S.conds;         catch, to_keep = [];      end
try placeholder = S.placeholder; catch, placeholder=1;   end
try max_n = S.max;            catch, max_n = [];         end
try min_n = S.min;            catch, min_n = 20;         end
try method = S.method;      catch, method = 'uniform';   end
try prefix = S.prefix;      catch, prefix = 'Q';         end

% Load SPM-format data file:
D = spm_eeg_load(S.D);
[~,fstem] = fileparts(D.fname);

fprintf('\n\n');
fprintf('++ %s\n',datetime);
fprintf('++ RUNNING spm_uomeeg_equalise ON %s\n',D.fname);


%% Get some info about conditions/trials

conds = D.condlist;
trial_conds  = D.conditions;
bad_trials   = D.badtrials;

% init cond table
C = cell2table(cell(0,3),'VariableNames',{'condition','n_trials','trials_idx'});

% get the indicies of trials in each condition which are not bad.
disp('++-----------------------CONDITIONS-----------------------')
for cond=1:length(conds)
    idx = find(ismember(trial_conds,conds{cond})); %get ALL trials in condition
    bads = ~ismember(idx,bad_trials);
    idx = idx(bads);
    row = {conds{cond},length(idx),{idx}};
    C = [C;row]; %#ok<*AGROW>
    %fprintf('++ %2s n=%d\n',C(cond,"condition"),C{cond,"n_trials"})
end

%lil summary table
disp(C(:,{'condition','n_trials'}))

% add trials of conditions not specified to keep to bad (if conds is
% specified)
if ~isempty(to_keep)
    %check if the specified conditions exist
    cond_check = ~ismember(to_keep,conds);
    if find(cond_check)>0
        error('ERROR: condition: %s not found \n',to_keep{cond_check});
    else
        conds_to_remove = ~ismember(conds,to_keep);
            for cond=1:height(C)
                if conds_to_remove(cond)==1
                   fprintf("Adding condition: %s to bad trials \n",C{cond,'condition'}{:})
                   bad_trials = [bad_trials,cell2mat(C{cond,'trials_idx'})]; 
                end
            end
    end
end

%get a logical of conditions to keep
if isempty(to_keep)
    to_keep2 = true([1,height(C)]);
else
    to_keep2 = ismember(conds,to_keep);
end

% if a condition has fewer than min_n amount of trials, label all of it's trials as bad 
if ~isempty(min_n)
    for cond=1:height(C)
        if C{cond,'n_trials'}<min_n
            bad_trials = [bad_trials,cell2mat(C{cond,'trials_idx'})];
        end
    end
end

% reduce trial count in conditions with greater>max_n trial

% get the max
if isempty(max_n)
    max_n = min(C{to_keep2,'n_trials'});
end

%warning if this is too low for a decent ERP
if max_n<20
    warning("WARNING: Equalised number of trials is <20. This may not be suitable for ERP analysis")
end
    
for cond=1:length(conds)
    if C{cond,'n_trials'}>max_n
        if strcmp(method,'uniform') %uniform sampling
           trials_to_keep_idx = int64(round(linspace(1,C{cond,'n_trials'},max_n)));
           trials_to_keep = C{cond,'trials_idx'}{:};
           trials_to_keep = trials_to_keep(trials_to_keep_idx);
        elseif strcmp(method,'random') %random sampling
           trials_to_keep = sort(datasample(C{cond,'trials_idx'}{:},max_n));        
        else
           error("ERROR: Unrecognised trial resampling method: %s",method)
        end

       trials_to_remove = C{cond,'trials_idx'}{:}(~ismember(C{cond,'trials_idx'}{:},trials_to_keep));
       bad_trials = [bad_trials,trials_to_remove];
       C{cond,'trials_idx'} = {trials_to_keep};
       C{cond,'n_trials'} = length(trials_to_keep);
    end
end
   
bad_trials = unique(bad_trials);
bad_trials_idx = zeros(1,D.ntrials);
bad_trials_idx(bad_trials) = 1;

% re-assign bads to D - why is this so difficult?! can't for the life of me
% work out how to do this without a loop..
for idx=1:length(bad_trials_idx)
    if bad_trials_idx(idx)==1
        D = D.badtrials(idx,1);
    end
end

if placeholder==1
    D = D.conditions(bad_trials,'bad_trials');
    conds = D.condlist;
    C = cell2table(cell(0,3),'VariableNames',{'condition','n_trials','trials_idx'});
    for cond=1:length(conds) %re-make the output table
        idx = find(ismember(trial_conds,conds{cond})); %get ALL trials in condition
        bads = ~ismember(idx,bad_trials);
        idx = idx(bads);
        row = {conds{cond},length(idx),{idx}};
        C = [C;row];   
    end
end

D = D.copy([prefix D.fname]);
D.save

disp("++ Conditions after trial editing...")

disp(C(:,{'condition','n_trials'}))

return