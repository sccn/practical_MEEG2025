% Practical MEEG 2022
% Wakeman & Henson Data analysis: Preprocessing for group analysis using
% EEGLAB BIDS Tools

% Authors: Arnaud Delorme, SCCN, 2022
%          Ramon Martinez-Cancino, Brain Products, 2022
%          Johanna Wagner, Zander Labs, 2022
%
% Copyright (C) 2022  Arnaud Delorme
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

%% Download the data at https://nemar.org/dataexplorer/detail?dataset_id=ds000117
%% This tutorial only process run 1, but you can change the call to pop_importbids to process all the runs

%%
% Clearing all is recommended to avoid variable not being erased between calls 
clear;                                      
clear globals;

% Comment one of the two lines below to process EEG or MEG data
%chantype = { 'megmag' }; % process MEG megmag channels
%chantype = { 'megplanar' }; % process MEG megplanar channels
chantype = { 'eeg' }; % process EEG

% Paths below must be updated to the files on your enviroment.
path2data = fullfile(pwd,'ds000117_pruned', 'derivatives', 'meg_derivatives'); % Path to data 
path2save = fullfile(pwd,'ds000117_pruned', 'derivatives', 'eeglab'); 
[ALLEEG, EEG, CURRENTSET] = eeglab; % start EEGLAB

%% IMPORTING THE DATA
[STUDY, ALLEEG] = pop_importbids(path2data, 'bidsevent', 'on', 'bidsevent', 'on', 'mergeruns', 'on', 'bidschanloc', 'off', 'eventtype', 'stim_type', 'outputdir', path2save, 'subjects', [1 2], 'runs', {'01' '02'});
CURRENTSET = 1:length(ALLEEG); EEG = ALLEEG; CURRENTSTUDY = 1;
eeglab redraw

% Step 2: Adding fiducials and rotating montage. Note:The channel location from this points were extracted from the sub-01_ses-meg_coordsystem.json
% files (see below) and written down here. The reason is that File-IO does not import these coordinates.
n = length(EEG(1).chanlocs)+1;
EEG=pop_chanedit(EEG, 'changefield',{n+0,'labels','LPA'},'changefield',{n+0,'X','0'},  'changefield',{n+0,'Y','7.1'},'changefield',{n+0,'Z','0'},...
                      'changefield',{n+1,'labels','RPA'},'changefield',{n+1,'X','0'}, 'changefield',{n+1,'Y','-7.756'},'changefield',{n+1,'Z','0'},...
                      'changefield',{n+2,'labels','Nz'} ,'changefield',{n+2,'Y','0'},'changefield',{n+2,'X','10.636'},'changefield',{n+2,'Z','0'});
EEG = eeg_checkset(EEG);

% Changing Channel types and removing channel locations for channels 61-64 (Raw data types are incorrect)
EEG = pop_chanedit(EEG,'changefield',{367  'type' 'HEOG'  'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});
EEG = pop_chanedit(EEG,'changefield',{368  'type' 'VEOG'  'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});
EEG = pop_chanedit(EEG,'changefield',{369  'type' 'EKG'   'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});
EEG = pop_chanedit(EEG,'changefield',{370  'type' 'EKG'   'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});

% Step 3: Re-import events from STI101 channel (the original ones are incorect)
edgelenval = 1;
EEG = pop_chanevent(EEG, 381,'edge','leading','edgelen',edgelenval,'delevent','on','delchan','off','oper','double(bitand(int32(X),31))'); % first 5 bits

% Step 4: Selecting EEG or MEG data 
EEG = pop_select(EEG, 'chantype', chantype);
for iEEG = 1:length(EEG)
    EEG(iEEG).chaninfo = rmfield(EEG(iEEG).chaninfo, 'topoplot');
    EEG(iEEG).chaninfo = rmfield(EEG(iEEG).chaninfo, 'originalnosedir');
end

% Step 5: Recomputing head center (for display only) Optional
EEG = pop_chanedit(EEG, 'eval','chans = pop_chancenter( chans, [],[])');

% Step 6: Cleaning artefactual events (keep only valid event codes) (
% NOT BE NECCESARY FOR US
EEG = pop_selectevent( EEG, 'type',[5 6 7 13 14 15 17 18 19] ,'deleteevents','on');

% rename events
EEG = pop_selectevent( EEG, 'type',256, 'renametype', 'left_nonsym','deleteevents','off');  % Event type : 'left_nonsym'
EEG = pop_selectevent( EEG, 'type',4096,'renametype', 'right_sym','deleteevents','off');    % Event type : 'right_sym'

% Step 9: Rename face presentation events (information provided by authors)
EEG = pop_selectevent( EEG, 'type',5,'renametype','Famous','deleteevents','off');           % famous_new
EEG = pop_selectevent( EEG, 'type',6,'renametype','Famous','deleteevents','off');           % famous_second_early
EEG = pop_selectevent( EEG, 'type',7,'renametype','Famous','deleteevents','off');           % famous_second_late

EEG = pop_selectevent( EEG, 'type',13,'renametype','Unfamiliar','deleteevents','off');      % unfamiliar_new
EEG = pop_selectevent( EEG, 'type',14,'renametype','Unfamiliar','deleteevents','off');      % unfamiliar_second_early
EEG = pop_selectevent( EEG, 'type',15,'renametype','Unfamiliar','deleteevents','off');      % unfamiliar_second_late

EEG = pop_selectevent( EEG, 'type',17,'renametype','Scrambled','deleteevents','off');       % scrambled_new
EEG = pop_selectevent( EEG, 'type',18,'renametype','Scrambled','deleteevents','off');       % scrambled_second_early
EEG = pop_selectevent( EEG, 'type',19,'renametype','Scrambled','deleteevents','off');       % scrambled_second_late

% Preprocess data
if length(EEG) == 1, EEG = eeg_checkset(EEG, 'loaddata'); end
EEG = pop_select(EEG, 'chantype', chantype);
EEG = pop_resample(EEG, 100);
EEG = pop_eegfiltnew(EEG, 1, 0);   % High pass at 1Hz
EEG = pop_eegfiltnew(EEG, 0, 40);  % Low pass below 40

%% Automatic rejection of bad channels
% Apply clean_artifacts() to reject bad channels
if contains(EEG(1).chanlocs(1).type, 'meg')
    minChanCorr = 0.4;
else
    minChanCorr = 0.9;
end
EEG = pop_clean_rawdata(EEG, 'Highpass', 'off',...
    'ChannelCriterion', minChanCorr,...
    'ChannelCriterionMaxBadTime', 0.4,...
    'LineNoiseCriterion', 4,...
    'BurstCriterion', 'off',...
    'WindowCriterion','off' );

%% Re-Reference
EEG = pop_reref(EEG,[]);

% %% Repair bursts and reject bad portions of data
EEG = pop_clean_rawdata( EEG, 'Highpass', 'off',...
    'ChannelCriterion', 'off',...
    'LineNoiseCriterion', 'off',...
    'BurstCriterion', 30,...
    'WindowCriterion',0.3);

%% run ICA
if exist('picard') % faster
    EEG = pop_runica( EEG , 'picard', 'maxiter', 500, 'pca', -1, 'concatcond', 'on');
else
    EEG = pop_runica( EEG , 'runica', 'extended',1, 'pca', -1, 'concatcond', 'on');
end

%% automatically classify Independent Components using IC Label
if ~contains(EEG(1).chanlocs(1).type, 'meg')
    EEG = pop_iclabel(EEG, 'default'); % IC label with MEG is technically possible but
                                       % IC label would need to be retrained with MEG components
    EEG = pop_icflag(EEG,  [0 0;0.9 1; 0.9 1; 0 0; 0 0; 0 0; 0 0]);
end

%% Extract event-locked trials using events listed in 'eventlist'
EEG = pop_epoch( EEG,  {'Famous' 'Unfamiliar' 'Scrambled' }, [-1  2], 'epochinfo', 'yes');

%% Perform baseline correction
EEG = pop_rmbase(EEG, [-1000 0]);

%% Clean data by rejecting epochs.
[EEG, rejindx] = pop_eegthresh(EEG, 1, [], -400, 400, EEG(1).xmin, EEG(1).xmax, 0, 1);

%% Settings for dipole localization
EEG = pop_dipfit_settings( EEG, 'model', 'standardBEM', 'coord_transform', 'warpfiducials');
EEG = pop_multifit(EEG, [1:10],'threshold', 100, 'dipplot','off');

%% Create STUDY design
ALLEEG = EEG;
STUDY = std_maketrialinfo(STUDY, ALLEEG);
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','STUDY.design 1','delfiles','off', ...
    'defaultdesign','off','variable1','type','values1',{'Famous' 'Unfamiliar' 'Scrambled' },'vartype1','categorical'); 

%% Precompute measures
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','rmicacomps','on','interp','on','recompute','on','erp','on');

%% Plot at 170 ms
chanList = eeg_mergelocs(ALLEEG.chanlocs);
STUDY = pop_erpparams(STUDY, 'plotconditions','together', 'topotime',[] );
STUDY = std_erpplot(STUDY,ALLEEG,'channels', {chanList.labels}, 'design', 1);
STUDY = pop_erpparams(STUDY, 'topotime',170 );
STUDY = std_erpplot(STUDY,ALLEEG,'channels',{chanList.labels}, 'design', 1);

%% Clustering
warning off; % for meg channel location
STUDY = std_checkset(STUDY,ALLEEG);
[STUDY ALLEEG]  = std_precomp(STUDY, ALLEEG, 'components','savetrials','on','recompute','on','erp','on','scalp','on','erpparams',{'rmbase' [-100 0]});
[STUDY ALLEEG]  = std_preclust(STUDY, ALLEEG, 1,{'erp' 'npca' 10 'weight' 1 'timewindow' [100 800]  'erpfilter' '25'},{'scalp' 'npca' 10 'weight' 1 'abso' 1},{'dipoles' 'weight' 10});
nclusters = 15;
[STUDY]         = pop_clust(STUDY, ALLEEG, 'algorithm','kmeans','clus_num',  nclusters , 'outliers',  2.8 );

%% Figures STUDY
% All clusters ERPs
STUDY = pop_erpparams(STUDY, 'filter',15,'timerange',[-100 400] );
STUDY = std_erpplot(STUDY,ALLEEG,'clusters',[2:nclusters+1], 'design', 1);

% All clusters topos
STUDY = std_topoplot(STUDY,ALLEEG,'clusters',[2:nclusters+1], 'design', 1);

% All clusters dipoles
STUDY = std_dipplot(STUDY,ALLEEG,'clusters',[2:nclusters+1], 'design', 1, 'spheres', 'off');
