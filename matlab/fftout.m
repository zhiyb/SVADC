function [P] = fftout(v)
L = length(v);
Y = fft(v);
P2 = abs(Y/L);
P = P2(1:L/2+1);
P(2:end-1) = 2*P(2:end-1);
