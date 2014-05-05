function [mu, sigma] = sample_gaussian_uninformative_prior(estimatedMu, estimatedSigma, nPoint, dim)
%SAMPLE_GAUSSIAN_UNINFORMATIVE_PRIOR 

S = estimatedSigma*(nPoint-1);
nu = nPoint-dim;
w = S / (nPoint * nu);

cor = corrcov(w); %the same as corrcov(S), doest not need to be done as it it done in mvtrnd but just to make it obvious 
mu = estimatedMu +  mvtrnd(cor, nu) * chol(w);

sigma = iwishrnd(S, nPoint-1);