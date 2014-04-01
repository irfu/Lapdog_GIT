%an_daily



function []= an_downsample(an_ind,tabindex,intval)
%count = 0;
%oldUTCpart1 ='shirley,you must be joking';

global an_tabindex;

%antemp ='';

foutarr=cell(1,7);

%fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval));
%outputarr =
%






for i=1:length(an_ind)
    
    arID = fopen(tabindex{an_ind(i),1},'r');
    %    scantemp=textscan(arID,'%s%f%f%f%i','delimiter',',');
    scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
    fclose(arID);
    
    UTCpart1 = scantemp{1,1}{1,1}(1:11);
    
    
    
 timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};
    
      
    
    
    
    %set starting spaceclock time to (UTC) 00:00:00.000000
    ah =str2double(scantemp{1,1}{1,1}(12:13));
    am =str2double(scantemp{1,1}{1,1}(15:16));
    as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
    hms = ah*3600 + am*60 + as;
    tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
    
    
    UTCpart2= datestr(((1:3600*24/intval)-0.5)*intval/(24*60*60), 'HH:MM:SS.FFF'); %calculate time of each interval, as fraction of a day
    tfoutarr{1,1} = strcat(UTCpart1,UTCpart2);
    tfoutarr{1,2} = [tday0 + ((1:3600*24/intval)-0.5)*intval]; 
    
    %     for j=1:3600*24/intval;
    %
    %         UTCpart2= datestr((0.5*intval+(j-1)*intval)/(24*60*60), 'HH:MM:SS.FFF'); %calculate time of each interval, as fraction of a day
    %         UTC_time =sprintf('%s%s',UTCpart1,UTCpart2); %collect date and time in one variable
    %         strcat(
    %
    %         tfoutarr{1,1}{j,1} = UTC_time;
    %         tfoutarr{1,2}(j) = tday0+ 0.5*intval+(j-1)*intval; %spaceclock time of measurement mean (
    %
    %     end
    %
    
    %  if count == 0 %first time going through loop! initialise things!
    %afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-6:end),sprintf('%s%i%s%iSEC.TAB',flag1,p,flag3,intval));

    
    %After Discussion 24/1 2014
    %FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_###_QPO.TAB OR
    %RPCLAP_YYMMDD_hhmmss_BLKLIST.TAB
    %
    % ### can be three integers, or 'PSD' or 'FRQ', or two integers + 'S'
    %
    % if ### = number between 000-999, then ### = MACROID (exists only for 
    % mode'H'/'L'/'S')
    % if ### = 'PSD' power spectrum of high frequency data (exists only for
    % mode 'H')
    % if ### = 'FRQ',corresponding frequency list to PSD data (exists only 
    % for mode 'H')
    % if ##S = 00S-99S downsampled data in seconds (only for mode 'D')
    %
    %  or if downsampled (O='D'), then MMM =XXS, where X is number of seconds.
    % Q= Measured quantity ('B'/'I'/'V'/'A')
    % P=Probe number(1/2/3), 
    % (Probe 3 = combined Probe 1 & Probe 2 measurement)
    % M = Mode ('H'/'L'/'S'/'D')
    %
    % B = probe bias voltage, exists only for mode = S
    % I = Current , all modes
    % V = Potential , only for mode = H/L
    % A = Derived (analysed) variables results, exists only for mode = S
    %
    % H = High frequency measurements
    % L = Low frequency measurements
    % S = Voltage sweep measurements
    % D = low frequency downsampled measurements, if O=D, then MMM = XXS, where XX = downsampling period (in seconds)
    
    %RPCLAP_YYMMDD_hhmmss_MMM_V1D
    %collect files of same macro? or skip macro information, but contain inside LBL file
    %RPCLAP_YYMMDD_DWNSMP_32S_V1L
    %RPCLAP_YYMMDD_hhmmss_32S_V1D
    
    afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-10:end-8),sprintf('%02iS',intval));
    afname(end-4) = 'D';
    %afname = strrep(afname,afname(end-4),'D');
    affolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
    
    
% QUALITYFLAG:
% is an 3 digit integer 
% from 000 (best) to 332 (worst quality)

% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
%
% low sample size(for avgs) = +2
% some zeropadding(for psd) = +2
    
    
    
    
    
    %t=scantemp{1,2}(:);
    
    
    %  tt = ( tday0+intval*floor((t(1)-tday0)/intval):1*intval:tday0+intval*ceil((t(end)-tday0)/intval) )'; %tidst?mplar med 32 sekunder mellan varje st?mpel, startar p? en multipel av 32 p? dygnet
    %tt = ( floor(t(1)):1*spacing:ceil(t(end)) )';
    % //        I would do this in three fully vectorized lines of code. First, if the breaks were arbitrary and potentially unequal in spacing,
    %//I would use histc to determine which intervals the data series falls in. Given they are uniform, just do this:
    
    
    
    
    %    inter = 1 + floor((t - tday0)/intval); %prepare subset selection to accumarray
    inter = 1 + floor((scantemp{1,2}(:) - tday0)/intval); %prepare subset selection to accumarray
    
    %intervals specified from beginning of day, in intervals of intval,
    %and the variable inter marks which interval the data in the file is related to
    
    
    
    
    
    
    
    
    imu = accumarray(inter,scantemp{1,3}(:),[],@mean); %select measurements during specific intervals, accumulate mean to array and print zero otherwise
    isd = accumarray(inter,scantemp{1,3}(:),[],@std); %select measurements during specific intervals, accumulate standard deviation to array and print zero otherwise
    
    vmu = accumarray(inter,scantemp{1,4}(:),[],@mean);
    vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
    
    
    
    foutarr{1,3}(inter(1):inter(end),1)=imu(inter(1):inter(end)); %prepare for printing results
    foutarr{1,4}(inter(1):inter(end),1)=isd(inter(1):inter(end));
    foutarr{1,5}(inter(1):inter(end),1)=vmu(inter(1):inter(end));
    foutarr{1,6}(inter(1):inter(end),1)=vsd(inter(1):inter(end));
    foutarr{1,7}(inter(1):inter(end),1)=1; %%flag to determine if row should be written.
    
    
    
    
    
    if intval ==0 %%analysis if
        
        
        
        for j = 2: length(scantemp{1,2})-1
            
            %leapfrog derivative method
            scantemp{1,6}(j)=scantemp{1,3}(j-1)-scantemp{1,3}(j+1)/(scantemp{1,2}(j-1)-scantemp{1,2}(j+1));  %%dI/dt
            scantemp{1,7}(j)=scantemp{1,4}(j-1)-scantemp{1,3}(j+1)/(scantemp{1,2}(j-1)-scantemp{1,2}(j+1));  %%dV/dt
            
        end%for
        
        scantemp{1,6}(1)=scantemp{1,3}(1)-scantemp{1,3}(1+1)/(scantemp{1,2}(1)-scantemp{1,2}(1+1));  %%dI/dt  %forward differentiation, larger error
        scantemp{1,6}(j+1)=scantemp{1,3}(j)-scantemp{1,3}(j+1)/(scantemp{1,2}(j)-scantemp{1,2}(j+1)); %%dI/dt %backward differentiation, larger error
        scantemp{1,7}(1)=scantemp{1,4}(1)-scantemp{1,4}(1+1)/(scantemp{1,2}(1)-scantemp{1,2}(1+1));  %%dV/dt  %forward differentiation, larger error
        scantemp{1,7}(j+1)=scantemp{1,4}(j)-scantemp{1,4}(j+1)/(scantemp{1,2}(j)-scantemp{1,2}(j+1)); %%dV/dt %backward differentiation,  larger error
        
        
        
        
        dimu = accumarray(inter,scantemp{1,6}(:),[],@mean);
        disd = accumarray(inter,scantemp{1,6}(:),[],@std);
        dvmu = accumarray(inter,scantemp{1,7}(:),[],@mean);
        dvsd = accumarray(inter,scantemp{1,7}(:),[],@std);
        
        
        afoutarr=foutarr;
        
        afoutarr{1,8}(inter(1):inter(end),1)=dimu(inter(1):inter(end));
        afoutarr{1,9}(inter(1):inter(end),1)=disd(inter(1):inter(end));
        afoutarr{1,10}(inter(1):inter(end),1)=dvmu(inter(1):inter(end));
        afoutarr{1,11}(inter(1):inter(end),1)=dvsd(inter(1):inter(end));
        
        
        
        mode = afname(end-6);
        
        if mode == 'V' %analyse electric field mode
            
            
            an_Emode(afoutarr);
            
        elseif mode == 'I' %analyse density mode
            
            an_Nmode(afoutarr);
            
        end%if
        
    end%if
    
    
    
    
    
    
    clear imu isd vmu vsd inter %save electricity kids!
    
    
    
    
    
    %     tabindex
    
    
    
    % if i ==length(an_ind) %only print if this is last file of the loop, otherwise perform print check at beginning of loop
    
    
    %For LBL file genesis, we need an index with name, shortname,
    %original file
    an_tabindex{end+1,1} = afname;%start new line of an_tabindex, and record file name
    an_tabindex{end,2} = strrep(afname,affolder,''); %shortfilename
    an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
    an_tabindex{end,4} = length(foutarr{1,3}); %number of rows
    an_tabindex{end,5} = 6; %number of columns
    
    an_tabindex{end,6} = an_ind(i);
    an_tabindex{end,7} = 'downsample'; %type
    an_tabindex{end,8} = timing;
    
    
    awID= fopen(afname,'w');
    for j =1:length(foutarr{1,3})
        
        if foutarr{1,7}(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e\n',tfoutarr{1,1}(j,:),tfoutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
        end%if
        
    end%for
    
    fclose(awID);
    clear foutarr  %not really needed, will not exist outside of function anyway.
    
    
    
    %    oldUTCpart1 = UTCpart1; %stuff to remember next loop iteration
    %   count = count +1; %increment counter
    
    
    
    
    
    
end%for main loop
end%function










