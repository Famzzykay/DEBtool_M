%% demo for nmfzero, relative to fzero

test(.5)

function out = test(par)
  char_eq = @(rho, rho_p) 1 + exp(- rho * rho_p) - exp(rho); % see DEB3 eq (9.22): exp(-r*a_p) = exp(r/R) - 1 
  %options = optimset('Display','iter');
  [rho_fzero, fval, info] = fzero(@(rho) char_eq(rho, par), [1e-9 1], []); 

  nmregr_options('tol_fun', 1e-10); nmregr_options('report', 0);
  [rho_nmfzero, info] = nmfzero(@charEq, 0.5, par);
  
  out = [rho_fzero rho_nmfzero];
end

function val = charEq (rho, rho_p)
  val = 1 + exp(- rho * rho_p) - exp(rho);
end