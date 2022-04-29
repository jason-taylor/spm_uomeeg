function [D,montagefname,montage] = spm_uomeeg_laplacian(S)
%  FORMAT: [D,montagefname,montage] = spm_uomeeg_scalpcurrentdensity(S)
%  
%  Computes surface Laplacian (current density) using FieldTrip's
%  ft_scalpcurrentdensity (hacked to output montage) and applies it using
%  spm_eeg_montage.
% 
%  INPUT: Struct 'S' with fields:
%   S.D            - MEEG object or filename of MEEG object
%   S.montagefname - Filename for output montage (def: montage_Laplace_%s)
%   S.apply        - Apply montage? (1=yes | 0=no) (def: 1)
%   S.newprefix    - Output prefix of data file (if apply) (def: MLaplace_)
%  OUTPUT:
%   D
%   montage        - montage for Laplacian
%   montagefname   - montage filename
%  NOTE:
%   Requires function ft_scalpcurrentdensity_jt.m (hacked to output the montage) 
%   to be in the spm/external/fieldtrip folder.
%
%  spm_uomeeg tools
%  by Jason Taylor (29/04/2022) jason.taylor@manchester.ac.uk
%
%-------------------------------------------------------------------------

% - This requires a hacked version of Field Trip's scalpcurrentdensity function,
%   ft_scalpcurrentdensity_jt.m -- unfortunately, this must be placed in the same
%   directory as the original. Type 'which ft_scalpcurrentdensity' to find out
%   where to copy the modified file.
if isempty(which('ft_scalpcurrentdensity_jt'))
    ftdir = fileparts(which('ft_scalpcurrentdensity'));
    fprintf('\nCannot find ft_scalpcurrentdensity_jt.m !!\n')
    error('ERROR: ft_scalpcurrentdensity_jt.m not found in %s\n',ftdir);
end

%% Run spm_uom_scalpcurrentdensity
[D,montagefname,montage] = spm_uom_scalpcurrentdensity(S);
return
