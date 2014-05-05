function p = mvtpdf_gaussian_uninformative_prior(X, estimatedMu, estimatedSigma, nPoint, dim)
%MVTPDF_GAUSSIAN_UNINFORMATIVE_PRIOR

S = estimatedSigma*(nPoint-1);
nu = nPoint - dim;
w = (S * (nPoint + 1)) / (nPoint * nu);

p = parammvtpdf(X, estimatedMu, w, nu);