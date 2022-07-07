%% ismin
% checks if a parameter combination is at a local minimum of the loss function
%%
function [info lf] = ismin(my_pet, del)
  %  created at 2022/07/07 by Bas Kooijman
  
  %% Syntax
  % [info lf] = <../ismin.m *ismin*> (my_pet, del)
  
  %% Description
  % checks if a parameter combination is at a local minimum of the loss
  % function by checking its value against values where all free parameters
  % are multiplied by 1-del, 1 and 1+del independently, which gives 3^n-1 comparisons for n free parameters. 
  % 
  % Input
  %
  % * my_pet: char string with name of pet
  % * del: scalar with perturbation factor
  %
  % Output
  %
  % * info: boolean: true if local minimum, false if not
  % * lf: scalar with value of the loss function
  
  %% Remarks
  % Assumes local existence of my_data_my_pet, pars_init_my_pet, predict_my_pet.
  % This function is computationally intensive if number of free parameter exceeds 6
  
  %% Example of use
  % ismin('Dipodomys_deserti', 0.05);
  
  % initiate par,data,auxData,weights for calls to lossfunction
  % the free pars in par will be overwritten
  eval(['[data, auxData, metaData, txtData, weights] = mydata_', my_pet,';']);
  eval(['[par, metaPar, txtPar] = pars_init_', my_pet, '(metaData);']);  
  func = ['predict_', my_pet];
  free = par.free; parNm = fields(free); % par names
  n_par = length(parNm); i_free = [];
  for i = 1:n_par; if free.(parNm{i}); i_free = [i_free, i]; end; end
  n_free = length(i_free);

  % compose txt, here for example with n=3 for perturbation factors pert 
  % txt = 'for i1=-1:1;for i2=-1:1;for i3=-1:1;k=k+1;pert(k,:)=[1+del*i1, 1+del*i2, 1+del*i3];end;end;end'
  n_pert = 3^n_free; % # of perturbations
  i_ref = round(n_pert/2 + 0.5); % row-index of pert with all ones
  pert = zeros(n_pert, n_free); val = zeros(n_pert,1); k = 0;
  txt='';
  for i=1:n_free
    txt = [txt, 'for i', num2str(i), '=-1:1;'];
  end
  txt = [txt, 'k=k+1; pert(k,:)=['];
  for i=1:n_free
    txt = [txt, '1+del*i', num2str(i), ','];
  end
  txt(end) = ']';
  for i=1:n_free
    txt = [txt, ';end'];
  end
  eval(txt); % fill pert
  
  par_ref = par; % copy par-structure to reference
  for i = 1:n_pert
    for j = 1:n_free; par.(parNm{j}) = par_ref.(parNm{j}) * pert(i,j); end
    val(i) = lossFn(func, par, data, auxData, weights);
    % fprintf([num2str(i), ' ', num2str(val(i)), '\n'])
  end
  
  lf = val(i_ref); % value of loss function at un-perturbed parameter combination
  info = all(lf <= val);
  
  % info = all(lf <= val);

end