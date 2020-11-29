_code_git_version="f5bd711c246e130269b3dfd9e3091ce8d3f7b871";
_code_repository="https://github.com/plops/cl-m-generator/tree/master/example/01_simple/source/run_00_start.m";
_code_generation_time="22:35:48 of Sunday, 2020-11-29 (GMT+1)";
;
;
x=((1)+(((2)*(3))));
;
format short;
y=((((1)/(((2)+(((3)^(2)))))))+(((((4)/(5)))*(((6)/(7))))));
;
format long;
y;
clear;
who;
;
x=((1)+(((2)*(3))));

format short
y=((((1)/(((2)+(((3)^(2)))))))+(((((4)/(5)))*(((6)/(7))))));

format long
y
clear
who
;
x=[1, 2, 3, 4, 5, 6];
y=[3, -1, 2, 4, 5, 1];
;
plot(x, y);
;
x=0:((pi)/(100)):((2)*(pi));
y=sin(x);
;
plot(x, y);
xlabel("x=0:2\pi");
ylabel("sine of x");
title("plot of sine function");
;
%% multiple datasets in one plot
;
x=0:((pi)/(100)):((2)*(pi));
;
y1=((2)*(cos(x)));
;
y2=cos(x);
;
y3=(((0.50    ))*(cos(x)));
;
plot(x, y1, "--", x, y2, "-", x, y3, ":");
xlabel("0 \leq x \leq 2\pi");
ylabel("cosinus functions");
legend("((2)*(cos(x)))", "cos(x)", "(((0.50    ))*(cos(x)))");
axis([0, ((2)*(pi)), -3, 3]);
;
;
v=[1, 4, 7, 10, 13];
w=[1; 4; 7; 10; 13];
;
w2=transpose(v);
;
;
v(1:3)
v(3:end)
v(:)
v(1:end)
;
%% matrix example
;
A=[1 2 3;4 5 6;7 8 9;];
;
[m, n]=size(A);
;
B=[A ((10)*(A));-A [1 0 0;0 1 0;0 0 1;];];
;
C=((A).*(A));
;
;
