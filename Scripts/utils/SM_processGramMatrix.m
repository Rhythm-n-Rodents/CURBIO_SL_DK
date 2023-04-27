%% SM_processGramMatrix

%% Usage: from the matrix output from Chonux, convert to a matrix that can be plotted by
% imagesc(x,y,C)

%% Inputs
% C0

%% Outputs
% C

function [C] = SM_processGramMatrix(C0)
    C1 = C0'; % [frequency(f1...fn) x time(t1...tn)]
    %C = flipud(C1); % [frequency(fn...f1) x time(t1...tn)]
    C = C1;
