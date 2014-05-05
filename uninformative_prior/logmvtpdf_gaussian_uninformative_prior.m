function logp = logmvtpdf_gaussian_uninformative_prior(X, estimatedMu, estimatedSigma, nPoint, dim)
%LOGMVTPDF_GAUSSIAN_UNINFORMATIVE_PRIOR

S = estimatedSigma*(nPoint-1);
nu = nPoint - dim;
w = (S * (nPoint + 1)) / (nPoint * nu);

logp = paramlogmvtpdf(X, estimatedMu, w, nu);