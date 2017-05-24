% Baseband signal
fb = 5 * 1000;
% Modulation carrier frequency
fc = 87.5 * 1000 * 1000;
c = fc / 100 / 1000 - 800;
% 80MHz sampling
fs = 80 * 1000 * 1000;
% Simulation time
tsim = 1000 / 1000 / 1000;
% Input precision
prec = 10;

% Timebase
step = 1 / fs / prec;
ti = 0 : step : tsim - step;
% Input message signal
xm = zeros(size(ti));
for i = 1 : 200
    xm = xm + cos(2 * pi * fb * i * ti);
end
xn = 2 * randn(size(ti)) / max(abs(xm));
xm = xm / max(abs(xm));
% Modulation carrier signal
xc = cos(2 * pi * fc * ti);
% Modulated signal
x = (xm + xn) .* xc;
x = x / max(abs(x));
% Sampling timebase
step = 1 / fs;
t = 0 : step : tsim - step;
% Sampled signal
u = downsample(x, prec);

% Down conversion mixer
n = 0 : length(u) - 1;
LO = exp(-1j * 2 * pi * c * n / 800);
ue = LO .* u;

% Filter stop band
f0 = 100 * 1000;
w0 = 2 * pi * f0 / fs;
% Filter order
M = 1200;
% Polyphase configurations
taps = 6;

% FIR index
n = -M / 2 : M / 2 - 1;
% FIR window (Blackman-Harris 3-term)
w = 0.42 + 0.5 * cos(2 * pi * 1 * n / (M + 1)) + 0.08 * cos(2 * pi * 2 * n / (M + 1));
% FIR coefficients
hs = sin(w0 * n) ./ (pi * n);
hs(M / 2 + 1) = w0 / pi;
hs = hs / (w0 / pi) / 1.05;
h = hs .* w;
% FIR output
v1 = cconv(ue, h, length(ue));

% Polyphase filter
P = M / taps;
hp = reshape(h, P, taps)';
l = mod(c, 4);
hm = zeros(taps, length(u));
ha = zeros(taps, length(u));
a = exp(1j * 2 * pi * c / 800);
s = (0:taps - 1)';
%s = taps - 1:-1:0;
for i = 1:length(u)
    p = P - mod(i + P - 2, P) - 1;
    hm(:, i) = u(i) .* hp(:, p + 1);
    ha(:, i) = hm(:, i) .* (1j .^ (l * s)) .* (a ^ p);
end
hsum = zeros(taps, length(u) / P);
for i = 1:length(u) / P
    hsum(:, i) = sum(ha(:, (i - 1) * P + 1:i * P), 2);
end
vp = zeros(1, length(u) / P + 1);
for i1 = taps + 1:length(u) / P + 1
    for i2 = 1:taps
        vp(i1) = vp(i1) + hsum(i2, i1 - i2);
    end
    vp(i1) = vp(i1) * ((-1j) ^ (l * (i1 - 1)));
end
to = downsample(t, P);

figure(4);
clf;
hold on
for i = 1:taps
    plot(real(hsum(i, :)));
    plot(imag(hsum(i, :)));
end

% Plotting
figure(1);
clf;
hold on;
plot(ti, xm, 'k--');
plot(t, u, 'g:');
plot(t, real(v1));
plot(t, imag(v1));
plot(to, real(vp(2:length(vp))));
plot(to, imag(vp(2:length(vp))));
legend('message', 'sampled', 'out real', 'out imag', 'poly real', 'poly imag');
xlabel('time (s)');

figure(2);
clf;
L = length(v1);
f = fs * (0:(L/2))/L;
Pv = fftout(v1);
Pvp = fftout(upsample(vp(2:length(vp)), P) * P);
Pu = fftout(u);
Pue = fftout(ue);
ax(1) = subplot(3, 1, 1);
hold on;
plot(f, Pu);
plot(f, Pue);
legend('sampled', 'mixed');
ax(2) = subplot(3, 1, 2);
hold on;
plot(f, Pv, 'r');
legend('direct');
ax(3) = subplot(3, 1, 3);
hold on;
plot(f, Pvp, 'r');
legend('polyphase');
linkaxes(ax, 'x');
xlabel('frequency (Hz)');

figure(3);
clf;
hold on;
plot(n, h);
plot(n, hs);
plot(n, w);
legend('h', 'hs', 'w');
