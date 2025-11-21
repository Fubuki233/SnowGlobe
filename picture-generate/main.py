"""
完整的sprite动画生成流水线
自动化整个流程: 生成动画 → 提取帧 → 去除背景 → 自动裁剪

使用方法:
    python main.py <角色图片路径> [动作描述]
    
示例:
    python main.py character.png
    python main.py goblin.png "running animation"
    python main.py warrior.png "attack animation" --no-crop
    
环境变量:
    GEMINI_API_KEY: Gemini API密钥（必需）
"""

import os
import sys
import time
import shutil
from datetime import datetime

# 导入各模块的功能
from generate_sprite_animation import (
    load_reference_image,
    generate_animation_video,
    client as gemini_client
)
from extract_sprite_frames import (
    extract_frames_from_video_segment,
    create_sprite_sheet,
    save_individual_frames
)
from remove_background import (
    process_directory
)

def print_banner(text):
    """打印美化的横幅"""
    print("\n" + "="*70)
    print(f"  {text}")
    print("="*70 + "\n")

def print_step(step_num, total_steps, description):
    """打印步骤信息"""
    print(f"\n{'─'*70}")
    print(f"📍 步骤 {step_num}/{total_steps}: {description}")
    print(f"{'─'*70}\n")

def cleanup_temp_files(*file_paths):
    """清理临时文件"""
    for file_path in file_paths:
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
                print(f"  🗑️  清理临时文件: {file_path}")
            except Exception as e:
                print(f"  ⚠️  无法删除 {file_path}: {e}")

def main():
    # 解析命令行参数
    if len(sys.argv) < 2:
        print("用法: python main.py <角色图片路径> [动作描述] [选项]")
        print("\n参数说明:")
        print("  角色图片路径: 必需，角色参考图")
        print("  动作描述: 可选，默认 'walking animation'")
        print("\n选项:")
        print("  --start-time N: 视频提取开始时间（秒），默认 2.0")
        print("  --end-time N: 视频提取结束时间（秒），默认 3.0")
        print("  --tolerance N: 背景颜色容差，默认 30")
        print("  --no-crop: 禁用自动裁剪")
        print("  --padding N: 裁剪边距（像素），默认 0")
        print("  --keep-temp: 保留临时文件")
        print("\n示例:")
        print('  python main.py character.png')
        print('  python main.py goblin.png "running animation"')
        print('  python main.py warrior.png "attack animation" --no-crop')
        print('  python main.py mage.png "casting spell" --tolerance 40 --padding 2')
        print('  python main.py knight.png --start-time 1.5 --end-time 2.5')
        sys.exit(1)
    
    reference_image_path = sys.argv[1]
    
    # 解析参数
    action = "walking animation"
    start_time = 2.0
    end_time = 3.0
    tolerance = 30
    auto_crop = True
    crop_padding = 0
    keep_temp = False
    
    i = 2
    while i < len(sys.argv):
        arg = sys.argv[i]
        
        if arg == '--start-time':
            start_time = float(sys.argv[i + 1])
            i += 2
        elif arg == '--end-time':
            end_time = float(sys.argv[i + 1])
            i += 2
        elif arg == '--tolerance':
            tolerance = int(sys.argv[i + 1])
            i += 2
        elif arg == '--no-crop':
            auto_crop = False
            i += 1
        elif arg == '--padding':
            crop_padding = int(sys.argv[i + 1])
            i += 2
        elif arg == '--keep-temp':
            keep_temp = True
            i += 1
        elif arg.startswith('--'):
            print(f"× 错误: 未知选项 {arg}")
            sys.exit(1)
        else:
            # 第一个非选项参数是动作描述
            if i == 2:
                action = arg
            i += 1
    
    # 检查输入文件
    if not os.path.exists(reference_image_path):
        print(f"× 错误: 找不到图片文件 {reference_image_path}")
        sys.exit(1)
    
    # 开始流水线
    start_overall = time.time()
    print_banner("Sprite动画生成流水线")
    
    print(f"配置:")
    print(f"  - 角色图片: {reference_image_path}")
    print(f"  - 动作: {action}")
    print(f"  - 提取时间段: {start_time}s - {end_time}s")
    print(f"  - 背景容差: {tolerance}")
    print(f"  - 自动裁剪: {'是' if auto_crop else '否'}")
    if auto_crop and crop_padding > 0:
        print(f"  - 裁剪边距: {crop_padding}px")
    
    # 生成时间戳用于输出目录
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_base_dir = f"output_{timestamp}"
    os.makedirs(output_base_dir, exist_ok=True)
    
    try:
        # ========== 步骤 1: 加载参考图片 ==========
        print_step(1, 5, "加载角色参考图片")
        reference_image = load_reference_image(reference_image_path)
        print(f"✓ 图片已加载: {reference_image.size}")
        
        # ========== 步骤 2: 生成动画视频 ==========
        print_step(2, 5, "使用 Gemini Veo 生成动画视频")
        
        # 构建完整的提示词
        full_prompt = f"""
Create a smooth sprite animation of the character {action} IN PLACE (not moving across screen).

CRITICAL REQUIREMENTS:
- START IMMEDIATELY with the character visible - NO fade in effect
- Character MUST face RIGHT and perform the animation IN THE SAME POSITION
- Character STAYS IN THE CENTER, does NOT move left or right across the screen
- Only the character's body/limbs animate, position remains FIXED
- Smooth, fluid animation with natural motion
- Complete {action} cycle IN PLACE
- Pure side view with character facing RIGHT direction
- Keep the exact same character design, colors, and art style
- Loop-able animation cycle

VISUAL STYLE REQUIREMENTS:
- NO physics effects (no particles, debris, dust, etc.)
- NO lighting effects (no shadows, highlights, glows, reflections)
- NO post-processing effects (no blur, bloom, color grading)
- Flat, clean animation with solid colors only
- Simple sprite animation style without any special effects

BACKGROUND REQUIREMENTS FOR POST-PRODUCTION:
- Background MUST be PURE CHROMA GREEN (#00FF00, RGB 0,255,0)
- Solid, uniform green color across entire background
- NO gradients, NO textures, NO variations in the green
- This green screen is SPECIFICALLY for video editing and background removal in post-production
- The green background will be keyed out and replaced later
- Character should NOT contain any green colors to avoid keying issues
- Keep background perfectly flat and uniform for clean chroma key

IMPORTANT: 
- BEGIN: Start with character fully visible immediately, NO fade in
- BACKGROUND: Solid chroma green (#00FF00) throughout entire video for post-production keying
- END: After the animation cycle completes (around 2 seconds), character disappears but background stays green
- Do Not use any fade effects - instant start, character vanishes at end, green background remains

Style: Clean pixel art / 2D game sprite animation with smooth motion, no effects
Camera: Fixed, character stays in center and animates in place
Background: Pure chroma green (#00FF00) for entire duration - FOR POST-PRODUCTION EDITING
Transitions: None - instant start, instant character removal at end, green background constant
Effects: NONE - no physics, lighting, or post-processing effects
"""
        
        video = generate_animation_video(reference_image, full_prompt)
        
        # 下载视频
        temp_video_path = os.path.join(output_base_dir, "temp_animation.mp4")
        print(f"正在下载视频到 {temp_video_path}...")
        video_data = gemini_client.files.download(file=video.video)
        with open(temp_video_path, "wb") as f:
            f.write(video_data)
        print("✓ 视频已下载")
        
        # ========== 步骤 3: 提取帧 ==========
        print_step(3, 5, "从视频中提取Sprite帧")
        frames = extract_frames_from_video_segment(temp_video_path, start_time, end_time)
        
        if not frames:
            raise ValueError("没有提取到任何帧")
        
        # 保存原始提取的帧
        extracted_dir = os.path.join(output_base_dir, "1_extracted_frames")
        save_individual_frames(frames, output_dir=extracted_dir)
        
        # 创建原始sprite sheet
        sprite_sheet, _ = create_sprite_sheet(frames, frame_size=None)
        original_sheet_path = os.path.join(output_base_dir, "1_original_sprite_sheet.png")
        sprite_sheet.save(original_sheet_path)
        print(f"原始 Sprite sheet 已保存: {original_sheet_path}")
        
        # ========== 步骤 4: 去除背景 ==========
        print_step(4, 5, "去除绿色背景")
        nobg_dir = os.path.join(output_base_dir, "2_nobg_frames")
        process_directory(
            extracted_dir,
            output_dir=nobg_dir,
            tolerance=tolerance,
            edge_size=10,
            num_workers=None,
            auto_crop=auto_crop,
            crop_padding=crop_padding
        )
        
        # ========== 步骤 5: 创建最终Sprite Sheet ==========
        print_step(5, 5, "生成最终Sprite Sheet")
        
        # 读取处理后的帧
        from PIL import Image
        nobg_files = sorted([f for f in os.listdir(nobg_dir) if f.endswith('.png')])
        final_frames = [Image.open(os.path.join(nobg_dir, f)) for f in nobg_files]
        
        # 创建最终sprite sheet
        final_sheet, _ = create_sprite_sheet(final_frames, frame_size=None)
        final_sheet_path = os.path.join(output_base_dir, "3_final_sprite_sheet.png")
        final_sheet.save(final_sheet_path)
        print(f"最终 Sprite sheet 已保存: {final_sheet_path}")
        
        # ========== 完成 ==========
        end_overall = time.time()
        
        # 清理临时文件
        if not keep_temp:
            print(f"\n{'─'*70}")
            print("清理临时文件")
            print(f"{'─'*70}\n")
            cleanup_temp_files(temp_video_path)
        
        # 输出总结
        print_banner("执行完成!")
        
        print(f"总耗时: {end_overall - start_overall:.1f} 秒")
        print(f"\n输出目录: {output_base_dir}/")
        print(f"\n生成的文件:")
        print(f"  原始提取帧: {extracted_dir}/")
        print(f"  去背景帧: {nobg_dir}/")
        print(f"  原始Sprite Sheet: {original_sheet_path}")
        print(f"  最终Sprite Sheet: {final_sheet_path}")
        
        if keep_temp:
            print(f"  视频文件: {temp_video_path}")
        
        print(f"\n可直接在游戏引擎中使用:")
        print(f"  - 导入: {final_sheet_path}")
        print(f"  - 帧数: {len(final_frames)}")
        print(f"  - 单帧尺寸: {final_frames[0].size if final_frames else 'N/A'}")
        
        print("\n" + "="*70 + "\n")
        
    except KeyboardInterrupt:
        print("\n\n用户中断操作")
        sys.exit(1)
    
    except Exception as e:
        print(f"\n\n错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
