%
% Initially created 2016-07-07 by Erik P G Johansson, IRF Uppsala, Sweden.
%
% Generic function for writing ODL (LBL/CAT) files using a "string-lists struct" on the same format
% as returned from read_ODL_from_struct. Does some basic "beautification" (indentation,
% added whitespace to make equal signs and value left-aligned).
%
% NOTE: Overwrites destination file if pre-existing.
% NOTE: Multiline values are not indented (except the key itself).
%
% ARGUMENTS
% =========
% s_str_lists : See lib_shared_EJ.read_ODL_to_structs.
% endRowsList : Cell array of strings, one for every line after the final "END" statement (without CR, LF).
%
function write_ODL_from_struct(file_path, s_str_lists, endRowsList, INDENTATION_LENGTH)
%
% PROPOSAL: Implement additional empty rows before/after OBJECT/END_OBJECT.
%    NOTE: Only one row between END_OBJECT and OBJECT. ==> Non-trivial.
%
% PROPOSAL: Add assertion check for (dis)allowed characters (superscripted hyphen disallowed in particular).
% PROPOSAL: Also accept data on the format of non-hierarchical list of key-value pairs?!
% PROPOSAL: Insert line-breaks (CR+LF) to limit row length.
%   NOTE: DVAL indicates that row length (including CR+LF) should be max 72 for .CAT files and 80 for .LBL files.
%   PROPOSAL: Line-break (qutoed) string values.
%       CON: Could potentially mess up, long manually line-broken string values.
    if ~isnumeric(INDENTATION_LENGTH) || (numel(INDENTATION_LENGTH) ~= 1)
        error('Illegal INDENTATION_LENGTH argument.')
    end

    LINE_BREAK = sprintf('\r\n');
    
    [c.fid, error_msg] = fopen(file_path, 'w');
    c.INDENTATION_LENGTH = INDENTATION_LENGTH;
    if c.fid == -1
        error('Failed to open file "%s": "%s"', file_path, error_msg)
    end
    
    write_key_values(c, s_str_lists, 0)
    
    fprintf(c.fid, 'END\r\n');
    
    for i=1:length(endRowsList)        
        fwrite(c.fid, [endRowsList{i}, LINE_BREAK]);
    end
    
    fclose(c.fid);    
end



% Recursive.
function write_key_values(c, s, indentation_level)

    % ARGUMENT CHECK. Implicitly checks that fields exist.
    if length(s.keys) ~= length(s.values) || length(s.keys) ~= length(s.objects)
        error('.keys, .values, and .objects do not have the same length.')
    end
    
    LINE_BREAK = sprintf('\r\n');
    keys    = s.keys;
    values  = s.values;
    objects = s.objects;

    nonOBJECT_keys           = keys(cellfun(@isempty, objects));    % Create list of keys without OBJECT/subsections.
    max_nonOBJECT_key_length = max(cellfun(@length, nonOBJECT_keys));

    indentation_str = repmat(' ', 1, c.INDENTATION_LENGTH*indentation_level);

    for i = 1:length(keys)
        key    = keys{i};
        value  = values{i};
        object = objects{i};
        
        if ~strcmp(key, 'OBJECT') && isempty(object)
            % CASE: non-OBJECT key
            
            post_key_padding = repmat(' ', 1, max_nonOBJECT_key_length-length(key));    % Create string of whitespaces.
            
            %str = sprintf('%s%s%s = %s\r\n',   indentation_str, key, post_key_padding, value);
            %fprintf(c.fid, str);
            
            % IMPLEMENTATION NOTE: Put together and write string to file without using fprintf/sprintf since the value
            % string may contain characters interpreted by fprintf/sprintf. Code has previously generated warnings
            % when using fprintf/sprintf but this avoids that.
            str = [indentation_str, key, post_key_padding, ' = ', value, LINE_BREAK];
            fwrite(c.fid, str);
            
        elseif strcmp(key, 'OBJECT') && ~isempty(value) && ~isempty(object) && isstruct(object)
            % CASE: OBJECT key.
            
            % Print OBJECT with different "post-key" whitespace padding.
            fprintf(c.fid, sprintf('%s%s = %s\r\n',   indentation_str, key, value));
            
            write_key_values(c, object, indentation_level+1);             % RECURSIVE CALL
            fprintf(c.fid, sprintf('%sEND_OBJECT = %s\r\n',   indentation_str, value));
        else
            error('Inconsistent combination of key, value and object.')
        end
    end
end