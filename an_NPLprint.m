
%Copy of an_USCprint.m but tweaked for NPL.TAB files
%FKJN: 14 March 2019
%frejon at irfu.se
%Input: filename, filenameshort, time, data,
%index_nr_of_of_first_file,timing for NPL_TABINDEX, and mode
%mode = 'vfloat' or 'ion' or 'electron'
%Outputs NPL.TAB files for the RPCLAP archive
%Depending on the mode, pre-made fits will be applied to create a density
%estimate. These fits should have large impact on quality values
%
function [] = an_NPLprint(NPLfname,NPLshort,data_arr,t_et,index_nr_of_firstfile,timing,mode)

global NPL_tabindex MISSING_CONSTANT
fprintf(1,'printing %s, mode: %s\n',NPLfname, mode);
%'hello'
%fprintf(1,'%s',time_arr{1,1}(1,:));


%fprintf(1,'printing: %s \r\n',NPLfname)
NPLwID= fopen(NPLfname,'w');
N_rows = 0;
row_byte=0;

load('usc_resampled_fit.mat', 'USC_FIT');
[t_et_end,USC_FIT_end]=max(USC_FIT.t_et);
[t_et_min,USC_FIT_start]=min(USC_FIT.t_et);
switch mode
        
        
    case 'vfloat'        
%if strcmp(mode,'vfloat')
   % save bullshit.mat


    
    %BASIC SOLUTION ONLY LOOKS FOR CLOSEST POINT

    P_interp1=nan(length(t_et),1);%initialise
    P_interp2=P_interp1;


    for i = 1:length(t_et) %interpolate fit coefficients between closest points
        
        if data_arr.printboolean(i)==1% These values all have t_et = 0 or nan
            if t_et(i)>t_et_end
                P_interp1(i)= USC_FIT.P(USC_FIT_end,1);
                P_interp2(i)= USC_FIT.P(USC_FIT_end,2);
            elseif t_et(i)<t_et_min
                P_interp1(i)= USC_FIT.P(USC_FIT_start,1);
                P_interp2(i)= USC_FIT.P(USC_FIT_start,2);
            else              
                P_interp1(i)= interp1(USC_FIT.t_et,USC_FIT.P(:,1),t_et(i));
                P_interp2(i)= interp1(USC_FIT.t_et,USC_FIT.P(:,2),t_et(i));
            end
            
            
        end
        
    end
    
    %[junk,ind]= min(abs(USC_FIT.t_et-t_et(1)));        
    %p1=USC_FIT.P(ind,1);
    %p2=USC_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    data_arr.NPL=data_arr.V;
    satind=data_arr.V==MISSING_CONSTANT;
    
    %data_arr.NPL(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
    data_arr.NPL(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.V(~satind).*P_interp1(~satind));

    %factor=1; 
    %data_arr.V(~satind)=data_arr.V(~satind)*factor;
    NPL_flag=data_arr.probe;%This is the probenumber/product type flag
    %take this out of the loop
    qvalue=max(1-abs(data_arr.V_sigma(:)./data_arr.V(:)),0.5);
    qvalue(satind)=0;
    
    for j =1:length(data_arr.V)
        
        if data_arr.printboolean(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            %qvalue=max(1-abs(data_arr.V_sigma(j)/data_arr.V(j)),0.5);
            %qvalue=max(1-abs((data_arr{1,6}(j)  /data_arr{1,5}(j))),0.5);

            %data_arr.V(j)=MISSING_CONSTANT;
            row_byte= fprintf(NPLwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.t_utc(j,:),data_arr.t_obt(j), data_arr.NPL(j),qvalue(j),NPL_flag(j),data_arr.qf(j));
%            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));

            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(NPLwID);
    
    
    NPL_tabindex(end+1).fname = NPLfname;                   % Start new line of an_tabindex, and record file name
    NPL_tabindex(end).fnameshort = NPLshort; % shortfilename
    NPL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    NPL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    NPL_tabindex(end).no_of_columns = 6;            % Number of columns
    NPL_tabindex(end).type = 'Vfloat'; % Type
    NPL_tabindex(end).timing = timing;
    NPL_tabindex(end).row_byte = row_byte;
    
    
    
    case 'vz'
        

    
    
        
    
    %BASIC SOLUTION ONLY LOOKS FOR CLOSEST POINT
%     [junk,ind]= min(abs(USC_FIT.t_et-data_arr.t0(1)));
%         
%     p1=USC_FIT.P(ind,1);
%     p2=USC_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    %data_arr.NPL=data_arr.Vz;
    %satind=data_arr.Vz(:,1)==MISSING_CONSTANT;


    %MORE ADVANCED LINEAR INTERPOLATION
    P_interp1=nan(length(data_arr.t0),1);%initialise
    P_interp2=P_interp1;
    for i = 1:length(data_arr.t0)
        if data_arr.t0(i)>t_et_end
            P_interp1(i)= USC_FIT.P(USC_FIT_end,1);
            P_interp2(i)= USC_FIT.P(USC_FIT_end,2);
        elseif t_et(i)<t_et_min
            P_interp1(i)= USC_FIT.P(USC_FIT_start,1);
            P_interp2(i)= USC_FIT.P(USC_FIT_start,2);
        else
            P_interp1(i)= interp1(USC_FIT.t_et,USC_FIT.P(:,1),data_arr.t0(i)) ;
            P_interp2(i)= interp1(USC_FIT.t_et,USC_FIT.P(:,2),data_arr.t0(i)) ;
        end
    end
    
    %[junk,ind]= min(abs(USC_FIT.t_et-t_et(1)));        
    %p1=USC_FIT.P(ind,1);
    %p2=USC_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    data_arr.NPL=data_arr.Vz(:,1);
    satind=data_arr.Vz(:,1)==MISSING_CONSTANT;
    
    %data_arr.NPL(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
    data_arr.NPL(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.Vz(~satind).*P_interp1(~satind));
    %data_arr.NPL(~satind)=exp(p2)*exp(-data_arr.Vz(~satind,1)*p1);

    
    
    
    
    %factor=1; 
    %data_arr.V(~satind)=data_arr.V(~satind)*factor;
   % NPL_flag=data_arr.probe;%This is the probenumber/product type flag
        
      %  factor=-1; %Vz data is being outputted by bias potential it is identified on,
        %so opposite sign applies. However, if we want to change this from 
        %a proxy to a Spacecraft potential, we could manipulate this factor.
        %possibly to something like 1/0.8, or something.
        

        %find all extrapolation points: I don't want to change the an_swp
        %routine, so let's do the conversion here instead
         extrap_indz=data_arr.Vz(:,2)==0.2;
         data_arr.Vz(extrap_indz,2)=0.7; % change 0.2 to 0.7. I mean, it's clearly not several intersections. 
        %and it survived ICA validation. It's clearly not as good quality as a detected zero-crossing though
        
        %prepare NPL_flag
        NPL_flag=3*ones(1,length(data_arr.qf));
        NPL_flag(extrap_indz)=4;
        
        for j = 1:length(data_arr.qf)
                        % row_byte= sprintf('%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.NPL(j),data_arr.Vz(j,2),NPL_flag(j),data_arr.qf(j));
   
            if data_arr.lum(j) > 0.9 %shadowed probe data is not allowed
                % NOTE: data_arr.Tarr_mid{j,1}(j,1) contains UTC strings with 6 second decimals. Truncates to have the same
                % number of decimals as for case "vfloat". /Erik P G Johansson 2018-11-16
                row_byte= fprintf(NPLwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.NPL(j),data_arr.Vz(j,2),NPL_flag(j),data_arr.qf(j));
                %row_byte= fprintf(NPLwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
                N_rows = N_rows + 1;
            end
            
            
        end
        
            NPL_tabindex(end+1).fname = NPLfname;                   % Start new line of an_tabindex, and record file name
            NPL_tabindex(end).fnameshort = NPLshort; % shortfilename
            NPL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            NPL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
            NPL_tabindex(end).no_of_columns = 6;            % Number of columns
            NPL_tabindex(end).type = 'Vz'; % Type
            NPL_tabindex(end).timing = timing;
            NPL_tabindex(end).row_byte = row_byte;
        

            
end        

    
fileinfo = dir(NPLfname);
if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
  %  if N_rows > 0 %doublecheck!
        delete(NPLfname); %will this work on any OS, any user?
        NPL_tabindex(end) = []; %delete tabindex listing to prevent errors.
   % end
    
else

end


        
        


%elseif  strcmp(mode,'vfloat')


    %fprintf(1,'error, wrong mode: %s\r\n',mode');
end
