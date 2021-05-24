% ************************************************************************
% Function: objFnMultiDimTest5G
% Purpose:  Example of an objective function where integer parameters
%           are subject to a conversion function
%
%
% Parameters:
%           
%
% Output:
%           value: computed value
%
% ************************************************************************

function value = objFnMultiDimTest5G( x )

noise = 2;
iterations = 2;

if isa( x, 'table' )
    a = table2array( x );
else
    a = x;
end

fcn = @(x) x*20+5;

a = fcn( a );

value = 1;
for i = 1:5
    value = value-sin(a(i)*pi/180)+sin(a(i)*pi/30);
end
        
value = value + normrnd( 0, noise )/sqrt(iterations);

end


