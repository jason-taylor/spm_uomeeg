% Quick script to plot ERPs in an array (jt 14/Aug/2017)
% NOTE: see last cell for optional (and interactive) formatting!


%% Parameters:

% Project directory (change this!!):
%proj_dir = 'M:\Jason_Taylor\AlzWordStream\v03\subjects\grandaverages'
proj_dir = 'C:\work\data\izzy_tasnim\preproc\jason_preproc\s204';

% Channels (in the desired array):
chans = {
    ''   'Fz'  ''    % <- skips blanks!
    'C1' 'Cz'  'C2'
    ''   'Pz'  ''
};

% Filenames (with subdirectories, as appropriate):
fnames = {
%    'ya21\wN400_fmaestim_dfMica_ffMspmeeg_ya21_stream_av.mat'
%    'oa08\wN400_fmaestim_dfMica_ffMspmeeg_oa08_stream_av.mat'
    'mafbMICA_effdMspmeeg_204.mat'
};

% Condition labels:
%conds = {'SA','SR','UR'};
conds = {'NearCong1', 'NearIncong1', 'VibeOnly1'};

% Plot colours (fnames x conds)
pc = {
    'b' 'r' [.4 .4 .4]
%    'r' 'r' 'r'
};

% Plot line styles (fnames x conds)
pl = {
    '-' '--' ':'
%    ':' '--' '-'
};

% Line widths (fnames x conds)
pw = {
    2   2   2
%    1   1   2
};


%% Load data:

cd(proj_dir);
D=[];
for fn=1:numel(fnames)
    D{fn} = spm_eeg_load(fnames{fn});
end


%% Extract ERP timecourses:
d=[];
for ch=1:numel(chans)
    chan = chans{ch};
    if ~isempty(chan)
    for fn=1:numel(fnames)
        for cn=1:numel(conds)
            d.(chan)(fn,:,cn) = selectdata(D{fn},chans{ch},[],conds{cn});
        end
    end
    end
end


%% Plot ERPs:
figure('color','w');
nrows = size(chans,1);
ncols = size(chans,2);
spindex =  reshape(1:numel(chans),ncols,nrows)';
timevec = D{1}.time;

for col=1:ncols
    for row=1:nrows
        chan = chans{row,col};
        
        if ~isempty(chan)
            subplot(nrows,ncols,spindex(row,col));
            for fn=1:numel(fnames)
                for cn=1:numel(conds)
                    if any(strmatch(chan,'L'));
                        xlim([min(timevec) max(timevec)].*1000);
                        ylim([-eps eps]);
                    else
                        plot(timevec*1000,d.(chan)(fn,:,cn),'color',pc{fn,cn},'linestyle',pl{fn,cn},'linewidth',pw{fn,cn});
                        hold on;
                        grid on;
                    end
                end
            end
            title(chan);
            axis tight
        end
                
    end
end

% Set y-limits to [min max] of subplots:
myaxes = findobj(gcf,'type','axes');
yl = cell2mat(get(myaxes,'ylim'));
set(myaxes,'ylim',[min(yl(:,1)) max(yl(:,2))]);
set(myaxes,'box','on')



%% Other things you can do (these will require some editing!)

% X and Y TICKS and TICK LABELS:

% - APPLY TICKS AND LABELS TO ALL:
% set(myaxes,'xtick',[-100 0:200:1000]);
% set(myaxes,'ytick',[-4:2:10]);

% - REMOVE ALL LABELS BUT KEEP TICKS?:
set(myaxes,'xticklabel','');
set(myaxes,'yticklabel','');

% - SELECT (CLICK) ONE, ADD LABELS?:
set(gca,'xticklabel',[-100 0:200:1000]);
set(gca,'yticklabel',[-4:2:10]);
xlabel('ms');
ylabel('uV');


% PLOT ZERO LINES:

x0=[]; y0=[];
for i=1:length(myaxes)
    axes(myaxes(i));
    x0(i) = plot([0 0],[min(yl(:,1)) max(yl(:,2))],'k-','linewidth',2);
    y0(i) = plot([timevec(1) timevec(end)]*1000,[0 0],'k-','linewidth',2);
end


% LEGEND:

% Select (click) a plot with data, then create the legend. You can then
% move the legend to empty space and remove the box with the second line of
% code.

leg = legend('YA assoc','YA rel','YA unrel','OA assoc','OA rel','OA unrel');
%set(leg,'box','off');


% GRID, BOX, ETC.:

% set(myaxes,'xcolor',[.7 .7 .7],'ycolor',[.7 .7 .7]);
% set(myaxes,'gridLineStyle',':');
% set(myaxes,'box','on');

% -- or --

set(myaxes,'box','off');
set(myaxes,'gridLineStyle','none');
set(myaxes,'xcolor','k','ycolor','k');
