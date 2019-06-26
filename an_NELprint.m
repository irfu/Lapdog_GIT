%Copy of an_NEDprint.m but tweaked for NEL.TAB files
%FKJN: 24 May 2019
%frejon at irfu.se
%Input: filename, filenameshort, time, data,
%index_nr_of_of_first_file,timing for NED_TABINDEX, and mode
%mode = 'vfloat' or 'ion' or 'electron'
%Outputs NED.TAB files for the RPCLAP archive
%Depending on the mode, pre-made fits will be applied to create a density
%estimate. These fits should have large impact on quality values
%
function data_arr = an_NELprint(NELfname,NELshort,data_arr,t_et,index_nr_of_firstfile,timing,mode)

global NEL_tabindex MISSING_CONSTANT
fprintf(1,'printing %s, mode: %s\n',NELfname, mode);
%'hello'
%fprintf(1,'%s',time_arr{1,1}(1,:));


%fprintf(1,'printing: %s \r\n',NEDfname)
N_rows = 0;
row_byte=0;

switch mode
                
  
    case 'vfloat'
        
        load('NED_FIT.mat', 'NED_FIT');
        [t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
        [t_et_min,NED_FIT_start]=min(NED_FIT.t_et);

    P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
    P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
    interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);

    indz_end=t_et>t_et_end;
    P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
    P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
    interp_qv(indz_end)= NED_FIT.qv(NED_FIT_end);

    indz_start=t_et<t_et_min;
    P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
    P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
    interp_qv(indz_start)= NED_FIT.qv(NED_FIT_start);


    data_arr.N_EL=data_arr.V;
    satind=data_arr.V==MISSING_CONSTANT;
    vj = -3;

    VS1 = -data_arr.V+5.5*exp(-data_arr.V/8); % correct USC to VS1 according to Anders' model. 
    VS1(-data_arr.V>0)=nan;  
    %del_ind=-data_arr.Vz>0;
    
    %I think we can safely assume that there are no Vph_knee data in Vfloat
    %mode. hopefully. Atleast it doesn't make sense to ffrom different
    %sources here

    
    data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp((VS1(~satind).').*P_interp1(~satind));

    data_arr.N_EL(isnan(VS1))=MISSING_CONSTANT;
   
    %data_arr.N_EL(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
   % data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.V(~satind).*P_interp1(~satind));

    %factor=1; 
    %data_arr.V(~satind)=data_arr.V(~satind)*factor;
    NEL_flag=data_arr.probe;%This is the probenumber/product type flag
    %take this out of the loop
    qvalue=max(1-abs(2./data_arr.V(:)),0.5);
    %qvalue(satind)=0;
    
    data_arr.qv= qvalue.*interp_qv.';
    data_arr.qv(data_arr.N_EL<0) =0; 
    %qvalue(data_arr.N_EL<0) =0; 

    NELwID= fopen(NELfname,'w');

    for j =1:length(data_arr.V)
        
        if data_arr.printboolean(j)~=1 %check if measurement data exists on row
            % Don't print zero values.
        else

            row_byte= fprintf(NELwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.t_utc{j,1},data_arr.t_obt(j), data_arr.N_EL(j),data_arr.qv(j),NEL_flag(j),data_arr.qf(j));
%            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));

            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(NELwID);
    
    
    NEL_tabindex(end+1).fname = NELfname;                   % Start new line of an_tabindex, and record file name
    NEL_tabindex(end).fnameshort = NELshort; % shortfilename
    NEL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    NEL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    NEL_tabindex(end).no_of_columns = 6;            % Number of columns
    NEL_tabindex(end).type = 'Vfloat'; % Type
    NEL_tabindex(end).timing = timing;
    NEL_tabindex(end).row_byte = row_byte;
    
    
    
    case 'vz' %will we ever create this NEL file?
        
        load('NED_FIT.mat', 'NED_FIT');
        [t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
        [t_et_min,NED_FIT_start]=min(NED_FIT.t_et);
        
        P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
        P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
        interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);
        
        indz_end=t_et>t_et_end;
        P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
        P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
        interp_qv(indz_end)= NED_FIT.qv(NED_FIT_end);
        
        indz_start=t_et<t_et_min;
        P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
        P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
        interp_qv(indz_start)= NED_FIT.qv(NED_FIT_start);
        
        data_arr.N_EL=data_arr.Vz(:,1);
        satind=data_arr.Vz(:,1)==MISSING_CONSTANT;
        
        
        % Model normalizing to Vph:
        % vs = usc_v09.usc;
        % ind_map=(usc_v09.usc<0); %problems for usc>0, which only happens for misidentified vz
        % vs(ind_map) = usc_v09.usc(ind_map) + 5.5*exp(usc_v09.usc(ind_map)/8);
        % vj = -3;
        % %vs(vz > vj) = vph(vz > vj);
        % ind_vph= usc_v09.usc>vj&~isnan(usc_v09.Vph_knee)&usc_v09.Vph_knee_qv>0.3&usc_v09.Vph_knee>vj;
        % vs(ind_vph) = usc_v09.Vph_knee(ind_vph);
        VS1qv = data_arr.Vz(:,2);
        vj = -3;
        
        %If I want to show leniency to left-wing activists, this is where I would show it with e.g. (-1)
        vj_vph= vj+5.5*exp(vj/8); %=0.7801 needed for swap to Vphknee later.

        VS1 = -data_arr.Vz(:,1)+5.5*exp(-data_arr.Vz(:,1)/8);
        VS1(-data_arr.Vz(:,1)>0)=nan; % these will be picked up soon
        
            
        %   Vz<3 ?   &~isnan(Vphknee(:,1))?     & Vph_knee(:,2)>0.3? changed to vph_knee_qv in an_outputscience.m    &data_arr.Vph_knee(:,1)>vj;
    
        ind_vph= -data_arr.Vz(:,1)>vj&~isnan(data_arr.Vph_knee(:,1))&data_arr.Vph_knee(:,2)>0.3&data_arr.Vph_knee(:,1)>vj_vph;
        VS1(ind_vph)=data_arr.Vph_knee(ind_vph,1);
        VS1qv(ind_vph) = data_arr.Vph_knee(ind_vph,2);
        
        data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp(VS1(~satind).*P_interp1(~satind));
        %data_arr.N_EL(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
        % data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.Vz(~satind).*P_interp1(~satind));
        %data_arr.N_EL(~satind)=exp(p2)*exp(-data_arr.Vz(~satind,1)*p1);
        
        data_arr.N_EL(isnan(VS1)|(isnan(data_arr.N_EL)))=MISSING_CONSTANT; %here we map them back to missing constant       
        
        
        %find all extrapolation points: I don't want to change the an_swp
        %routine, so let's do the conversion here instead
        %extrap_indz=data_arr.Vz(:,2)==0.2;
        %data_arr.Vz(extrap_indz,2)=0.7; % change 0.2 to 0.7. I mean, it's clearly not several intersections.
        %and it survived ICA validation. It's clearly not as good quality as a detected zero-crossing though
        
        %prepare NED_flag
        NEL_flag=3*ones(1,length(data_arr.qf));
        %NEL_flag(extrap_indz)=4;
        
        data_arr.qv= VS1qv.*interp_qv;
        %VS1qv(data_arr.N_EL<0) =0;
        data_arr.qv(data_arr.N_EL<0) =0;
        
        
        NELwID= fopen(NELfname,'w');
        
        for j = 1:length(data_arr.qf)
            % row_byte= sprintf('%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.N_EL(j),data_arr.Vz(j,2),NED_flag(j),data_arr.qf(j));
            
            if data_arr.lum(j) > 0.9 %shadowed probe data is not allowed
                % NOTE: data_arr.Tarr_mid{j,1}(j,1) contains UTC strings with 6 second decimals. Truncates to have the same
                % number of decimals as for case "vfloat". /Erik P G Johansson 2018-11-16
                row_byte= fprintf(NELwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.N_EL(j),data_arr.qv(j),NEL_flag(j),data_arr.qf(j));
                %row_byte= fprintf(NEDwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
                N_rows = N_rows + 1;
            end
            
            
        end
        fclose(NELwID);
        

            NEL_tabindex(end+1).fname = NELfname;                   % Start new line of an_tabindex, and record file name
            NEL_tabindex(end).fnameshort = NELshort; % shortfilename
            NEL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            NEL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
            NEL_tabindex(end).no_of_columns = 6;            % Number of columns
            NEL_tabindex(end).type = 'Vz'; % Type
            NEL_tabindex(end).timing = timing;
            NEL_tabindex(end).row_byte = row_byte;

            
    case 'Ion'
        
        
        
        load('NED_I_FIT.mat', 'NED_I_FIT');
        NED_FIT=NED_I_FIT;
        [t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
        [t_et_min,NED_FIT_start]=min(NED_FIT.t_et);
        
        data_arr.N_EL=data_arr.I;
        satind=data_arr.I==MISSING_CONSTANT;

        
        P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
        P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
        interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);

        indz_end=t_et>t_et_end;
        P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
        P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
        interp_qv(indz_end)= NED_FIT.qv(NED_FIT_end);

        indz_start=t_et<t_et_min;
        P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
        P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
        interp_qv(indz_start)= NED_FIT.qv(NED_FIT_start);
        
        data_arr.N_EL(~satind)=(data_arr.I(~satind).'-P_interp2(~satind))./P_interp1(~satind);

        data_arr.N_EL(data_arr.dark_ind)=(data_arr.I(data_arr.dark_ind).')./P_interp1(data_arr.dark_ind);

        %prepare NED_flag
        NEL_flag=5;%This is the probenumber/product type flag
        
        qvalue=(data_arr.I);
%        qvalue(:)=1;
        
        %qvalue(~satind)=max(1-2*exp(-abs((data_arr.I(~satind).'./P_interp2(~satind)))),0);
        %qv = [0-1] = 1- exp(-(I-p2)/p2);

        %qvalue(~satind)=max(1-exp(1-(data_arr.I(~satind).'./P_interp2(~satind))),0);
        width= -2e-9;%1nA?
        qvalue(~satind)=max(1-exp(-(data_arr.I(~satind).'-P_interp2(~satind))./width),0);
        
        qvalue(data_arr.N_EL<0) =0;
        qvalue(data_arr.dark_ind)=0.9;
        
        data_arr.qv= qvalue.*interp_qv.';
        NELwID= fopen(NELfname,'w');

        for j =1:length(data_arr.I)
            
            if data_arr.printboolean(j)~=1 %check if measurement data exists on row

            else

                row_byte= fprintf(NELwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.t_utc{j,1},data_arr.t_obt(j), data_arr.N_EL(j),qvalue(j),NEL_flag,data_arr.qf(j));
                %            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));
                N_rows = N_rows + 1;
            end%if
            
        end%for
        fclose(NELwID);
        
        
        NEL_tabindex(end+1).fname = NELfname;                   % Start new line of an_tabindex, and record file name
        NEL_tabindex(end).fnameshort = NELshort; % shortfilename
        NEL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
        NEL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
        NEL_tabindex(end).no_of_columns = 6;            % Number of columns
        NEL_tabindex(end).type = 'Ion'; % Type
        NEL_tabindex(end).timing = timing;
        NEL_tabindex(end).row_byte = row_byte;
        
        
    otherwise
        fprintf(1,'Unknown Method:%s',mode);
        
        
end%switch mode        

    
fileinfo = dir(NELfname);
if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
  %  if N_rows > 0 %doublecheck!
        delete(NELfname); %will this work on any OS, any user?
        NEL_tabindex(end) = []; %delete tabindex listing to prevent errors.
   % end
    
end


        
        


%elseif  strcmp(mode,'vfloat')


    %fprintf(1,'error, wrong mode: %s\r\n',mode');
end
