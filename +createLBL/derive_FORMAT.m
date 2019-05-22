%
% Automatically derive the PDS FORMAT keyword value.
%
%
% See "Planetary Data System Standards Reference", Version 3.6, Section 3.8, page 3-5 for what should be returned.
% IMPLEMENTATION NOTE: Implemented as a separate function to simplify testing.
%
%
% ARGUMENTS AND RETURN VALUE
% ==========================
% nBytes      : Length of tabValueStr. Also PDS keyword BYTES, or ITEM_BYTES if that is available.
% tabValueStr : Example of value extracted from TAB file.
% FORMAT      : PDS keyword value, unquoted. (Should probably be quoted by the caller.)
%
%
% Initially created 2019-08-21 by Erik P G Johansson, IRF Uppsala.
%
function FORMAT = derive_FORMAT(tabValueStr, DATA_TYPE, nBytes)

    % ASSERTION
    if numel(tabValueStr) ~= nBytes
        error('tabValueStr="%s" and nBytes=%i are incompatible.', tabValueStr, nBytes)
    end
    
    

    if any(strcmp(DATA_TYPE, {'TIME', 'CHARACTER'}))
        
        FORMAT = sprintf('A%i', nBytes);
        
    elseif strcmp(DATA_TYPE, 'ASCII_INTEGER')
        
        if ~isempty(regexp(tabValueStr, '^ *(|-)[0-9]+ *$', 'once'))   % NOTE: Permits whitespace before and after.
            FORMAT = sprintf('I%i', nBytes);
        else
            error('Can not derive FORMAT from tabValueStr="%s" with DATA_TYPE=%s.', tabValueStr, DATA_TYPE)
        end
        
        
    elseif strcmp(DATA_TYPE, 'ASCII_REAL')
       
        if ~isempty(regexp(tabValueStr, '^ *(|-)[0-9]+\.[0-9]+ *$', 'once'))   % NOTE: Requires at least one decimal. Permits whitespace before and after.
            % CASE: Decimal format.
            
            integerMatches = regexp(tabValueStr, '[0-9]+', 'match');
            nDecimals = length(integerMatches{2});
            
            FORMAT = sprintf('F%i.%i', nBytes, nDecimals);
            
        elseif ~isempty(regexp(tabValueStr, '^ *(|-)[0-9]+.[0-9]+e[+-][0-9][0-9] *$', 'once'))   % NOTE: Requires at least one decimal. Permits whitespace before and after.
            % CASE: Exponential format.
            
            integerMatches = regexp(tabValueStr, '[0-9]+', 'match');
            nDecimals = length(integerMatches{2});
            
            FORMAT = sprintf('E%i.%i', nBytes, nDecimals);
            
        else
            error('Can not derive FORMAT from tabValueStr="%s" with DATA_TYPE=%s.', tabValueStr, DATA_TYPE)
        end
        
    else
        
        error('Can not derive FORMAT for DATA_TYPE=%s.', DATA_TYPE)
    end

end
