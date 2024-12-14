%% 预备工作
clc; % 清除命令行窗口
clear; % 清空工作区中的变量
format compact; % 紧凑格式输出
close all; % 关闭所有图形窗口

% 创建日志文件夹
logFolder = 'log';
if ~exist(logFolder, 'dir')
    mkdir(logFolder);
end

% 创建控制点文件夹
pointFolder = 'data';
if ~exist(pointFolder, 'dir')
    mkdir(pointFolder);
end

% 获取当前日期和时间
currentDate = datetime("now", 'Format', 'yyyyMMdd');  % 格式：20241119
currentTime = datetime("now", 'Format', 'HHmmss');    % 格式：时分秒，例如 153045

% 查找日志文件名中已有的次数
experimentCount = 1; % 初始次数为1
while exist(['log/load_log_' char(currentDate) '_' num2str(experimentCount) '.txt'], 'file') == 2
    experimentCount = experimentCount + 1; % 如果文件已存在，则增加次数
end

% 生成动态文件名
logFileName = ['log/load_log_' char(currentDate) '_' num2str(experimentCount) '.txt'];

% 设置日志文件
diary(logFileName); % 启用日志记录
diary on; % 开始记录所有命令行输出

% 显示实验信息
currentDate1 = datetime("now", 'Format', 'yyyy年MM月dd日');  % 格式：2024年11月19日
currentTime1 = datetime("now", 'Format', 'HH时mm分ss秒');    % 格式：时分秒，例如 15时30分45秒

disp(['实验日期：', char(currentDate1)]); % 显示实验日期
disp(['实验时间：', char(currentTime1)]); % 显示实验时间
disp(['实验编号：', num2str(experimentCount)]); % 显示实验编号
disp('--------------------------------------------------');

% 读取图像
normalImg = imread('img/武汉参考影像.png'); % 参考影像
distortedImg = imread('img/武汉待校正影像.png'); % 待校正影像

% 转换为灰度图像
grayNormalImg = rgb2gray(normalImg);
grayDistortedImg = rgb2gray(distortedImg);

%% 从文件读取控制点
shiTomasiFileName = 'data/control_point_data.txt';
% 初始化存储数组
shiTomasiData = [];

% 检查是否已经存在控制点坐标文件
if exist(shiTomasiFileName, 'file')
    % 如果文件存在，直接加载坐标
    disp(['检测到控制点坐标文件：', shiTomasiFileName, '！']);
else
    % 如果文件不存在，手动选择控制点
    figure, imshow(distortedImg);
    hold on;
    [x_distorted, y_distorted] = ginput(); % 选择多个点
    plot(x_distorted, y_distorted, 'ro');
    hold off;

    % 确保选择的点数不少于 4 个
    while length(x_distorted) < 4
        disp('请选择至少 4 个点！');
        [x_distorted, y_distorted] = ginput(); % 重新选择
    end

    % 手动选择正常图像上的对应点
    figure, imshow(normalImg);
    hold on;
    [x_original, y_original] = ginput(); % 选择与扭曲图像对应的多个点
    plot(x_original, y_original, 'y+');
    hold off;

    % 确保选择的点数与扭曲图像上的点数一致
    while length(x_original) ~= length(x_distorted)
        disp('请确保选择的点数与扭曲图像上的点数一致！');
        [x_original, y_original] = ginput(); % 重新选择
        plot(x_original, y_original, 'y+');
        hold off;
    end

    % 保存控制点坐标到文件
    fileID = fopen(shiTomasiFileName, 'w');
    fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
    for i = 1:length(x_original)
        fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
            x_original(i), y_original(i), ...
            x_distorted(i), y_distorted(i));
    end
    fclose(fileID);
    disp(['手动选择的控制点已保存到文件：' shiTomasiFileName]);
end

tic; % 计时开始
% 逐行读取文件
fileID = fopen(shiTomasiFileName, 'r');
fgetl(fileID); % 跳过表头
% 初始化存储数组
shiTomasiData = [];
while ~feof(fileID)
    line = fgetl(fileID); % 读取一行
    % 检查是否是有效行（非空且不以%开头）
    if ~isempty(line) && ~startsWith(strtrim(line), '%')
        % 按格式解析数据
        data = sscanf(line, '%f %f %f %f');
        if numel(data) == 4 % 确保读取到的是4列数据
            shiTomasiData = [shiTomasiData; data']; % 添加到结果中
        end
    end
end
fclose(fileID);

fileID = fopen(shiTomasiFileName, 'r');
fgetl(fileID); % 跳过表头

% 提取匹配点
allMatchedPoints1 = shiTomasiData(:, 1:2); % 第1列和第2列
allMatchedPoints2 = shiTomasiData(:, 3:4); % 第3列和第4列

% 去除重复的控制点
[uniquePoints1, uniqueIdx1] = unique(allMatchedPoints1, 'rows');
uniquePoints2 = allMatchedPoints2(uniqueIdx1, :);

% 确保至少有4对控制点
disp(['共计产生的控制点数量为：', num2str(size(uniquePoints1, 1))])
if size(uniquePoints1, 1) < 4
    error('控制点数量不足，无法进行几何变换');
end

disp(['步骤 1: 获取控制点数据, 耗时：', num2str(toc), '秒']);
disp('--------------------------------------------------');

% 可视化匹配结果
subplot(211);
showMatchedFeatures(normalImg, distortedImg, allMatchedPoints1, allMatchedPoints2, 'montage');
title('最终使用的所有控制点匹配结果');

%% 建立多项式变换模型
tic; % 计时开始
numPoints = size(allMatchedPoints1, 1);
normalPoints = allMatchedPoints1; % 参考图像中的控制点
distortedPoints = allMatchedPoints2; % 待校正图像中的控制点

% 建立变换模型
A_x = [];
A_y = [];
b_x = distortedPoints(:, 1); 
b_y = distortedPoints(:, 2);

for i = 1:numPoints
    x = normalPoints(i, 1);
    y = normalPoints(i, 2);
    % 增加二次多项式项
    A_x = [A_x; x^2, x*y, y^2, x, y, 1];
    A_y = [A_y; x^2, x*y, y^2, x, y, 1];
end

coeff_x = A_x \ b_x; % x 方向的多项式系数
coeff_y = A_y \ b_y; % y 方向的多项式系数

disp(['步骤 2: 建立多项式变换模型, 耗时：', num2str(toc), '秒']);
disp('--------------------------------------------------');

%% 进行几何纠正
tic; % 计时开始
% 待纠正图像尺寸
[height,width,~]=size(distortedImg);
% 目标图像尺寸
[height1,width1,~]=size(normalImg);
% 初始化一个空的图像
correctedImg=uint8(zeros(height1,width1,3));

% 遍历每个像素
for i = 1:height1
    for j = 1:width1
        % 使用二次多项式进行变换
        x_prime = coeff_x(1)*j^2 + coeff_x(2)*j*i + coeff_x(3)*i^2 + coeff_x(4)*j + coeff_x(5)*i + coeff_x(6);
        y_prime = coeff_y(1)*j^2 + coeff_y(2)*j*i + coeff_y(3)*i^2 + coeff_y(4)*j + coeff_y(5)*i + coeff_y(6);

        if x_prime >= 1 && x_prime <= width && y_prime >= 1 && y_prime <= height
            correctedImg(i, j, :) = distortedImg(round(y_prime), round(x_prime), :);
        end
    end
end

% 显示纠正后的图像
subplot(212);
imshow(correctedImg);
title('几何校正后的影像');
imwrite(correctedImg, 'img/武汉校正后影像.png');

disp(['步骤 3: 进行几何纠正, 耗时：', num2str(toc), '秒']);
disp('--------------------------------------------------');

%% 计算PSNR
tic; % 计时开始

% 确保原始参考图像和几何纠正后的图像具有相同的大小
[correctedHeight, correctedWidth, ~] = size(correctedImg);
croppedNormalImg = normalImg(1:correctedHeight, 1:correctedWidth, :);

% 转换为灰度图像用于计算PSNR
correctedGrayImg = rgb2gray(correctedImg);
croppedGrayNormalImg = rgb2gray(croppedNormalImg);

% 计算均方误差(MSE)
mse = mean((double(correctedGrayImg) - double(croppedGrayNormalImg)).^2, 'all');

% 计算PSNR
if mse == 0
    psnrValue = Inf; % 如果MSE为0，PSNR为无穷大
else
    maxPixelValue = 255; % 对于8位图像，像素值范围为0到255
    psnrValue = 10 * log10(maxPixelValue^2 / mse);
end

disp(['步骤 4: 计算PSNR, 耗时：', num2str(toc), '秒']);
disp(['几何纠正后的图像与参考图像的PSNR值为：', num2str(psnrValue), ' dB']);

diary off; % 关闭日志记录
disp('--------------------------------------------------');
disp('所有步骤完成！');