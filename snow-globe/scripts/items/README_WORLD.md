# 物品地图放置系统

## 概述
这个系统允许你在游戏地图上放置、生成和拾取物品。

## 核心组件

### 1. ItemWorld (item_world.gd)
**地图上的物品实体**

**功能:**
- 在地图上显示物品
- 浮动和旋转动画效果
- 拾取交互
- 磁力吸引效果
- 根据品质显示不同颜色

**关键属性:**
```gdscript
@export var item_data: ItemBase        # 物品数据
@export var stack_count: int          # 堆叠数量
@export var pickup_radius: float      # 拾取范围
@export var auto_pickup: bool         # 自动拾取
```

### 2. ItemSpawner (item_spawner.gd)
**物品生成器 - 静态工具类**

**主要方法:**
```gdscript
# 在世界坐标生成物品
ItemSpawner.spawn_item(item, position, parent, count)

# 在网格坐标生成物品
ItemSpawner.spawn_item_at_grid(item, grid_pos, tilemap, parent, count)

# 在区域内随机生成多个物品
ItemSpawner.spawn_random_items(items, count, area, parent)

# 从实体掉落物品
ItemSpawner.drop_item_from_entity(item, entity, parent, count)
```

### 3. Inventory (inventory.gd)
**背包系统**

**功能:**
- 物品存储管理
- 堆叠处理
- 重量限制
- 排序功能
- 信号系统

**主要方法:**
```gdscript
inventory.add_item(item, count)      # 添加物品
inventory.remove_item(item, count)   # 移除物品
inventory.has_item(item, count)      # 检查物品
inventory.get_all_items()            # 获取所有物品
inventory.sort_by_type()             # 按类型排序
```

## 使用指南

### 步骤1: 在地图上生成物品

#### 方法A: 在指定位置生成
```gdscript
# 创建物品数据
var potion = ConsumableItem.new()
potion.item_name = "生命药水"

# 在位置 (100, 100) 生成
var item_world = ItemSpawner.spawn_item(potion, Vector2(100, 100), get_parent())
```

#### 方法B: 在网格位置生成
```gdscript
var tilemap = get_node("/root/main/TileMapLayer")
var grid_pos = Vector2i(5, 5)

ItemSpawner.spawn_item_at_grid(potion, grid_pos, tilemap, get_parent())
```

#### 方法C: 随机生成多个物品
```gdscript
var items = [potion, sword, gold]
var area = Rect2(0, 0, 1000, 1000)  # 生成区域

ItemSpawner.spawn_random_items(items, 10, area, get_parent())
```

### 步骤2: 为玩家添加背包功能

在 `player_physics.gd` 中添加:

```gdscript
# 在文件顶部添加
var inventory: Inventory = null

# 在 _ready() 函数中添加
func _ready():
    # ...现有代码...
    
    # 初始化背包
    inventory = Inventory.new()
    inventory.max_slots = 20
    inventory.max_weight = 100.0
    inventory.item_added.connect(_on_item_added)
    inventory.inventory_full.connect(_on_inventory_full)
    add_child(inventory)

# 添加拾取方法
func add_item_to_inventory(item: ItemBase, count: int = 1) -> bool:
    """添加物品到背包"""
    if inventory:
        return inventory.add_item(item, count)
    return false

func pickup_item(item: ItemBase, count: int = 1) -> bool:
    """拾取物品"""
    return add_item_to_inventory(item, count)

# 信号回调
func _on_item_added(item: ItemBase, count: int):
    print("获得了: %s x%d" % [item.item_name, count])

func _on_inventory_full():
    print("背包已满!")
```

### 步骤3: 设置拾取交互

ItemWorld 会自动检测进入拾取范围的物体,并调用其 `pickup_item()` 或 `add_item_to_inventory()` 方法。

**手动拾取:**
```gdscript
# 在玩家脚本中
func _input(event):
    if event.is_action_pressed("interact"):  # 按E键
        pickup_nearby_items()

func pickup_nearby_items():
    var nearby = get_tree().get_nodes_in_group("items")
    for item_world in nearby:
        if global_position.distance_to(item_world.global_position) < 50:
            item_world.pickup_item(self)
```

**自动拾取:**
```gdscript
# 创建物品时设置自动拾取
item_world.auto_pickup = true
```

**磁力吸引:**
```gdscript
# ItemWorld 进入磁力范围时开始吸引
item_world.start_attraction(player)
```

## 实际应用示例

### 示例1: 怪物死亡掉落
```gdscript
# 在怪物脚本中
func die():
    # 掉落金币
    var gold = ItemBase.new()
    gold.item_id = "gold"
    gold.item_name = "金币"
    
    ItemSpawner.drop_item_from_entity(
        gold, 
        self, 
        get_parent(), 
        randi_range(5, 15)  # 随机5-15个金币
    )
    
    queue_free()
```

### 示例2: 箱子系统
```gdscript
extends StaticBody2D

var items: Array[ItemBase] = []
var is_opened: bool = false

func open():
    if is_opened:
        return
    
    is_opened = true
    
    # 生成箱子里的物品
    for item in items:
        var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
        ItemSpawner.spawn_item(item, global_position + offset, get_parent())
    
    # 播放开箱动画
    $AnimationPlayer.play("open")
```

### 示例3: 资源采集
```gdscript
# 树木脚本
func chop_down():
    # 掉落木材
    var wood = ItemBase.new()
    wood.item_id = "wood"
    wood.item_name = "木材"
    wood.item_type = ItemBase.ItemType.MATERIAL
    
    ItemSpawner.spawn_item(wood, global_position, get_parent(), 3)
    queue_free()
```

### 示例4: 商店购买
```gdscript
func buy_item(item: ItemBase, price: int) -> bool:
    # 检查金币
    var gold_count = player.inventory.get_item_count(gold_item)
    if gold_count < price:
        print("金币不足!")
        return false
    
    # 扣除金币
    player.inventory.remove_item(gold_item, price)
    
    # 添加物品
    if player.inventory.add_item(item, 1):
        print("购买成功!")
        return true
    else:
        # 退款
        player.inventory.add_item(gold_item, price)
        print("背包已满!")
        return false
```

## 场景设置

### ItemWorld 场景结构
```
ItemWorld (Node2D)
├── Sprite2D              # 物品图标
├── Area2D                # 拾取检测区域
│   └── CollisionShape2D  # 圆形碰撞体
└── Label                 # 物品名称标签
```

### 碰撞层设置
建议的碰撞层配置:
- Layer 1: 玩家
- Layer 2: 敌人
- Layer 3: 环境
- **Layer 8: 物品拾取区域**

在 ItemWorld 的 Area2D 中:
- `collision_layer = 8` (第8层)
- `collision_mask = 1` (检测第1层,即玩家)

## 信号系统

### Inventory 信号
```gdscript
signal item_added(item: ItemBase, count: int)
signal item_removed(item: ItemBase, count: int)
signal inventory_full()
signal inventory_changed()

# 连接信号
inventory.item_added.connect(func(item, count):
    print("获得: %s x%d" % [item.item_name, count])
)
```

### ItemWorld 信号
```gdscript
signal item_picked_up(item: ItemBase, picker: Node)

# 连接信号
item_world.item_picked_up.connect(func(item, picker):
    print("%s 拾取了 %s" % [picker.name, item.item_name])
)
```

## 性能优化建议

1. **对象池**: 频繁生成/销毁物品时使用对象池
```gdscript
var item_pool: Array[ItemWorld] = []

func get_pooled_item() -> ItemWorld:
    if item_pool.size() > 0:
        return item_pool.pop_back()
    return ItemSpawner.create_item_world_node()

func return_to_pool(item: ItemWorld):
    item.visible = false
    item_pool.append(item)
```

2. **视距剔除**: 只更新屏幕附近的物品
```gdscript
func _process(delta):
    if not is_on_screen():
        return
    # ...更新逻辑...
```

3. **批量生成**: 使用 `call_deferred` 避免卡顿
```gdscript
func spawn_many_items(items: Array):
    for i in range(items.size()):
        call_deferred("spawn_single", items[i])
```

## 常见问题

### Q: 物品生成后看不见?
**A:** 检查:
1. 物品是否有图标 `item.icon`
2. 父节点是否正确
3. z_index 设置
4. 摄像机视野范围

### Q: 拾取不起作用?
**A:** 确保:
1. 玩家有 `pickup_item()` 或 `add_item_to_inventory()` 方法
2. 碰撞层和遮罩设置正确
3. Area2D 的 CollisionShape2D 已配置

### Q: 背包无法堆叠?
**A:** 检查:
1. `item.is_stackable = true`
2. `item.max_stack > 1`
3. `item.item_id` 相同

## 扩展功能

### 添加物品品质光效
```gdscript
# 在 ItemWorld 中
func add_glow_effect():
    var light = PointLight2D.new()
    match item_data.rarity:
        ItemBase.Rarity.RARE:
            light.color = Color.BLUE
        ItemBase.Rarity.EPIC:
            light.color = Color.PURPLE
        ItemBase.Rarity.LEGENDARY:
            light.color = Color.ORANGE
    add_child(light)
```

### 添加拾取音效
```gdscript
func play_pickup_effect():
    var audio = AudioStreamPlayer2D.new()
    audio.stream = preload("res://sounds/pickup.wav")
    add_child(audio)
    audio.play()
    audio.finished.connect(func(): audio.queue_free())
```
