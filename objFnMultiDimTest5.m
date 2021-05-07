% ************************************************************************
% Function: objFnMultiDimTest5
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

function value = objFnMultiDimTest5( x )

if isa( x, 'table' )
    a = table2array( x );
else
    a = x;
end

value = 1;
for i = 1:5
    value = value-sin(a(i)*pi/180)+sin(a(i)*pi/30);
end
        
value = value + normrnd( 0, 0.25 );

end


