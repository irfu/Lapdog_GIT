%hf sweep

%function [] = an_hf(derivedpath,an_ind,index,macrotime,fileflag)


function [] = an_hf(an_ind,tabindex,fileflag)

diag = 1;

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

for i=1:len
    
    fout={};  %fout is the array that will be printed.fout{:,end} will be a boolean print check, but is first saved as a
    
    %names, folders
    fname = tabindex{an_ind(i),1};
    fname(end-10:end-8)='FRQ';
    ffolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
    
    sname = strrep(fname,'FRQ','PSD');%%
    
    
    %  fprintf(1,'Calculating V1H spectrum #%.0f of %.0f\n',i,len)
    % [tstr ib vp] = textread(index(ob(p1eh(i))).tabfile,'%s%*f%f%f','delimiter',',');
    % ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
    % [psd,f1eh] = pwelch(vp,[],[],nfft,18750);
    % psd_p1eh = [psd_p1eh; mean(ts) psd'];
    
    
    %  fprintf(1,'Calculating %s spectrum #%.0f of %.0f\n',fileflag,i,len)
    trID = fopen(tabindex{an_ind(i),1},'r');
    
    %[tstr,sct,ib,vp] = textscan(trID,'%s%f%f%f','delimiter',',');
    
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
        
        
        if count==1 && reltime(n+1)-t0 >= 2e-3
            
            sind(n+1) = count;
        end
        
        
        if reltime(n+1)-t0 >8e-3 
            %%start new timer, but don't increment line counter, results
            %%will be averaged
            t0 =reltime(n+1);
            '1'
        end
        
        
        if reltime(n+1)-reltime(n)>dt*5000 %new timer
            
            t0 =reltime(n+1);
            count = count+1; %each count will generate 1 line of output in file
            
        end
        
        if reltime(n+1)-t0 >= 2e-3 && reltime(n+1)-t0 <= 8e-3
            
            sind(n+1) = count;
            %         else
            %             sind(n) = 0;
            
        end
        
        
    end
    obs = find(diff(sind)>0)+1;
    obe = find(diff(sind)<0)-1;
    if sind(end)~=0
        obe(end+1)=length(sind);
    end
    
 
    timing={scantemp{1,1}{obs(1)},scantemp{1,1}{obe(end)},scantemp{1,2}(obs(1)),scantemp{1,2}(obe(end))};
    
    
    for b=1:length(obs) %loop each 6ms spectra subsample
        
        if reltime(obe(b))-reltime(obs(b)) >3e-3%if subsample too small, disregard
            
            ob = obs(b):obe(b);
            
            
            %if reltime(ob(end))-reltime(ob(1)) >3e-3
            
            
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
            %
            %             if b==1 timing={tstr{1,1},[],sct(1)}; end
            %             if b==length(obs) timing{1,2}=tstr{end,1};timing{1,4}=sct(end);end
            %
            
            
            
            % Quality factor to a single value for entire sweep
            %            qfd= unique(qfarray);
            
            %      qfunique=unique(qfarray);
            
            %        qf= sum(unique(qfarray));
            
            
            lens = length(vp);
            %
            %             if(lens < nfft)
            %
            %                 %              ib = [ib; zeros(pad,1)];
            %                 qf=qf+2; %zeropadding QF
            %                 %        elseif(lens > 128)
            %                 %              lens = 128;
            %             end %if zeropadding
            %             %  pad = 0;
            %             %  q= 0;
            if strcmp(fileflag(1),'V')
                
                %                 if fileflag(2) =='3' && (std(ib1)>1e-12 || std(ib2)>1e-12) %
                %                     qf=qf+20; %bias change QF
                %                 elseif std(ib)>1e-12 %
                %                     qf=qf+20; %bias change QF
                %                 end %if bias change
                %
                %
                %
                %                 if(lens < nfft)
                %                     %          pad = 128-lens;
                %                     %           vp = [vp; zeros(pad,1)];
                %                     qf=qf+2; %zeropadding QF
                %                     %             elseif(lens > nfft)
                %                     %                lens = 128;
                %                 end %if zeropadding
                %                 %        [psd,freq] = pwelch(vp,[],[],nfft,18750);
                %
                
                %       nfft = 256;
                % Or whatever is the real value [Hz]
                vpred = vp - mean(vp);
                %       lens = length(vp);
                [psd,freq] = pwelch(vpred,hanning(lens),[], nfft, fsamp);
                %
                %                 if fileflag(2) =='3'
                %                     fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib1),mean(ib2),mean(vp));
                %                 else
                %                     fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp));
                %                 end %if
                
                
            elseif strcmp(fileflag(1),'I')
                
                
                %
                %                 if fileflag(2) =='3' && (std(vp1)>1e-8 || std(vp2)>1e-8) %
                %                     qf=qf+20; %bias change QF
                %                 elseif std(vp)>1e-8 %
                %                     qf=qf+20; %bias change QF
                %                 end %if bias change
                %
                
                %
                %                 if(lens < nfft)
                %                     %              pad = 128-lens;
                %                     %              ib = [ib; zeros(pad,1)];
                %                     qf=qf+2; %zeropadding QF
                %                     %        elseif(lens > 128)
                %                     %              lens = 128;
                %                 end %if zeropadding
                %
                
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
            
            
            
            
            %             psdtemp=[psdtemp;psd.'];
            %
            %
            %
            %             print = 1;
            %             %print line?
            %             if b~=length(obs) %need seperate ifs because next operation generates errors otherwise
            %                 if sind(obs(b))==sind(obs(b+1)) && reltime(obe(b+1))-reltime(obs(b+1)) >3e-3%if subsample too small, disregard
            %                     print = 0;
            %
            %
            %
            %                 end
            %             end %print?
            %
            %
            %             if print
            %                 psdout = mean(psdtemp,1);
            %                 qfout= sum(unique([qfunique;qf]));
            %                 qf=0;
            %                 psdtemp=[];
            %
            %             end
            %
            
            
            
                        if diag
            
                            ts = datenum(tstr(1:23),'yyyy-mm-ddTHH:MM:SS.FFF');
            
                            plotpsd=[plotpsd,psd];
                            plotT=[plotT;ts(floor(length(ts)/2))];
                            plotSCT=[plotSCT;mean(sct)];
            
                            plotF=freq;
            
                        end %if diag
            
            
            
            fout(end+1,1:13)={tstr{1,1},tstr{end,1},sct(1),sct(end),qfarray,mean(ib),mean(ib1),mean(ib2),mean(vp),mean(vp1),mean(vp2),psd,sind(obs(b))};
            
            %    dlmwrite(sname,psdout.','-append','precision', '%14.7e', 'delimiter', ','); %appends to end of row, column 5. pretty neat.
            
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
      %      fout{k+1,4} = [fout{k+1,4};fout{k,4}];
            fout{k+1,5} = [fout{k+1,5};fout{k,5}];
            avgind = [avgind;k];
            fout{k,end} = 0; %print flag
        else %print
            
            fout{k,end}=1; %print flag
            %            check(k) = 1;
            
            if ~isempty(avgind)
                avgind=[avgind;k]; %add index
                %fout{k,5} = mean(cell2mat(fout(avgind,5)));
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
    
    
    
    % LET'S PRINT!
    
 %   tmpf = fopen(sname,'w');
%    fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
    awID= fopen(sname,'w');
    
    
    for k=1:length(fout(:,1)) % print loop
        if fout{k,end} %last index should be file checker
            if strcmp(fileflag(1),'V')
                if  fileflag(2) =='3'
                    fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,7},fout{k,8},fout{k,9});
                    fprintf(awID,', %14.7e',fout{k,end-1}.');
                    fprintf(awID,'\n');                    
                else
                    fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,9});
                    fprintf(awID,', %14.7e',fout{k,end-1}.');
                    fprintf(awID,'\n');                    
                    
                end
                
            elseif strcmp(fileflag(1),'I')
                
                if fileflag(2) =='3'
                    
                    fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,10},fout{k,11});
                    fprintf(awID,', %14.7e',fout{k,end-1}.');
                    fprintf(awID,'\n');                    
                    
                    
                    %fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2));
                else
                    fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,9});
                    fprintf(awID,', %14.7e',fout{k,end-1}.');
                    fprintf(awID,'\n');
                    
                    
                    %dlmwrite(sname,fout{k,end-1}.','-append','precision', '%14.7e', 'delimiter', ','); %appends to end of row, column 5. pretty neat.
                    
                    %       fout = {fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp)};
                    %      fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp));
                end %if
            end
        end
    end
    
    
    fclose(awID);
    afID = fopen(fname,'w');
    
    
    fprintf(afID,'%14.7e',freq);
    dlmwrite(fname,freq,'precision', '%14.7e');
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
    an_tabindex{end,4} = length(freq); %number of rows
    an_tabindex{end,5} = 1; %number of columns
    %an_tabindex{end,6} = an_ind(i);
    an_tabindex{end,7} = 'frequency'; %type
    an_tabindex{end,8} = timing;
    
    
    an_tabindex{end+1,1} = sname;%start new line of an_tabindex, and record file name
    an_tabindex{end,2} = strrep(sname,ffolder,''); %shortfilename
    an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
    %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
    an_tabindex{end,4} = len; %number of rows
    an_tabindex{end,5} = 6+length(freq); %number of columns
    
    
    
    %an_tabindex{end,6} = an_ind(i);
    an_tabindex{end,7} = 'spectra'; %type
    an_tabindex{end,8} = timing;
    
    
    
    % figure(86);
    % %  surf(plotT,plotF/1e3,10*log10(plotpsd(:,1:(2+nfft/2))).','edgecolor','none');
    % surf(plotT,plotF/1e3,10*log10(plotpsd),'edgecolor','none');
    %
    % view(0,90);
    % %datetick(
    %
    % datetick('x',13);
    % xlabel('HH:MM:SS (UT)');
    % ylabel('Frequency [kHz]');
    % titstr = sprintf('LAP %s spectrogram %s',fileflag,datestr(ts(1),29));
    % title(titstr);
    % drawnow;
    
    
end
end

