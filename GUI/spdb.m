function X=spdb(xi,N,W,fs)
%%%%%%%%%%%%%%%%%%% Computes the FFT of the signal 'x'
%     x=spdb(input signal, number of points,window,fs);
n=1:N;
m=1:N/2;
f=fs*m/N;
x=xi(n).*W;
y=20*log10(abs(fft(x)))-20*log10(sum(W)/2);
X=y(m);
