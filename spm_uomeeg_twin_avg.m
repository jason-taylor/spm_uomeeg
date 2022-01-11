function [twtable,twdatacell,twcolnames] = spm_uomeeg_twin_avg(S)

% Extract time- (and/or frequency-) window averaged data from an 
% SPM12-format data file. Output is a table-style cell array with column 
% headers, row labels (subject index and filename), and data with 
% participants as rows and time-window x channel x condition as columns. 
% Optionally, a cell array of 1 cell per participant (chans x twins x conds) 
% can also be output.
%
% Input: 
%   S struct with (optional) subfields:
%       D           - filename (.mat) of SPM12 M/EEG object
%                     OR cell array of filenames 
%                     OR leave blank to be prompted
%       chans       - cell array of channel names (in D.chanlabels)
%       fwins       - cell array of frequency borders
%       twins       - cell array of start/end times
%       conds       - cell array of condition labels (in D.condlist)
%       outfname    - filename for output (tab-delimited *.txt) - uses
%                      present working directory if no path given.
%
% Output:
%   twtable    - table of data, repeated-measures style
%   twdatacell - cell array {#files} of time-window averaged data 
%                 each cell is (chans (x twins) (x fwins) x conds)
%   twcolnames - cell array of column names
%            
% jt (11/09/2020)
%
% Examples
%
%Single file (e.g., grandaverage):
% S = [];
% S.D = 'my_grandaveraged_data_tf.mat';
% S.chans = {'Fz','Cz','Pz'};
% S.fwins = {[3 7],[8 12]};
% S.twins = {[140 200],[300 600]}; % (ms) cell array of start/end times
% S.conds = {'cond1','cond2'}; 
% S.outfname = 'my_twdata.txt';
%
% [twtable,twdatacell,twcolnames] = spm_uomeeg_twin_avg(S);
%
%Multiple files (e.g., individual participants):
% S = [];
% S.D = {
%     'p1/mrtfeffdspmeeg_p1.mat'
%     'p2/mrtfeffdspmeeg_p2.mat'
%     'p3/mrtfeffdspmeeg_p3.mat'
%     'p4/mrtfeffdspmeeg_p4.mat'
%     'p5/mrtfeffdspmeeg_p5.mat'
% };
% S.chans = {'Fz','Cz','Pz'};
% S.fwins = {[3 7],[8 12]};
% S.twins = {[140 200],[300 600]}; % (ms) cell array of start/end times
% S.conds = {'cond1', 'cond2'};
% S.outfname = 'my_group_twdata.txt';
%
% [twtable,twdatacell,twcolnames] = spm_uomeeg_twin_avg(S);


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
try fwins = S.fwins; catch, fwins = []; end
try twins = S.twins; catch, twins = []; end
try chans = S.chans; catch, chans = []; end
try outfname = S.outfname; catch, outfname = []; end

if isempty(conds)
    conds = D{1}.condlist';
end
if isempty(fwins) 
    switch D{1}.transformtype
        case {'TF'}
            fwins = {D{1}.frequency([1 end])};
    end
elseif ~iscell(fwins)
    fwins = {fwins};
end
if isempty(twins)
    switch D{1}.transformtype
        case {'time'}
            twins = {D{1}.time([1 end])*1000};
        case {'TF'}
            if length(D{1}.time)>1
                twins = {D{1}.time([1 end])*1000};
            else % spectra:
                twins = {[]};
            end
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


%% Load data

cwd = pwd;

for i=1:length(D)
    
    switch D{1}.transformtype
        
        case 'time'
            
            %if i==1
                twdatacell{i} = zeros([length(chans) length(twins) length(conds)]);
            %end
            
            for tw=1:length(twins)
                twin=twins{tw};
                
                d = selectdata(D{i},chans,twin/1000,conds);
                md = mean(d,2);
                twdatacell{i}(:,tw,:) = md;
            end
            
        case 'TF'
            
            if length(D{1}.time)>1 % TF
                
                %if i==1
                    twdatacell{i} = zeros([length(chans) length(fwins) length(twins) length(conds)]);
                %end
                
                for tw=1:length(twins)
                    twin=twins{tw};
                    
                    for fq=1:length(fwins)
                        fwin=fwins{fq};
                        
                        d = selectdata(D{i},chans,fwin,twin/1000,conds);
                        md = mean(mean(d,3),2);
                        twdatacell{i}(:,fq,tw,:) = md;
                        
                    end
                end
                
            else % spectra
                %if i==1
                    twdatacell{i} = zeros([length(chans) length(fwins) length(conds)]);
                %end
                
                for fq=1:length(fwins)
                    fwin=fwins{fq};
                    
                    d = selectdata(D{i},chans,fwin,[],conds);
                    md = mean(d,2);
                    twdatacell{i}(:,fq,:) = md;
                end
                
            end
            
    end
end


%% Format table
twtabledata = [];
twcolnames = [];
subjnums = [];
filenames = [];

twcolnames{1}='subjectIndex';
twcolnames{2}='fileName';

switch D{1}.transformtype
    case 'time'
        
        for i=1:length(twdatacell)
            j=0;
            
            for tw=1:length(twins)
                twin=twins{tw};
                
                for ch=1:length(chans)
                    chan=chans{ch};
                    
                    for co=1:length(conds)
                        cond=conds{co};
                        
                        j=j+1;
                        twtabledata(i,j) = twdatacell{i}(ch,tw,co);
                        if i==1
                            twcolnames{j+2} = sprintf('%s_%g-%gms_%s',chan,twin,cond);
                        end
                        
                        if j==1
                            subjnums(i) = i;
                            filenames{i} = fullfile(D{i}.path,D{i}.fname);
                        end
                    end
                end
            end
        end
        
    case 'TF'
        
        if length(D{1}.time)>1
            
            for i=1:length(twdatacell)
                j=0;
                
                for fw=1:length(fwins)
                    fwin=fwins{fw};
                    
                    for tw=1:length(twins)
                        twin=twins{tw};
                        
                        for ch=1:length(chans)
                            chan=chans{ch};
                            
                            for co=1:length(conds)
                                cond=conds{co};
                                
                                j=j+1;
                                twtabledata(i,j) = twdatacell{i}(ch,fw,tw,co);
                                if i==1
                                    twcolnames{j+2} = sprintf('%s_%g-%gHz_%g-%gms_%s',chan,fwin,twin,cond);
                                end
                                
                                if j==1
                                    subjnums(i) = i;
                                    filenames{i} = fullfile(D{i}.path,D{i}.fname);
                                end
                            end
                        end
                    end
                end
            end
            
        else % spectra
            
            for i=1:length(twdatacell)
                j=0;
                
                for fw=1:length(fwins)
                    fwin=fwins{fw};
                    
                    for ch=1:length(chans)
                        chan=chans{ch};
                        
                        for co=1:length(conds)
                            cond=conds{co};
                            
                            j=j+1;
                            twtabledata(i,j) = twdatacell{i}(ch,fw,co);
                            if i==1
                                twcolnames{j+2} = sprintf('%s_%g-%gHz_%s',chan,fwin,cond);
                            end
                            
                            if j==1
                                subjnums(i) = i;
                                filenames{i} = fullfile(D{i}.path,D{i}.fname);
                            end
                        end
                    end
                end
            end
            
        end
end

% Format for output:
twtable = [twcolnames; [num2cell(subjnums') filenames' num2cell(twtabledata)]];

%% Write to file:

if ~isempty(outfname)
    [p,f] = fileparts(outfname);
    if isempty(p)
        outfname = fullfile(cwd,outfname);
    end

    fid = fopen(outfname,'w');
    for j=1:size(twtable,2)
        fprintf(fid,'%s',twtable{1,j});
        if j<size(twtable,2)
            fprintf(fid,'\t');
        else
            fprintf(fid,'\n');
        end
    end
    for i=2:size(twtable,1)
        fprintf(fid,'%d\t%s\t',twtable{i,1:2});
        for j=3:size(twtable,2)
            fprintf(fid,'%g',twtable{i,j});
            if j<size(twtable,2)
                fprintf(fid,'\t');
            else
                fprintf(fid,'\n');
            end
        end
    end

    fclose(fid);
    fprintf(1,'Time-window data written to %s\n',outfname);

end

