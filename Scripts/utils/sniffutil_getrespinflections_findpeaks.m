function [peaks, valleys] = sniffutil_getrespinflections_findpeaks(respfilt)

% 09/11/18 Liao - added "-1" in the ends of Lines 15 & 23

thresh = .5*std(respfilt);


% compute resp onset and resp peak
respreset = diff(angle(hilbert(-respfilt)));
resppeaks = find(respreset<-pi);

for i=1:(length(resppeaks)-1)
    respi = respfilt([resppeaks(i):resppeaks(i+1)]);
    respvalley = min(respi);
    respvalleytime = resppeaks(i)+find(respi==respvalley,1) -1;
    respstarts(i) = respvalleytime;
end

% re-calculate peaks as maxima between valleys
for i=1:(length(respstarts)-1)
    respi2 = respfilt([respstarts(i):respstarts(i+1)]);
    resppeak2 = max(respi2);
    resppeaktime2 = respstarts(i) + find(respi2 == resppeak2,1) -1;
    resppeaks2(i) = resppeaktime2;
end

peaks = resppeaks2;
valleys = respstarts;