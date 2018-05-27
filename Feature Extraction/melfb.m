function m = melfb (p,n,fs)
%MELFB  Determine matrix for a mel-spaced filterbank
%
%   DE-ESSER X
%
%   Usage:
%       M = melfb (P,N,FS)
%
%   Input arguments:
%       P - Number of filters in filterbank
%       N - Length of DFT to apply
%       FS - Sampling frequency in Hz
%
%   Output arguments:
%       M - The filterbank matrix (sparse)
%
%   The columns of the matrix M are the frequency response vectors of each
%   of the P filters in the filterbank. Each filter is a triangular
%   bandpass filter, which means it has a triangular support and zeros
%   outside of it. The filters are arranged according to the Mel scale,
%   that is their width and center band increase roughly logarithmically.
%   Since the matrix is mostly zeros, it is returned as a sparse array, to
%   consume less memory.
%
%   See also:
%       MFCC2, MFCD, DEESSER_TEMPL, DEESSER_MAIN

f0 = 700 / fs;
fn2 = floor(n/2);

lr = log(1 + 0.5/f0) / (p+1);

% convert to fft bin numbers with 0 for DC term
bl = n * (f0 * (exp([0 1 p p+1] * lr) - 1));

b1 = floor(bl(1)) + 1;
b2 = ceil(bl(2));
b3 = floor(bl(3));
b4 = min(fn2, ceil(bl(4))) - 1;

pf = log(1 + (b1:b4)/n/f0) / lr;
fp = floor(pf);
pm = pf - fp;

r = [fp(b2:b4) 1+fp(1:b3)];
c = [b2:b4 1:b3] + 1;
v = 2 * [1-pm(b2:b4) pm(1:b3)];

m = sparse(r,c,v,p,1+fn2);

