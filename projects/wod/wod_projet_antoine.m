function wod_project_antoine(slurm_task_id)

% Ce script projet sert à calculer les données de chaque rat
% 'irat' est en input car il prendra la valeur du array slurm sur le cluster
% Rassembler les données de tous les rats pour faire des moyennes ou stats
% sur tous les rats : dans un autre script (si possible organisé comme
% celui-ci)

% a faire pour réorganiser les fonctions WOD : 
% - mettre en input : cfg, MuseStruct, LFP, et toutes les structures qui sont calculées 
% dans une autre fonction
% - retirer les addpath, les config = wod_setparams, les boucles irat
% - remplacer tous les config{irat} par cfg
% - si possible, sauvegarder les données en fin de script, et créer la 
% possibilité de les charger avec l'argument 'force'

%% set parameters
try %en local
    scriptpath = matlab.desktop.editor.getActiveFilename;
catch %cluster
    scriptpath = mfilename('fullpath');
end

epicodepath = [fileparts(fileparts(fileparts(scriptpath))), filesep];

addpath (genpath([epicodepath,'development']))
addpath (genpath([epicodepath,'shared']))
addpath (genpath([epicodepath,'external']))
addpath (genpath([epicodepath,'templates']))
addpath (genpath([epicodepath,'projects', filesep, 'wod']))
addpath (genpath([epicodepath,'projects', filesep, 'dtx']))
addpath (genpath([epicodepath,'projects', filesep, 'wod',filesep,'wod_functions']))

if ispc
    addpath \\lexport\iss01.charpier\analyses\wod\fieldtrip-20200607
elseif isunix
    addpath /network/lustre/iss01/charpier/analyses/wod/fieldtrip-20200607
end

ft_defaults


config16 = wod_setparams;
config32 = wod_setparams_32chan;
config = wod_setparams_32chan;
cfgorig = config;

ipart= 1;

%% analysis by rat

if slurm_task_id >0
for irat= slurm_task_id

    if isempty(config{irat})
        continue
    end
    
%find concatenated LFP (see wod_concatenateLFP.m)
[~,dir_name]                       = fileparts(cfgorig{irat}.rawdir);
config{irat}.rawdir                = fullfile(config{irat}.concatdata_path);
config{irat}.directorylist{ipart}  = {config{irat}.prefix};

%read Muse markers 
MuseStruct = readMuseMarkers(config{irat}, false);
save(fullfile(config{irat}.datasavedir,sprintf('%s-MuseStruct.mat',config{irat}.prefix)),'MuseStruct');

%read LFP, append electrodes, and cut into trials according to Muse Markers
LFP = readLFP(config{irat}, MuseStruct, false);
LFP = LFP{1}.(config{irat}.LFP.name{1}); %remove this 'epicode' organisation for now.
%end
%vérifier qu'il y a bien autant de trials que de marqueurs Vent_Off
startmarker = config{irat}.muse.startmarker.(config{irat}.LFP.name{1});
if size(LFP.trial,2) ~= size(MuseStruct{1}{1}.markers.(startmarker).synctime,2)
    error('Not the same number of trials that of marker start for %s. \nCheck that begin/end of each trial is not before start of file or after end of file', config{irat}.prefix(1:end-1));
end


% Compute TFR for each rat
wod_tfr_compute(config{irat}, MuseStruct,LFP);

%Plot TFR data for each rat
wod_tfr_plotrat(config{irat});




end %irat
end %if slurm_task_id

if slurm_task_id==0
%% Analysis for pooled rats

%% Waves delay data
%Detect waves, extract timings and values
stats_all=wod_wavedetection([config16, config32],false);

%extract origin depth, timing, propagation speed. make stats between
%protocols and between waves.
calculated_data= wod_propag_analysis([config16 config32],false);

%gather 16 and 32 chans
ordered_data = wod_fusion_data(stats_all,[config16 config32],false);

%plot delays
wod_plot_delays(ordered_data,config16);
%

%% Frequency band data

%extract peak time and value for power bands
freq_data=wod_tfr_extractdata([config16, config32],true);

%gather 16 and 32 chans
ordered_freqdata = wod_fusion_freqdata(freq_data,[config16 config32],true);

%plot freq data

%freq data stats

%Plot average TFR
%wod_tfr_grandaverage(config);



end %rat_list
end %wod_project