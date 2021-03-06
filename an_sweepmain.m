% Analyses sweeps, utilising modded version of Anders an_swp code, and other
% methods.
function [] = an_sweepmain(an_ind,tabindex,targetfullname)

global an_tabindex der_struct;
global target;
global diag_info
global CO IN     % Physical & instrumental constants
global MISSING_CONSTANT;


global assmpt;

        assmpt =[];
        assmpt.Vknee = 0; %dummy
        assmpt.Tph = 2; %eV
        assmpt.Iph0 = -6.6473e-09;   % from median of M06 & SPIS simulation
        %    assmpt.Iph0 = -8.55e-09; % from mean of M08, probably too high.
        assmpt.vram = 4E5; % Solar wind assumption
        assmpt.ionZ = 1;   % SW assumption
        assmpt.ionM = 1;   % SW assumption



dynampath = strrep(mfilename('fullpath'),'/an_sweepmain','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths(); 

cspice_furnsh(kernelFile);


k=0; %needed for error output

try

    for i=1:length(an_ind)     % iterate over sweep files...

        % get file, read variables etc
        rfile =tabindex{an_ind(i),1};                  % Sweep file
        rfolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        %tabindex{an_ind(i),1}(end-10:end-8)
        mode      = rfile(end- 6:end-4);
        diagmacro = rfile(end-10:end-8);
        probe     = rfile(end-5);

        diag_info{1} = strcat(diagmacro,'P',probe); %remember probe and macro everywhere for debugging
        diag_info{2} = rfile; %let's also remember the full name

        arID = fopen(tabindex{an_ind(i),1},'r');                   % Open sweep file.

        if arID < 0
            fprintf(1,'Error, cannot open file %s\n', tabindex{an_ind(i),1});
            break
        end % if I/O error

        scantemp = textscan(arID,'%s','delimiter',',','CollectOutput', true);   % Reads all values into one long 1D vector of strings.

        fclose(arID);

        rfile(end-6)='B';
        arID = fopen(rfile,'r');                                 % Open sweep potentials/times file.
        scantemp2 = textscan(arID,'%f%f','delimiter',',');


        % scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
        fclose(arID);

        steps = length(scantemp2{1,2})+5;       % Nbr of values per sweep: currents/voltages + 4 timestamps + 1 QF
        N_file_values = numel(scantemp{1,1});   % Nbr of values in sweep data file (all sweeps & columns).
        N_sp = N_file_values/steps;             % Nbr of sweep/pairs. sp = sweep/pair

        if mod(N_file_values,steps) ~=0
            fprintf(1,'error, bad sweepfile at \n %s \n, aborting %s mode analysis\n',rfile,mode);
            return
        end


        A = reshape(scantemp{1,1},steps,N_file_values/steps);        % Matrix of STRINGS (<column nbr>, <sweep/pair index>)
        Iarr= str2double(A(6:end,1:end));                  % Matrix of doubles (<sweep voltage nbr>, <sweep/pair index>)
        timing = {A{1,1},A{2,end},A{3,1},A{4,end}};        % Timing for entire analysis file.
        Qfarr =str2double(A(5,:));

        Vb = scantemp2{1,2};              % Voltage, for each sweep/pair.

        Tarr = A(1:4,1:end);              % Matrix for individual sweep times: (<column nbr>, <sweep/pair index>)

        
        
        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        satur_ind = Iarr==MISSING_CONSTANT; % logical matrix which is true if any current is saturated (pds outputs -1000 as of 6/3 2018)
        %Iarr(Iarr==MISSING_CONSTANT)    = NaN;
        Iarr(satur_ind) = NaN;% This should also work, so we don't have to
        %do this twice
        %
        %note that this index needs special handling for V or /\ sweeps
        %(see :if split), etc
        %-------------------------------------------------------------%
        
        % Classify "sweep" depending on voltage curve: one/two sweeps, up/down, where split.
        potdiff = diff(Vb);
        upd = max(0,sign(potdiff));    % is an int either 0 or 1...
        if potdiff(1) > 0 && Vb(end)~=max(Vb)
            % potbias looks like V.

            mind=find(Vb==max(Vb));
            split = 1;
            upd = [ 0 1];

        elseif potdiff(1) <0 && Vb(end)~=min(Vb)
            % potbias looks like upside-down V.

            mind=find(Vb==min(Vb));
            split = -1;
            upd = [ 1 0];
        else
            split = 0;
        end



        if split

            % Split data for first and second sweep in sweep pair.
            Vb2   = Vb(mind:end);
            Iarr2 = Iarr(mind:end,:);
           % satur_ind2 = satur_ind(mind:end,:);%mirror Iarr treatment everywhere.
            

            Vb   = Vb(1:mind);
            Iarr = Iarr(1:mind,:);
           % satur_ind = satur_ind(1:mind,:); %mirror Iarr treatment everywhere.

            Tarr2 = Tarr;
            t_sweep_rel = scantemp2{1,1};     % Time, relative to beginning of sweep/pair sequence (one/two sweeps).
            t_diff = t_sweep_rel(mind);

            for i_sp = 1:N_sp         % sp = sweep pair

                % Take start time and add time interval.
                % NOTE: Not important which time system is used for converting UTC string, since converts back to UTC string anyway.
                t_spm_utc_str = cspice_et2utc(   cspice_str2et(Tarr{ 1, i_sp}) + t_diff, 'ISOC', 6);    % spm = sweep pair middle
                t_spm_nbr_str = num2str( str2double(Tarr{ 4, i_sp}) + t_diff,   '%f' );

                Tarr{  2, i_sp} = t_spm_utc_str;
                Tarr{  4, i_sp} = t_spm_nbr_str;
                Tarr2{ 1, i_sp} = t_spm_utc_str;
                Tarr2{ 3, i_sp} = t_spm_nbr_str;
            end
        end



        % 'preloaded' is a dummy entry, just so orbit realises spice kernels
        % are already loaded.
        [altitude,junk,SAA]=orbit('Rosetta',Tarr(1:2,:),target,'ECLIPJ2000','preloaded');
        clear junk

        if strcmp(mode(2),'1') %probe 1
            %current (Elias) SAA = z axis, Anders = x axis.
            % *Anders values* (converted to the present solar aspect angle definition
            % by ADDING 90 degrees) :
            Phi11 = 131;
            Phi12 = 181;

            illuminati = ((SAA < Phi11) | (SAA > Phi12));

        else %we will hopefully never have sweeps with probe number "3"

            %%%
            % *Anders values* (+90 degrees)
            Phi21 = 18;
            Phi22 = 82;
            Phi23 = 107;
            %illuminati = ((SAA < Phi21) | (SAA > Phi22));

            illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            % illuminati = illuminati - 0.6*((SAA > Phi22) & (SAA < Phi23));
        end



        len = length(Iarr(1,:));     % Number of sweeps/pairs. Should be identical to N_sp. Kept for now.
        %  cspice_str2et(



        %% initialise output struct


        %tscsweep = str2double(Tarr{3,1});

        %check if we are close to comet
        %(3000 km ? 1000*radius of comet)


    %    if (le(altitude(end),3000) && strcmp(target,'CHURYUMOV-GERASIMENKO'))
        if strcmp(target,'CHURYUMOV-GERASIMENKO')

            %date = cspice_et2utc(cspice_str2et(Tarr{ 1,1}), 'ISOC', 0);
            %formatin = 'YYYY-mm-ddTHH:MM:SS';
            %this if should have worked, but MatLab sucks between versions and
            %linux/mac differences.
            %            if datenum(Tarr{1,1}(1:19),formatin) < datenum('2015-01-01T00:00:00',formatin)378691143.436616

            if (str2double(Tarr{3,1}) > 365904090.294412)%if past 6 aug 2014 (ESA blog post "arrival at comet")

                assmpt.vram = 550; %m/s
                assmpt.ionZ = +1; % ion charge
                assmpt.ionM = 19; % atomic mass units
                %assmpt.v_SW = 5E5; %500 km/s
            end
        end



        %Edit 31 Aug 2015 added new Iph0 selector, to be used with Norwegian Iph0
        %results.
        %EDIT 6 April 2016, FKJN modified Iph0 selector, to be used with Niklas results

        
        switch str2double(probe)           

            case 1
                iph0file = 'iph0_probe1.txt';                                
            case 2
                iph0file = 'iph0_probe2.txt';                
        end    
        
        assmpt.Iph0 = Iph0selector(iph0file,str2double(Tarr{3,1}));
        
        
        %Anders analysed parameters
        AP(len).ts       = [];
        AP(len).vx       = [];
        AP(len).Tph      = [];
        AP(len).Iph0     = [];
        AP(len).vs       = [];
        AP(len).lastneg  = [];
        AP(len).firstpos = [];
        AP(len).poli1    = [];
        AP(len).poli2    = [];
        AP(len).pole1    = [];
        AP(len).pole2    = [];
        AP(len).probe    = [];
        AP(len).vbinf    = [];
        AP(len).diinf    = [];
        AP(len).d2iinf   = [];
        AP(len).Vz       = [];


        %EP = extra parameters, not from functions

        EP(len).tstamp   = [];
        EP(len).SAA      = [];
        EP(len).qf       = [];
        EP(len).Tarr     = {};
        EP(len).lum      = [];
        EP(len).split    = [];
        EP(len).dir      = [];
%
%         EP(len).ni_1comp = [];
%         EP(len).ni_2comp = [];
%         EP(len).v_ion    = [];
        EP(len).ne_5eV   = [];
        EP(len).Vsc_ni_ne= [];

%         EP(len).ni_aion    = [];
%         EP(len).Vsc_aion   = [];
%         EP(len).v_aion = [];
%         EP(len).asm_ni_aion    = [];
%         EP(len).asm_Vsc_aion   = [];
%         EP(len).asm_v_aion = [];
%
%         EP(len).asm_ni_1comp = [];
%         EP(len).asm_ni_2comp = [];
%         EP(len).asm_v_ion    = [];
        EP(len).asm_ne_5eV   = [];
        EP(len).asm_Vsc_ni_ne= [];


        % Derived parameters from sweep
        DP(len).Iph0                = [];
        DP(len).Tph                 = [];
        DP(len).Vsi                 = [];
        DP(len).Te                  = [];
        DP(len).ne                  = [];

        DP(len).Vsg                 = [];
        DP(len).Vph_knee            = [];
        DP(len).Vbar                = [];

        DP(len).Vsg_lowAc           = [];
        DP(len).Vph_knee_lowAc      = [];
        DP(len).Vbar_lowAc          = [];


        DP(len).ion_Vb_slope        = [];
        DP(len).ion_Vb_intersect    = [];
        DP(len).ion_slope           = [];
        DP(len).ion_intersect       = [];
        DP(len).ion_Up_slope        = [];
        DP(len).ion_Up_intersect    = [];


        DP(len).ni_1comp            = [];
        DP(len).ni_2comp            = [];
        DP(len).v_ion               = [];

        DP(len).ni_aion             = [];
        DP(len).Vsc_aion            = [];
        DP(len).v_aion              = [];


        DP(len).e_Vb_slope          = [];
        DP(len).e_Vb_intersect      = [];
        DP(len).e_slope             = [];
        DP(len).e_intersect         = [];

        DP(len).Tphc                = [];
        DP(len).nphc                = [];
        DP(len).phc_slope           = [];
        DP(len).phc_intersect       = [];

        DP(len).Te_exp              = [];
        DP(len).Ie0_exp             = [];
        DP(len).ne_exp              = [];

        DP(len).Te_exp_belowVknee   = [];
        DP(len).Ie0_exp_belowVknee  = [];
        DP(len).ne_exp_belowVknee   = [];


        DP(len).Quality             = [];
        DP(len).Rsq                 = [];


        DP_asm= DP;

        % initial estimate

        %these asumptions should be printed somewhere. Maybe in the LBL file?
        %print in description of LBL file?


        % try whole batch of sweep analysis at once, why not?
        % 50 sweeps would correspond to ~ 30 minutes of sweeps

        % if len > 1
        if 0 == 1

            lmax=min(len,50); %lmax is whichever is smallest, len or 50.

            lind=logical(floor(mean(reshape(illuminati,2,len),1)));% logical index of all sunlit sweeps
            dind=~logical((mean(reshape(illuminati,2,len),1))); %logical index of all fully shadowed sweeps


            if sum(unique(lind(1:lmax))) % if we have sunlit sweeps, do this
                I_50 = mean(Iarr(:,lind),2);   %average each potential step current
                [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vph_knee estimate from that.

                assmpt.Vknee =Vknee;

                % init_1 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,1);  %get initial estimate of all variables in that sweep.
            end

            if sum(unique(~(lind(1:lmax)))) % if we also) have non-sunlit sweeps?

                I_50 = mean(Iarr(:,~lind),2);
                [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vsg estimate from that.
                assmpt.Vknee = Vknee;
                % init_2 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,0);  %get initial estimate of all variables in that sweep.
            end
            % non-sunlit sweep V_SC should have priority!!



            if unique(lind+dind)==0 %if everything is in partial shade

                I_50 = mean(Iarr(:,1:lmax),2); %all
                [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vph_knee estimate from that.

                assmpt.Vknee =Vknee;

                % init_1 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,0.4);  %get initial estimate of all variables in that sweep.
            end

        end


        % analyse!


%         parfor k=1:len    % Iterate over first sweep in every potential sweep pair (one/two sweeps)
        for k=1:len    % Iterate over first sweep in every potential sweep pair (one/two sweeps)

            %  a= cspice_str2et(timing{1,k});

            % quality factor check
            qf = Qfarr(k);

            if (abs(SAA(1, 2*k-1)-SAA(1, 2*k)) >0.05) %rotation of more than 0.05 degrees  %arbitrary chosen value... seems decent
                qf = qf+10; %rotation
            end
            
%             if (any(satur_ind(:,k))) 
%                 qf = qf+400; % saturation flagging
%             end
            

            EP(k).split = 0;
            EP(k).SAA = mean(SAA(1,2*k-1:2*k));
            EP(k).lum = mean(illuminati(1,2*k-1:2*k));
            EP(k).Tarr = {Tarr{:,k}};
            EP(k).tstamp = Tarr{3,k};
            EP(k).qf = qf;
            EP(k).dir = upd(1);

            % Anders LP sweep analysis
            AP(k) = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(k).lum);

            if k>1
                Vguess = DP(k-1).Vph_knee(1);
            else
                Vguess = -AP(k).vs;
            end

            [DP(k),DP_asm(k)] = an_LP_Sweep_v2(Vb, Iarr(:,k),Vguess,EP(k).lum);

            %DP(k) = an_LP_Sweep(Vb, Iarr(:,k),Vguess,EP(k).lum);
            %DP_asm(k) = an_LP_Sweep_with_assmpt(Vb),Iarr(:,k),assmpt,EP(k).lum);

            Te_guess = 5;%eV
            %EP(k).ne_5eV = abs(1e-6*DP(k).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
            %EP(k).asm_ne_5eV = abs(1e-6*DP_asm(k).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
            EP(k).ne_5eV        = max(1e-6*sqrt(2*pi*CO.me*Te_guess) * DP(k).e_slope(1) / (IN.probe_A*CO.e.^1.5),0); %max out of expression and 0 -> if >0, ne=0;
            EP(k).asm_ne_5eV    = max(1e-6*sqrt(2*pi*CO.me*Te_guess) * DP_asm(k).e_slope(1) / (IN.probe_A*CO.e.^1.5),0);%max out of expression and 0 -> if >0, ne=0;
            EP(k).asm_Vsc_ni_ne = nansum((DP_asm(k).ion_Vb_intersect(1)-(sqrt(DP_asm(k).ion_intersect(1))*DP_asm(k).ne(1)/DP_asm(k).ni_2comp(1)).^2)/DP_asm(k).ion_slope(1));
            EP(k).Vsc_ni_ne     = nansum((DP(k).ion_Vb_intersect(1)    -(sqrt(DP(k).ion_intersect(1))    *DP(k).ne(1)    /DP(k).ni_2comp(1)).^2)    /DP(k).ion_slope(1));

        end % parfor

        if (split~=0)    % If every sweep/pair is really two sweeps...

            %parfor k=1:length(Iarr2(1,:))     % Iterate over second sweep in every sweep pair (two sweeps together)
            for k=1:length(Iarr2(1,:))     % Iterate over second sweep in every sweep pair (two sweeps together)
                m=k+len;
                %note Vb =! Vb2, Iarr =! Iarr2, etc.
                % quality factor check
                qf = Qfarr(k);

                if (abs(SAA(1, 2*k-1)-SAA(1, 2*k)) >0.05) %rotation of more than 0.01 degrees
                    qf = qf+10; %rotation
                end
                
%                 
%                 if (any(satur_ind2(:,k)))
%                     qf = qf+400; % saturation flagging not necessary.
%                     Done in createTAB and already in QF array
%                 end
                
                

                EP(m).split = split;  % 1 for V form, -1 for upside-down V
                EP(m).SAA = mean(SAA(1,2*k-1:2*k));
                EP(m).lum = mean(illuminati(1,2*k-1:2*k));
                EP(m).Tarr = {Tarr2{:,k}};
                EP(m).tstamp = Tarr2{4,k};
                EP(m).qf = qf;
                EP(m).dir = upd(2);

                AP(m) = an_swp(Vb2,Iarr2(:,k),cspice_str2et(Tarr2{1,k}),mode(2),EP(m).lum);

                if k>1
                    Vguess = DP(m-1).Vph_knee;
                else
                    Vguess = AP(m).vs; %use last calculation as a first guess
                end

                [DP(m),DP_asm(m)] = an_LP_Sweep_v2(Vb2,Iarr2(:,k),Vguess,EP(m).lum);

                %DP(m) = an_LP_Sweep(Vb2,Iarr2(:,k),Vguess,EP(m).lum);
                %DP_asm(m) = an_LP_Sweep_with_assmpt(Vb2,Iarr2(:,k),assmpt,EP(m).lum);

                Te_guess = 5;%eV
                %EP(m).ne_5eV = abs(1e-6*DP(m).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
                %EP(m).asm_ne_5eV = abs(1e-6*DP_asm(m).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
                EP(m).ne_5eV        = max((1e-6*sqrt(2*pi*CO.me*Te_guess) * DP(m).e_slope(1) / (IN.probe_A*CO.e.^1.5)),0); %max out of expression and 0 -> if >0, n=0;
                EP(m).asm_ne_5eV    = max((1e-6*sqrt(2*pi*CO.me*Te_guess) * DP_asm(m).e_slope(1) / (IN.probe_A*CO.e.^1.5)),0);  %max out of expression and 0 -> if >0, ni=0;
                EP(m).asm_Vsc_ni_ne = nansum((DP_asm(k).ion_Vb_intersect(1)-(sqrt(DP_asm(k).ion_intersect(1))*DP_asm(k).ne(1)/DP_asm(k).ni_2comp(1)).^2)/DP_asm(k).ion_slope(1));
                EP(m).Vsc_ni_ne     = nansum((DP(k).ion_Vb_intersect(1)    -(sqrt(DP(k).ion_intersect(1))    *DP(k).ne(1)    /DP(k).ni_2comp(1)).^2)    /DP(k).ion_slope(1));

            end%for
        end%if split

        [junk,ind] = sort({EP.tstamp});
        klen=length(ind);

        AP=AP(ind);
        DP=DP(ind);
        DP_asm=DP_asm(ind);
        EP=EP(ind);
        wfile= rfile;
        wfile(end-6)='A';
        awID= fopen(wfile,'w');



        % IF THIS HEADER IS REMOVED (WHICH IT SHOULD BE BEFORE ESA
        % DELIVERY) NOTIFY TONY ALLEN!
        fprintf(awID,strcat('START_TIME(UTC), STOP_TIME(UTC), START_TIME_OBT, STOP_TIME_OBT, Qualityfactor, SAA, Illumination, direction',...
        ', old.Vsi, old.Vx, Vsg, sigma_Vsg',...
        ', old.Tph, old.Iph0, Vb_lastnegcurrent, Vz',...
        ', Vbinfl, dIinfl, d2Iinfl',...
        ', Iph0, Tph, Vsi, Vph_knee, sigma_Vph_knee, Te_linear, sigma_Te_linear, ne_linear, sigma_ne_linear',...
        ', ion_slope, sigma_ion_slope, ion_intersect, sigma_ion_intersect, e_slope, sigma_e_slope, e_intersect, sigma_e_intersect',...
        ', ion_Vb_intersect, sigma_ion_Vb_intersect, e_Vb_intersect, sigma_e_Vb_intersect',...
        ', Tphc, nphc, phc_slope, sigma_phc_slope, phc_intersect, sigma_phc_intersect',...
        ', ne_5eV, ni_v_dep, ni_v_indep, v_ion, Te_exp, sigma_Te_exp, ne_exp, sigma_ne_exp, Rsquared_linear, Rsquared_exp',...
        ', Vbar, sigma_Vbar',...
        ', ASM_Iph0, ASM_Tph, asm_Vsi, asm_Te_linear, asm_sigma_Te_linear, asm_ne_linear, sigma_asm_ne_linear',...
        ', asm_ion_slope, asm_sigma_ion_slope, asm_ion_intersect, asm_sigma_ion_intersect, asm_e_slope, asm_sigma_e_slope, asm_e_intersect, asm_sigma_e_intersect',...
        ', asm_ion_Vb_intersect, asm_sigma_ion_Vb_intersect, asm_e_Vb_intersect, asm_sigma_e_Vb_intersect',...
        ', asm_Tphc, asm_nphc, asm_phc_slope, asm_sigma_phc_slope, asm_phc_intersect, asm_sigma_phc_intersect',...
        ', asm_ne_5eV, asm_ni_v_dep, asm_ni_v_indep, asm_v_ion, asm_Te_exp, asm_sigma_Te_exp, asm_ne_exp, asm_sigma_ne_exp, asm_Rsquared_linear, asm_Rsquared_exp',...
        ', ASM_m_ion, ASM_Z_ion, ASM_v_ion, Vsc_ni_ne, asm_Vsc_ni_ne',...
        ', Vsc_aion, ni_aion, v_aion, asm_Vsc_aion, asm_ni_aion, asm_v_aion',...
        ', Te_exp_belowVknee, sigma_Te_exp_belowVknee, ne_exp_belowVknee, sigma_ne_exp_belowVknee, asm_Te_exp_belowVknee, asm_sigma_Te_exp_belowVknee, asm_ne_exp_belowVknee, asm_sigma_ne_exp_belowVknee',...
        ', Vsg_lowAc, sigma_Vsg_lowAc, Vph_knee_lowAc, sigma_Vph_knee_lowAc, Vbar_lowAc, sigma_Vbar_lowAc',...
        '\r\n'));

        % fpformat = '%s, %s, %05i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e  %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
        for k=1:klen
            % print variables to file. separated into substrings.

            str1  = sprintf('%s, %s, %16s, %16s, %05i, %07.3f, %04.2f, %1i,', EP(k).Tarr{1,1}, EP(k).Tarr{1,2}, EP(k).Tarr{1,3}, EP(k).Tarr{1,4}, EP(k).qf,EP(k).SAA,EP(k).lum,EP(k).dir);
            str2  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', AP(k).vs,  AP(k).vx,   DP(k).Vsg);
            str3  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', AP(k).Tph, AP(k).Iph0, AP(k).lastneg, AP(k).Vz);
            str4  = sprintf(' %14.7e, %14.7e, %14.7e,',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf);
            str5  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,', DP(k).Iph0, DP(k).Tph, DP(k).Vsi(1), DP(k).Vph_knee, DP(k).Te, DP(k).ne);
            str6  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).ion_slope,DP(k).ion_intersect,DP(k).e_slope,DP(k).e_intersect);
            str7  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).ion_Vb_intersect,DP(k).e_Vb_intersect);
            str8  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).Tphc,DP(k).nphc,DP(k).phc_slope,DP(k).phc_intersect);                                                                                                      %NB DP(k).Te_exp is vector size 2, so two ouputs.
            str9  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,', EP(k).ne_5eV, DP(k).ni_1comp, DP(k).ni_2comp, DP(k).v_ion, DP(k).Te_exp, DP(k).ne_exp, DP(k).Rsq.linear, DP(k).Rsq.exp);
            str10 = sprintf(' %14.7e, %14.7e,',DP(k).Vbar);
            str11 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_asm(k).Iph0,DP_asm(k).Tph,DP_asm(k).Vsi(1),DP_asm(k).Te,DP_asm(k).ne);
            str12 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_asm(k).ion_slope,DP_asm(k).ion_intersect,DP_asm(k).e_slope,DP_asm(k).e_intersect);
            str13 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', DP_asm(k).ion_Vb_intersect, DP_asm(k).e_Vb_intersect);
            str14 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_asm(k).Tphc,DP_asm(k).nphc,DP_asm(k).phc_slope,DP_asm(k).phc_intersect);
            str15 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',EP(k).asm_ne_5eV,DP_asm(k).ni_1comp,DP_asm(k).ni_2comp,DP_asm(k).v_ion,DP_asm(k).Te_exp,DP_asm(k).ne_exp,DP_asm(k).Rsq.linear,DP_asm(k).Rsq.exp);
            str16 = sprintf(' %03i, %02i, %14.7e, %14.7e, %14.7e,',assmpt.ionM,assmpt.ionZ,assmpt.vram,EP(k).Vsc_ni_ne,EP(k).asm_Vsc_ni_ne);
            str17 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,', DP(k).Vsc_aion,DP(k).ni_aion,DP(k).v_aion,DP_asm(k).Vsc_aion,DP_asm(k).ni_aion,DP_asm(k).v_aion);
            str18 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,', DP(k).Te_exp_belowVknee, DP(k).ne_exp_belowVknee, DP_asm(k).Te_exp_belowVknee, DP_asm(k).ne_exp_belowVknee);            
            str19 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e', DP(k).Vsg_lowAc, DP(k).Vph_knee_lowAc,DP(k).Vbar_lowAc);


            strtot=strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9,str10,str11,str12,str13,str14,str15,str16,str17,str18,str19);

            strtot=strrep(strtot,'  0.0000000e+00','            NaN'); % ugly fix, but this fixes the ni = 0 problem in the least code heavy way & probably most efficient way.
            strtot=strrep(strtot,'-Inf',' NaN');
            strtot=strrep(strtot,'Inf','NaN');
            %strtot=strrep(strtot,'NaN','   ');

            %If you need to change NaN to something (e.g. N/A, as accepted by Rosetta Archiving Guidelines) change it here!

            row_bytes = fprintf(awID,'%s\r\n',strtot);

        end
        fclose(awID);

        an_tabindex{end+1,1} = wfile;                   % start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(wfile,rfolder,'');  % shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3};     % first calib data file index
        %an_tabindex{end,3} = an_ind(1);                % First calib data file index of first derived file in this set
        an_tabindex{end,4} = klen; % Number of rows
        an_tabindex{end,5} = 112;  % Number of columns
        an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'sweep'; % Type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_bytes;

         if str2double(probe)==1
            dfile= wfile;
            dfile(end-6:end-4)='A1P';
            awID= fopen(dfile,'w');
            if i==1
                 der_struct=[];
                 der_struct.file={};                 
                 der_struct.shortname={};
                 der_struct.firstind=[];
                 der_struct.rows=[];
                 der_struct.cols=[];
                 der_struct.an_ind_id=[];
                 der_struct.timing={};
                 der_struct.bytes=[];
            end
            
            
         %   nanind=isnan(DP(:).Vph_knee(1));
            
            
            
            for k=1:klen
                
                dstr1  = sprintf('%s, %s, %16s, %16s, %04i,', EP(k).Tarr{1,1}, EP(k).Tarr{1,2}, EP(k).Tarr{1,3}, EP(k).Tarr{1,4}, EP(k).qf);
                dstr2 = sprintf(' %14.7e, %14.7e', DP(k).Vph_knee(1),DP(k).Te_exp_belowVknee(1));
       
                
                if isnan(DP(k).Vph_knee(1))
                    
                    
                    
                    dstrtot=strcat(dstr1,dstr2);
                    % NOTE: Can not replace NaN etc with string "-1000" directly, since DVAL-NG inteprets that as an integer (?), which
                    % is incompatible with DATA_TYPE=ASCII_REAL.  /Erik P G Johansson
                    dstrtot=strrep(dstrtot,'  0.0000000e+00','       -1.0e+03'); % ugly fix, but this fixes the ni = 0 problem in the least code heavy way & probably most efficient way.
                    %dstrtot=strrep(dstrtot,'  NaN','-1000');
                    dstrtot=strrep(dstrtot,'     NaN','-1.0e+03');
                    %                         dstrtot=strrep(dstrtot,'  -Inf','-1.0e3');
                    %                         dstrtot=strrep(dstrtot,'   Inf','-1.0e3');
                end
                drow_bytes = fprintf(awID,'%s\r\n',dstrtot);

                
            end
            fclose(awID);
                                
            der_struct=[];
            der_struct.file{i}      = dfile;
            der_struct.shortname{i} =strrep(dfile,rfolder,'');
            der_struct.firstind(i)  =tabindex{an_ind(i),3};
            der_struct.rows(i)      =klen;
            der_struct.cols(i)      =7;
            der_struct.an_ind_id(i) =an_ind(i);
            der_struct.timing(i,1:4)=timing;
            der_struct.bytes=drow_bytes;    % I do not think I need this variable. drow_bytes is also not always set ==>bug. /Erik P G Johansson 2018-08-03
                      
        end

        
        
        
        %clear output structs before looping again
        clear AP DP EP
        
    end  % for every sweep file

    cspice_kclear;  %unload ALL kernels when exiting function
    %
catch err

    fprintf(1,'Error at loop step %i, file %s',i,tabindex{an_ind(i),1});
    if ~isempty(k)
        fprintf(1,'\n Error at loop step k=%i,',k);
    end
    err.identifier
    err.message
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i; ',err.stack(i).name,err.stack(i).line);
        end
    end
    cspice_kclear;  %unload ALL kernels when exiting function
    %cspice_unload(kernelFile);  %unload kernels when exiting function

end


end    % function
