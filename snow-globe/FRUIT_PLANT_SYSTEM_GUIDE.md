# 果实-植物系统使用示例

## 1. 创建果实场景 (apple_fruit.tscn)

```gdscript
# apple_fruit.gd (挂载到果实场景根节点)
extends AIFruit

func _ready():
	# 基础信息
	display_name = "苹果"
	description = "一个新鲜的红苹果，可以食用或种植"
	
	# 消耗品属性（食用效果）
	healing_amount = 20
	hunger_restore = 30
	weight = 0.2
	rarity = "common"
	
	# 种植属性
	is_plantable = true
	plant_scene_path = "res://scenes/plants/apple_tree.tscn"  # 对应的苹果树场景
	growth_time = 120.0
	required_farming_skill = 1
	required_soil_type = "壤土"
	
	super._ready()
```

## 2. 创建植物场景 (apple_tree.tscn)

```gdscript
# apple_tree.gd (挂载到植物场景根节点)
extends AIPlant

func _ready():
	# 基础信息
	display_name = "苹果树"
	description = "一棵结满苹果的树"
	plant_type = "树"
	
	# 生长参数
	growth_stages = 4
	current_stage = 0
	
	# 果实配置 - 绑定回苹果果实
	has_fruit = true
	fruit_mature_stage = 3  # 第4阶段成熟
	fruit_drop_mechanism = "采集后获得"
	fruit_scene_path = "res://scenes/items/apple_fruit.tscn"  # 绑定果实场景
	fruit_yield = 3  # 每次采集获得3个苹果
	
	# 采集配置
	harvest_times = 0  # 无限采集
	harvest_cooldown = 60.0  # 60秒冷却
	
	# 其他属性
	weight = 5.0
	rarity = "普通"
	usage = "食材"
	
	super._ready()
```

## 3. 完整使用流程

```gdscript
# 在 main.gd 或测试脚本中

func test_fruit_plant_cycle():
	# 获取玩家
	var player = get_node("Node2D/player/Player")
	
	print("\n========== 果实-植物循环测试 ==========\n")
	
	# === 步骤1: 给玩家一个苹果 ===
	var apple = load("res://scenes/items/apple_fruit.tscn").instantiate()
	player.add_to_inventory(apple, 1)
	print("✓ 玩家获得了苹果")
	
	# === 步骤2: 检查果实是否在背包 ===
	if apple.is_in_inventory(player):
		print("✓ 苹果在玩家背包中")
		print("  数量: %d" % apple.get_quantity_in_inventory(player))
	
	# === 步骤3: 玩家种植苹果 ===
	var plant_pos = player.global_position + Vector2(100, 0)
	var apple_tree = player.plant_fruit("苹果", plant_pos)
	
	if apple_tree:
		print("✓ 成功种植苹果树")
		print("  位置: (%.0f, %.0f)" % [apple_tree.global_position.x, apple_tree.global_position.y])
		print("  当前阶段: %d/%d" % [apple_tree.current_stage, apple_tree.growth_stages])
	
	# === 步骤4: 等待树木生长并采集 ===
	await get_tree().create_timer(5.0).timeout
	
	# 手动设置为成熟阶段（测试用）
	if apple_tree:
		apple_tree.current_stage = 3
		print("\n✓ 苹果树已成熟")
		
		# === 步骤5: 采集果实 ===
		var products = apple_tree.harvest(player)
		print("✓ 采集完成")
		print("  获得产物: %s" % products)
		
		# === 步骤6: 检查背包 ===
		player.print_inventory()
	
	print("\n========== 测试完成 ==========\n")

# 测试直接使用果实方法
func test_fruit_usage():
	var player = get_node("Node2D/player/Player")
	var apple = load("res://scenes/items/apple_fruit.tscn").instantiate()
	
	# 添加到背包
	player.add_to_inventory(apple, 5)
	
	# 方法1: 食用果实
	var inventory_data = player.get_inventory_info()
	var apple_in_bag = inventory_data["items"]["苹果"]["item"]
	apple_in_bag.eat(player)  # 恢复生命值和饥饿度
	
	# 方法2: 种植果实
	var tree = apple_in_bag.plant(player, player.global_position + Vector2(50, 0))
	if tree:
		print("种植成功!")
	
	# 方法3: 使用 player 的便捷方法
	var tree2 = player.plant_fruit("苹果", player.global_position + Vector2(100, 0))

# 测试果实信息查询
func test_fruit_info():
	var apple = load("res://scenes/items/apple_fruit.tscn").instantiate()
	
	# 获取种植信息
	var plant_info = apple.get_plant_info()
	print("果实种植信息:")
	print("  可种植: %s" % plant_info["is_plantable"])
	print("  植物场景: %s" % plant_info["plant_scene_path"])
	print("  生长时间: %.0f 秒" % plant_info["growth_time"])
	print("  需要技能: %d" % plant_info["required_skill"])
	print("  土壤类型: %s" % plant_info["soil_type"])
```

## 4. 关键特性

### 果实 (AIFruit)
- ✅ 继承自 AIConsumable，可以食用
- ✅ 可绑定植物场景 (plant_scene_path)
- ✅ 检查背包持有状态
- ✅ 消耗背包物品进行种植
- ✅ 种植成功后生成植物实例
- ✅ 技能需求检查

### 植物 (AIPlant)
- ✅ 可绑定果实场景 (fruit_scene_path)
- ✅ 采集时自动生成果实实例
- ✅ 果实直接添加到采集者背包
- ✅ 支持多个果实产出 (fruit_yield)
- ✅ 采集冷却系统

### 角色背包集成
- ✅ `player.plant_fruit(fruit_name, position)` - 便捷种植方法
- ✅ 自动从背包移除果实
- ✅ 种植失败时退还果实
- ✅ 完整的背包检测功能

## 5. 完整循环示意

```
1. 玩家采集成熟的苹果树
   └─> 苹果实例自动添加到背包 (3个)

2. 玩家从背包种植苹果
   └─> 消耗1个苹果
   └─> 在指定位置生成苹果树

3. 苹果树生长
   └─> 阶段 0 → 1 → 2 → 3 (成熟)

4. 玩家采集成熟的苹果树
   └─> 获得3个苹果（回到步骤1）

循环往复，形成可持续的资源系统
```

## 6. 配置 JSON 示例

```json
{
  "fruit_config": {
    "display_name": "苹果",
    "description": "可以食用或种植的红苹果",
    "weight": 0.2,
    "healing_amount": 20,
    "hunger_restore": 30,
    "is_plantable": true,
    "plant_scene_path": "res://scenes/plants/apple_tree.tscn",
    "growth_time": 120,
    "required_farming_skill": 1
  },
  "plant_config": {
    "display_name": "苹果树",
    "plant_type": "树",
    "growth_stages": 4,
    "has_fruit": true,
    "fruit_mature_stage": 3,
    "fruit_scene_path": "res://scenes/items/apple_fruit.tscn",
    "fruit_yield": 3,
    "harvest_cooldown": 60
  }
}
```
