"""
生成 Tileset 图片
包含三种地形: 草地(草绿色)、海洋(海蓝色)、石头(石青色)
每个 tile 64x64 像素
"""

from PIL import Image, ImageDraw
import os

# Tile 配置
TILE_SIZE = 64  # 每个 tile 的尺寸
TILES_PER_ROW = 3  # 每行的 tile 数量
TILE_COUNT = 3  # 总共的 tile 数量

# 颜色定义 (RGB)
COLORS = {
    "grass": (124, 252, 0),      # 草绿色 (LawnGreen)
    "water": (30, 144, 255),     # 海蓝色 (DodgerBlue)
    "stone": (70, 130, 180)      # 石青色 (SteelBlue)
}

def create_tileset(output_path="tileset.png"):
    """生成 tileset 图片"""
    
    # 计算总图片尺寸
    width = TILES_PER_ROW * TILE_SIZE
    height = ((TILE_COUNT - 1) // TILES_PER_ROW + 1) * TILE_SIZE
    
    # 创建空白图片 (带透明背景)
    tileset = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tileset)
    
    # 生成三种 tile
    tiles = [
        ("grass", COLORS["grass"]),
        ("water", COLORS["water"]),
        ("stone", COLORS["stone"])
    ]
    
    for idx, (name, color) in enumerate(tiles):
        # 计算 tile 位置
        row = idx // TILES_PER_ROW
        col = idx % TILES_PER_ROW
        
        x = col * TILE_SIZE
        y = row * TILE_SIZE
        
        # 绘制基础色块
        draw.rectangle(
            [x, y, x + TILE_SIZE, y + TILE_SIZE],
            fill=color + (255,)  # 添加 alpha 通道
        )
        
        # 添加纹理细节
        add_texture(draw, x, y, name, color)
    
    # 保存图片
    tileset.save(output_path)
    print(f"✓ Tileset 已生成: {output_path}")
    print(f"  尺寸: {width}x{height} 像素")
    print(f"  Tile 数量: {TILE_COUNT}")
    print(f"  Tile 尺寸: {TILE_SIZE}x{TILE_SIZE} 像素")
    
    return output_path

def add_texture(draw, x, y, tile_type, base_color):
    """为 tile 添加简单纹理"""
    
    if tile_type == "grass":
        # 草地纹理：随机点
        import random
        random.seed(42)  # 固定种子，保证每次生成相同
        
        # 深色草点
        darker = tuple(max(0, c - 40) for c in base_color)
        for _ in range(20):
            px = x + random.randint(2, TILE_SIZE - 3)
            py = y + random.randint(2, TILE_SIZE - 3)
            draw.rectangle([px, py, px + 2, py + 2], fill=darker + (255,))
        
        # 浅色草点
        lighter = tuple(min(255, c + 30) for c in base_color)
        for _ in range(15):
            px = x + random.randint(2, TILE_SIZE - 3)
            py = y + random.randint(2, TILE_SIZE - 3)
            draw.rectangle([px, py, px + 1, py + 1], fill=lighter + (255,))
    
    elif tile_type == "water":
        # 水面纹理：波浪线
        wave_color = tuple(min(255, c + 40) for c in base_color)
        
        for i in range(0, TILE_SIZE, 8):
            y_wave = y + i
            draw.line(
                [(x + 5, y_wave), (x + TILE_SIZE - 5, y_wave)],
                fill=wave_color + (150,),  # 半透明
                width=1
            )
        
        # 添加一些深色区域
        darker = tuple(max(0, c - 30) for c in base_color)
        draw.ellipse([x + 10, y + 10, x + 25, y + 25], fill=darker + (100,))
        draw.ellipse([x + 40, y + 35, x + 55, y + 50], fill=darker + (100,))
    
    elif tile_type == "stone":
        # 石头纹理：裂纹和阴影
        import random
        random.seed(123)
        
        # 深色裂纹
        crack_color = tuple(max(0, c - 50) for c in base_color)
        
        # 随机裂纹
        for _ in range(5):
            start_x = x + random.randint(5, TILE_SIZE - 5)
            start_y = y + random.randint(5, TILE_SIZE - 5)
            end_x = start_x + random.randint(-20, 20)
            end_y = start_y + random.randint(-20, 20)
            
            draw.line(
                [(start_x, start_y), (end_x, end_y)],
                fill=crack_color + (255,),
                width=2
            )
        
        # 高光
        highlight = tuple(min(255, c + 40) for c in base_color)
        draw.ellipse([x + 15, y + 15, x + 30, y + 30], fill=highlight + (150,))

def create_advanced_tileset(output_path="tileset_advanced.png"):
    """生成更精细的 tileset（像素艺术风格）"""
    
    width = TILES_PER_ROW * TILE_SIZE
    height = ((TILE_COUNT - 1) // TILES_PER_ROW + 1) * TILE_SIZE
    
    tileset = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    pixels = tileset.load()
    
    # 像素级绘制
    import random
    
    tiles_data = [
        ("grass", COLORS["grass"]),
        ("water", COLORS["water"]),
        ("stone", COLORS["stone"])
    ]
    
    for idx, (name, base_color) in enumerate(tiles_data):
        row = idx // TILES_PER_ROW
        col = idx % TILES_PER_ROW
        
        offset_x = col * TILE_SIZE
        offset_y = row * TILE_SIZE
        
        random.seed(idx * 100)  # 不同的种子
        
        # 填充基础色
        for px in range(TILE_SIZE):
            for py in range(TILE_SIZE):
                # 添加随机噪点
                noise = random.randint(-15, 15)
                color = tuple(max(0, min(255, c + noise)) for c in base_color)
                pixels[offset_x + px, offset_y + py] = color + (255,)
    
    tileset.save(output_path)
    print(f"✓ 高级 Tileset 已生成: {output_path}")
    
    return output_path

def main():
    """主函数"""
    print("=== Tileset 生成器 ===\n")
    
    # 生成基础 tileset
    basic_path = create_tileset("tileset_basic.png")
    
    print()
    
    # 生成高级 tileset
    advanced_path = create_advanced_tileset("tileset_advanced.png")
    
    print("\n生成完成!")
    print(f"  基础版: {os.path.abspath(basic_path)}")
    print(f"  高级版: {os.path.abspath(advanced_path)}")
    
    print("\n在 Godot 中使用:")
    print("  1. 将图片导入到 res://assets/")
    print("  2. 创建 TileSet 资源")
    print("  3. 设置 Tile Size 为 64x64")
    print("  4. 在 TileMap 节点中使用")

if __name__ == "__main__":
    # 需要安装: pip install pillow
    main()