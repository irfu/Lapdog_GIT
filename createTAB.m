function []= createTAB(derivedpath,tabind,index,macrotime,fileflag,sweept)
%derivedpath   =  filepath
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data
%sweept         = start&stop times for sweep in macroblock
%    FILE GENESIS

%After Discussion 24/1 2014
%FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_MMM_QPO
% MMM = MacroID,
% Q= Measured quantity (B/I/V/A)
% P=Probe number(1/2/3),
% O = Mode (H/L/S)
%
% B = probe bias voltage, exists only for mode = S
% I = Current , all modes
% V = Potential , only for mode = H/L
% A = Derived (analysed) variables results, all modes
%
% H = High frequency measurements
% L = Low frequency measurements
% S = Voltage sweep measurements 

% TIME STAMP example : 2011-09-05T13:45:20.026075
%YYYY-MM-DDThh:mm:ss.ffffff % double[s],double[A],double [V],int

%probe = str2double(fileflag(2));


% QUALITYFLAG:
% is an 3 digit integer "DDD"
% starting at 000

% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
% low sample size(for avgs) = +1


%e.g. QF = 320 -> Sweep during measurement, bug during measurement, bias change during measurement 
%  QF =000 ALL OK.







dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');



filename = sprintf('%sRPCLAP_%s_%s_%d_%s.TAB',tabfolder,datestr(macrotime,'yyyymmdd'),datestr(macrotime,'HHMMSS'),index(tabind(1)).macro,fileflag); %%
filenamep = strrep(filename,tabfolder,'');
twID = fopen(filename,'w');

global tabindex;
tabindex{end+1,1} = filename; %% Let's remember all TABfiles we create
tabindex{end,2} = filenamep; %%their shorter name
tabindex{end,3} = tabind(1); %% and the first index number



len = length(tabind);
counttemp = 0;
%tot_bytes = 0;
if(~index(tabind(1)).sweep); %% if not a sweep, do:
    
    for(i=1:len);
        trID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        
        %at some macros, we have measurements taken during sweeps, which leads to weird results
        %we need to find these and remove them          
        
        if ~isempty(sweept)
            
            for j =1:length(sweept(1,:))
                after  = scantemp{1,2}(:)   >= sweept(1,j);   %after sweep start
                before = scantemp{1,2}(:)   <= sweept(2,j);   %before sweep ends
                
                %NB: sweep stop % start time (from LBL files) seem to be roughly
                %0.2 seconds before and after first and final measurement, so we
                %probably won't have to increase "deletion window"
                del = find(after==before); %%after ~= before unless value within sweep window
                if ~isempty(del)
                    
                    % instead of remove, do qualityflag?
                    % scantemp{1,5}(del) =100;
                    
                    scantemp{1,1}(del)    = [];
                    scantemp{1,2}(del)    = [];
                    scantemp{1,3}(del)    = [];
                    scantemp{1,4}(del)    = [];

                end%if
            end% for
        end%  sweep window deletions
        


        scanlength = length(scantemp{1,1});
        counttemp = counttemp + scanlength;
   
        for (j=1:scanlength)       %print  

            %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            
            if isempty(scantemp{1,5}{j,1})
                fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, 000\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            else
                fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %3i\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j));
                
                
            end
            
        end
        
        if (i==len) %finalisation
            tabindex{end,4}= scantemp{1,1}{end,1}; %%remember stop time in universal time and spaceclock time
            tabindex{end,5}= scantemp{1,2}(end); %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            tabindex{end,6}= counttemp;
        end
        
        fclose(trID);
        clear scantemp scanlength
    end
else %% if sweep, do:
    
    filename2 = filename;
    filename2(end-6) = 'I'; %current data file name according to convention%   
    filename3 = filename;
    filename3(end-6) = 'A'; %A for derived  analysis
    
%     if exist(filename2,'file')==2 %this doesn't work!
%         delete('filename2');
%     end
    tmpf = fopen(filename2,'w');
    fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
    tmpf = fopen(filename3,'w');
    fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
    condfile = fopen(filename2,'a');
 
    
    
    
    for(i=1:len); %read&write loop
        trID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');  
        fclose(trID); %close read file, terminated each new read iteration  
        
        
        %first values are not in the defined sweep, This will cause trouble*
        %if first potential values change during 4-5 measurements
        step1 = find(diff(scantemp{1,4}(1:end)),1,'first');       
        scantemp{1,1}(1:step1)    = []; 
        scantemp{1,2}(1:step1)    = [];
        scantemp{1,3}(1:step1)    = [];
        scantemp{1,4}(1:step1)    = [];

        if (i==1) %do this only once
            stepnr= find(diff(scantemp{1,4}(1:end)),1,'first'); %find the number of measurements on each sweep
            %downsample sweep
            
            scan2temp =downsample(scantemp{1,2},stepnr); %needed once
            potbias =downsample(scantemp{1,4},stepnr); %needed once
            
            potlength=length(potbias);
%             potbias = scan2temp{1,4}(1:end);
            reltime = scan2temp(:)-scan2temp(1);
            pottemp = [reltime(:),potbias];
            dlmwrite(filename,pottemp,'-append','precision', '%14.7e'); %also writes \n
            
        end
  
        
        %due to a bug, the first deleted measurements will lead to a shortage of measurements on the final sweep step 
        leee = length(scantemp{1,3});
        if mod(leee,stepnr)~=0 %if bug didn't end after step completion 
        %pad matrix with mean value of last row
            mooo=mod(leee,stepnr);
            meee = scantemp{1,3}(end-mooo+1:end);
            scantemp{1,3}(end+1:end+stepnr-mooo) = mean(meee);
        end
        B = reshape(scantemp{1,3}.',stepnr,potlength);    %I need only one transpose!
        curtemp = mean(B); %curtemp is now a row vector
        clear B mooo meee leee
        
        
        
        
        
        fprintf(condfile,'%s, %s, %16.6f, %16.6f',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end));
        dlmwrite(filename2,curtemp,'-append','precision', '%14.7e', 'delimiter', ', '); %appends to end of row, column 4. pretty neat.
        
        curtemp = curtemp.'; %transpose..
        
        
        %excellent time for some analysis!
        %
        %         filename3 = filename;
        %         filename3(end-6) = 'A'; %A for derived  analysis
        %
        
       
        
        [Vb,ind]=sort(potbias);
        
       % Vb=potbias(ind);
        Is=curtemp(ind);
        
        
        Weyderived = preliminaries(Vb,Is);
        
        
        
        derived = an_swp(potbias,curtemp,scantemp{1,2}(1,1),filename(end-5));
        
        
%    %     p2s_params= derived;
%         
%     figure(157);
% 
%     subplot(4,1,1);
%     plot(derived(:,1),1e9*derived(:,15),'k.',p2s_params(:,1),1e9*p2s_params(:,15)+7,'r.');
%     ylim([-15 0])
%     grid on;
%     datetick('x',15);
%     ylabel('If0 [nA]');
%     if(~isempty(derived))
%       titstr = sprintf('Sweep summary %s',datestr(derived(1,1),29));
%     else
%       titstr = sprintf('Sweep summary %s',datestr(p2s_params(1,1),29));
%     end
%     title(titstr);
% 
%     subplot(4,1,2);
%     plot(derived(:,1),-derived(:,11),'ko',p2s_params(:,1),-p2s_params(:,11),'ro');
%     hold on;
%     plot(derived(:,1),derived(:,16),'k.',p2s_params(:,1),p2s_params(:,16),'r.');
%     hold off;
%     grid on;
%     datetick('x',15);
%     ylim([-5 5]);
%     ylabel('Vps [V]');
% 
%     subplot(4,1,3);
%     Te1 = derived(:,12)./derived(:,13);
%     Te2 = p2s_params(:,12)./p2s_params(:,13);
%     semilogy(derived(:,1),Te1,'k.',p2s_params(:,1),Te2,'r.',derived(:,1),derived(:,14),'ko',p2s_params(:,1),p2s_params(:,14),'ro');
%     ylim([0.01 10]);
%     grid on;
%     datetick('x',15);
%     ylabel('Te [V]');
% 
%     subplot(4,1,4)
%     % Cal fact n/(dI/dV): (1.6e-19)^1.5 * 4 * pi * 0.025 / sqrt(2*pi*Te*9.1e-31); 
%     k = sqrt(2*pi*9.1e-31) ./ ((1.6e-19)^1.5 * 4 * pi * 0.025^2);
%     semilogy(derived(:,1),1e-6*k*derived(:,8).*sqrt(Te1),'k.',p2s_params(:,1),1e-6*k*p2s_params(:,8).*sqrt(Te2),'r.');
%     ylim([0.1 100]);
%     grid on;
%     datetick('x',15);
%     ylabel('ne [cm-3]');
%     
%     samexaxis('join');
%     drawnow;
%     
%         
        
        
%         % dlmwrite(filename3,derived,'-append','precision','%14,7e');
%         dlmwrite(filename3,derived,'-append');
%         
    
        if (i==len)
            scanlength = length(scantemp{1,1});

            tabindex(end,4:6)= {scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),scanlength}; %one index for bias voltages
            tabindex(end+1,1:7)={filename2,strrep(filename2,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len,scanlength};
 %           tabindex(end+1,1:6)={filename3,strrep(filename3,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len};
            %one index for currents and two timestamps
            
            %remember stop time in universal time and spaceclock time
            %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            %%remember stop time in universal time (WITH ONLY 3 DECIMALS!) 
            %and spaceclock time for sweep current data, store number of 
            %rows & no of columns (+4)
        end
       
        clear scantemp;
    end
    fclose(condfile); %write file nr 2, condensed data, terminated asap
    
end
fclose(twID); %write file nr 1


                    
                    
                    
                    
end


