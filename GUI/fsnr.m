function y =fsnr(signalreal2,Nsignals,points,fsreal,finreal,fcorte,betareal,ripreal,win,kind_spec,merit)
% y =fsnr(signalname,Nsignals,Npoints,fs,fin,Bw,beta,ripreal,win,kind_spec,SNR-SNDR)

switch win
    case 1
        window=kaiser(points,betareal);
    case 2
        window=bartlett(points);
    case 3
        window=blackman(points);
    case 4
        window=hamming(points);
    case 5
        window=hanning(points);
    case 6
        window=chebwin(points,ripreal);
    case 7
        window=boxcar(points);
    case 8
        window=triang(points);
end
for i=1:Nsignals
    salida(:,i) = signalreal2(1:points,i);
    salida(:,i)=salida(1:points,i).*window;
end
if (kind_spec==1)   %LP
    fbdown=0;
    fbup=fcorte;
else                %BP
    fbdown=finreal-fcorte/2;
    fbup=finreal+fcorte/2;
end

Nbin=8;
b_signal=round(finreal*points/fsreal);
b_cortedown=round(fbdown*points/fsreal+1);
b_corteup=round(fbup*points/fsreal+1);
n_h2=(round(2*finreal*points/fsreal+1));
n_h3=(round(3*finreal*points/fsreal+1));
if((b_signal-Nbin)<=b_cortedown)
    Nbind=b_signal-b_cortedown;
else
    Nbind=Nbin;
end;
if((b_signal+Nbin)>=b_corteup)
    Nbinup=b_corteup-b_signal;
else
    Nbinup=Nbin;
end;
nsi=b_signal-Nbind:b_signal+Nbinup;
n_bw=b_cortedown:b_corteup;
espectro = abs(fft(salida/sqrt(points))).^2;
espectro = 2*espectro/norm(window)^2;
%%%%SNDR
if (merit==2)
    spec_sig=espectro(double(uint16(nsi)),:);
    spec_band=espectro(double(uint16(n_bw)),:);
    pot_signal=10*log10(sum((spec_sig)));
    pot_noise_distorsion=10*log10(sum((spec_band))-sum((spec_sig)));
    y   = pot_signal - pot_noise_distorsion;
%%%%SNR
else
    spec_sig=espectro(double(uint16(nsi)),:);
    spec_band=espectro(double(uint16(n_bw)),:);
    pot_signal=10*log10(sum((spec_sig)));
    Nbin=8;
    %suponemos que fs>=3*fi ==> 2º y 3º armonico <= fs
    %2º ARMONICO
    if (2*finreal>=fsreal/2)        %2º armonico plegado
        b2ar=round((fsreal-2*finreal)*points/fsreal);
    else
        b2ar=round(2*finreal*points/fsreal);
    end
    if ((b2ar-Nbin>=b_cortedown)&(b2ar+Nbin<=b_corteup))
        b2ar=b2ar-Nbin:1:b2ar+Nbin; 
        spec_h2=espectro(double(uint16(b2ar)),:);
    elseif ((b2ar>=b_cortedown)&(b2ar<=b_corteup))
        nbin=min(b2ar-b_cortedown,b_corteup-b2ar);
        b2ar=n_h2-nbin:1:n_h2+nbin;
        spec_h2=espectro(double(uint16(b2ar)),:);
    else
        spec_h2=0;      
    end
    %3º ARMONICO
    if (3*finreal>=fsreal/2)        %3º armonico plegado
        b3ar=round((fsreal-3*finreal)*points/fsreal);
    else
        b3ar=round(3*finreal*points/fsreal);
    end
    if ((b3ar-Nbin>=b_cortedown)&(b3ar+Nbin<=b_corteup))
        b3ar=b3ar-Nbin:1:b3ar+Nbin;
        spec_h3=espectro(double(uint16(b3ar)),:);
    elseif ((b3ar>=b_cortedown)&(b3ar<=b_corteup))
        nbin=min(b3ar-b_cortedown,b_corteup-b3ar);
        b3ar=b3ar-nbin:1:b3ar+nbin;
        spec_h3=espectro(double(uint16(b3ar)),:);
    else
        spec_h3=0;
    end
    pot_noise=10*log10(sum((spec_band))-sum((spec_sig))-sum(spec_h2)-sum(spec_h3));
    y = pot_signal - pot_noise;
end