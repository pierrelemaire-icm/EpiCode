% ajouter une bande de fr�quence dans la config, avec toutes les fr�quences 
% voulues de 0 � 50

% retirer du script le moment o� on moyenne les fr�quences de la bande de 
% fr�quence. Cela permet de garder l'information fr�quence par fr�quence,
% n�cessaire pour le plot TFR.
%  -> Ca ne change rien au reste du script, sauf au moment de l'interpolation (wod 
% et wor normalis�s), o� il faut rajouter une boucle pour faire
% l'interpolation pour chacune des fr�quences (car la dimension 'freq' dans le
% powspctrm ne vaut plus 1). Pour voir quelle dimension correspond aux
% frequences : regarder dans le field "dimord"

% au moment du plot de chaque bande de fr�quence, moyenner d'abord les fr�quences
% de la bande de fr�quence, avec nanmean(data.powspctrm,3); 
% Les fr�quences sont dans la dimension n�3, d'o� l'utilisation de 
% nanmean(...,3) qui moyenne selon la dimension 3  


% suggestion pour le plot TFR avec Fieldtrip, un subplot par �lectrode :
%  - one figure per trial : boucle iwod
%  - one figure with the average over rats for each electrode

fig = figure;

for chan_name = string(fieldnames(data{idata}{ifreq}))'
     
    data_plot = data{idata}{ifreq}.(chan_name);
    
    %%%%%%% a mettre pour la figure average
    %average over patients
    data_plot.powspctrm = nanmean(data_plot.powspctrm,1); %mean of the 1st dimension
    %%%%%%%
    
    %%%%%%% a mettre pour la figure iwod
    %select one patient (dans une boucle iwod)
    data_plot.powspctrm = data_plot.powspctrm(iwod,:,:,:); %mean de la dimension 1 : mean over patients
    if all(isnan(data_plot.powspctrm)) %do not plot tfr of nan channels
        continue
    end
    %%%%%%%
    
    %remove patient's dimension (must be removed to be able to use
    %ft_singleplotTFR)
    data_plot.powspctrm = permute(data_plot.powspctrm, [2 3 4 1]); 
    data_plot.dimord    = erase(data_plot.dimord, 'subj_');
    
    %find electrode position to plot each electrode in the ascending order
    iplot = str2double(cell2mat(regexp(chan_name,'\d*','Match')))-7;%-7 because E8 is 1st and E16 is 9th
    subplot(9,1,iplot);
    
    %plot TFR
    %voir les param�tres optionnels dans le descriptifs de la fonction pour
    %modifier l'aspect du TFR. Avec les param�tres par d�faut :
    cfgtemp         = [];
    cfgtemp.channel = chan_name;
    ft_singleplotTFR(cfgtemp, data_plot);
    
    title([]);
    ylabel(chan_name);
    
    if iplot <9 
        xticks([]);
        xlabel([]);
    else
        xlabel(time (s));
    end
    
end

%figure settings (fontsize,fontweight, ticks dir, renderer etc.)

% print image to file