clear
clc
close all
% dlmwrite with append test

Fs = 5e3;           % samples per second
NChs = 124;
DataLength = 300;   % seconds
BlockSize = 4;      % seconds

for n=1:3%floor(DataLength/BlockSize)
    
%     x = rand(BlockSize*Fs,NChs);

    x = rand(2,2)
    dlmwrite('dlmwrite_APPEND_test2.dat',x,'-append','precision',20)
    
end
dlmread('dlmwrite_APPEND_test2.dat')