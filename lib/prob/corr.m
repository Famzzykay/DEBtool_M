%% corr
% computes correlation coefficients between two sets of variables

%%
function R = corr(x,y)
% created 2021/11/23 by Bas Kooijman

%% Syntax
% R = <../corr.m *corr*> (x, y) 

%% Description
% Computes a matrix of correlation coefficients for the colums of x and y.
% The observations are in the rows.
%
% Input:
%
% * x: (n,r)-matrix of observations 
% * y: (n,c)-matrix of observations 
%
% Output:
%
% * R: (r,c)-matrix of correlation coefficients
%
%% Example of use
% corr(rand(11,3), rand(11,4));

n = size(x,1); 
if ~(n == size(y,1))
  fprintf('Warning from corr: the number of observations in both arguments are not same\n');
  R = []; return
end

x = x - ones(n,1) * mean(x,1); std_x = var(x,1).^0.5;
y = y - ones(n,1) * mean(y,1); std_y = var(y,1).^0.5;
R = x' * y ./ (std_x' * std_y)/ n;