function p = mvtcdf_gaussian_uninformative_prior(X, estimatedMu, estimatedSigma, nPoint, dim)
%CDF_GAUSSIAN_UNINFORMATIVE_PRIOR 

S = estimatedSigma*(nPoint-1);
nu = nPoint - dim;
w = (S * (nPoint + 1)) / (nPoint * nu);

p = parammvtcdf(X, estimatedMu, w, nu);