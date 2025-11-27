# 物品系统场景配置指南

## 📋 已完成的配置

### 1. 场景文件
✅ **ItemWorld 场景** (`scenes/item_world.tscn`)
- 已创建完整的物品实体场景
- 包含 Sprite2D, CollisionShape2D, Label
- 碰撞层设置: Layer 8, Mask 1

### 2. 主场景修改 (`node.tscn`)
✅ **添加了 ItemsContainer 节点**
```
main (Node)
├── TileMapLayer
├── ItemsContainer (Node2D)  ← 新增,用于放置所有物品
├── player
├── Button
└── External_Controller
```

### 3. 玩家脚本修改 (`player_physics.gd`)
✅ **添加了背包系统**
- 初始化 Inventory (20格,100重量)
- 添加拾取方法: `pickup_item()`, `add_item_to_inventory()`
- 连接信号回调

### 4. 测试脚本 (`test_items_spawn.gd`)
✅ **自动生成测试物品**
- 生命药水 (红色圆形图标)
- 金币 x50 (金色圆形图标)
- 铁剑 (灰银色渐变图标)
- 传说宝石 (橙黄色渐变图标)

## 🚀 如何使用

### 方法1: 在主场景中自动生成测试物品

1. **在主场景添加测试脚本**:
   - 打开 `node.tscn` 场景
   - 选中 `main` 节点
   - 在右侧属性面板,找到 Node → Script
   - 添加子节点: 右键 main → Add Child Node → Node
   - 命名为 `ItemSpawnTest`
   - 附加脚本: `res://scripts/items/test_items_spawn.gd`

2. **运行场景**:
   - 按 F5 运行,会自动在地图上生成4个测试物品
   - 控制玩家靠近物品即可拾取

### 方法2: 手动在场景中放置物品

1. **实例化 ItemWorld**:
   - 打开 `node.tscn`
   - 右键 `ItemsContainer` → Instantiate Child Scene
   - 选择 `scenes/item_world.tscn`

2. **配置物品属性**:
   - 在检查器中设置:
     - Item Data (创建新的 ConsumableItem/EquipmentItem)
     - Stack Count
     - Pickup Radius

### 方法3: 通过代码生成

在任何脚本中使用:
```gdscript
# 创建物品
var potion = ConsumableItem.new()
potion.item_name = "生命药水"
potion.icon = ItemIconManager.create_circle_icon(Color.RED, 64)

# 生成到地图
var container = get_node("/root/main/ItemsContainer")
ItemSpawner.spawn_item(potion, Vector2(100, 100), container)
```

## 🎮 当前项目结构

```
snow-globe/
├── scenes/
│   └── item_world.tscn          ← 物品实体场景
├── scripts/
│   ├── items/
│   │   ├── item_base.gd         ← 物品基类
│   │   ├── consumable_item.gd   ← 消耗品
│   │   ├── equipment_item.gd    ← 装备
│   │   ├── item_world.gd        ← 地图物品逻辑
│   │   ├── item_spawner.gd      ← 生成器
│   │   ├── inventory.gd         ← 背包系统
│   │   ├── item_icon_manager.gd ← 图标管理
│   │   └── test_items_spawn.gd  ← 测试生成
│   └── player_physics.gd        ← 已添加背包
├── node.tscn                    ← 主场景(已添加ItemsContainer)
└── player.tscn                  ← 玩家场景
```

## ⚙️ 项目设置检查

### 碰撞层配置
确保在 Project → Project Settings → Layer Names → 2D Physics 中:
- Layer 1: Player
- Layer 8: Items

### 输入映射
可以添加拾取键(可选):
Project → Project Settings → Input Map:
- 添加 `interact` 动作,映射到 E 键

## 🎯 下一步

### 1. 测试物品拾取
```gdscript
# 运行主场景
# 控制玩家(WASD)靠近物品
# 物品会自动被拾取,控制台显示消息
```

### 2. 查看背包内容
```gdscript
# 在 player_physics.gd 中添加调试按键
func _input(event):
    if event.is_action_pressed("ui_accept"):  # 空格键
        print_inventory()

func print_inventory():
    print("\n=== 背包内容 ===")
    var items = inventory.get_all_items()
    for item_data in items:
        print("  [%d] %s x%d" % [
            item_data.slot_index,
            item_data.item.item_name,
            item_data.count
        ])
    print("空槽位: %d/%d" % [inventory.get_empty_slots(), inventory.max_slots])
```

### 3. 添加更多物品
参考 `test_items_spawn.gd` 创建新物品

## 🐛 故障排除

### 物品不显示?
- 检查 ItemsContainer 节点是否存在
- 检查物品的 z_index (应该 > 0)
- 检查摄像机范围

### 无法拾取?
- 检查碰撞层设置 (Layer 8, Mask 1)
- 确保玩家在 Layer 1
- 确保 player_physics.gd 有 `add_item_to_inventory()` 方法

### 图标不显示?
- 物品生成时会使用程序生成的图标
- 或者设置 `icon = load("res://path/to/icon.png")`

## 📞 快速参考

**生成物品**:
```gdscript
ItemSpawner.spawn_item(item, position, container)
```

**创建图标**:
```gdscript
ItemIconManager.create_circle_icon(Color.RED, 64)
```

**拾取物品**:
```gdscript
player.add_item_to_inventory(item, count)
```

**检查背包**:
```gdscript
player.inventory.get_all_items()
```
