% ************************************************************************
% Function: objFnMultiDimTest
% Purpose:  Example of an objective function with categorical, real and
%           integer arguments.
%
%
% Parameters:
%           
%
% Output:
%           value: computed value
%
% ************************************************************************

function value = objFnMultiDimTest( x )

if isa( x, 'table' )
    a = table2array( x );
else
    a = x;
end

value = 1;
for i = 1:2
    value = value-sin(a(i)*pi/180)+sin(a(i)*pi/30);
end
        
value = value + normrnd( 0, 0.25 );

end


