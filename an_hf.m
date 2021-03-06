%hf sweep

%function [] = an_hf(derivedpath,an_ind,index,macrotime,fileflag)


function [] = an_hf(an_ind,tabindex,fileflag)

global an_tabindex;
%global MISSING_CONSTANT  %found a way to get around using this global
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

%qf=0;
nfft=128;
%fsamp = 18750;

%fname = sprintf('%sRPCLAP_%s_%s_FRQ_%s.TAB',ffolder,datestr(macrotime,'yyyymmdd'),datestr(macrotime,'HHMMSS'),fileflag); %%
%fpath = strrep(filename,ffolder,'');


len = length(an_ind);

k=0;
b=0;
try    
    for i=1:len
        
        fout=cell(0,13);  %fout is the array that will be printed.fout{:,end} will be a boolean print check, but is first saved as a
        
        %names, folders
        fname = tabindex{an_ind(i),1};
        fname(end-10:end-8)='FRQ';
        ffolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        
        sname = strrep(fname,'FRQ','PSD');
        
        
        
        trID = fopen(tabindex{an_ind(i),1},'r');
        
        if trID < 0
            fprintf(1,'Error, cannot open file %s\n', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        if fileflag(2) == '3'    % One additional column for probe 3 files.
            scantemp = textscan(trID,'%s%f%f%f%f%d','delimiter',','); %ts,sct,ib1,ib2,vp1-vp2
            ib1=scantemp{1,3};
            ib2=scantemp{1,4};
            N_PSD_nonspectrum_cols = 8;
        else
            scantemp = textscan(trID,'%s%f%f%f%d','delimiter',',');
            N_PSD_nonspectrum_cols = 7;
        end
        
        fclose(trID);
        
        
        
        
        % Need to split **H.TAB file into separate high frequency snap shots
        % and remove times when MIP is operating.
        
        reltime= scantemp{1,2} - scantemp{1,2}(1);
        dt = reltime(2);
        count = 1;
        t0=reltime(1);
        sind = zeros(length(reltime),1);
        
        %-----%edit FKJN 18/7 2016 wait up, are we doing a new macro with a lower(1/8th)freq HF spectra?
        %%% Also, remove the MIP filter.
        if 1/dt < 3e+03 %some margins around expected 2.4khz 
            ffactor=8; %low frequency HF, so we need more points subsampling turn off MIPfilter.
        %   fsamp =  18750/8;
            MIPfilter =0; % off
           
            
        else
            ffactor =1; % unit
            MIPfilter = 1;% on
            
        end
        fsamp = 18750/ffactor;
        %if you want to test without MIPfilter on other macros just add MIPfilter =0;
        %-----%edit  carry on.
        

        
        
        % Loop from n =1 to end-1, checking n+1. (no need to check first entry)
        % made such that we avoid 'Index exceeds matrix dimensions' errors.
        for n=1:length(reltime)-1

            if reltime(n+1)-t0 >(8e-3*ffactor)
                % Start new timer, but don't increment line counter, results
                % will be averaged
                t0 =reltime(n+1);
            end
            
            
            if reltime(n+1)-reltime(n)>dt*5000 %large jump, new timer
                
                t0 =reltime(n+1);
                count = count+1; %each count will generate 1 line of output in file
                
            end
            
             %Here's the actual filtering. Ignore the first 2ms every 8ms.
             %EDIT FKJN: unless MIPfilter is off, and we have to increase
             %range
             
             
            if reltime(n+1)-t0 >= (2e-3*MIPfilter) && reltime(n+1)-t0 <= (8e-3*ffactor)
                sind(n+1) = count;
                %         else
                %             sind(n) = 0;
                
            end
            
            

        end
        obs = find(diff(sind)>0)+1;
        obe = find(diff(sind)<0);
        if sind(end)~=0 %%last obe value needs some extra care
            obe(end+1)=length(sind);
        end
       
        %%EDIT FKJN 18/7 2016 
        if ~MIPfilter           
           obe = obs(2:end) - 1;% no filter, so no need to be fancy. 
           obe(end+1)=length(sind);
        end
        %%
        if isempty(obs)
            fprintf(1, 'Macro with 0 valid points for PSD, skipping file %s\n', tabindex{an_ind(i),1});
        else
        
        
        timing={scantemp{1,1}{obs(1)},scantemp{1,1}{obe(end)},scantemp{1,2}(obs(1)),scantemp{1,2}(obe(end))};
        
        a=[];
        for b=1:length(obs) %loop each 6ms spectra subsample. For it to be printed it has to be long enough and not contain any saturated values)
            a= [a;reltime(obe(b))-reltime(obs(b))];
            if reltime(obe(b))-reltime(obs(b)) >3e-3*ffactor   %edit FKJN 18July2016
                %If subsample too small, disregard.
                % if reltime(obe(b))-reltime(obs(b)) >(3e-3-0.1304)  %old line,
                % what is the significance of -0.1304?  it seems completely out
                % of place.
                
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
                vp=scantemp{1,end-1}(ob(1):ob(end));       % For probe 3, vp is scantemp{1,5}, otherwise {1,4}.
                qfarray = scantemp{1,end}(ob(1):ob(end));  % Quality factor, always at the end.

                %-----------------Saturation Handling 8/3 FKJN-------------------------------------%
                if isempty(qfarray(qfarray > 399.9)) %400 is the saturation constant. if this value is below it, no measurement  is saturated. This way I don't have to remember the global paramter MISSING_CONSTANT
                 % i.e. if no value is saturated then continue, else ignore(won't be printed)  
                
               %  if isempty(ib(ib==MISSING_CONSTANT)) && isempty(vp(vp==MISSING_CONSTANT)) % if no value is saturated then continue, else ignore(won't be printed)  
               %  if ~(any(isnan(ib)) || any(isnan(vp))) % if any is saturated then ignore, else continue
                %----------------------------------------------------------------------------------%

                    
                    lens = length(vp);
                    
                    if strcmp(fileflag(1),'V')
                        
                        
                        %vpred = vp - mean(vp);
                        
                        P= polyfit(1:lens,vp.',1);
                        vpred = vp - polyval(P,1:lens).';
                        
                        %       lens = length(vp);
                        [psd,freq] = pwelch(vpred,hanning(lens),[], nfft, fsamp);
                        
                        
                        
                    elseif strcmp(fileflag(1),'I')
                        
                        
                        
                        %ibred = ib - mean(ib);
                        P= polyfit(1:lens,ib.',1);
                        ibred = ib - polyval(P,1:lens).';
                        
                        
                        [psd,freq] = pwelch(ibred,hanning(lens),[], nfft, fsamp);
                        
                        %[psd,freq] = pwelch(ib,[],[],nfft,18750);
                        %    plot(freq,psd)
                        psd=psd*1e18;    % Scale to nA for current files
                        %
                        %
                        %                 if fileflag(2) =='3'
                        %
                        %              %       fout={fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2)};
                        %
                        %                     %fprintf(awID,'%s, %s, %16.6f, %16.6f, %05i, %14.7e, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2));
                        %                 else
                        %              %       fout = {fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp)};
                        %               %      fprintf(awID,'%s, %s, %16.6f, %16.6f, %05i, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp));
                        %                 end %if
                        
                    else
                        fprintf(1,'Error, bad fileflag %s at \n %s \n',fileflag,tabindex{an_ind(i),1});
                    end %if filetype detection
                    
                    
                    
                    
                    
                    if ((std(ib1)>1e-12 || std(ib2)>1e-12) ||std(vp1)>1e-8 ||std(vp2)>1e-8) ...
                            ||((strcmp(fileflag(1),'V') &&  std(ib)>1e-12) ||(strcmp(fileflag(1),'I') &&  std(vp)>1e-8))
                        qfarray=[qfarray;10]; %bias change
                        
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
                    
                end%if non-saturated / NAN
            end%if long enough
            
        end %for loop
            

            check = cell2mat(fout(:,end));
            
            
            
           % indcheck = find(diff(check));
            
            avgind =[];
            for k = 1:length(check) %print checker loop & average some values if we're doing burst mode
                
                %    if k~=length(check) && fout{k+1,end} ==  fout{k,end}
                if k~=length(check) && check(k+1) ==  check(k)
                    fout{k+1,1} = fout{k,1};
                    fout{k+1,3} = fout{k,3};
                    fout{k+1,5} = [fout{k+1,5};fout{k,5}];
                    avgind = [avgind;k]; %these indices will be averaged
                    fout{k,end} = 0; %print flag, i.e. don' print
                else %print
                    
                    fout{k,end}=1; %print flag  %i.e. print
                    
                    if ~isempty(avgind)
                        avgind=[avgind;k]; %add index
                        fout{k,6} = mean(cell2mat(fout(avgind,6)));
                        fout{k,7} = mean(cell2mat(fout(avgind,7)));
                        fout{k,8} = mean(cell2mat(fout(avgind,8)));
                        fout{k,9} = mean(cell2mat(fout(avgind,9)));
                        fout{k,10} = mean(cell2mat(fout(avgind,10)));
                        fout{k,11} = mean(cell2mat(fout(avgind,11)),1); %
                        %first convert fout(avgind,end-1)) to matlab array, reshape to
                        %65xavgind size, and average it to a an array.
                        %also transpose it, so it matches old shape.
                        %fout{k,end-1}= mean(reshape(cell2mat(fout(avgind,end-1)),length(avgind),length(freq)),1).'; %avg psd values over wavesnapshot block
                        fout{k,end-1}= mean(reshape(cell2mat(fout(avgind,end-1)),length(freq),length(avgind)),2).'; %avg psd values over wavesnapshot block
                        
                        %fout{k,end-1}= mean(cell2mat(fout(avgind,end-1)),2); %avg psd values over wavesnapshot block
                    end
                    avgind=[];
                end
            end%main loop
            
            
            
            %--------------------- LET'S PRINT!
            if(sum(cell2mat(fout(:,end)))>0)% is there a non-empty file to print?

            awID = fopen(sname,'w');
            
            lbl_rows = 0;
            for k=1:length(fout(:,1)) % print loop
                if fout{k,end} %last index should be file checker
                    if strcmp(fileflag(1),'V')
                        if  fileflag(2) =='3'
                            b1= fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,7},fout{k,8},fout{k,9});
                            b2= fprintf(awID,', %14.7e',fout{k,end-1}.');
                            b3= fprintf(awID,'\r\n');
                        else
                            b1= fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,9});
                            b2= fprintf(awID,', %14.7e',fout{k,end-1}.');
                            b3= fprintf(awID,'\r\n');
                            
                        end
                        
                    elseif strcmp(fileflag(1),'I')
                        
                        if fileflag(2) =='3'
                            
                            b1= fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,10},fout{k,11});
                            b2= fprintf(awID,', %14.7e',fout{k,end-1}');
                            b3= fprintf(awID,'\r\n');
                            
                            %   fprintf(awID,'%s, %s, %16.6f, %16.6f, %05i, %14.7e, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp1),mean(vp2));
                        else
                            b1= fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %14.7e, %14.7e',fout{k,1},fout{k,2},fout{k,3},fout{k,4},sum(unique(fout{k,5})),fout{k,6},fout{k,9});
                            b2= fprintf(awID,', %14.7e',fout{k,end-1}');
                            b3= fprintf(awID,'\r\n');
                            
                            %dlmwrite(sname,fout{k,end-1}.','-append','precision', '%14.7e', 'delimiter', ','); %appends to end of row, column 5. pretty neat.
                            
                            %       fout = {fout;tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp)};
                            %      fprintf(awID,'%s, %s, %16.6f, %16.6f, %05i, %14.7e, %14.7e,',tstr{1,1},tstr{end,1},sct(1),sct(end),qf,mean(ib),mean(vp));
                        end %if fileflag
                        
                    end
                    row_byte = b1+b2+b3;
                    lbl_rows = lbl_rows+1;
                end
            end%print loop
            
            
            fclose(awID);
            
                afID = fopen(fname,'w');
    
                f1 = fprintf(afID,'%14.7e, ',   freq(1:end-1));
                f2 = fprintf(afID,'%14.7e\r\n', freq(end));
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
            
            an_tabindex{end+1,1} = fname;    % Start new line of an_tabindex, and record file name
            an_tabindex{end,2} = strrep(fname,ffolder,''); % shortfilename
            an_tabindex{end,3} = tabindex{an_ind(i),3};    % First calib data file index
            %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
            an_tabindex{end,4} = 1;                        % Number of rows
            an_tabindex{end,5} = length(freq);             % Number of columns
            an_tabindex{end,6} = an_ind(i);                % Indices into "index" data structure. Needed for LBL files.
            an_tabindex{end,7} = 'frequency';              % Type
            an_tabindex{end,8} = timing;
            an_tabindex{end,9} = f1+f2;
            
            an_tabindex{end+1,1} = sname;   % Start new line of an_tabindex, and record file name
            an_tabindex{end,2} = strrep(sname,ffolder,'');              % shortfilename
            an_tabindex{end,3} = tabindex{an_ind(i),3};                 % First calib data file index
            %an_tabindex{end,3} = an_ind(1); % first calib data file index of first derived file in this set
            an_tabindex{end,4} = lbl_rows;                              % Number of rows
            an_tabindex{end,5} = N_PSD_nonspectrum_cols + length(freq); % Number of columns
            
            
            
            an_tabindex{end,6} = an_ind(i);                % Indices into "index" data structure. Needed for LBL files.
            an_tabindex{end,7} = 'spectra'; %type
            an_tabindex{end,8} = timing;
            an_tabindex{end,9} = row_byte;
            end%file empty?

        end %Invalid Macro
        
    end    
    
catch err
    
    fprintf(1,'Error at loop step %i and fout{}(%i),obs %i, file %s, outputfile %s',i,k,b,tabindex{an_ind(i),1},sname);
    
    disp(err.identifier)
    disp(err.message)
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,\n',err.stack(i).name,err.stack(i).line);
        end
    end
    
end

end

