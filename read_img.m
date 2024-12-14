%% 预备工作
clc; % 清除命令行窗口
clear; % 清空工作区中的变量
format compact; % 紧凑格式输出
close all; % 关闭所有图形窗口

%% 读取图像
image = imread('武汉校正后影像.png');  % 图像文件名
% 如果是彩色图像，将其转换为灰度图像
if size(image, 3) == 3
    image = rgb2gray(image);
end
% 将图像数据写入CSV文件
writematrix(image, '武汉校正后影像.csv');  % 将数据写入 '.csv' 文件

image = imread('data/武汉参考影像.png');  % 图像文件名
% 如果是彩色图像，将其转换为灰度图像
if size(image, 3) == 3
    image = rgb2gray(image);
end
% 将图像数据写入CSV文件
writematrix(image, '武汉参考影像.csv');  % 将数据写入 '.csv' 文件
