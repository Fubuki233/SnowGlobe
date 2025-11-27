# 物品贴图自定义指南

## 📁 推荐的文件结构

```
Assets/
└── Items/
    ├── Consumables/
    │   ├── potion_health.png
    │   ├── potion_mana.png
    │   └── food_bread.png
    ├── Weapons/
    │   ├── sword_iron.png
    │   ├── sword_steel.png
    │   └── bow_wooden.png
    ├── Armors/
    │   ├── helmet_iron.png
    │   └── chest_leather.png
    ├── Materials/
    │   ├── wood.png
    │   ├── stone.png
    │   └── iron_ore.png
    └── Misc/
        ├── gold_coin.png
        └── key.png
```

## 🎨 方法1: 从文件加载图标

### 基础用法

```gdscript
# 方式A: 使用 preload (编译时加载,推荐)
var potion = ConsumableItem.new()
potion.icon = preload("res://Assets/Items/Consumables/potion_health.png")

# 方式B: 使用 load (运行时加载)
var sword = EquipmentItem.new()
sword.icon = load("res://Assets/Items/Weapons/sword_iron.png")

# 方式C: 使用 ResourceLoader (带检查)
if ResourceLoader.exists("res://Assets/Items/gold_coin.png"):
    gold.icon = ResourceLoader.load("res://Assets/Items/gold_coin.png")
```

### 使用图标管理器

```gdscript
# 自动加载和缓存
var potion = ConsumableItem.new()
potion.icon = ItemIconManager.load_icon("potion_health.png")

# 根据物品ID自动加载
var item = ItemBase.new()
item.item_id = "potion_health_001"
item.icon = ItemIconManager.load_icon_by_id(item.item_id)
```

## 🖌️ 方法2: 程序化生成图标

### 纯色图标

```gdscript
# 创建红色图标
var red_icon = ItemIconManager.create_colored_icon(Color.RED, 64)
item.icon = red_icon
```

### 渐变图标

```gdscript
# 创建紫色到粉色渐变
var gradient_icon = ItemIconManager.create_gradient_icon(
    Color.PURPLE, 
    Color.PINK, 
    64
)
item.icon = gradient_icon
```

### 圆形图标

```gdscript
# 创建蓝色圆形图标,带边框
var circle_icon = ItemIconManager.create_circle_icon(Color.BLUE, 64, true)
item.icon = circle_icon
```

### 根据品质自动生成

```gdscript
# 根据物品品质生成对应颜色的图标
var item = ItemBase.new()
item.rarity = ItemBase.Rarity.LEGENDARY
item.icon = ItemIconManager.create_rarity_icon(item.rarity, 64)
```

### 根据类型自动生成

```gdscript
# 根据物品类型生成对应颜色的图标
var weapon = EquipmentItem.new()
weapon.item_type = ItemBase.ItemType.WEAPON
weapon.icon = ItemIconManager.create_item_type_icon(weapon.item_type, 64)
```

## 📦 方法3: 批量设置图标

### 创建物品工厂

```gdscript
class_name ItemFactory

static func create_potion(type: String) -> ConsumableItem:
    var potion = ConsumableItem.new()
    
    match type:
        "health":
            potion.item_id = "potion_health"
            potion.item_name = "生命药水"
            potion.icon = ItemIconManager.load_icon("potion_health.png")
            potion.restore_health = 50
        "mana":
            potion.item_id = "potion_mana"
            potion.item_name = "魔法药水"
            potion.icon = ItemIconManager.load_icon("potion_mana.png")
            potion.restore_energy = 30
    
    return potion

# 使用
var health_potion = ItemFactory.create_potion("health")
```

### 从数据文件加载

```gdscript
# items_data.json
{
    "potion_health": {
        "name": "生命药水",
        "icon": "potion_health.png",
        "type": "consumable",
        "restore_health": 50
    },
    "sword_iron": {
        "name": "铁剑",
        "icon": "sword_iron.png",
        "type": "weapon",
        "damage": 15
    }
}

# 加载脚本
func load_items_from_json(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}
    
    var json = JSON.parse_string(file.get_as_text())
    var items = {}
    
    for item_id in json:
        var data = json[item_id]
        var item = create_item_from_data(item_id, data)
        items[item_id] = item
    
    return items

func create_item_from_data(id: String, data: Dictionary) -> ItemBase:
    var item = ItemBase.new()
    item.item_id = id
    item.item_name = data.get("name", "未命名")
    
    # 自动加载图标
    if data.has("icon"):
        item.icon = ItemIconManager.load_icon(data["icon"])
    
    return item
```

## 🎯 方法4: 动态图标变化

### 根据耐久度改变图标

```gdscript
extends EquipmentItem

func update_icon_by_durability():
    """根据耐久度显示不同的图标"""
    var durability_percent = float(durability) / float(max_durability)
    
    if durability_percent > 0.75:
        icon = load("res://Assets/Items/sword_iron_new.png")
    elif durability_percent > 0.5:
        icon = load("res://Assets/Items/sword_iron_used.png")
    elif durability_percent > 0.25:
        icon = load("res://Assets/Items/sword_iron_damaged.png")
    else:
        icon = load("res://Assets/Items/sword_iron_broken.png")
```

### 根据数量改变图标

```gdscript
func get_stack_icon(count: int) -> Texture2D:
    """根据堆叠数量返回不同图标"""
    if count >= 100:
        return load("res://Assets/Items/gold_pile_large.png")
    elif count >= 10:
        return load("res://Assets/Items/gold_pile_medium.png")
    else:
        return load("res://Assets/Items/gold_pile_small.png")
```

## 🖼️ 图标规格建议

### 推荐尺寸
- **小图标**: 32x32 (背包格子)
- **中图标**: 64x64 (物品详情)
- **大图标**: 128x128 (3D物品预览)

### 文件格式
- **PNG**: 支持透明度,推荐使用
- **SVG**: 矢量图,适合UI元素
- **WebP**: 体积小,Godot 4支持

### 导入设置
在Godot中选中图标文件,在导入面板设置:
- **Compress**: `VRAM Compressed` (节省内存)
- **Mipmaps**: `Enabled` (远距离清晰)
- **Filter**: `Linear` 或 `Nearest` (像素风格用Nearest)

## 💡 高级技巧

### 1. 图标着色/调色

```gdscript
# 在ItemWorld中动态着色图标
func set_icon_tint(color: Color):
    if sprite and sprite.texture:
        sprite.modulate = color

# 根据品质着色
match item_data.rarity:
    ItemBase.Rarity.EPIC:
        set_icon_tint(Color.PURPLE)
    ItemBase.Rarity.LEGENDARY:
        set_icon_tint(Color.ORANGE)
```

### 2. 添加图标效果

```gdscript
# 在ItemWorld中添加发光效果
func add_glow_effect():
    if item_data.rarity >= ItemBase.Rarity.RARE:
        sprite.material = preload("res://Materials/glow_material.tres")
```

### 3. 图标动画

```gdscript
# 在ItemWorld中旋转图标
func _process(delta):
    if sprite:
        sprite.rotation += rotation_speed * delta

# 缩放动画
func animate_pickup():
    var tween = create_tween()
    tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
    tween.tween_property(sprite, "scale", Vector2(0, 0), 0.3)
```

### 4. 使用精灵表(Sprite Sheet)

```gdscript
# 如果多个物品图标在一张图上
var atlas = preload("res://Assets/Items/item_atlas.png")

func get_icon_from_atlas(index: int, grid_size: Vector2i = Vector2i(8, 8)) -> AtlasTexture:
    var atlas_texture = AtlasTexture.new()
    atlas_texture.atlas = atlas
    
    var icon_size = 64
    var col = index % grid_size.x
    var row = index / grid_size.x
    
    atlas_texture.region = Rect2(
        col * icon_size, 
        row * icon_size, 
        icon_size, 
        icon_size
    )
    
    return atlas_texture

# 使用
item.icon = get_icon_from_atlas(5)  # 获取第6个图标
```

## 📋 完整示例

```gdscript
# 创建完整的物品并设置图标
func create_legendary_sword() -> EquipmentItem:
    var sword = EquipmentItem.new()
    sword.item_id = "sword_legendary_001"
    sword.item_name = "传说之剑"
    sword.rarity = ItemBase.Rarity.LEGENDARY
    sword.item_type = ItemBase.ItemType.WEAPON
    
    # 方法1: 从文件加载
    if ResourceLoader.exists("res://Assets/Items/Weapons/sword_legendary.png"):
        sword.icon = load("res://Assets/Items/Weapons/sword_legendary.png")
    else:
        # 方法2: 程序化生成
        sword.icon = ItemIconManager.create_gradient_icon(
            Color.ORANGE,
            Color.YELLOW,
            128
        )
    
    return sword

# 在地图上生成带图标的物品
func spawn_item_with_icon():
    var sword = create_legendary_sword()
    var item_world = ItemSpawner.spawn_item(sword, Vector2(100, 100), get_parent())
    
    # ItemWorld会自动使用sword.icon显示
    # 添加额外的视觉效果
    item_world.sprite.material = preload("res://Materials/legendary_glow.tres")
```

## 🎨 免费图标资源

- **Kenney Assets**: https://kenney.nl/assets (大量免费游戏素材)
- **OpenGameArt**: https://opengameart.org
- **itch.io**: https://itch.io/game-assets/free (搜索 "item icons")
- **Game-icons.net**: https://game-icons.net (可自定义颜色)

## ⚠️ 注意事项

1. **图标尺寸统一**: 同一类型的图标使用相同尺寸
2. **透明背景**: 使用PNG格式并保持背景透明
3. **命名规范**: 使用清晰的命名 `类型_名称.png`
4. **版权**: 确保使用的图标资源有合法授权
5. **性能**: 大量图标使用图集或缓存管理器
