% Sampling frequency
fs = 400 * 1000;
% Simulation time
tsim = 1 / 1000;
% Simulation steps
step = 100;
% Filter stopband frequency
f0 = 140 * 1000;
w0 = 2*pi*f0/fs;
% Filter order
M = 18;

% Filter coefficients
n = (1:M) - (M+1)/2;
d = (n .* w0 .* cos(n*w0) - sin(n*w0)) ./ (pi * n.^2);
%d((M+1)/2) = 0;
% Windowing (Blackman-Harris 3-term)
w = 0.42 + 0.5 * cos(2 * pi * 1 * n / (M + 1)) + 0.08 * cos(2 * pi * 2 * n / (M + 1));
dw = d .* w;

% Impulse signal
t = 0:1/fs:tsim-1/fs;
s = zeros(size(t));
s(round(length(s)/4)) = 1;
%s = cos(2*pi * fs / 100 *t);
% Direct filtering
vd = cconv(s, dw, length(s));

% Implementation
taps = M / 2;
hm = dw(1:taps)' * s;
v = zeros(1, length(s) + 1);
for i1 = taps * 2 + 1 : length(s) + 1
    for i2 = 1:taps
        v(i1) = v(i1) + hm(i2, i1 - i2);
        v(i1) = v(i1) - hm(taps - i2 + 1, i1 - taps - i2);
    end
end
v = v(2:end);

% Plotting
figure(1);
clf;

subplot(2, 2, 1);
axis tight;
hold on;
plot(t, s);
plot(t, vd);
plot(t, v);
legend('signal', 'direct', 'implement');
xlabel('Time (s)');

subplot(2, 2, 3);
axis tight;
hold on;
P = fftout(s);
L = length(s);
f = fs * (0:(L/2))/L;
plot(f, P);
plot(f, fftout(vd));
plot(f, fftout(v));
legend('signal', 'direct', 'implement');
xlabel('Frequency (Hz)');

subplot(2, 2, 2);
axis tight;
hold on;
plot(n, d);
plot(n, w);
plot(n, dw);
stem(n, dw);
legend('d', 'w', 'dw');
xlabel('Coefficients');

subplot(2, 2, 4);
axis tight;
hold on;
Pdw = fftout([dw zeros(1, length(dw)*3)]) * 4;
L = length(Pdw);
f = pi * (0:L-1)/(L-1);
plot(f, Pdw);
Pdw = fftout(dw);
L = length(Pdw);
f = pi * (0:L-1)/(L-1);
stem(f, Pdw);
legend('Pdw');
xlabel('Frequency (\omega)');
