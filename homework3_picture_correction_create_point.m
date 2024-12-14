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
while exist(['log/create_log_' char(currentDate) '_' num2str(experimentCount) '.txt'], 'file') == 2
    experimentCount = experimentCount + 1; % 如果文件已存在，则增加次数
end

% 生成动态文件名
logFileName = ['log/create_log_' char(currentDate) '_' num2str(experimentCount) '.txt'];

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

%% 使用SURF自动选取控制点
tic; % 计时开始

% 读取图像
normalImg = imread('img/武汉参考影像.png'); % 参考影像
distortedImg = imread('img/武汉待校正影像.png'); % 待校正影像

% 转换为灰度图像
grayNormalImg = rgb2gray(normalImg);
grayDistortedImg = rgb2gray(distortedImg);

% 检测SURF特征点
points1 = detectSURFFeatures(grayNormalImg);
points2 = detectSURFFeatures(grayDistortedImg);

% 提取特征描述符
[features1, validPoints1] = extractFeatures(grayNormalImg, points1);
[features2, validPoints2] = extractFeatures(grayDistortedImg, points2);

% 匹配特征
indexPairs = matchFeatures(features1, features2);

% 获取匹配的控制点
matchedPoints1_SURF = validPoints1(indexPairs(:, 1), :);
matchedPoints2_SURF = validPoints2(indexPairs(:, 2), :);

% 可视化匹配结果
subplot(321);
showMatchedFeatures(normalImg, distortedImg, matchedPoints1_SURF, matchedPoints2_SURF, 'montage');
title('SURF匹配结果');

disp(['步骤 1-1: 使用 SURF 选取控制点, 耗时：', num2str(toc), '秒']);

% 保存 SURF 匹配点到文件
SURF_FileName = ['data/each_point/SURF_points_' char(currentDate) '_' num2str(experimentCount) '.txt'];
fileID = fopen(SURF_FileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
for i = 1:size(matchedPoints1_SURF, 1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
        matchedPoints1_SURF.Location(i, 1), matchedPoints1_SURF.Location(i, 2), ...
        matchedPoints2_SURF.Location(i, 1), matchedPoints2_SURF.Location(i, 2));
end
fclose(fileID);
disp(['SURF 匹配点已保存到文件：' SURF_FileName]);

%% 使用 Harris 角点检测选择控制点
tic; % 计时开始

% 使用 Harris 角点检测
harrisPoints1 = detectHarrisFeatures(grayNormalImg);
harrisPoints2 = detectHarrisFeatures(grayDistortedImg);

% 提取特征描述符
[features1, validPoints1] = extractFeatures(grayNormalImg, harrisPoints1);
[features2, validPoints2] = extractFeatures(grayDistortedImg, harrisPoints2);

% 匹配特征
indexPairs = matchFeatures(features1, features2);

% 获取匹配的控制点
matchedPoints1_Harris = validPoints1(indexPairs(:, 1), :);
matchedPoints2_Harris = validPoints2(indexPairs(:, 2), :);

% 可视化匹配结果
subplot(322);
showMatchedFeatures(normalImg, distortedImg, matchedPoints1_Harris, matchedPoints2_Harris, 'montage');
title('Harris角点匹配结果');

disp(['步骤 1-2: 使用 Harris 角点检测选择控制点, 耗时：', num2str(toc), '秒']);

% 保存 Harris 匹配点到文件
Harris_FileName = ['data/each_point/Harris_points_' char(currentDate) '_' num2str(experimentCount) '.txt'];
fileID = fopen(Harris_FileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
for i = 1:size(matchedPoints1_Harris, 1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
        matchedPoints1_Harris.Location(i, 1), matchedPoints1_Harris.Location(i, 2), ...
        matchedPoints2_Harris.Location(i, 1), matchedPoints2_Harris.Location(i, 2));
end
fclose(fileID);
disp(['Harris 匹配点已保存到文件：' Harris_FileName]);

%% 使用 Shi-Tomasi 角点检测选择控制点
tic; % 计时开始

% 使用 Shi-Tomasi 角点检测
shiTomasiPoints1 = detectMinEigenFeatures(grayNormalImg);
shiTomasiPoints2 = detectMinEigenFeatures(grayDistortedImg);

% 提取特征描述符
[features1, validPoints1] = extractFeatures(grayNormalImg, shiTomasiPoints1);
[features2, validPoints2] = extractFeatures(grayDistortedImg, shiTomasiPoints2);

% 匹配特征
indexPairs = matchFeatures(features1, features2);

% 获取匹配的控制点
matchedPoints1_ShiTomasi = validPoints1(indexPairs(:, 1), :);
matchedPoints2_ShiTomasi = validPoints2(indexPairs(:, 2), :);

% 可视化匹配结果
subplot(323);
showMatchedFeatures(normalImg, distortedImg, matchedPoints1_ShiTomasi, matchedPoints2_ShiTomasi, 'montage');
title('Shi-Tomasi角点匹配结果');

disp(['步骤 1-3: 使用 Shi-Tomasi 角点检测选择控制点, 耗时：', num2str(toc), '秒']);

% 保存 Shi-Tomasi 匹配点到文件
Shi_Tomasi_FileName = ['data/each_point/Shi_Tomasi_points_' char(currentDate) '_' num2str(experimentCount) '.txt'];
fileID = fopen(Shi_Tomasi_FileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
for i = 1:size(matchedPoints1_ShiTomasi, 1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
        matchedPoints1_ShiTomasi.Location(i, 1), matchedPoints1_ShiTomasi.Location(i, 2), ...
        matchedPoints2_ShiTomasi.Location(i, 1), matchedPoints2_ShiTomasi.Location(i, 2));
end
fclose(fileID);
disp(['Shi-Tomasi 匹配点已保存到文件：' Shi_Tomasi_FileName]);

%% 使用 SIFT 选择控制点
tic; % 计时开始

% 使用 SIFT 特征检测
siftPoints1 = detectSIFTFeatures(grayNormalImg);
siftPoints2 = detectSIFTFeatures(grayDistortedImg);

% 提取特征描述符
[features1, validPoints1] = extractFeatures(grayNormalImg, siftPoints1);
[features2, validPoints2] = extractFeatures(grayDistortedImg, siftPoints2);

% 匹配特征
indexPairs = matchFeatures(features1, features2);

% 获取匹配的控制点
matchedPoints1_SIFT = validPoints1(indexPairs(:, 1), :);
matchedPoints2_SIFT = validPoints2(indexPairs(:, 2), :);

% 可视化匹配结果
subplot(324);
showMatchedFeatures(normalImg, distortedImg, matchedPoints1_SIFT, matchedPoints2_SIFT, 'montage');
title('SIFT特征匹配结果');

disp(['步骤 1-4: 使用 SIFT 选择控制点, 耗时：', num2str(toc), '秒']);

% 保存 SIFT 匹配点到文件
SIFT_FileName = ['data/each_point/SIFT_points_' char(currentDate) '_' num2str(experimentCount) '.txt'];
fileID = fopen(SIFT_FileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
for i = 1:size(matchedPoints1_SIFT, 1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
        matchedPoints1_SIFT.Location(i, 1), matchedPoints1_SIFT.Location(i, 2), ...
        matchedPoints2_SIFT.Location(i, 1), matchedPoints2_SIFT.Location(i, 2));
end
fclose(fileID);
disp(['SIFT 匹配点已保存到文件：' SIFT_FileName]);

%% 使用 ORB 选择控制点
tic; % 计时开始

% 使用 ORB 特征检测
orbPoints1 = detectORBFeatures(grayNormalImg);
orbPoints2 = detectORBFeatures(grayDistortedImg);

% 提取特征描述符
[features1, validPoints1] = extractFeatures(grayNormalImg, orbPoints1);
[features2, validPoints2] = extractFeatures(grayDistortedImg, orbPoints2);

% 匹配特征
indexPairs = matchFeatures(features1, features2);

% 获取匹配的控制点
matchedPoints1_ORB = validPoints1(indexPairs(:, 1), :);
matchedPoints2_ORB = validPoints2(indexPairs(:, 2), :);

% 可视化匹配结果
subplot(325);
showMatchedFeatures(normalImg, distortedImg, matchedPoints1_ORB, matchedPoints2_ORB, 'montage');
title('ORB特征匹配结果');

disp(['步骤 1-5: 使用 ORB 选择控制点, 耗时：', num2str(toc), '秒']);
% 保存 ORB 匹配点到文件
ORB_FileName = ['data/each_point/ORB_points_' char(currentDate) '_' num2str(experimentCount) '.txt'];
fileID = fopen(ORB_FileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
for i = 1:size(matchedPoints1_ORB, 1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
        matchedPoints1_ORB.Location(i, 1), matchedPoints1_ORB.Location(i, 2), ...
        matchedPoints2_ORB.Location(i, 1), matchedPoints2_ORB.Location(i, 2));
end
fclose(fileID);
disp(['ORB 匹配点已保存到文件：' ORB_FileName]);

%% 使用 FAST 角点检测选择控制点
tic; % 计时开始

% 使用 FAST 特征检测
fastPoints1 = detectFASTFeatures(grayNormalImg);
fastPoints2 = detectFASTFeatures(grayDistortedImg);

% 提取特征描述符
[features1, validPoints1] = extractFeatures(grayNormalImg, fastPoints1);
[features2, validPoints2] = extractFeatures(grayDistortedImg, fastPoints2);

% 匹配特征
indexPairs = matchFeatures(features1, features2);

% 获取匹配的控制点
matchedPoints1_FAST = validPoints1(indexPairs(:, 1), :);
matchedPoints2_FAST = validPoints2(indexPairs(:, 2), :);

% 可视化匹配结果
subplot(326);
showMatchedFeatures(normalImg, distortedImg, matchedPoints1_FAST, matchedPoints2_FAST, 'montage');
title('FAST特征匹配结果');

disp(['步骤 1-6: 使用 FAST 选择控制点, 耗时：', num2str(toc), '秒']);

% 保存 FAST 匹配点到文件
FAST_FileName = ['data/each_point/FAST_points_' char(currentDate) '_' num2str(experimentCount) '.txt'];
fileID = fopen(FAST_FileName, 'w');
fprintf(fileID, 'x1\ty1\tx2\ty2\n'); % 表头
for i = 1:size(matchedPoints1_FAST, 1)
    fprintf(fileID, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
        matchedPoints1_FAST.Location(i, 1), matchedPoints1_FAST.Location(i, 2), ...
        matchedPoints2_FAST.Location(i, 1), matchedPoints2_FAST.Location(i, 2));
end
fclose(fileID);
disp(['FAST 匹配点已保存到文件：' FAST_FileName]);
disp('--------------------------------------------------');
%% 合并所有方法的匹配控制点
% 初始化所有方法的控制点
allMatchedPoints1 = [];
allMatchedPoints2 = [];

% 合并SURF、Harris、Shi-Tomasi、SIFT、ORB、FAST的控制点
allMatchedPoints1 = [allMatchedPoints1; matchedPoints1_SURF.Location]; % 这里提取位置数据
allMatchedPoints2 = [allMatchedPoints2; matchedPoints2_SURF.Location];

allMatchedPoints1 = [allMatchedPoints1; matchedPoints1_Harris.Location];
allMatchedPoints2 = [allMatchedPoints2; matchedPoints2_Harris.Location];

allMatchedPoints1 = [allMatchedPoints1; matchedPoints1_ShiTomasi.Location];
allMatchedPoints2 = [allMatchedPoints2; matchedPoints2_ShiTomasi.Location];

allMatchedPoints1 = [allMatchedPoints1; matchedPoints1_SIFT.Location];
allMatchedPoints2 = [allMatchedPoints2; matchedPoints2_SIFT.Location];

allMatchedPoints1 = [allMatchedPoints1; matchedPoints1_ORB.Location];
allMatchedPoints2 = [allMatchedPoints2; matchedPoints2_ORB.Location];

allMatchedPoints1 = [allMatchedPoints1; matchedPoints1_FAST.Location];
allMatchedPoints2 = [allMatchedPoints2; matchedPoints2_FAST.Location];

% 去除重复的控制点
[uniquePoints1, uniqueIdx1] = unique(allMatchedPoints1, 'rows');
uniquePoints2 = allMatchedPoints2(uniqueIdx1, :);

% 确保至少有4对匹配点
disp(['共计产生的控制点数量为：', num2str(size(uniquePoints1, 1))])
if size(uniquePoints1, 1) < 4
    error('控制点数量不足，无法进行几何变换');
end

% 可视化匹配结果
figure;
% subplot(211);
showMatchedFeatures(normalImg, distortedImg, allMatchedPoints1, allMatchedPoints2, 'montage');
title('产生的所有控制点匹配结果');

% %% 建立多项式变换模型
% tic; % 计时开始
% numPoints = size(allMatchedPoints1, 1);
% normalPoints = allMatchedPoints1; % 参考图像中的控制点
% distortedPoints = allMatchedPoints2; % 待校正图像中的控制点
% 
% % 建立变换模型
% A_x = [];
% A_y = [];
% b_x = distortedPoints(:, 1); 
% b_y = distortedPoints(:, 2);
% 
% for i = 1:numPoints
%     x = normalPoints(i, 1);
%     y = normalPoints(i, 2);
%     A_x = [A_x; x, y, 1, x^2, x*y, y^2];
%     A_y = [A_y; x, y, 1, x^2, x*y, y^2];
% end
% 
% coeff_x = A_x \ b_x; % x 方向的多项式系数
% coeff_y = A_y \ b_y; % y 方向的多项式系数
% 
% disp(['步骤 2: 建立多项式变换模型, 耗时：', num2str(toc), '秒']);
% disp('--------------------------------------------------');
% 
% %% 进行几何纠正
% tic; % 计时开始
% [height, width, ~] = size(distortedImg);
% correctedImg = uint8(zeros(height, width, 3));
% 
% for i = 1:height
%     for j = 1:width
%         x_prime = coeff_x(1)*j + coeff_x(2)*i + coeff_x(3) + coeff_x(4)*j^2 + coeff_x(5)*j*i + coeff_x(6)*i^2;
%         y_prime = coeff_y(1)*j + coeff_y(2)*i + coeff_y(3) + coeff_y(4)*j^2 + coeff_y(5)*j*i + coeff_y(6)*i^2;
% 
%         if x_prime >= 1 && x_prime <= width && y_prime >= 1 && y_prime <= height
%             correctedImg(i, j, :) = distortedImg(round(y_prime), round(x_prime), :);
%         end
%     end
% end
% 
% 纠正后的图像显示和保存
% subplot(212);
% imshow(correctedImg);
% title('几何纠正后的影像');
% imwrite(correctedImg, '遥感影像2（纠正后影像）.png');
% 
% disp(['步骤 3: 进行几何纠正, 耗时：', num2str(toc), '秒']);
% 
% diary off; % 关闭日志记录
% disp('--------------------------------------------------');
% disp('产生控制点的所有步骤完成！');