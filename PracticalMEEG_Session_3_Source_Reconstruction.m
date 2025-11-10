% Practical MEEG 2025
% Wakeman & Henson Data analysis: Dipole localization

% Authors: Ramon Martinez-Cancino, Brain Products, 2022
%          Arnaud Delorme, SCCN, 2022-2025
%          Johanna Wagner, Zander Labs, 2022
%
% Copyright (C) 2022  Ramon Martinez-Cancino 
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

%%
% Clearing all is recommended to avoid variable not being erased between calls 
clear;                                      
clear globals;

% Path to data below. Using relative paths so no need to update.
path2data = fullfile(pwd,'ds000117_pruned', 'derivatives', 'meg_derivatives', 'sub-01', 'ses-meg', 'meg'); % Path to data 
filename = 'wh_S01_run_01_preprocessing_data_session_1_out.set';

% Start EEGLAB
[ALLEEG, EEG, CURRENTSET] = eeglab; 

%% Loading data
EEG = pop_loadset('filename', filename,'filepath',path2data);

%% Extract event-locked trials using events
EEG = pop_epoch( EEG, {'Famous', 'Unfamiliar', 'Scrambled'}, [-1  2], 'newname', 'WH_Epoched', 'epochinfo', 'yes');

%% Perform baseline correction
EEG = pop_rmbase(EEG, [-1000 0]);

%% Source localization
dipfitpath       = fileparts(which('pop_multifit'));
electemplatepath = fullfile(dipfitpath, 'standard_BEM', 'elec', 'standard_1005.elc');
if ~contains(EEG.chanlocs(1).type, 'meg') % EEG only
    %  Clean data by rejecting epochs.
    EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -400, 400, EEG.xmin, EEG.xmax, 0, 1);
    
    % Subtract artefactual components from the EEG
    [M,I] = max(EEG.etc.ic_classification.ICLabel.classifications,[],2);                       % Use max prob for classification
    Brain_comps = find(I == find(strcmp(EEG.etc.ic_classification.ICLabel.classes, 'Brain')));
    EEG = pop_subcomp( EEG, Brain_comps, 0, 1);
else % MEG
    Brain_comps = 1:size(EEG.icaweights);
end

% perform dipole fitting
EEG = pop_dipfit_settings( EEG, 'model', 'standardBEM', 'coord_transform', 'warpfiducials');
EEG = pop_multifit(EEG, 1:10,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}); % only 10 fine fit for speed

% Fitting dual dipole (for you may not be IC 4, check and asses)
choosenIC = 4;
EEG = pop_multifit(EEG, choosenIC, 'threshold', 100, 'dipoles', 2, 'plotopt', {'normlen' 'on'});

%% Plot brain component dipole for component 5
% There might be a coregistration issue with MEG as components tend to be frontal
pop_dipplot( EEG, Brain_comps(2),'mri',fullfile(dipfitpath,'standard_BEM', 'standard_mri.mat'),'normlen','on', 'rvrange', 15);

%% Compute leadfield and Loreta for that same component
EEG = pop_leadfield(EEG, 'sourcemodel',fullfile(dipfitpath,'LORETA-Talairach-BAs.mat'),'sourcemodel2mni',[],'downsample',1);
pop_dipfit_loreta(EEG, 3);

%% ERP Image Dipole on Fusiform Area
% Changing dipolarity
EEG.icaweights(choosenIC,:) = -EEG.icaweights(choosenIC,:);
EEG.icawinv(:,choosenIC) = -EEG.icawinv(:,choosenIC);
EEG.icaact(choosenIC,:) = -EEG.icaact(choosenIC,:);
figure; pop_erpimage(EEG,0, choosenIC,[[]],['Comp. ' int2str(choosenIC) ],10,1,{},[],'' ,'yerplabel','','erp','on','cbar','on','topo', { mean(EEG.icawinv(:,[choosenIC]),2) EEG.chanlocs EEG.chaninfo } );

%% Saving data
EEG = pop_saveset( EEG,'filename', 'wh_S01_run_01_Source_Reconstruction_Session_4_out.set','filepath', path2data);

%% Source reconstruction realistic
EEG = pop_dipfit_headmodel(EEG, fullfile(pwd,'ds000117_pruned', 'sub-01','ses-mri','anat','sub-01_ses-mri_acq-mprage_T1w.nii.gz'), 'datatype','EEG','plotmesh','scalp');
EEG = pop_dipfit_settings( EEG, 'coordformat','ctf','coord_transform',[6.9504 -1.0214 43.3393 1.0735e-07 -9.8111e-06 0.013134 10.5701 10.5701 10.5701] );
EEG = pop_multifit(EEG, Brain_comps, 'threshold', 100, 'dipoles', 1, 'plotopt', {'normlen' 'on'});
pop_dipplot( EEG, Brain_comps(2),'mri',EEG.dipfit.mrifile,'normlen','on', 'rvrange', 100);
