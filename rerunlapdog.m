%LAP DERIVED ARCHIVE GENERATION
% anders.eriksson@irfu.se 2012-03-29
% frejon@irfu.se 2014-05-07
%
%For batch mode execution via script, to execute local execution in Matlab, see main.m
%if the calibrated and derived archive is already in /data/LAP_ARCHIVE/
%
%Quick description
%1. The program is designed to be called by a script, and somewhat controlled in batch_control.m, with no other user
% input necessary
%2. preamble defines some variables used everywhere in the script
%3.
%indexgen reads every .LBL file in the archive (50% of all files) as
%specified from the index.dat file in outputs it into a useful "index"
%variable
%4. some post-processing of the index is needed in indexcorr to split files
%exactly at midnight, OBS some files created in temp/ folder,
%5.generates daily geometry files
%6. Seperates all files into macro operation blocks, each block terminated
%by midnight or new macroid
%7.
%process reads all data, and mills it into new, condensed files
%** information of each new file is stored in "tabindex" variable
%8. an_IV analyses sweeps, wave snapshots (spectra), and downsamples data for
%quick-look plots and stores them in files
%** information of each new file is stored in "an_tabindex" variable
%9. createLBL produces .LBL files for each generated file  (PDS archive
%specific file type)
%
function [] = rerunlapdog_test(archpath, archID, missioncalendar,rerun_mode)




fprintf(1,'LAPDOG - LAP Data Overview and Geometry \n');



 fprintf(1,'rerunlapdog(%s,%s,%s,%s) activated ...\n',archpath, archID, missioncalendar,rerun_mode);


rerun_mode = str2double(rerun_mode);
remake_index = 1;
remake_tabindex = 1;
remake_analysis = 1;
remake_sweepsonly = 0;
%remake_bestestimates = 1;
remake_LBL =1;
remake_BLKLISTONLY = 0;


switch rerun_mode
    
    case 0
        %        redo_index = 1;
        %       redo_tabindex = 1;
        %        redo_analysis = 1;
        %        redo_bestestimates = 1;
        %        redo_LBL =1;
        fprintf(1,'lapdog: load nothing from caches, remake everything...\n');
        
        
    case 1
        remake_index = 0;
        
        fprintf(1,'lapdog: load only CALIB index from cache, rerun the rest (tabindex.m test mode) \n');
        
        
    case 2
        remake_index = 0;
        remake_tabindex = 0;
%        remake_analysis = 1;
%        remake_bestestimates = 1;
%        remake_LBL =1;
        
        fprintf(1,'lapdog: Load all indices, rerun analysis and the rest (analysis mode) \n');
        
        
    case 3
        remake_index = 0;       
        remake_tabindex = 0;
        remake_analysis = 0;
%        remake_bestestimates = 0;       
        fprintf(1,'lapdog: create new LBL files (currently only works for resampled part of archive (no analysis & an_index))...\n');
        
        
     case 4
         
         remake_index = -1; % -1 skips index all together
         remake_tabindex = 0;
         remake_analysis = 1;
%         remake_bestestimates = 0;
         remake_LBL =0;
%         
         fprintf(1,'lapdog: analysis test mode. Only used for test purposes, will crash and not create EST.TAB & LBL files..\n');
%         
    case 5
        remake_index = 0;
        remake_tabindex = 0;
	remake_sweepsonly = 1;
%        remake_analysis = 1;
%        remake_bestestimates = 1;
%        remake_LBL =1;

        fprintf(1,'lapdog: Load all indices, rerun sweep analysis and best estimates, make lbl file (sweep mode) \n');

       
    case 7


        remake_index = 0;
        remake_tabindex = 0;
        remake_BLKLISTONLY = 1;

 
        
end


% fprintf(1,'lapdog: Reading pds.conf\n ')
batch_control;

% Set up PDS keywords etc:

fprintf(1,'lapdog: calling preamble...\n');

preamble;

% Load or, if not defined, generate index:
% fprintf(1,'lapdog: load indices if existing...')
dynampath= mfilename('fullpath'); %find path & remove/lapdog from string
dynampath = dynampath(1:end-12);


fprintf(1,'lapdog: %s\n',dynampath);


if ge(remake_index,0) %remake index ~=-1
    
    indexversion = '2'; %index updated with new variable 17Dec 2014
    indexfile = sprintf('%s/index/index_%s_v%s.mat',dynampath,archiveid,indexversion);
    %indexfile = sprintf('%s/index/index_%s.mat',dynampath,archiveid);
    
    
    
    if((exist(indexfile) == 2) && remake_index == 0) %let's try to load from cache
        %             fp = fopen(indexfile,'r');
        %
        %             fclose(fp);
        fprintf(1, 'loading index...\n',dynampath);
        
        load(indexfile);
        
        substring = '/mnt/localhd/cron_script_temp/'; 
       % substring = '/data/LAP_ARCHIVE/cronworkfolder/';
        newstring= '/data/LAP_ARCHIVE/';
        fprintf(1,'replacing substrings...\n');
        
        index = struct_string_replace(index,substring,newstring); %third party code
	
        substring = '/usr/local/src/cronworkfolder/';
        %newstring= '/data/LAP_ARCHIVE/';
        fprintf(1,'replacing substring type 2...\n');

       % index = struct_string_replace(index,substring,newstring); %third party code
        

        fprintf(1, 'lapdog: succesfully loaded server index\n');
        
        
    else
        
        
        fprintf(1,'lapdog: calling indexgen\n');
        indexgen;
        fprintf(1,'lapdog: splitting files at midnight..\n');
        indexcorr;
        
        
        folder= sprintf('%s/index',dynampath);
        if exist(folder,'dir')~=7
            mkdir(folder);
        end
        
        
        save(indexfile,'index');
    end
    
    
end

    
    
    
if ge(remake_index,0)

    % Generate daily geometry files:
    if(do_geom)
        fprintf(1,'lapdog: calling geometry...\n');
        geometry;
    end
    
    % Generate block list file:
    
    fprintf(1,'lapdog: calling opsblocks...\n');
 
if (remake_BLKLISTONLY)

opsblocks;
return;

else
   opsblocks;

end

end

% Resample data
tabindexfile = sprintf('%s/tabindex/tabindex_%s.mat',dynampath,archiveid);

% if(fp > 0)
if (exist(tabindexfile) == 2 && remake_tabindex == 0)
    %    fclose(fp);
    fprintf(1,'lapdog: loading tabfiles...\n');
    load(tabindexfile);
    
    
    substring = '/data/LAP_ARCHIVE/cronworkfolder/';
    newstring= '/data/LAP_ARCHIVE/';
    
	%substring = strrep(tabindex(1,1),tabindex(1,2),'');
    %	tabindexsubstring= substring{1,1}(1:end-42);
    %	newstring= '/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/';
	fprintf(1,'replacing substrings in tabindex...\n');
    tabindex(:,1) = cellfun(@(x) strrep(x,substring,newstring),tabindex(:,1),'un',0);
    
    substring = '/usr/local/src/cronworkfolder/';

    %newstring= '/data/LAP_ARCHIVE/';
    fprintf(1,'replacing substrings type 2 in tabindex...\n');
    tabindex(:,1) = cellfun(@(x) strrep(x,substring,newstring),tabindex(:,1),'un',0);

    substring = '/mnt/localhd/cron_script_temp/'

    %newstring= '/data/LAP_ARCHIVE/';
    fprintf(1,'replacing substrings type 3 in tabindex...\n');
    tabindex(:,1) = cellfun(@(x) strrep(x,substring,newstring),tabindex(:,1),'un',0);
    fprintf(1,'lapdog: succesfully loaded tabfiles...\n');




    
else
    
    fprintf(1,'lapdog: calling process...\n');
    process;
    
    
    folder= sprintf('%s/tabindex',dynampath);
    if exist(folder,'dir')~=7
        mkdir(folder);
    end
    
    save(tabindexfile,'tabindex');
end


%analyse


if remake_analysis
    
   if remake_sweepsonly
	analysis_test;
   else
	analysis;
   end
end


%create all LBL files

if remake_LBL
    fprintf(1,'lapdog: generate LBL files....\n');
    createLBL;
    
end


fprintf(1,'lapdog: DONE!\n');

end

% End of main.m
