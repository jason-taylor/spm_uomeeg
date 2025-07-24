function [topovec,topoimage,handlestruct] = spm_uomeeg_topo(S)

% Plot a time-window averaged topography from SPM12-format data M/EEG data.
%
% Input:
%   S struct with (optional) subfields:
%     D          - filename (.mat) of SPM12 M/EEG object (Default=prompt)
%     cond       - condition label ([] plots empty array)
%     twin       - [start end] of time-window (ms)
%     fwin       - [start end] of frequency window (Hz)
%     style      - 'spm'|'eeglab' style of topo plot (default='spm')
%     chantype   - channel type (default='EEG')
%     title      - 'auto'|'none'|'(your title)' include title (default='auto')
%                   if 'auto', 'Topography of $cond (%start-%endms)'
%     fighandle  - handle of figure to use (default=[] (create))
%     axhandle   - handle of axes to use (default = [] (create))
%     save       - 'fig'|'png'|'none' save? (default='none')
%
%   Plot formatting options
%     electrodes  - 'on'|'off'|'labels'|'numbers' plot electrodes
%     colormap    - colormap to use (default = 'parula')
%     colorbar    - 'on'|'off' add colorbar to plot? (default=on)
%     maplimits   - [min max]|'absmax'|'minmax'|'zeromax'|'minzero'
%                    colorlimits (def='absmax'=[-max(abs(x)) max(abs(x))])
%     numcontour  - [n] number of contour lines (0=none) (default=-1 (auto))
%     colcontour  - colour of contour lines (default=[0.2 0.2 0.2])
%     chanmark    - channel plotting marker (default = '.')
%     chansize    - channel marker size (default = 5)
%     chancol     - channel marker color (default = [0 0 0] or 'k')
%     chanfacecol - channel face color (default = 'none')
%     figcol      - figure color (default = 'w' (white))
%     spmbuttons  - 'on'|'off' include buttons on plot? (default='yes')
%     eeghcolor   - head colo(u)r for eeglab style (default='k')
%
%   EEGLAB topoplot options:
%     topoplotopts    - cell array of property, value pairs (default=[])
%     .. e.g., S.topoplotopts = {'numcontour',10,'hcolor','k'};
%     .. see 'help topoplot' for options (beware - not fully tested!)
%
%   Open in editor to see examples.
% 
% by Jason Taylor (18/July/2025) jason.taylor@manchester.ac.uk
%  based partly on the old script_plot_topo_twin.m
%  essentially a wrapper for spm_eeg_plotScalpData (SPM) / topoplot (EEGLAB)
%  + jt (24/July/2025) added frequency window option

% Examples
%
% Simple SPM example:
%  S = [];
%  S.D = 'wgrandaverage.mat'; 
%  S.cond = 'unrelated-related'; 
%  S.twin = [300 500]; 
%  spm_uomeeg_topo(S);
%
% Simple SPM example with time/frequency window:
%  S = [];
%  S.D = 'wgrandaverage.mat'; 
%  S.cond = 'unrelated-related'; 
%  S.twin = [300 500];
%  S.fwin = [4 7];
%  S.colormap = 'autumn';
%  S.maplimits = 'minmax';
%  spm_uomeeg_topo(S);
%
% Simple EEGLAB topoplot example:
%  S = [];
%  S.D = 'wgrandaverage.mat'; 
%  S.cond = 'unrelated-related'; 
%  S.twin = [300 500]; 
%  S.style = 'eeglab';
%  S.eeghcolor = [.7 .7 .7];
%  S.topoplotopts = {'style','fill'};
%  spm_uomeeg_topo(S);
%
% Elaborate example:
%  S = [];
%  S.D = 'wgrandaverage.mat'; 
%  S.cond = 'unrelated-related'; 
%  S.twin = [300 500]; 
%  S.fwin = [3 7];
%  S.style = 'spm';
%  S.fighandle = gcf; % or use existing figure handle
%  S.axhandle = gca; % or use existing axes handle
%  S.title = 'my topography';
%  S.maplimits = absmax;
%  S.figcol = [.5 .5 .5];
%  S.electrodes = 'on';
%  S.numcontour = 10;
%  S.colcontour = [.8 .8 .8];
%  S.colorbar = 'on';
%  S.colormap = 'parula';
%  S.chanmark = 'square';
%  S.chancol = 'k';
%  S.chanfacecol = [.7 1 .7];
%  S.chansize = 7;
%  S.spmbuttons = 'off';
%  S.save = 'both';
%  [topovec,topoimage,handlestruct] = spm_uomeeg_topo(S);
%
% Channel array example (no data)
%  S = [];
%  S.D = 'wgrandaverage.mat'; 
%  S.style = 'eeglab'; % or 'spm' 
%  S.eeghcolor = [.8 .8 .8];
%  S.electrodes = 'labels';
%  S.colormap = [1 1 1; .95 .95 .95]; % 'white' for no color; 'jet' for green
%  spm_uomeeg_topo(S);


%% Check inputs

try D = spm_eeg_load(S.D);       catch, D=spm_eeg_load;        end
try cond = S.cond;               catch, cond=[];               end
try twin = S.twin;               catch, twin=[];               end
try fwin = S.fwin;               catch, fwin=[];               end
try style = S.style;             catch, style = 'spm';         end
try chantype = S.chantype;       catch, chantype='EEG';        end
try dotitle = S.title;           catch, dotitle='auto';        end
try fighandle = S.fighandle;     catch, fighandle=[];          end
try axhandle = S.axhandle;       catch, axhandle=[];           end
try dosave = S.save;             catch, dosave='none';         end

try electrodes = S.electrodes;   catch, electrodes='on';       end
try usecolormap = S.colormap;    catch, usecolormap='parula';  end
try usecolorbar = S.colorbar;    catch, usecolorbar='on';      end
try maplimits = S.maplimits;     catch, maplimits='absmax';    end
try spmbuttons = S.spmbuttons;   catch, spmbuttons='on';       end
try eeghcolor = S.eeghcolor;     catch, eeghcolor='k';         end
try numcontour = S.numcontour;   catch, numcontour=-1;         end
try colcontour = S.colcontour;   catch, colcontour=[.2 .2 .2]; end
try chanmark = S.chanmark;       catch, chanmark='.';          end
try chansize = S.chansize;       catch, chansize=5;            end
try chancol = S.chancol;         catch, chancol='k';           end
try chanfacecol = S.chanfacecol; catch, chanfacecol='none';    end
try figcol = S.figcol;           catch, figcol='w';            end

try topoplotopts = S.topoplotopts; catch, topoplotopts = {};   end

%% Data

% Get channel info:
eeginds = indchantype(D,chantype);
eeglabs = chanlabels(D,eeginds);
eegpos  = coor2D(D,eeginds);
senspos = D.sensors(chantype).chanpos;
senslab = D.sensors(chantype).label;

% Extract data, average over time-window:
if isempty([twin fwin cond])
    % Plot empty array (solid green topography)
    topovec = zeros(length(eeginds),1);
    usecolorbar = 'no';
    useclim = [-100 100];
    ttl = 'Channel Array';
else
    % Extract data, average
    ttl = sprintf('Topography of %s ',strrep(cond,'_',' '));
    if ~isempty(twin) && isempty(fwin) 
        % Time-window only (time-domain data)
        d = selectdata(D,eeglabs,twin/1000,cond); % /1000 ms-->sec
        topovec = squeeze(mean(d,2));
        ttl = sprintf('%s (%d-%dms)',ttl,twin);
    elseif ~isempty(twin) && ~isempty(fwin)
        % Time-and-frequency window (TF data)
        d = selectdata(D,eeglabs,fwin,twin/1000,cond); % /1000 ms-->sec
        topovec = squeeze(mean(mean(d,2),3));
        ttl = sprintf('%s (%d-%dms, %d-%dHz)',ttl,twin,fwin);
    elseif isempty(twin) && ~isempty(fwin)
        % Frequency-window only (spectra)
        d = selectdata(D,eeglabs,fwin,[],cond); 
        topovec = squeeze(mean(d,2));
        ttl = sprintf('%s (%d-%dHz)',ttl,fwin);
    end

    % Determine colour limits
    if isnumeric(maplimits)
        useclim = maplimits;
    else
        switch maplimits
            case 'absmax'
                useclim = [-max(abs(topovec)) max(abs(topovec))];
            case 'minmax'
                useclim = [min(topovec) max(topovec)];
            case 'zeromax'
                useclim = [0 max(topovec)];
            case 'minzero'
                useclim = [min(topovec) 0];
        end
    end
end


%% Figure
% Create new figure
if isempty(fighandle)
    fighandle = figure('color',figcol);
end

% Create new axes in figure
if isempty(axhandle)
    axhandle = axes('parent',fighandle);
end

%% Plot topography
switch lower(style)
    case 'spm'
        opts = [];
        opts.type = chantype;
        opts.f = fighandle;
        opts.ParentAxes = axhandle;
        opts.min = useclim(1);
        opts.max = useclim(2);
        opts.plotpos = 1;

        switch usecolorbar
            case 'on'
                opts.cbar = 1;
            case 'off'
                opts.cbar = 0;
        end

        switch spmbuttons
            case 'on'
                opts.noButtons = 0;
            case 'off'
                opts.noButtons = 1;
        end

        switch electrodes
            case 'on'
                usechanlabels = eeglabs;
            case 'off'
                usechanlabels = eeglabs;
            case 'labels'
                usechanlabels = eeglabs;
            case 'numbers'
                usechanlabels = cellstr(num2str(eeginds'));
        end

        switch usecolorbar
            case 'yes'
                opts.cbar = 1;
            case 'no'
                opts.cbar = 0;
        end

        topoimage = spm_eeg_plotScalpData(topovec,eegpos,usechanlabels,opts);

        % Contours
        contourH = findobj(axhandle,'type','contour');
        switch numcontour
            case -1
                set(contourH,'visible','on');
            case 0
                set(contourH,'visible','off');
             otherwise
                delete(contourH);
                [~,contourH] = contour(axhandle,flipud(topoimage),numcontour,'linecolor',colcontour);
        end

        % Format channel appearance
        chanH = findobj(axhandle,'marker','o');
        set(chanH,'marker',chanmark,'MarkerSize',chansize,'Color',chancol,'MarkerFaceColor',chanfacecol);

        labelH = findobj(axhandle,'type','text');
        switch electrodes
            case {'labels','numbers'}
                set(labelH,'visible','on');
                set(chanH,'visible','off');
            case 'on'
                set(labelH,'visible','off');
                set(chanH,'visible','on');
            case 'off'
                set(labelH,'visible','off');
                set(chanH,'visible','off');
        end

        % Colormap?
        if ~isempty(usecolormap)
            cm = colormap(axhandle,usecolormap);
            cm(1,:) = get(fighandle,'color');
            colormap(axhandle,cm);
        end

    case 'eeglab'

        % Get topoplot options (this is ugly)
        topoplotopts{end+1} = 'electrodes';
        topoplotopts{end+1} = electrodes;

        topoplotopts{end+1} = 'colormap';
        topoplotopts{end+1} = colormap(usecolormap);

        topoplotopts{end+1} = 'maplimits';
        topoplotopts{end+1} = useclim;

        if numcontour>=0
            topoplotopts{end+1} = 'numcontour';
            topoplotopts{end+1} = numcontour;
        end

        topoplotopts{end+1} = 'hcolor';
        topoplotopts{end+1} = eeghcolor;

        topoplotopts{end+1} = 'ccolor';
        topoplotopts{end+1} = colcontour;

        topoplotopts{end+1} = 'emarker';
        topoplotopts{end+1} = {chanmark,chancol,chansize,1};

        % Create temporary channel location file
        fid=fopen('tmp_chanlocs.xyz','w');
        for ch=1:length(senslab)
            fprintf(fid,'%d\t%.3f\t%.3f\t%.3f\t%s\n',ch,senspos(ch,:),senslab{ch});
        end
        fclose(fid);

        % Do topoplot!
        [~,topoimage] = topoplot(topovec,'tmp_chanlocs.xyz',topoplotopts{:});

        %delete('tmp_chanlocs.xyz');

        % Set some leftover plot options:
        set(fighandle,'color',figcol);
        set(findobj(fighandle,'type','patch'),'facecolor',figcol);
        set(axhandle,'visible','off');
        if strcmp(usecolorbar,'on')
            cbH=colorbar;
        end
end

% Give it a title:
switch dotitle
    case 'auto'
        title(sprintf('%s\n',ttl))
    case 'none'
        title('');
    otherwise
        title(sprintf('%s\n',dotitle)); % user-provided title
end

% Handles
handlestruct = [];
handlestruct.fighandle = fighandle;
handlestruct.axhandle = axhandle;
try handlestruct.contours = findobj(axhandle,'type','contour'); end
try handlestruct.electrodes = findobj(axhandle,'marker',chanmark); end
try handlestruct.labels = findobj(axhandle,'type','text'); end
try 
    handlestruct.image = findobj(axhandle,'type','image'); 
catch 
    handlestruct.image = findobj(axhandle,'type','surface');
end
try handlestruct.buttons = findobj(fighandle,'type','UIControl'); end
try handlestruct.colorbar = findobj(fighandle,'type','colorbar'); end
try handlestruct.patch = findobj(axhandle,'type','patch'); end

% Save it?
if ~isempty(dosave) && ~strcmp(dosave,'none')
    savetypes = [];
    switch dosave
        case 'both'
            savetypes = {'png','fig'};
        case 'png'
            savetypes = {'png'};
        case 'fig'
            savetypes = {'fig'};
    end
    for st=savetypes
        if isempty(twin) && isempty(cond)
            saveas(fighandle,sprintf('EEGarray.%s',char(st)),char(st));
        else
            saveas(fighandle,sprintf('Topo_%s_%d-%dms.%s',strrep(cond,' ','_'),twin,char(st)),char(st));
        end
    end
end

return
