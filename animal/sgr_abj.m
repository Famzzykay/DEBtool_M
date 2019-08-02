%% sgr_abj
% Gets specific population growth rate for the abj model

%%
function [r, info] = sgr_abj (par, T_pop, f_pop)
  % created 2019/07/06 by Bas Kooijman
  
  %% Syntax
  % [r, info] = <../sgr_abj.m *sgr_abj*> (par, T_pop, f_pop)
  
  %% Description
  % Specific population growth rate for the abj model.
  % Hazard includes 
  %
  %  * thinning (optional, default: 1; otherwise specified in par.thinning), 
  %  * stage-specific background (optional, default: 0; otherwise specified in par.h_B0b, par.h_Bbj, par.h_Bjp, par.h_Bpi)
  %  * ageing (controlled by par.h_a and par.s_G)
  %
  % With thinning the hazard rate is such that the feeding rate of a cohort does not change during growth, in absence of other causes of death.
  % Survival of embryo due to ageing is taken for sure
  % Buffer handling rule: continuous reproduction is used in the abj model.
  % Food density and temperature are assumed to be constant; temperature is specified in par.T_typical.
  % The resulting specific growth rate r is solved from the characteristic equation 1 = \int_0^a_max S(a) R(a) exp(- r a) da
  %   with a_max such that S(a_max) = 1e-6
  %
  % Input
  %
  % * par: structure with parameters for individual (for hazard rates, see remarks)
  % * T_pop: optional temperature (in Kelvin, default C2K(20))
  % * f_pop: optional scalar with scaled functional response (overwrites value in par.f)
  %
  % Output
  %
  % * r: scalar with specific population growth rate
  % * info: scalar with indicator for failure (0) or success (1)
  %
  %% Remarks
  % See <ssd_abj.html *ssd_abj*> for mean age, length, squared length, cubed length and other statistics.
  % See <f_ris0_mod.html *f_ris0_mod*> for f at which r = 0.
  % par.thinning, par.h_B0b, par.h_Bbj, par.h_Bjp and par.h_Bpi are not standard in structure par; Add them before use if necessary.
  % par.reprodCode is not standard in structure par. Add it before use. If missing, "O" is assumed.

  % unpack par and compute statisitics
  cPar = parscomp_st(par); vars_pull(par);  vars_pull(cPar);  

  % defaults
  if exist('T_pop','var') && ~isempty(T_pop)
    T = T_pop;
  else
    T = C2K(20);
  end
  if exist('f_pop','var') && ~isempty(f_pop)
    f = f_pop;  % overwrites par.f
  end
  if ~exist('thinning','var')
    thinning = 1;
  end
  if ~exist('h_B0b', 'var')
    h_B0b = 0;
  end
  if ~exist('h_Bbj', 'var')
    h_Bbj = 0;
  end
  if ~exist('h_Bjp', 'var')
    h_Bjp = 0;
  end
  if ~exist('h_Bpi', 'var')
    h_Bpi = 0;
  end
  if ~exist('reprodCode', 'var') || ~isempty(strfind(reprodCode, 'O'))
    kap_R = kap_R/2; % take cost of male production into account
  end
  
  % temperature correction
  pars_T = T_A;
  if exist('T_L','var') && exist('T_AL','var')
    pars_T = [T_A; T_L; T_AL];
  end
  if exist('T_L','var') && exist('T_AL','var') && exist('T_H','var') && exist('T_AH','var')
    pars_T = [T_A; T_L; T_H; T_AL; T_AH]; 
  end
  TC = tempcorr(T, T_ref, pars_T);   % -, Temperature Correction factor
  kT_M = k_M * TC; vT = v * TC; hT_a = h_a * TC^2;   
  
  % supporting statistics
  u_E0 = get_ue0([g k v_Hb], f); % -, scaled cost for egg
  [tau_j tau_p, tau_b, l_j, l_p, l_b, l_i, rho_j, rho_B] = get_tj([g k l_T v_Hb v_Hj v_Hp], f); % -, scaled ages and lengths
  aT_b = tau_b/ kT_M; tT_j = (tau_j - tau_b)/ kT_M; tT_p = (tau_p - tau_b)/ kT_M; % d, age at birth, time since birth at metam, puberty
  L_b = L_m * l_b; L_j = L_m * l_j; L_p = L_m * l_p;  L_i = L_m * l_i; s_M = l_j/ l_b; % cm, struc length at birth, metam, puberty, ultimate
  S_b = exp(-aT_b * h_B0b);          % -, survivor prob at birth
  rT_j = kT_M * rho_j; rT_B = kT_M * rho_B; % 1/d, expo, von Bert growth rate
  pars_qhSC = {f, kap, kap_R, kT_M, vT, g, k, u_E0, L_b, L_j, L_p, L_i, tT_j, tT_p, rT_j, rT_B, v_Hp, s_G, hT_a, h_Bbj, h_Bjp, h_Bpi, thinning};
  
  % ceiling for r
  R_i = kap_R * (1 - kap) * kT_M * (l_i^3 * (g * s_M + 1)/ (g + 1) - k * v_Hp)/ u_E0; % #/d, ultimate reproduction rate at T eq (2.56) of DEB3 for l_T = 0 and l = f
  char_eq = @(rho, rho_p) 1 + exp(- rho * rho_p) - exp(rho); % see DEB3 eq (9.22): exp(-r*a_p) = exp(r/R) - 1 
  nmregr_options('report',0); nmregr_options('max_step_number',100);
  [rho_max, info] = nmfzero(@(rho) char_eq(rho, R_i * tT_p), 1); 
  r_max = rho_max * R_i; % 1/d, pop growth rate for eternal surivival and ultimate reproduction rate since puberty
    
  % find r from char eq 1 = \int_0^infty S(t) R(t) exp(-r*t) dt
  if charEq(0, S_b, pars_qhSC{:}) > 0
    r = NaN; info = 0; % no positive r exists
  else 
    nmregr_options('report', 0); nmregr_options('max_step_number', 100);% used in nmfzero (which is like fzero, but more stable, using simplex)
    if charEq(r_max, S_b, pars_qhSC{:}) > 0.99
      [r, info] = nmfzero(@charEq, 0, S_b, pars_qhSC{:});
    else
      [r, info] = nmfzero(@charEq, r_max, S_b, pars_qhSC{:});
    end
  end
end

% event dead_for_sure
function [value,isterminal,direction] = dead_for_sure(t, qhSC, sgr, varargin)
  value = qhSC(3) - 1e-6;  % trigger 
  isterminal = 1;          % terminate after the first event
  direction  = [];         % get all the zeros
end

% reproduction is continuous
function dqhSC = dget_qhSC(t, qhSC, sgr, f, kap, kap_R, k_M, v, g, k, u_E0, L_b, L_j, L_p, L_i, t_j, t_p, r_j, r_B, v_Hp, s_G, h_a, h_Bbj, h_Bjp, h_Bpi, thinning)
  % t: time since birth
  q   = max(0, qhSC(1)); % 1/d^2, aging acceleration
  h_A = max(0, qhSC(2)); % 1/d^2, hazard rate due to aging
  S   = max(0, qhSC(3)); % -, survival prob
  
  if t < t_j
    h_B = h_Bbj;
    L = L_b * exp(t * r_j/ 3);
    s_M = L/ L_b;
    r = r_j;
    h_X = thinning * r; % 1/d, hazard due to thinning
  else
    h_B = (t < t_p) * h_Bjp + (t > t_p) * h_Bpi;
    L = L_i - (L_i - L_j) * exp(- r_B * (t - t_j));
    s_M = L_j/ L_b;
    r = 3 * r_B * (L_i/ L - 1); % 1/d, spec growth rate of structure
    h_X = thinning * r * 2/3; % 1/d, hazard due to thinning
  end

  L_m = v/ k_M/ g; % cm, "max" structural length
  dq = (q * s_G * L^3/ L_m^3 + h_a) * f * (v * s_M/ L - r) - r * q;
  dh_A = q - r * h_A; % 1/d^2, change in hazard due to aging

  h = h_A + h_B + h_X; 
  dS = - h * S; % 1/d, change in survival prob
  
  l = L/ L_m; l_p = L_p/ L_m; 
  R = (l > l_p) * kap_R * k_M * (f * l^2/ (f + g) * (g * s_M + l) - k * v_Hp) * (1 - kap)/ u_E0;
  dCharEq = S * R * exp(- sgr * t);
  
  dqhSC = [dq; dh_A; dS; dCharEq]; 
end

function value = charEq (sgr, S_b, varargin)
  options = odeset('Events', @dead_for_sure, 'AbsTol',1e-8, 'RelTol',1e-8);  
  [t, qhSC] = ode45(@dget_qhSC, [0 1e8], [0 0 S_b 0], options, sgr, varargin{:});
  value = 1 - qhSC(end,4);
end
