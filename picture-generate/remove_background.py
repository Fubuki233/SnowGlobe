"""
AI生成伪像素画背景剔除工具
从四角向中心侵蚀，剔除背景色，保留角色主体

使用方法:
    python remove_background.py <图片路径> [颜色容差]
    
示例:
    python remove_background.py extracted_frames/frame_000.png
    python remove_background.py extracted_frames/frame_000.png 30
"""

import os
import sys
import numpy as np
from PIL import Image
from multiprocessing import Pool, cpu_count
from functools import partial
import colorsys

def get_edge_average_colors(image, edge_size=10, sample_points=5):
    """
    获取四边的平均颜色（多点采样）
    
    参数:
        image: PIL Image对象
        edge_size: 边缘采样厚度
        sample_points: 每条边采样点数量
    
    返回:
        检测到的背景色列表 [(R, G, B), ...]
    """
    img_array = np.array(image.convert('RGB'))
    h, w = img_array.shape[:2]
    
    bg_colors = []
    
    # 上边 - 多点采样
    for i in range(sample_points):
        x = int(w * (i + 1) / (sample_points + 1))
        sample = img_array[0:edge_size, max(0, x-edge_size):min(w, x+edge_size)]
        if sample.size > 0:
            bg_colors.append(tuple(np.mean(sample.reshape(-1, 3), axis=0).astype(int)))
    
    # 下边
    for i in range(sample_points):
        x = int(w * (i + 1) / (sample_points + 1))
        sample = img_array[h-edge_size:h, max(0, x-edge_size):min(w, x+edge_size)]
        if sample.size > 0:
            bg_colors.append(tuple(np.mean(sample.reshape(-1, 3), axis=0).astype(int)))
    
    # 左边
    for i in range(sample_points):
        y = int(h * (i + 1) / (sample_points + 1))
        sample = img_array[max(0, y-edge_size):min(h, y+edge_size), 0:edge_size]
        if sample.size > 0:
            bg_colors.append(tuple(np.mean(sample.reshape(-1, 3), axis=0).astype(int)))
    
    # 右边
    for i in range(sample_points):
        y = int(h * (i + 1) / (sample_points + 1))
        sample = img_array[max(0, y-edge_size):min(h, y+edge_size), w-edge_size:w]
        if sample.size > 0:
            bg_colors.append(tuple(np.mean(sample.reshape(-1, 3), axis=0).astype(int)))
    
    # 聚类相似颜色
    unique_colors = []
    for color in bg_colors:
        is_new = True
        for uc in unique_colors:
            if color_distance(color, uc) < 30:
                is_new = False
                break
        if is_new:
            unique_colors.append(color)
    
    print(f"检测到 {len(unique_colors)} 种背景色:")
    for i, color in enumerate(unique_colors):
        print(f"  颜色 {i+1}: RGB{color}")
    
    return unique_colors

def color_distance(color1, color2):
    """计算两个颜色的欧氏距离"""
    return np.sqrt(sum((c1 - c2) ** 2 for c1, c2 in zip(color1, color2)))

def is_greenish(rgb_color):
    """
    判断颜色是否偏绿色系
    
    参数:
        rgb_color: (R, G, B) 元组
    
    返回:
        bool: 是否为绿色系
    """
    r, g, b = rgb_color
    
    # 转换为HSV色彩空间
    h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
    
    # 绿色色相范围: 80-160度 (0.22-0.44)
    # 饱和度阈值: > 0.15 (排除灰色)
    is_green_hue = 0.22 <= h <= 0.44
    has_saturation = s > 0.15
    
    return is_green_hue and has_saturation

def is_similar_to_background(pixel_color, bg_colors, tolerance, aggressive_green=True):
    """
    改进的背景判断：支持多策略
    
    参数:
        pixel_color: 待判断像素颜色 (R, G, B)
        bg_colors: 背景色列表
        tolerance: 基础容差
        aggressive_green: 是否对绿色系采用激进移除策略
    
    返回:
        bool: 是否应该移除
    """
    # 策略1: 标准颜色距离匹配
    for bg_color in bg_colors:
        if color_distance(pixel_color, bg_color) <= tolerance:
            return True
    
    # 策略2: 对绿色系采用更宽松的判断
    if aggressive_green and is_greenish(pixel_color):
        # 检查是否接近任何背景色（扩大容差）
        for bg_color in bg_colors:
            if color_distance(pixel_color, bg_color) <= tolerance * 1.8:
                return True
    
    return False

def erode_from_edges_multi(image, bg_colors, tolerance=30, max_iterations=10000000):
    """
    从四边向中心侵蚀多种背景色，带碰壁边界检测 + 绿色残留清理
    
    参数:
        image: PIL Image对象
        bg_colors: 背景色列表 [(R, G, B), ...]
        tolerance: 颜色容差
        max_iterations: 最大迭代次数
    
    返回:
        带透明通道的PIL Image对象
    """
    # 转换为RGBA
    img_array = np.array(image.convert('RGB'))
    h, w = img_array.shape[:2]
    
    # 创建alpha通道，默认全不透明
    alpha = np.ones((h, w), dtype=np.uint8) * 255
    
    # 创建访问标记数组
    visited = np.zeros((h, w), dtype=bool)
    
    # 创建边界数组 - 记录不可越过的边界点
    boundary = np.zeros((h, w), dtype=bool)
    
    print(f"开始侵蚀背景 (容差: {tolerance})...")
    
    # 从四条边开始的侵蚀队列
    queue = []
    
    # 上边
    for x in range(w):
        if is_similar_to_background(tuple(img_array[0, x]), bg_colors, tolerance):
            queue.append((0, x))
            visited[0, x] = True
    
    # 下边
    for x in range(w):
        if is_similar_to_background(tuple(img_array[h-1, x]), bg_colors, tolerance):
            queue.append((h-1, x))
            visited[h-1, x] = True
    
    # 左边
    for y in range(h):
        if is_similar_to_background(tuple(img_array[y, 0]), bg_colors, tolerance):
            queue.append((y, 0))
            visited[y, 0] = True
    
    # 右边
    for y in range(h):
        if is_similar_to_background(tuple(img_array[y, w-1]), bg_colors, tolerance):
            queue.append((y, w-1))
            visited[y, w-1] = True
    
    # 四个方向
    directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    
    removed_count = 0
    boundary_count = 0
    iteration = 0
    
    # BFS侵蚀
    while queue and iteration < max_iterations:
        iteration += 1
        y, x = queue.pop(0)
        
        # 标记为透明
        alpha[y, x] = 0
        removed_count += 1
        
        # 检查四个方向的邻居
        for dy, dx in directions:
            ny, nx = y + dy, x + dx
            
            # 边界检查
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                # 检查是否为边界点（不可越过）
                if boundary[ny, nx]:
                    continue
                
                pixel_color = tuple(img_array[ny, nx])
                
                # 如果邻居也是背景色，加入队列
                if is_similar_to_background(pixel_color, bg_colors, tolerance):
                    queue.append((ny, nx))
                    visited[ny, nx] = True
                else:
                    # 碰壁：遇到非背景色，标记为边界
                    boundary[ny, nx] = True
                    boundary_count += 1
    
    print(f"✓ 主侵蚀完成: 移除 {removed_count} 像素 ({removed_count/(h*w)*100:.1f}%)")
    
    # === 第二阶段：清理残留的绿色边缘 ===
    print("开始清理残留边缘...")
    
    green_cleaned = 0
    
    # 遍历所有透明像素的邻居
    for y in range(h):
        for x in range(w):
            # 如果当前像素已经透明，检查其邻居
            if alpha[y, x] == 0:
                for dy, dx in directions:
                    ny, nx = y + dy, x + dx
                    
                    # 边界检查 + 邻居仍然不透明
                    if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] > 0:
                        neighbor_color = tuple(img_array[ny, nx])
                        
                        # 如果邻居是绿色系 + 接近背景色
                        if is_greenish(neighbor_color):
                            # 使用更激进的容差
                            for bg_color in bg_colors:
                                if color_distance(neighbor_color, bg_color) <= tolerance * 2.0:
                                    alpha[ny, nx] = 0
                                    green_cleaned += 1
                                    break
    
    print(f"✓ 边缘清理完成: 移除 {green_cleaned} 个绿色残留像素")
    print(f"✓ 总计移除: {removed_count + green_cleaned} 像素 ({(removed_count + green_cleaned)/(h*w)*100:.1f}%)")
    
    # 合并RGB和Alpha
    result = np.dstack((img_array, alpha))
    return Image.fromarray(result, 'RGBA')

def auto_crop_transparent(image, padding=0):
    """
    自动裁剪透明边缘，让主体"顶天立地"
    
    参数:
        image: PIL Image对象 (RGBA)
        padding: 保留的边距像素数
    
    返回:
        裁剪后的PIL Image对象
    """
    img_array = np.array(image)
    
    # 获取alpha通道
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        # 如果没有alpha通道，直接返回
        return image
    
    # 找到非透明像素的边界
    non_transparent = np.where(alpha > 0)
    
    if len(non_transparent[0]) == 0:
        # 完全透明，返回原图
        print("⚠ 警告: 图片完全透明，跳过裁剪")
        return image
    
    # 计算边界框
    y_min = max(0, non_transparent[0].min() - padding)
    y_max = min(img_array.shape[0], non_transparent[0].max() + 1 + padding)
    x_min = max(0, non_transparent[1].min() - padding)
    x_max = min(img_array.shape[1], non_transparent[1].max() + 1 + padding)
    
    # 裁剪
    cropped = image.crop((x_min, y_min, x_max, y_max))
    
    old_size = image.size
    new_size = cropped.size
    
    print(f"✓ 自动裁剪: {old_size} → {new_size} (节省 {(1 - new_size[0]*new_size[1]/(old_size[0]*old_size[1]))*100:.1f}% 空间)")
    
    return cropped

def process_image(input_path, output_path=None, tolerance=100, corner_size=10, auto_crop=True, crop_padding=0):
    """
    处理单张图片
    
    参数:
        input_path: 输入图片路径
        output_path: 输出图片路径（如果为None，自动生成）
        tolerance: 颜色容差
        corner_size: 角落采样大小
        auto_crop: 是否自动裁剪透明边缘
        crop_padding: 裁剪时保留的边距
    """
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"找不到文件: {input_path}")
    
    # 加载图片
    print(f"加载图片: {input_path}")
    image = Image.open(input_path)
    print(f"图片大小: {image.size}")
    
    # 获取边缘背景色
    bg_colors = get_edge_average_colors(image, corner_size)
    
    # 侵蚀背景
    result = erode_from_edges_multi(image, bg_colors, tolerance)
    
    # 自动裁剪透明边缘
    if auto_crop:
        result = auto_crop_transparent(result, padding=crop_padding)
    
    # 生成输出路径
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_nobg.png"
    
    # 保存结果
    result.save(output_path)
    print(f"✓ 已保存: {output_path}")
    
    return output_path

def process_single_image_wrapper(args):
    """
    包装函数用于多进程处理
    
    参数:
        args: (input_path, output_path, tolerance, edge_size, auto_crop, crop_padding) 元组
    
    返回:
        (filename, success, error_msg)
    """
    input_path, output_path, tolerance, edge_size, auto_crop, crop_padding = args
    filename = os.path.basename(input_path)
    
    try:
        process_image(input_path, output_path, tolerance, edge_size, auto_crop, crop_padding)
        return (filename, True, None)
    except Exception as e:
        return (filename, False, str(e))

def process_directory(input_dir, output_dir=None, tolerance=30, edge_size=10, num_workers=None, auto_crop=True, crop_padding=0):
    """
    批量处理目录中的所有图片（多核心并行）
    
    参数:
        input_dir: 输入目录
        output_dir: 输出目录（如果为None，创建 *_nobg 目录）
        tolerance: 颜色容差
        edge_size: 边缘采样大小
        num_workers: 工作进程数（默认为CPU核心数）
        auto_crop: 是否自动裁剪透明边缘
        crop_padding: 裁剪时保留的边距
    """
    if not os.path.exists(input_dir):
        raise FileNotFoundError(f"找不到目录: {input_dir}")
    
    # 生成输出目录
    if output_dir is None:
        output_dir = f"{input_dir}_nobg"
    
    os.makedirs(output_dir, exist_ok=True)
    
    # 支持的图片格式
    image_exts = {'.png', '.jpg', '.jpeg', '.bmp', '.webp'}
    
    # 获取所有图片文件
    image_files = [f for f in os.listdir(input_dir) 
                   if os.path.splitext(f)[1].lower() in image_exts]
    
    if not image_files:
        print(f"× 在 {input_dir} 中没有找到图片文件")
        return
    
    # 确定工作进程数
    if num_workers is None:
        num_workers = cpu_count()
    
    print(f"找到 {len(image_files)} 个图片文件")
    print(f"输出目录: {output_dir}")
    print(f"自动裁剪: {'开启' if auto_crop else '关闭'}")
    print(f"使用 {num_workers} 个进程并行处理\n")
    
    # 准备任务列表
    tasks = []
    for filename in image_files:
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename)
        tasks.append((input_path, output_path, tolerance, edge_size, auto_crop, crop_padding))
    
    # 使用多进程池处理
    success_count = 0
    fail_count = 0
    
    with Pool(processes=num_workers) as pool:
        # 使用 imap 显示进度
        results = pool.imap(process_single_image_wrapper, tasks)
        
        for i, (filename, success, error_msg) in enumerate(results, 1):
            if success:
                print(f"[{i}/{len(image_files)}] ✓ {filename}")
                success_count += 1
            else:
                print(f"[{i}/{len(image_files)}] × {filename}: {error_msg}")
                fail_count += 1
    
    print(f"\n{'='*60}")
    print(f"批量处理完成!")
    print(f"  - 成功: {success_count}")
    print(f"  - 失败: {fail_count}")
    print(f"  - 输出目录: {output_dir}")
    print(f"{'='*60}")

def main():
    if len(sys.argv) < 2:
        print("用法: python remove_background.py <图片路径或目录> [颜色容差] [边缘大小] [进程数] [--no-crop] [--padding N]")
        print("\n参数说明:")
        print("  图片路径或目录: 必需，要处理的图片或目录")
        print("  颜色容差: 可选，默认 30 (0-255，越大容差越大)")
        print("  边缘大小: 可选，默认 10 (采样边缘的像素大小)")
        print("  进程数: 可选，默认使用所有CPU核心")
        print("  --no-crop: 可选，禁用自动裁剪透明边缘")
        print("  --padding N: 可选，裁剪时保留的边距像素数（默认0）")
        print("\n示例:")
        print("  python remove_background.py frame_000.png")
        print("  python remove_background.py frame_000.png 50")
        print("  python remove_background.py extracted_frames/")
        print("  python remove_background.py extracted_frames/ 40 15")
        print("  python remove_background.py extracted_frames/ 30 10 4  # 使用4个进程")
        print("  python remove_background.py extracted_frames/ --no-crop  # 不裁剪")
        print("  python remove_background.py extracted_frames/ --padding 5  # 保留5像素边距")
        sys.exit(1)
    
    path = sys.argv[1]
    
    # 解析参数
    tolerance = 30
    edge_size = 10
    num_workers = None
    auto_crop = True
    crop_padding = 0
    
    i = 2
    while i < len(sys.argv):
        arg = sys.argv[i]
        
        if arg == '--no-crop':
            auto_crop = False
            i += 1
        elif arg == '--padding':
            if i + 1 < len(sys.argv):
                crop_padding = int(sys.argv[i + 1])
                i += 2
            else:
                print("× 错误: --padding 需要指定像素数")
                sys.exit(1)
        elif arg.startswith('--'):
            print(f"× 错误: 未知选项 {arg}")
            sys.exit(1)
        else:
            # 位置参数
            if i == 2:
                tolerance = int(arg)
            elif i == 3:
                edge_size = int(arg)
            elif i == 4:
                num_workers = int(arg)
            i += 1
    
    try:
        if os.path.isdir(path):
            # 处理目录（多核心并行）
            process_directory(path, tolerance=tolerance, edge_size=edge_size, 
                            num_workers=num_workers, auto_crop=auto_crop, crop_padding=crop_padding)
        elif os.path.isfile(path):
            # 处理单个文件
            process_image(path, tolerance=tolerance, edge_size=edge_size, 
                         auto_crop=auto_crop, crop_padding=crop_padding)
        else:
            print(f"× 错误: 路径不存在 {path}")
            sys.exit(1)
    
    except Exception as e:
        print(f"\n× 错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
