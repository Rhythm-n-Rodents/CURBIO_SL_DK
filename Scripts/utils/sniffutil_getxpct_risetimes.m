

function risetimes_xpct = sniffutil_getxpct_risetimes(signal, peaks, valleys, pct)

% 09/11/18 Liao: removed Line 9
% 09/11/18 Liao: added "-1" in the end of Line 13

% get pct% risetime for signal of events
sxpctthresh = signal(valleys(1:end-1))+(pct/100)*(signal(peaks)-signal(valleys(1:end-1)));

risetimes_xpct = [];

for ievent = 1:length(sxpctthresh)
    % rise = []; thresh = [];
    rise = signal(valleys(ievent):peaks(ievent));
    thresh = find(rise >= sxpctthresh(ievent), 1, 'first');
    risetimes_xpct(ievent) = valleys(ievent) + thresh -1;
end