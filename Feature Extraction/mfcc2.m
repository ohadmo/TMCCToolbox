function y = mfcc2 (x,win,melbank,n_coeff)
%MFCC2  Calculate Mel Frequency Cepstral Coefficients of a speech matrix.
%
%   DE-ESSER X
%
%   Usage:
%       Y = mfcc2 (X,WIN,MELBANK,N_COEFF)
%
%   Input arguments:
%       X - The speech, in a N1xN2 matrix, where the columns are the speech
%       windows (possibly overlapping), and the rows are the speech samples
%       in each window.
%       WIN - The window which to apply to the speech windows (typically
%       Hamming or Hanning). Must have the same number of rows as X.
%       MELBANK - Mel filter bank (obtained by MELFB.M) which is used to
%       filter the frequency response (DFT) of the speech windows.
%       N_COEFF - Number of MFC coefficients to produce.
%
%   Output arguments:
%       Y - MFCC matrix, consisting of MFCC vectors for each speech window
%       in X.
%
%   See also:
%       MELFB, MFCD, DEESSER_TEMPL, DEESSER_MAIN

[n1,n2] = size(x);
if (length(win)~=n1)
    error ('Window size mismatch.');
end
winmat=win(:,ones(1,n2));
x_win=x.*winmat;                                % Apply window to the speech matrix
X_spectrum=(abs(fft(x_win))).^2;                % The energy of the frequency response of the speech matrix
n_half1=floor(n1/2)+1;
ms = melbank * X_spectrum(1:n_half1,:);         % Take the first half of the spectrum and filter with the Mel filter bank

y = dct(log(ms),n_coeff);                       % Compute cepstral envelope of wanted length
y(1,:) = [];                                    % Exclude zero order cepstral coefficient
