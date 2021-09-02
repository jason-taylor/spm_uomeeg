% Usage examples for spm_uomeeg_twin_avg.m (jt 02/Sep/2021)

%% Time Domain

%% Single file (e.g., grandaverage):
S = [];
S.D = 'mabfcMICA_effMdspmeeg_P105_T1.mat';
S.chans = {'Fz','Cz','Pz'};
S.twins = {[300 500],[500 800]}; % (ms) cell array of start/end times
S.conds = {'StudiedPrimed','StudiedUnprimed','UnstudiedPrimed','UnstudiedUnprimed'}; 
S.outfname = 'my_timewin_data.txt';

twtable = spm_uomeeg_twin_avg(S)


%% Multiple files (e.g., individual participants):
S = [];
S.D = {
    'P106_Test\preprocessing\TimeDomain-withICA\mapbfMICA_cefMdfspmeeg_P106_T1.mat'
    'P107_Test\Preprocessing\TimeDomain-withICA\mapbfMICA_cefMdfspmeeg_P107_T1.mat'
    'P108_Test\Preprocessing\TimeDomain-withICA\mapbfMICA_cefMdfspmeeg_P108_T1.mat'
};
S.chans = {'Fz','Cz','Pz'};
S.twins = {[300 500],[500 800]}; % (ms) cell array of start/end times
S.conds = {'StudiedPrimed','StudiedUnprimed','UnstudiedPrimed','UnstudiedUnprimed'}; 
S.outfname = 'my_timewin_data_allsubjects.txt';

twtable_allsubjects = spm_uomeeg_twin_avg(S)

%% Time-Frequency

%% Single file (e.g., grandaverage):
S = [];
S.D = 'mtf_fcMICA_effMdspmeeg_P105_T1.mat';
S.chans = {'Fz','Cz','Pz'};
S.fwins = {[3 7],[8 12],[13 30]}; % (Hz) cell array of start/end frequencies
S.twins = {[150 250],[300 500]}; % (ms) cell array of start/end times
S.conds = {'StudiedPrimed','StudiedUnprimed','UnstudiedPrimed','UnstudiedUnprimed'}; 
S.outfname = 'my_tfwin_data.txt';

tfwtable = spm_uomeeg_twin_avg(S)

%% Multiple files (e.g., individual participants):
S = [];
S.D = {
    'P106_Test\preprocessing\FreqDomain\mtf_fcMICA_effMdspmeeg_P106_T1.mat'
    'P107_Test\Preprocessing\FreqDomain\mtf_fcMICA_effMdspmeeg_P107_T1.mat'
    'P108_Test\Preprocessing\FreqDomain\mtf_fcMICA_effMdspmeeg_P108_T1.mat'
};
S.chans = {'Fz','Cz','Pz'};
S.fwins = {[3 7],[8 12],[13 30]}; % (Hz) cell array of start/end frequencies
S.twins = {[150 250],[300 500]}; % (ms) cell array of start/end times
S.conds = {'StudiedPrimed','StudiedUnprimed','UnstudiedPrimed','UnstudiedUnprimed'}; 
S.outfname = 'my_tfwin_data_allsubjects.txt';

tfwtable_allsubjects = spm_uomeeg_twin_avg(S)

%% Frequency (spectra)

%% Single file (e.g., grandaverage):
S = [];
S.D = 'mspec_tf_fcMICA_effMdspmeeg_P105_T1.mat';
S.chans = {'Fz','Cz','Pz'};
S.fwins = {[3 7],[8 12],[13 30]}; % (Hz) cell array of start/end frequencies
S.conds = {'StudiedPrimed','StudiedUnprimed','UnstudiedPrimed','UnstudiedUnprimed'}; 
S.outfname = 'my_fwin_data.txt';

fwtable = spm_uomeeg_twin_avg(S)

%% Multiple files (e.g., individual participants):
S = [];
S.D = {
    'P106_Test\preprocessing\FreqDomain\mspec_tf_fcMICA_effMdspmeeg_P106_T1.mat'
    'P107_Test\Preprocessing\FreqDomain\mspec_tf_fcMICA_effMdspmeeg_P107_T1.mat'
    'P108_Test\Preprocessing\FreqDomain\mspec_tf_fcMICA_effMdspmeeg_P108_T1.mat'
};
S.chans = {'Fz','Cz','Pz'};
S.fwins = {[3 7],[8 12],[13 30]}; % (Hz) cell array of start/end frequencies
S.conds = {'StudiedPrimed','StudiedUnprimed','UnstudiedPrimed','UnstudiedUnprimed'}; 
S.outfname = 'my_fwin_data_allsubjects.txt';

fwtable_allsubjects = spm_uomeeg_twin_avg(S)



