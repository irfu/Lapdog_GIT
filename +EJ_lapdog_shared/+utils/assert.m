%
% Class for static methods for creating assertions.
%
% NOTE: MATLAB already (at least MATLAB R2009a) has a function "assert" which is useful for simpler cases.
%
%
% POLICY
% ======
% Functions should be named as propositions (when including the class name "assert") which are true if the assertion function does not yield error.
% "castring" refers to arrays of char, not the concept of "strings" which begins with MATLAB 2017a and later.
%
%
% RATIONALE, REASONS FOR USING INSTEAD OF MATLAB's "assert"
% =========================================================
% PRO: Still more convenient and CLEARER for some cases.
%       PRO: More convenient for natural combinations of checks.
%           Ex: Structs (is struct + set of fields)
%           Ex: Strings (is char + size 1xN)
%           Ex: "String set" (cell array + only strings + unique strings)
%           Ex: "String list" (cell array + only strings)
%           Ex: Function handle (type + nargin + nargout)
%       PRO: Can have more tailored default error messages: Different messages for different checks within the same
%           assertions.
%           Ex: (1) Expected struct is not. (2) Struct has wrong set of fields + fields which are superfluous/missing.
% CON: Longer statement because of packages.
% PRO: MATLAB's assert requires argument to logical, not numerical (useful if using 0/1=false/true).
% --
% Ex: assert(strcmp(datasetType, 'DERIV1'))
%     vs EJ_lapdog_shared.utils.assertions.castring_in_set(datasetType, {'DERIV1'})
% Ex: assert(any(strcmp(s, {'DERIV1', 'EDDER'})))
%     vs EJ_lapdog_shared.utils.assertions.castring_in_set(datasetType, {'EDDER', 'DERIV1'})
% Ex: assert(isstruct(s) && isempty(setxor(fieldnames(s), {'a', 'b', 'c'})))
%     vs EJ_lapdog_shared.utils.assertions.is_struct_w_fields(s, {'a', 'b', 'c'})
%
%
% NAMING CONVENTIONS
% ==================
% castring : Character Array (CA) string. String consisting 1xN (or 0x0?) matrix of char.
%            Name chosen to distinguish castrings from the MATLAB "string arrays" which were introduced in MATLAB R2017a.
%
%
% Initially created 2018-07-11 by Erik P G Johansson.
%
classdef assert
% TODO-DECISION: Use assertions on (assertion function) arguments internally?
% PROPOSAL: Struct with minimum set of fieldnames.
% PROPOSAL: isvector, iscolumnvector, isrowvector.

    methods(Static)
        
        % NOTE: Empty string literal '' is 0x0.
        function castring(s)
            if ~ischar(s)
                error('Expected castring (0x0, 1xN char array) is not char.')
            elseif ~(isempty(s) || size(s, 1) == 1)
                error('Expected castring (0x0, 1xN char array) has wrong dimensions.')
            end
        end
        
        
        
        % Cell matrix of unique strings.
        function castring_set(s)
            if ~iscell(s)
                error('Expected cell array of unique strings, but is not cell array.')
            elseif numel(unique(s)) ~= numel(s)
                error('Expected cell array of unique strings, but not all strings are unique.')
            end
        end

        
        
        function castring_in_set(s, strSet)
        % PROPOSAL: Abolish
        %   PRO: Unnecessary since can use assert(ismember(s, strSet)).
        %       CON: This gives better error messages for string not being string, for string set not being string set.
        
            EJ_lapdog_shared.utils.assert.castring_set(strSet)
            EJ_lapdog_shared.utils.assert.castring(s)
            
            if ~ismember(s, strSet)
                error('Expected string in string set is not in set.')
            end
        end
        
        
        
        % Either regular file or symlink to regular file (i.e. not directory or symlink to directory).
        function file_exists(filePath)
            if ~(exist(filePath, 'file') == 2)
                error('Expected existing regular file "%s" can not be found.', filePath)
            end
        end
        
        
        
        function dir_exists(dirPath)
            if ~exist(dirPath, 'dir')
                error('Expected existing directory "%s" can not be found.', dirPath)
            end
        end
        
        
        
        % Assert that a path to a file/directory does not exist.
        %
        % Useful if one intends to write to a file (without overwriting).
        % Dose not assume that parent directory exists.
        function path_is_available(path)
        % PROPOSAL: Different name
        %   Ex: path_is_available
        %   Ex: file_dir_does_not_exist
        
            if exist(path, 'file')
                error('Path "%s" which was expected to point to nothing, actually points to a file/directory.', path)
            end
        end
        
        
        
        % Struct with certain fixed set of fields.
        % NOTE: Does NOT assume 1x1 struct. Can be matrix.
        function struct(s, fieldNamesSet)
            % PROPOSAL: Print superfluous and missing fieldnames.
            % PROPOSAL: Option to specify subset or superset of field names.
            %   PRO: Superset useful for when submitting settings/policy struct to function which then adds default
            %        values for missing fields.
            %   PRO: Subset useful for "pdsData" structs(?)
            %   Ex: EJ_lapdog_shared.PDS_utils.construct_DATA_SET_ID
            %   
            % PROPOSAL: Recursive structs field names.
            %   TODO-DECISION: How specify fieldnames? Can not use cell arrays recursively.
            
            if ~isstruct(s)
                error('Expected struct is not struct.')
            end
            EJ_lapdog_shared.utils.assert.castring_set(fieldNamesSet)    % Abolish?
            if ~isempty(setxor(fieldnames(s), fieldNamesSet))
                error('Expected struct has the wrong set of fields.')
            end
        end
        
        
        
        % NOTE: Can not be used for an assertion that treats functions with/without varargin/varargout.
        %   Ex: Assertion for functions which can ACCEPT (not require exactly) 5 arguments, i.e. incl. functions which
        %       take >5 arguments.
        % NOTE: Not sure how nargin/nargout work for anonymous functions. Always -1?
        % NOTE: Can not handle: is function handle, but does not point to existing function(!)
        function func(funcHandle, nArgin, nArgout)
            if ~isa(funcHandle, 'function_handle')
                error('Expected function handle is not a function handle.')
            end
            if nargin(funcHandle) ~= nArgin
                error('Expected function handle ("%s") has the wrong number of input arguments. nargin()=%i, nArgin=%i', func2str(funcHandle), nargin(funcHandle), nArgin)
            elseif nargout(funcHandle) ~= nArgout
                % NOTE: MATLAB actually uses term "output arguments".
                error('Expected function handle ("%s") has the wrong number of output arguments (return values). nargout()=%i, nArgout=%i', func2str(funcHandle), nargout(funcHandle), nArgout)
            end
        end
        
    end    % methods
end    % classdef