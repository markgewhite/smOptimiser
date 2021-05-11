% ************************************************************************
% Function: objFnAverager
% Purpose:  Example of objective function that simply averages 
%           the values in the data vector provided with some noise added.
%
%
% Parameters:
%           v: simple parameter
%           x: data
%
% Output:
%           y: computed value
%
% ************************************************************************

function y = objFnAverager( v, x, o )

v = table2array( v );

y = mean( x.outcome ) - sin(v*pi/180)-sin(v*pi/30)  + normrnd( 0, 0.25 );

end