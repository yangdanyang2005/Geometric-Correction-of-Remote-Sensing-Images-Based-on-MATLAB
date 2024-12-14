%% 预备工作
% tic; % 总计时开始
clc; % 清除命令行窗口
clear; % 清空工作区中的变量
format compact % 紧凑格式输出
close all; % 关闭所有图形窗口

% 创建日志文件夹
logFolder = 'log_control';
if ~exist(logFolder, 'dir')
    mkdir(logFolder);
end

% 创建数据文件夹
logFolder = 'data_control';
if ~exist(logFolder, 'dir')
    mkdir(logFolder);
end

% 获取当前日期和时间
currentDate = datetime("now", 'Format', 'yyyyMMdd');  % 格式：20241119
currentTime = datetime("now", 'Format', 'HHmmss');    % 格式：时分秒，例如 153045

% 查找日志文件名中已有的次数
experimentCount = 1; % 初始次数为1
while exist(['log_control/process_log_' char(currentDate) '_' num2str(experimentCount) '.txt'], 'file') == 2
    experimentCount = experimentCount + 1; % 如果文件已存在，则增加次数
end

% 生成动态文件名
logFileName = ['log_control/process_log_' char(currentDate) '_' num2str(experimentCount) '.txt'];

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

%% 读取原图数据
tic; % 开始计时
img = imread('img_control/扭曲图片.png'); % 读取原图
disp(['读取原图数据耗时: ', num2str(toc), '秒']);

subplot(2, 6, [1 2]);
imshow(img);
title('原扭曲图片');

% 获取原图尺寸
[height, width, ~] = size(img);

tic; % 开始计时
% 提取原图的 RGB 三个通道
R = img(:, :, 1);
G = img(:, :, 2);
B = img(:, :, 3);
disp(['提取原图的 RGB 三通道耗时: ', num2str(toc), '秒']);

tic; % 开始计时
% 将 RGB 转换为表格显示格式
[X, Y] = meshgrid(1:width, 1:height);
xCoord = reshape(X, [], 1);
yCoord = reshape(Y, [], 1);
rgbMatrix = [yCoord, xCoord, reshape(R, [], 1), reshape(G, [], 1), reshape(B, [], 1)];

% 创建表格数据
columnNames = {'Y (行)', 'X (列)', '红', '绿', '蓝'};
rgbTable = array2table(rgbMatrix, 'VariableNames', columnNames);

% 保存表格数据到 txt 文件
writetable(rgbTable, 'data_control/RGB_Matrix.txt', 'Delimiter', '\t');
disp(['写入 RGB 三通道数据到 RGB_Matrix.txt 耗时: ', num2str(toc), '秒']);

% 创建弹窗显示 RGB 矩阵
fig = uifigure('Name', 'RGB 矩阵显示', 'Position', [100, 100, 600, 400]);
uitable(fig, 'Data', rgbTable, 'Position', [20, 20, 560, 360], 'ColumnName', columnNames);

%% 查找顶点坐标
disp('--------------------------------------------------');
tic; % 开始计时
topLeft = [];
topRight = [];
bottomLeft = [];
bottomRight = [];

isWhite = @(pixel) all(pixel == 255);

% 左上角：从上往下，从左到右扫描
for y = 1:height
    for x = 1:width
        if ~isWhite(img(y, x, :))
            topLeft = [y, x];
            break;
        end
    end
    if ~isempty(topLeft)
        break;
    end
end

% 左下角：从下往上，从左到右扫描
for y = height:-1:1
    for x = 1:width
        if ~isWhite(img(y, x, :))
            bottomLeft = [y, x];
            break;
        end
    end
    if ~isempty(bottomLeft)
        break;
    end
end

% 右上角：从上往下，从右到左扫描
for y = 1:height
    for x = width:-1:1
        if ~isWhite(img(y, x, :))
            topRight = [y, x];
            break;
        end
    end
    if ~isempty(topRight)
        break;
    end
end

% 计算右下角点
bottomRight = topRight + (bottomLeft - topLeft);

% 输出顶点坐标
disp('找到的图片的四个顶点坐标:');
disp(['左上角: ', mat2str(topLeft)]);
disp(['右上角: ', mat2str(topRight)]);
disp(['左下角: ', mat2str(bottomLeft)]);
disp(['右下角: ', mat2str(bottomRight)]);
disp('--------------------------------------------------');
disp(['查找顶点耗时: ', num2str(toc), '秒']);

% 提取裁剪范围（最小最大范围）
tic; % 开始计时
cropXMin = min([topLeft(2), topRight(2), bottomLeft(2), bottomRight(2)]);
cropXMax = max([topLeft(2), topRight(2), bottomLeft(2), bottomRight(2)]);
cropYMin = min([topLeft(1), topRight(1), bottomLeft(1), bottomRight(1)]);
cropYMax = max([topLeft(1), topRight(1), bottomLeft(1), bottomRight(1)]);

% 确保范围不超出图片尺寸
cropXMin = max(cropXMin, 1);
cropXMax = min(cropXMax, width);
cropYMin = max(cropYMin, 1);
cropYMax = min(cropYMax, height);

% 裁剪图片
croppedImg = img(cropYMin:cropYMax, cropXMin:cropXMax, :);

subplot(2, 6, [3 4]);
imshow(croppedImg);
title('裁剪后的图片');

% 保存裁剪结果
imwrite(croppedImg, 'img_control/裁剪后的图片.png');

% 转换为行列顺序
inputCorners = [topLeft; topRight; bottomLeft; bottomRight];

disp(['裁剪图片耗时: ', num2str(toc), '秒']);

%% 透视变换
tic; % 开始计时
outputWidth = 2048;
outputHeight = 1032;
outputCorners = [1, 1; outputWidth, 1; 1, outputHeight; outputWidth, outputHeight];

tform = fitgeotrans(inputCorners(:, [2, 1]), outputCorners, 'projective'); % 注意行列转换
warpedImg = imwarp(img, tform, 'OutputView', imref2d([outputHeight, outputWidth]));

% 上面这两行代码的作用是执行图片的透视变换，具体步骤如下：
% 
% 1. tform = fitgeotrans(inputCorners(:, [2, 1]), outputCorners, 'projective');
% 这一行使用了 fitgeotrans 函数来计算从源图片（原始图片）到目标图片（目标输出尺寸和视角）的变换矩阵。
% fitgeotrans 是 MATLAB 中用于几何变换的函数，可以根据对应的点对计算透视变换矩阵。
% 
% inputCorners(:, [2, 1])：这里你传入了源图片的四个顶点坐标作为 inputCorners。
% inputCorners 包含四个点：左上角、右上角、左下角和右下角。
% 这里使用了 (:, [2, 1]) 来交换 x 和 y 坐标的顺序，原因是 MATLAB 的 fitgeotrans 函数期望输入的坐标顺序是 [X, Y]，而不是 [Y, X]。
% 这就意味着源图片的顶点坐标 [y, x] 被转换为 [x, y] 的形式。
% 
% outputCorners：这是目标图片的四个角点坐标，指定了图片在透视变换后的目标位置，
% 假设目标图片的尺寸为 2048x1032，且角点按顺序排列为左上角、右上角、左下角和右下角。
% 
% 'projective'：这个参数指定了变换类型为透视变换。
% 透视变换能够处理图片的倾斜、扭曲等问题，适用于校正和对齐不同视角下的图片。
% 
% fitgeotrans 函数会返回一个变换对象 tform，它包含了从源图片到目标图片的透视变换矩阵。
% 
% 2. warpedImg = imwarp(img, tform, 'OutputView', imref2d([outputHeight, outputWidth]));
% 这一行代码使用 imwarp 函数对原始图片进行透视变换。
% 
% img：原始图片，将被透视变换处理。
% tform：前一步计算得到的变换对象，包含了透视变换所需的矩阵信息。
% 'OutputView', imref2d([outputHeight, outputWidth])：OutputView 参数指定了变换后图片的尺寸和坐标系统。
% imref2d([outputHeight, outputWidth]) 创建了一个 2D 空间的坐标参考对象，
% 指定了目标图片的大小为 [outputHeight, outputWidth]（2048x1032）。
% 这意味着目标图片将根据指定的尺寸进行变换，imwarp 会将源图片中的内容映射到这个目标空间。
% imwarp 函数根据 tform 计算出新的图片并返回给 warpedImg，这就是经过透视变换后的图片。

disp(['透视变换耗时: ', num2str(toc), '秒']);

% 打印透视变换矩阵
disp('透视变换矩阵：');
disp(tform.T);

subplot(2, 6, [5 6]);
imshow(warpedImg);
title('复原图片');

% 保存复原结果
imwrite(warpedImg, 'img_control/复原图片.png');

% 保存复原图片的矩阵数据到文件
csvwrite('data_control/复原图片矩阵.csv', warpedImg);
disp('复原图片的矩阵数据已保存为复原图片矩阵.csv');


%% 拉伸图片至 2048x1432
% 将复原图片拉伸到 2048x1432
tic; % 开始计时
stretchedImg = imresize(warpedImg, [1432, 2048]);
disp(['拉伸图片耗时: ', num2str(toc), '秒']);

% 显示拉伸后的图片
subplot(2, 6, [7 9]);
imshow(stretchedImg);
title('拉伸后的图片');

% 保存拉伸结果
imwrite(stretchedImg, 'img_control/复原拉伸图片.png');

%% 计算 PSNR
% 读取原始正常图片（可能需要调整为相同大小或确保两图片尺寸一致）
fineImg = imread('img_control/正常图片.png');
% 显示原始正常图片
subplot(2, 6, [10 12]);
imshow(fineImg);
title('正常图片');

% 计算 PSNR
psnrValue = psnr(stretchedImg, fineImg);
disp('--------------------------------------------------');
disp(['复原拉伸图片与正常图片的 PSNR 值: ', num2str(psnrValue)]);

% 添加窗口标题
sgtitle('图片几何变换纠正处理'); % 添加整个图形窗口的标题

% 结束总计时
diary off; % 关闭日志记录
% disp(['总运行时间: ', num2str(toc1), '秒']);
disp('--------------------------------------------------');
disp(['日志文件已保存为: ', logFileName]);