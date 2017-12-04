%
% Create LBL file for TAB file.
%
% ("OBJTABLE" refers to "OBJECT = TABLE" in ODL files.)
% Only for LBL files based on one OBJECT = TABLE section (plus header keywords).
%
%
% PARAMETER LBL_data = struct with the following fields.
%    .N_TAB_file_rows
%    .kvl_header
%    .consistency_check.N_TAB_bytes_per_row     % Value from when writing TAB file. For double-checking.
%    .consistency_check.N_TAB_columns           % Value from when writing TAB file. For double-checking.
%    .OBJTABLE
%       .DESCRIPTION                   % Description for entire table.
%       .OBJCOL_list{i}.NAME
%       .OBJCOL_list{i}.BYTES
%       .OBJCOL_list{i}.DATA_TYPE
%       .OBJCOL_list{i}.UNIT               % Optional. Replaced by standardized default value if empty (field exists with value []).
%                                          % Automatically quoted.
%       .OBJCOL_list{i}.FORMAT             % Required if not IGNORE_OBJCOLUMN_FORMAT
%       .OBJCOL_list{i}.ITEMS              % Optional
%       .OBJCOL_list{i}.DESCRIPTION        % Replaced by standardized default value if empty. Automatically quoted.
%       .OBJCOL_list{i}.MISSING_CONSTANT   % Optional
%
% PARAMETER TAB_LBL_inconsistency_policy = 'warning', 'error', or 'nothing'.
%    Determines how to react in the event of
%    inconsistencies.
%
% NOTE: LBL_data.consistency_check.* are not actually needed to complete the function's tasks. They are there
% as consistency checks so that the caller can submit those values when they came from code creating
% the TAB file, e.g. fprintf and when setting tabindex{:,6} (number of columns). The code will then
% produce error/warning if they differ from what the other arguments suggest.
%
% NOTE: The caller is NOT supposed to surround key value strings with quotes, or units with </>.
% The implementation should add that when appropriate.
% NOTE: The implementation will add certain keywords to kvl_header, and derive the values, and assume that caller has not set them. Error otherwise.
%
% NOTE: Previous implementations have added a DELIMITER=", " field (presumably not PDS compliant) in
% agreement with Imperial College/Tony Allen to somehow help them process the files
% It appears that at least part of the reason was to make it possible to parse the files before
% we used ITEM_OFFSET+ITEM_BYTES correctly. DELIMITER IS NO LONGER NEEDED AND SHOULD BE PHASED OUT!
% (E-mail Tony Allen->Erik Johansson 2015-07-03 and that thread).
%
% NOTE: Not full general-purpose function.
%       (1) Calls createLBL_write_LBL_header to write initial top-level PDS keywords.
%       (2) Also does not use general-purpose ODL writing function (like EJ's write_ODL_from_struct).
%       (3) OBJTABLE_DELIMITER
%       (4) hardcoded indentation length
%       NOTE: Uses createLBL_KVPL_add_kv_pair, createLBL_KVPL_merge.
%
function createLBL_create_OBJTABLE_LBL_file(TAB_file_path, LBL_data, TAB_LBL_inconsistency_policy)
    %
    % CONCEIVABLE LBL FILE SPECIAL CASES that may have different requirements:
    %    Data measurement files (DATA/)
    %    Block lists.
    %    Geometry files.
    %    INDEX.LBL
    %       => Does not require SPACECRAFT_CLOCK_START_COUNT etc.
    %
    % PROPOSAL: Only set/require keys that are common for all OBJECT=TABLE files (ODL standard, not PDS standard).
    %     PROPOSAL: Different requirements for different LBL files can be implemented in the form of wrapping functions.
    %         NOTE: Seems the only header fields set are:
    %             Keep
    %                 RECORD_TYPE  = FIXED_LENGTH
    %                 RECORD_BYTES = 153
    %                 FILE_RECORDS = 2700
    %             Move to context-dependent wrapping function.
    %                 FILE_NAME    = "2014-DEC-31orb.LBL"
    %                 ^TABLE       = "2014-DEC-31orb.TAB"
    %                 PRODUCT_ID   = "2014-DEC-31orb"
    %
    % PROPOSAL: Derive number of TAB file rows from TAB file itself?
    % PROPOSAL: Check TAB file size = N_rows * N_bytes_per_row.
    %     PRO: Fast way of checking (almost) N_rows and N_bytes_per_row.
    %        CON: When something is wrong, it will not be able to tell what is wrong.
    %     NOTE: Requires knowledge of RECORD_BYTES, FILE_RECORDS (not in a future wrapping function).
    %     NOTE: AxS files will give irrelevant errors. Use TAB_LBL_inconsistency_policy.
    % PROPOSAL: Check non-PDS-compliant inline headers of AxS files with the LBL column descriptions (column names)?
    %
    % PROBLEM: Replacing [] with 'N/A'. Caller may use [] as a placeholder before knowing the proper value, rather than in the meaning of no value (N/A).
    %
    % PROPOSAL: Ignore FORMAT? Warning/error on finding FORMAT? (Flag for whether to trigger error?)
    %   NOTE: Current usage of "FORMAT" seems wrong. DVAL checks imply that FORMAT can be omitted.
    %
    % PROPOSAL: Change name from "consistency_checks" to "assertions".
    %
    % PROPOSAL: Write to file using the general-purpose write_ODL_from_struct function? Only need to build structure to pass on.
    %    NOTE: Actually concerns quite a small part of the code.
    %    NOTE: Need to simultaneously abolish createLBL_write_LBL_header which should not be used by any other code.
    %    PRO: Standardizes LBL "beautification", ODL assertions (slow?).
    %    PRO: Shortens code.
    %
    
    %=============================
    % "Function global" constants
    %=============================
    
    % --- Constants: ---
    OBJTABLE_DELIMITER = ', ';                            % TEMPORARY solution
    BYTES_BETWEEN_COLUMNS = length(OBJTABLE_DELIMITER);   % Requires absence of quotes in string. Variable is TEMPORARY solution?
    BYTES_PER_LINEBREAK   = 2;      % Carriage return + line feed.
    
    % NOTE: Exclude COLUMNS, ROW_BYTES, ROWS.
    PERMITTED_OBJTABLE_FIELD_NAMES = {'COLUMNS_consistency_check', 'ROW_BYTES_consistency_check', 'DESCRIPTION', 'OBJCOL_list'};
    % NOTE: Exclude ITEM_OFFSET
    PERMITTED_OBJCOL_FIELD_NAMES   = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'FORMAT', 'ITEMS', 'ITEM_BYTES', 'DESCRIPTION', 'MISSING_CONSTANT'};
    INDENTATION                    = '    ';         % Indentation between every "OBJECT level" in LBL file.
    IGNORE_OBJCOLUMN_FORMAT        = 1;              % Flag for whether to ignore all FORMAT fields.
    
    % "Planetary Data Systems Standards Reference", Version 3.6, p12-11, section 12.3.4.
    % Applies to what PDS defines as identifiers, i.e. "values" without quotes.
    PDS_IDENTIFIER_PERMITTED_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789';
    
    
    
    %disp(['Create LBL table for: ', TAB_file_path]);     % DEBUG / log message.
    
    OBJTABLE_data = LBL_data.OBJTABLE;
    
    % --------------------------------------------------------------
    % Argument check
    % --------------
    % Check if caller only uses permissible field names. Disable?
    % Useful when changing field names.
    % --------------------------------------------------------------
    if any(~ismember(fieldnames(OBJTABLE_data), PERMITTED_OBJTABLE_FIELD_NAMES))
        error('ERROR: Found illegal field name(s) in parameter "OBJTABLE_data".')
    end
    
    %-----------------------------------------------------------------------------------
    % Argument check
    % --------------
    % When a caller takes values from tabindex, an_tabindex etc, and they are sometimes
    % mistakenly set to []. Therefore this check is useful. A mistake might
    % otherwise be discovered first when examining LBL files.
    %-----------------------------------------------------------------------------------
    if isempty(LBL_data.consistency_check.N_TAB_columns) || isempty(LBL_data.consistency_check.N_TAB_bytes_per_row) || isempty(LBL_data.N_TAB_file_rows)
        error('ERROR: Trying to use empty value.')
    end
    
    %################################################################################################
    
    % Extract useful information from TAB file path.
    [file_path, file_basename, TAB_file_ext] = fileparts(TAB_file_path);
    TAB_filename  = [file_basename, TAB_file_ext];
    LBL_filename  = [file_basename, '.LBL'];
    LBL_file_path = [file_path, filesep, LBL_filename];
    
    %################################################################################################
    
    %--------------------------------------------------------------------------------------------------
    % Iterate over list of ODL "OBJECT=COLUMN" segments
    % ___IN_PREPARATION_FOR___ writing to file
    % -------------------------------------------------------------------------------
    % Calculate "COLUMNS" (taking ITEMS into account) rather than take from argument.
    % Calculate "ROW_BYTES" rather than take from argument.
    % NOTE: ROW_BYTES is only correct if fprintf prints correctly when creating the TAB file.
    %--------------------------------------------------------------------------------------------------
    OBJTABLE_data.ROW_BYTES = 0;   % NOTE: Adds new field to structure.
    OBJTABLE_data.COLUMNS   = 0;   % NOTE: Adds new field to structure.
    OBJCOL_names_list = {};
    for i = 1:length(OBJTABLE_data.OBJCOL_list)
        cd = OBJTABLE_data.OBJCOL_list{i};       % cd = column data
        
        % --------------------------------------------------------------
        % Check if caller has added fields that can not be used.
        % --------------------------------------------------------------
        % Useful for not loosing information in optional arguments/field
        % names by misspelling, or misspelling when overwriting values,
        % or adding fields that are never used by the function.
        % --------------------------------------------------------------
        if any(~ismember(fieldnames(cd), PERMITTED_OBJCOL_FIELD_NAMES))
            error('ERROR: Found illegal COLUMN OBJECT field name(s).')
        end
        
        
        if isfield(cd, 'FORMAT') && IGNORE_OBJCOLUMN_FORMAT
            cd = rmfield(cd, 'FORMAT');
        end
        
        
        if isfield(cd, 'BYTES') && ~isfield(cd, 'ITEMS') && ~isfield(cd, 'ITEM_BYTES')
            N_subcolumns = 1;
        elseif ~isfield(cd, 'BYTES') && isfield(cd, 'ITEMS') && isfield(cd, 'ITEM_BYTES')
            N_subcolumns = cd.ITEMS;
            cd.ITEM_OFFSET = cd.ITEM_BYTES + BYTES_BETWEEN_COLUMNS;
            cd.BYTES = N_subcolumns * cd.ITEM_OFFSET - (cd.ITEM_OFFSET - cd.ITEM_BYTES);
        else
            % Value is needed in case execution continues after warning/error. If wrong value, then possibly this will cause further
            % errors anyway.
            if isfield(cd, 'ITEMS')
                N_subcolumns = cd.ITEMS;
            else
                N_subcolumns = 1;
            end
            warning_error___LOCAL(sprintf('Found disallowed combination of BYTES/ITEMS/ITEM_BYTES. NAME="%s"', cd.NAME), TAB_LBL_inconsistency_policy)
        end
        
        %-------------------------------------------------------------------
        % Check UNIT:
        % Check for presence of "raised minus" in UNIT.
        % This is a common typo when writing cm^-3 which then becomes cm⁻3.
        %-------------------------------------------------------------------
        if isfield(cd, 'UNIT')
            if isempty(cd.UNIT)
                cd.UNIT = 'N/A';     % NOTE: Should add quotes later.
            end
            if any(strfind(cd.UNIT, '⁻')) || any(strfind(cd.UNIT, '"'))
                 warning_error___LOCAL(sprintf('Found "raised minus" or double quote in UNIT. This is assumed to be a typo. NAME="%s"; UNIT="%s"', cd.NAME, cd.UNIT), TAB_LBL_inconsistency_policy)
            end
        end
        
        %-------------
        % Check NAME.
        %-------------
        if isempty(cd.NAME)
            error('ERROR: Trying to use empty value for NAME.')
        end
        disallowed_chars = setdiff(cd.NAME, PDS_IDENTIFIER_PERMITTED_CHARS);
        if ~isempty(disallowed_chars)
            % NOTE 2016-07-22: The NAME value that triggers this error may come from a CALIB LBL file produced by pds, NAME = P1-P2_CURRENT/VOLTAGE.
            % pds should no longer produce this kind of LBL files since they violate the PDS standard but they may still occur in old data sets.
            % Therefore, there is also value in printing the file name since the user can then (maybe) determine if that is true.
            warning_error___LOCAL(sprintf('Found disallowed character(s) "%s" in NAME. NAME="%s". (Replacing dash with underscore.)\n   File: %s', disallowed_chars, cd.NAME, LBL_file_path), TAB_LBL_inconsistency_policy)
            
            cd.NAME = strrep(cd.NAME, '-', '_');     % TEMPORARY.
        end
        
        if isempty(cd.DESCRIPTION)
            cd.DESCRIPTION = 'N/A';   % NOTE: Quotes are added later.
        else
            if ~isempty(strfind(cd.DESCRIPTION, '"'))
                error('Parameter field DESCRIPTION contains quotes. This is not needed as quotes are added automatically.')
            end
        end
        
        OBJTABLE_data.COLUMNS  = OBJTABLE_data.COLUMNS + N_subcolumns;
        %OBJTABLE_data.ROW_BYTES = OBJTABLE_data.ROW_BYTES + N_subcolumns*(cd.BYTES + BYTES_BETWEEN_COLUMNS);
        OBJTABLE_data.ROW_BYTES = OBJTABLE_data.ROW_BYTES + cd.BYTES + BYTES_BETWEEN_COLUMNS;     % Multiple subcolumns (ITEMS) have already taken into account.
        OBJCOL_names_list{end+1} = cd.NAME;
        
        OBJTABLE_data.OBJCOL_list{i} = cd;      % Return updated info to original data structure.
        clear cd
    end
    OBJTABLE_data.ROW_BYTES = OBJTABLE_data.ROW_BYTES - BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;
    
    %################################################################################################
    
    % ---------------------------------------------
    % Check for doubles among the ODL column names.
    % Useful for A?S.LBL files.
    % ---------------------------------------------
    if length(unique(OBJCOL_names_list)) ~= length(OBJCOL_names_list)
        error('Found doubles among the ODL column names.')
    end
    
    % ------------------------------------------------------------
    % Do consistency checks.
    % ------------------------------------------------------------
    if (OBJTABLE_data.COLUMNS ~= LBL_data.consistency_check.N_TAB_columns)
        msg =       sprintf('LBL_file_path = %s\n', LBL_file_path);
        msg = [msg, sprintf('OBJTABLE_data.COLUMNS (derived)          = %i\n', OBJTABLE_data.COLUMNS)];
        msg = [msg, sprintf('LBL_data.consistency_check.N_TAB_columns = %i\n', LBL_data.consistency_check.N_TAB_columns)];
        msg = [msg,         'OBJTABLE_data.COLUMNS deviates from the consistency check value.'];
        warning_error___LOCAL(msg, TAB_LBL_inconsistency_policy)
    end
    if OBJTABLE_data.ROW_BYTES ~= LBL_data.consistency_check.N_TAB_bytes_per_row
        msg =       sprintf('LBL_file_path = %s\n', LBL_file_path);
        msg = [msg, sprintf('OBJTABLE_data.ROW_BYTES (derived)              = %i\n', OBJTABLE_data.ROW_BYTES)];
        msg = [msg, sprintf('LBL_data.consistency_check.N_TAB_bytes_per_row = %i\n', LBL_data.consistency_check.N_TAB_bytes_per_row)];
        msg = [msg,         'OBJTABLE_data.ROW_BYTES deviates from the consistency check value.'];
        
        warning_error___LOCAL(msg, TAB_LBL_inconsistency_policy)
    end
    
    % Remove quotes, if there are any. Quotes are added later.
    % NOTE: One does not want to give error on finding quotes since the value may have been read from CALIB LBL file.
    OBJTABLE_data.DESCRIPTION = strrep(OBJTABLE_data.DESCRIPTION, '"', '');
    
    %################################################################################################
    
    % Add keywords to the LBL "header".
    kvl_set = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
    kvl_set.keys   = {};
    kvl_set.values = {};
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'RECORD_TYPE',  'FIXED_LENGTH');   % NOTE: Influences whether one must use RECORD_BYTES, FILE_RECORDS, LABEL_RECORDS.
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'RECORD_BYTES', sprintf('%i',   OBJTABLE_data.ROW_BYTES));
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_NAME',    sprintf('"%s"', LBL_filename));    % Should be qouted.
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, '^TABLE',       sprintf('"%s"', TAB_filename));    % Should be qouted.
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'PRODUCT_ID',   sprintf('"%s"', file_basename));   % Should be qouted.
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_RECORDS', sprintf('%i',   LBL_data.N_TAB_file_rows));
    
    LBL_data.kvl_header = createLBL_KVPL_merge(LBL_data.kvl_header, kvl_set);
    
    %################################################################################################
    
    pi = [];     % pi = Print (noun) info
    pi.fid               = fopen(LBL_file_path, 'w');   % Open LBL file to create/write to.
    pi.indentation_level = 0;
    pi.indentation_str   = INDENTATION;
    
    % Log message
    %fprintf(1, 'Writing LBL file: "%s"\n', LBL_file_path);
    
    
    
    %=========================
    % Write LBL file "header"
    %=========================
    createLBL_write_LBL_header(pi.fid, LBL_data.kvl_header);
    
    %=====================================
    % Write LBL file OBJECT=TABLE segment
    %=====================================
    pi = ind_print(+1, pi, 'OBJECT = TABLE');
    pi = ind_print( 0, pi,     'INTERCHANGE_FORMAT = ASCII');
    pi = ind_print( 0, pi,     'ROWS               = %d',   LBL_data.N_TAB_file_rows);
    pi = ind_print( 0, pi,     'COLUMNS            = %d',   OBJTABLE_data.COLUMNS);
    pi = ind_print( 0, pi,     'ROW_BYTES          = %d',   OBJTABLE_data.ROW_BYTES);
    pi = ind_print( 0, pi,     'DESCRIPTION        = "%s"', OBJTABLE_data.DESCRIPTION);
    
    current_row_byte = 1;    % Used for deriving START_BYTE. Starts with one, not zero.
    for i = 1:length(OBJTABLE_data.OBJCOL_list)   % Iterate over list of ODL OBJECT COLUMN
        cd = OBJTABLE_data.OBJCOL_list{i};        % cd = column OBJTABLE_data
        
        pi = ind_print(+1, pi, 'OBJECT = COLUMN');
        pi = ind_print( 0, pi,     'NAME             = %s', cd.NAME);
        pi = ind_print( 0, pi,     'START_BYTE       = %i', current_row_byte);    % Move down to ITEMS?
        pi = ind_print( 0, pi,     'BYTES            = %i', cd.BYTES);            % Move down to ITEMS?
        pi = ind_print( 0, pi,     'DATA_TYPE        = %s', cd.DATA_TYPE);
        if isfield(cd, 'UNIT')
            pi = ind_print( 0, pi, 'UNIT             = "%s"', cd.UNIT);
        end
        if isfield(cd, 'FORMAT')
            pi = ind_print( 0, pi, 'FORMAT           = %s', cd.FORMAT);
        end
        if isfield(cd, 'MISSING_CONSTANT')
            pi = ind_print( 0, pi, 'MISSING_CONSTANT = %f', cd.MISSING_CONSTANT);
        end
        if isfield(cd, 'ITEMS')
            pi = ind_print( 0, pi, 'ITEMS            = %i', cd.ITEMS);
            pi = ind_print( 0, pi, 'ITEM_BYTES       = %i', cd.ITEM_BYTES);
            pi = ind_print( 0, pi, 'ITEM_OFFSET      = %i', cd.ITEM_OFFSET);
            N_subcolumns = cd.ITEMS;
        else
            N_subcolumns = 1;
        end
        pi = ind_print( 0, pi,     'DESCRIPTION      = "%s"', cd.DESCRIPTION);      % NOTE: Added quotes.
        pi = ind_print(-1, pi, 'END_OBJECT = COLUMN');
        
        current_row_byte = current_row_byte + N_subcolumns*cd.BYTES + BYTES_BETWEEN_COLUMNS;
        
        clear cd
    end
    
    pi = ind_print(-1, pi, 'END_OBJECT = TABLE');
    
    %################################################################################################
    
    pi = ind_print(0, pi, 'END');
    fclose(pi.fid);
end



%##########################################################################################################



%------------------------------------------------------------------------------------------
% Print with indentation.
% -----------------------
% pi         : "print info". State needed by function between calls.
% printf_str : String to be passed to printf
% varargin   : Values to printf.
% 
% NOTE: Change of indentation takes place before/after printf depending on decrement/increment.
% NOTE: Adds correct carriage return and line feed at the end.
%------------------------------------------------------------------------------------------
function pi = ind_print(indentation_increment, pi, printf_str, varargin)
    %indentation_increment = varargin{1};
    %pi                    = varargin{2};
    %printf_str = [varargin{3}, '\r\n'];
    %printf_arg = varargin(4:end);
    printf_arg = varargin;
    
    if indentation_increment < 0
        pi.indentation_level = pi.indentation_level + indentation_increment;
    end
    
    printf_str = [repmat(pi.indentation_str, 1, pi.indentation_level), printf_str, '\r\n'];    % Add indentation.
    fprintf(pi.fid, printf_str, printf_arg{:});
    
    if indentation_increment > 0
        pi.indentation_level = pi.indentation_level + indentation_increment;
    end
end



%##########################################################################################################



% PROPOSAL: Remake into general function?!
function warning_error___LOCAL(msg, policy)
    if strcmp(policy, 'warning')
        %fprintf(1, '%s\n', msg)     % Print since warning is sometimes turned off automatically. Change?
        warning(msg)
    elseif strcmp(policy, 'error')
        error(msg)
    elseif ~strcmp(policy, 'nothing')
        error('Can not interpret warning/error policy.')
    end
end
