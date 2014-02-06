% opsblocks.m -- define operation blocks
% 
% Limits of operations blocks are defined by:
% 1. Start/stop of any macro
% 2. Midnight UT
% An ops block thus is defined by the continuous running of a certain
% macro during a certain day.
%
% Assumes index has been generated and exists in workspace.

% Define file start times:
t0 = [index.t0]';
macro = [index.macro]';
n = length(t0);

% Operation blocks are defined by jumps in macros and day:
jumps = find(diff(floor(t0)) | diff(macro));
obe = [jumps; n];    % ops block end points
obs = [1; jumps+1];  % ops block start points
nob = length(obe);   % number of ops blocks

% Prepare obs block list for all archive
mac = macro(obs);
tmac0 = t0(obs);  % Start time of first file in ops block
tmac1 = t0(obe);  % Start time of last file in ops block
macind = [tmac0 tmac1 mac];

str = sprintf('blocklists/block_list_%s.txt',archiveid);
mf = fopen(str,'w');
for j=1:nob
    fprintf(mf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));
    
end
fclose(mf);
    
%for j=1:nob
%    fprintf(mf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));
    




% Prepare archive with blocklist files

derivedpath = strrep(archivepath,'RPCLAP-3','RPCLAP-4');
derivedpath = strrep(derivedpath,'CALIB','DERIV');
blockTAB = {};
rcount = 0;
cmpdate='';


for j=1:nob
    
    
    if(strcmp(datestr(tmac0(j),'yyyymmdd'),cmpdate)) %if the file has already been created:
        
        %append to file
        bf = fopen(blockfile,'a');
        fprintf(bf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));
        rcount = rcount + 1; %number of rows
        blockTAB{end,3}=rcount; %change value of rcount of last blockfile
        
    else %ooh, new file!
        
        rcount = 1; %first row of new file
        %create filepath
        dirY = datestr(tmac0(j),'YYYY');
        dirM = upper(datestr(tmac0(j),'mmm'));
        dirD = strcat('D',datestr(tmac0(j),'dd'));
        
        bfshort = strcat('RPCLAP_',datestr(tmac0(j),'yyyymmdd'),'_000000_BLKLIST.TAB');
        blockfile = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/',bfshort);
        
        
        
        blockTAB(end+1,1:3)={blockfile,bfshort,rcount}; %new blockfile, with path, shorthand % row count
        
        %write file
        bf = fopen(blockfile,'w');
        fprintf(bf,'%s,%s,%.0f\n',datestr(tmac0(j),'yyyy-mm-ddTHH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-ddTHH:MM:SS.FFF'),mac(j));
  %        fprintf(bf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));  
    end%if
    fclose(bf); %close file
    cmpdate =datestr(tmac0(j),'yyyymmdd'); %if
        
end%for

clear rcount cmpdate 

     


fprintf(1,'opsblock generated\n');

% End of opsblocks.m
