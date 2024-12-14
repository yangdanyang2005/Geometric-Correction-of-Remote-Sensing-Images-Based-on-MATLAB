%% 预备工作
clc; % 清除命令行窗口
clear; % 清空工作区中的变量
format compact; % 紧凑格式输出
close all; % 关闭所有图形窗口

%% 使用 cpselect 工具进行交互式选择控制点
% 读取两张PNG图片
reference_image = imread('img/武汉参考影像.png');
target_image = imread('img/武汉待校正影像.png');

% 使用 cpselect 工具进行交互式选择控制点，cpselect自动加载两张图像并允许用户选择对应点
cpselect(reference_image, target_image);

% 假设 movingPoints 和 fixedPoints 已在 cpselect 后导出
% 参考影像控制点
% 【注意】在 x1 = movingPoints(:, 1);  这一行设置断点，运行至这里进行选点，
% 完成选点后，在菜单栏点击【文件-将点导出到工作区】，关闭窗口，再继续运行代码
% 如果不设置断点，程序会直接运行后续代码，而 movingPoints 和 fixedPoints 还没有生成，导致后续部分出错
x1 = movingPoints(:, 1);  % 获取参考影像的 x 坐标
y1 = movingPoints(:, 2);  % 获取参考影像的 y 坐标

% 待校正影像控制点
x2 = fixedPoints(:, 1);  % 获取待校正影像的 x 坐标
y2 = fixedPoints(:, 2);  % 获取待校正影像的 y 坐标

% 输出格式化结果，保留4位小数
fprintf('%% 参考影像控制点\n');
fprintf('x1 = ');
fprintf('%.4f,', x1(1:end-1));
fprintf('%.4f\n', x1(end));

fprintf('y1 = ');
fprintf('%.4f,', y1(1:end-1));
fprintf('%.4f\n', y1(end));

fprintf('\n%% 待校正影像控制点\n');
fprintf('x2 = ');
fprintf('%.4f,', x2(1:end-1));
fprintf('%.4f\n', x2(end));

fprintf('y2 = ');
fprintf('%.4f,', y2(1:end-1));
fprintf('%.4f\n', y2(end));

%% 文件保存
% 确定实验计数
currentDate = datestr(now, 'yyyymmdd');  % 当前日期
outputFolder = 'data';  % 保存文件的文件夹
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);  % 如果文件夹不存在，则创建
end

% 获取当前日期的所有已保存文件
filePattern = fullfile(outputFolder, ['selected_control_points_' currentDate '_*.txt']);
existingFiles = dir(filePattern);

% 根据已有文件确定实验计数
if isempty(existingFiles)
    experimentCount = 1;  % 如果没有找到文件，从1开始
else
    % 提取文件名中的计数并找出最大的计数值
    fileNames = {existingFiles.name};
    counts = cellfun(@(x) sscanf(x, ['selected_control_points_' currentDate '_%d.txt']), fileNames);
    experimentCount = max(counts) + 1;  % 最大计数加1
end

% 生成输出文件名
outputFileName = fullfile(outputFolder, ['selected_control_points_' currentDate '_' num2str(experimentCount) '.txt']);

% 创建文件并写入数据
fileID = fopen(outputFileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n');  % 表头
for i = 1:length(x1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', x1(i), y1(i), x2(i), y2(i));
end
fclose(fileID);

disp(['控制点已保存到文件：' outputFileName]);
