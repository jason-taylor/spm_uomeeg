% Get ERP component latency (fractional area latency and peak latency).
%  jt 17/04/2020

%% Parameters % EDIT THESE

%fname = 'grandmean_experts.mat'; % fill this in!
fname = 'maeMICA_ffMdspmeeg_501_stream_av.mat'; 

twin = [300 450];  % time window in ms
%cond = 'studyFace'; % label of condition of interest
cond = 'allwords';
chan = 'P4';       % label of channel of interest
pkpol = 'pos';     % polarity of peak (pos/neg)

% twin = [80 120];   % time window in ms
% cond = 'allwords'; % label of condition of interest
% chan = 'O1';       % label of channel of interest
% pkpol = 'neg';     % polarity of peak (pos/neg)


%% Begin

% Load data, get time points and channel data:
D = spm_eeg_load(fname);
x = D.time*1000;
y = selectdata(D,chan,[],cond);

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

% Plot it:
f = figure('color','w'); 

% Whole ERP with time window:
subplot(2,1,1); 
plot(x,y,'b-'); hold on;
plot([xtwin(1) xtwin(1)],get(gca,'ylim'),'k:');
plot([xtwin(end) xtwin(end)],get(gca,'ylim'),'k:');

% Time-window (min/max adjusted):
subplot(2,1,2);
plot(xtwin,yadj,'b-'); hold on;
if pkpol==-1
    set(gca,'ydir','reverse');
    yt = get(gca,'ytick');
    set(gca,'ytickLabel',-1*yt);
end


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
    
inds = xtwin>=twin(1) & xtwin<=fal;
%ha = area(x(inds),y(inds),'facecolor','r');
area(xtwin(inds),yadj(inds),'facecolor','r');

% Label on plot:
xlab = xlabel(sprintf('FAL=%dms',fal));
xlpos = get(xlab,'Position');
set(xlab,'Position',[fal xlpos(2:end)]);


%% Peak latency (positive)
    
try [pks,lats] = findpeaks(yadj); % requires signal processing toolbox
catch
    [lats,pks] = peakseek(yadj); % https://uk.mathworks.com/matlabcentral/fileexchange/26581-peakseek
end
    
if length(lats)==1
    pklat = xtwin(lats);
    pk = pks;
else
    pk = max(pks);
    pklat = xtwin(lats(find(pks==pk,1,'first')));
end

% Label on plot:
%plot(pklat,pk,'k+');
plot([pklat pklat],[0 pk],'g--','linewidth',2);
text(pklat,pk+.15,sprintf('PKL=%.0fms',pklat),'horizontalalign','center','verticalalign','middle','color','k');

% Report:
fprintf('\nFAL: %dms\nPKL: %dms\n\n',fal,pklat);

