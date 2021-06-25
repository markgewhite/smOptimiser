% ************************************************************************
% Function: initials
% Purpose:  Return the initial capitalised letters of a string
%
%
% Parameters:
%       txtLong:    char vector or string to be shortened
%
% Output:
%       txtShort:   initials
%
% ************************************************************************

function txtShort = initials( txtLong )

% find the location of the first letter of each word

% look for spaces
spcID = find( txtLong == 32 ); 
if ~isempty( spcID )
    % locate the first letters
    firstID = spcID+1;
    if firstID( end ) > length( txtLong )
        firstID( end ) = [];
    end
    % capitalise the first letters
    txtLong( firstID ) = upper( txtLong(firstID) );
    % remove spaces
    txtLong( spcID ) = [];
end

% ensure first letter is a capital (at least)
txtLong(1) = upper( txtLong(1) );

% extract initials
txtShort = txtLong(txtLong >=65 & txtLong <=90);

if isempty( txtShort )
    % it doesn't contain capitals - revert to original 
    txtShort = txtLong;
end

end