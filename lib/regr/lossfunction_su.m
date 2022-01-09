%% lossfunction_su
% loss function "symetric unbounded"

%%
function lf = lossfunction_su(data, meanData, prdData, meanPrdData, weights)
  % created: 2016/08/23 by Goncalo Marques
  
  %% Syntax 
  % lf = <../lossfunction_su.m *lossfunction_su*>(func, par, data, auxData, weights, psdtrue)
  
  %% Description
  % Calculates the loss function
  %   w' ((d - p)^2 (1/ mean_d^2 + 1/ mean_p^2))
  % multiplicative symmetric unbounded 
  %
  % Input
  %
  % * data: vector with data
  % * meanData: vector with mean value of data per set
  % * prdData: vector with predictions
  % * meanPrdData: vector with mean value of predictions per set
  % * weights: vector with weights for the data
  %  
  % Output
  %
  % * lf: loss function value

  lf = weights' * ((data - prdData).^2 .*(1./ meanData.^2 + 1./ meanPrdData.^2));
  