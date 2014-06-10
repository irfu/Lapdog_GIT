%hf sweep

%function [] = an_hf(derivedpath,an_ind,index,macrotime,fileflag)


function [] = an_hf(an_ind,tabindex,fileflag)

diag = 0;

plotpsd=[];
plotT=[];
plotSCT=[];

ib1 =0;
ib2 =0;
vp1 = 0;
vp2 = 0;

% QUALITYFLAG (qf):
% is an 3 digit integer "DDD"
% starting at 000

% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
%
% low sample size(for avgs) = +2
% some zeropadding(for psd) = +2

qf=0;
nfft=128;
fsamp = 18750;

%fname = sprintf('%sRPCLAP_%s_%s_FRQ_%s.TAB',ffolder,datestr(macrotime,'yyyymmdd'),datestr(macrotime,'HHMMSS'),fileflag); %%
%fpath = strrep(filename,ffolder,'');


len = length(an_ind);

k=0;

try
    
    
    for i=1:len
        
        fout={};  %fout is the array that will be printed.fout{:,end} will be a boolean print check, but is first saved as a
        
        %names, folders
        fname = tabindex{an_ind(i),1};
        fname(end-10:end-8)='FRQ';
        ffolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        
        sname = strrep(fname,'FRQ','PSD');%%
        
        
        
        
        trID = fopen(tabindex{an_ind(i),1},'r');
        
        if fileflag(2) =='3' %one more column for probe 3 files
            scantemp = textscan(trID,'%s%f%f%f%f%d','delimiter',','); %ts,sct,ib1,ib2,vp1-vp2
            ib1=scantemp{1,3};
            ib2=scantemp{1,4};
        else
            scantemp = textscan(trID,'%s%f%f%f%d','delimiter',',');
        end
        
        fclose(trID);
        
        
        
        
        %need to split **H.TAB file into seperate high frequency snap shots
        
        reltime= scantemp{1,2} - scantemp{1,2}(1);
        dt = reltime(2);
        count = 1;
        t0=reltime(1);
        sind = zeros(length(reltime),1);
        
        
        %loop from n =1 to end-1, checking n+1. (no need to check first entry)
        %made such that we avoid 'Index exceeds matrix dimensions' errors
        for n=1:length(reltime)-1
            
            
            
            
            if reltime(n+1)-t0 >8e-3
                %%start new timer, but don't increment line counter, results
                %%will be averaged
                t0 =reltime(n+1);
            end
            
            
            if reltime(n+1)-reltime(n)>dt*5000 %large jump, new timer
                
                t0 =reltime(n+1);
                count = count+1; %each count will generate 1 line of output in file
                
            end
            
            if reltime(n+1)-t0 >= 2e-3 && reltime(n+1)-t0 <= 8e-3
                
                sind(n+1) = count;
                %         else
                %             sind(n) = 0;
                
            end
            
            %         if count==1 && reltime(n+1)-t0 >= 2e-3
            %
            %             sind(n+1) = count;
            %         end
            
            
            
        end
        obs = find(diff(sind)>0)+1;
        obe = find(diff(sind)<0);
        if sind(end)~=0
            obe(end+1)=length(sind);
        end
        
        
        timing={scantemp{1,1}{obs(1)},scantemp{1,1}{obe(end)},scantemp{1,2}(obs(1)),scantemp{1,2}(obe(end))};
        
        a=[];
        for b=1:length(obs) %loop each 6ms spectra subsample
            a= [a;reltime(obe(b))-reltime(obs(b))];
            if reltime(obe(b))-reltime(obs(b)) >(3e-3-0.1304)%if subsample too small, disregard
                
                ob = obs(b):obe(b);
                
                
                
                tstr= scantemp{1,1}(ob(1):ob(end));
                sct= scantemp{1,2}(ob(1):ob(end));
                
                
                if strcmp(fileflag,'V3H') %one more column for probe 3 files
                    ib1=scantemp{1,3}(ob(1):ob(end));
                    ib2=scantemp{1,4}(ob(1):ob(end));
                    
                elseif strcmp(fileflag,'I3H')
                    
                    vp1 =scantemp{1,4}(ob(1):ob(end));
                    vp2 =scantemp{1,5}(ob(1):ob(end));
                end
                
                ib=scantemp{1,3}(ob(1):ob(end));
                vp=scantemp{1,end-1}(ob(1):ob(end)); %for probe 3, vp is scantemp{1,5}, otherwise {1,4}
                qfarray = scantemp{1,end}(ob(1):ob(end)); %quality factor, always at the end
                
                
                
                lens = length(vp);
                
                if strcmp(fileflag(1),'V')
                    
                    
                    vpred = vp - mean(vp);
                    %       lens = length(vp);
                    [psd,freq] = pwelch(vpred,hanning(lens),[], nfft, fsamp);
                    
                    
                    
                elseif strcmp(fileflag(1),'I')
                    
                    
                    
                    ibred = ib - mean(ib);
                    [psd,freq] = pwelch(ibred,hanning(lens),[], nfft, fsamp);
                    
                    %[psd,freq] = pwelch(ib,[],[],nfft,18750);
                    %    plot(freq,psd)
                    psd=psd*1e18; %scale to nA for current files
                    %
                    %                 if fileflag(2) =='3'
                    %
                    %              %       fout={fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2)};
                    %
                    %                     %fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2));
                    %                 else
                    %              %       fout = {fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp)};
                    %               %      fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp));
                    %                 end %if
                    
                else
                    fprintf(1,'Error, bad fileflag %s at \n %s \n',fileflag,tabindex{an_ind(i),1});
                end %if filetype detection
                
                
                
                
                
                if ((std(ib1)>1e-12 || std(ib2)>1e-12) ||std(vp1)>1e-8 ||std(vp2)>1e-8) ...
                        ||((strcmp(fileflag(1),'V') &&  std(ib)>1e-12) ||(strcmp(fileflag(1),'I') &&  std(vp)>1e-8))
                    qfarray=[qfarray;20];
                    
                end
                if(lens < nfft)
                    qfarray=[qfarray;2]; %zeropadding QF
                    
                end %if zeropadding
                
                
                
                
                
                
                if diag
                    
                    ts = datenum(tstr(1:23),'yyyy-mm-ddTHH:MM:SS.FFF');
                    
                    plotpsd=[plotpsd,psd];
                    plotT=[plotT;ts(floor(length(ts)/2))];
                    plotSCT=[plotSCT;mean(sct)];
                    
                    plotF=freq;
                    
                end %if diag
                
                
                
                fout(end+1,1:13)={tstr{1,1},tstr{end,1},sct(1),sct(end),qfarray,mean(ib),mean(ib1),mean(ib2),mean(vp),mean(vp1),mean(vp2),psd,sind(obs(b))};
                
            end%if long enough
            
        end %for loop
        
        
        check = cell2mat(fout(:,end));
        
        
        
        indcheck = find(diff(check));
        
        avgind =[];
        for k = 1:length(check) %print checker loop & average some values
            
            %    if k~=length(check) && fout{k+1,end} ==  fout{k,end}
            if k~=length(check) && check(k+1) ==  check(k)
                fout{k+1,1} = fout{k,1};
                fout{k+1,3} = fout{k,3};
                fout{k+1,5} = [fout{k+1,5};fout{k,5}];
                avgind = [avgind;k];
                fout{k,end} = 0; %print flag
            else %print
                
                fout{k,end}=1; %print flag
                %            check(k) = 1;
                
                if ~isempty(avgind)
                    avgind=[avgind;k]; %add index
                    fout{k,6} = mean(cell2mat(fout(avgind,6)));
                    fout{k,7} = mean(cell2mat(fout(avgind,7)));
                    fout{k,8} = mean(cell2mat(fout(avgind,8)));
                    fout{k,9} = mean(cell2mat(fout(avgind,9)));
                    fout{k,10} = mean(cell2mat(fout(avgind,10)));
                    fout{k,11} = mean(cell2mat(fout(avgind,11)),1);
                end
                avgind=[];
            end
        end
        
        
        
        %--------------------- LET'S PRINT!
        
        awID= fopen(sname,'w');
        
        
        for k=1:length(fout(:,1)) % print loop
            if fout{k,end} %last index should be file checker
                if strcmp(fileflag(1),'V')
                    if  fileflag(2) =='3'
                        b1= fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,7},fout{k,8},fout{k,9});
                        b2= fprintf(awID,', %14.7e',fout{k,end-1}.');
                        b3= fprintf(awID,'\n');
                    else
                        b1=fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,9});
                        b2= fprintf(awID,', %14.7e',fout{k,end-1}.');
                        b3= fprintf(awID,'\n');
                        
                    end
                    
                elseif strcmp(fileflag(1),'I')
                    
                    if fileflag(2) =='3'
                        
                        b1=fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,10},fout{k,11});
                        b2=fprintf(awID,', %14.7e',fout{k,end-1}.');
                        b3= fprintf(awID,'\n');
                        
                        
                        %fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2));
                    else
                        b1= fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,9});
                        b2= fprintf(awID,', %14.7e',fout{k,end-1}.');
                        b3=fprintf(awID,'\n');
                        
                        
                        %dlmwrite(sname,fout{k,end-1}.','-append','precision', '%14.7e', 'delimiter', ','); %appends to end of row, column 5. pretty neat.
                        
                        %       fout = {fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp)};
                        %      fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp));
                    end %if
                    
                end
                row_byte=b1+b2+b3;
            end
        end
        
        
        fclose(awID);
        afID = fopen(fname,'w');
        
        
        f1= fprintf(afID,'%14.7e, ',freq(1:end-1));
        f2= fprintf(afID,'%14.7e',freq(end));
        
        
        %   dlmwrite(fname,freq,'precision', '%14.7e');
        fclose(afID);
        
        
        
        % fout = [fout; mean(ts),(128/lens)^2 * psd'];
        if diag
            
            %         figure(156);
            %         surf(psd_p1eh(:,1)',f1eh/1e3,10*log10(psd_p1eh(:,2:(2+nfft/2))'),'edgecolor','none');
            %         view(0,90);
            %         datetick('x','HH:MM');
            %         xlabel('HH:MM (UT)');
            %         ylabel('Frequency [kHz]');
            %         titstr = sprintf('LAP V1H spectrogram %s',datestr(psd_p1eh(1,1),29));
            %         title(titstr);
            %         drawnow;
            
            figure(2);
            imagesc( plotT,plotF/1e3,10*log10(plotpsd));
            set(gca,'YDir', 'normal'); % flip the Y Axis so lower frequencies are at the bottom
            colorbar('Location','EastOutside');
            datetick('x',13);
            xlabel('HH:MM:SS (UT)');
            ylabel('Frequency [kHz]');
            titstr = sprintf('LAP %s spectrogram %s',fileflag,datestr(ts(1),29));
            title(titstr);
            drawnow;
        end%if diag
        
        
        %dlmwrite(fname,freq,'precision', '%14.7e');
        
        global an_tabindex;
        
        an_tabindex{end+1,1} = fname;%start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(fname,ffolder,''); %shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
        %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
        an_tabindex{end,4} = 1; %number of rows
        an_tabindex{end,5} = length(freq); %number of columns
        %an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'frequency'; %type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = f1+f2;
        
        an_tabindex{end+1,1} = sname;%start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(sname,ffolder,''); %shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
        %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
        an_tabindex{end,4} = len; %number of rows
        an_tabindex{end,5} = 6+length(freq); %number of columns
        
        
        
        %an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'spectra'; %type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_byte;
        
        
        
    end
    
    
catch err
    
    fprintf(1,'Error at loop step %i and fout{}(%i), file %s, outputfile %s',i,k,tabindex{an_ind(i),1},sname);
    
    err
    err.stack.name
    err.stack.line

    
end

end

