function row = el2row(el)
%converts the electrode number on 32-ch NeuroNexus array (HC32 connector; el = 1 at the tip, el = 32 at the base)
%to numering of rows in Matlab after data are read in using
%read_Intan_RHS2000
%
%assumes that the 1710 amplifier is connected to the connector on the right
%(when electrodes are facing in the upper direction), and that 1710 is the
%B channel

%       tip (el 1)                                                                           base (el 32)
rows = [16, 15, 17, 14, 18, 13, 20, 11, 21, 10, 22,  9, 31,  0, 30,  1, 29, 2, 27,  4, 26,  5, 25,  6, 24,  7, 28,  3, 23,  8, 19, 12]+1;
% +1 to acconut for MATLAB indexing starting at 1 (not 0)

row = rows(el);