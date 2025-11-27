# 物品系统说明

## 目录结构
```
scripts/items/
├── item_base.gd              # 物品基类
├── consumable_item.gd        # 消耗品类(继承)
├── equipment_item.gd         # 装备类(继承)
├── advanced_item.gd          # 高级物品(支持组件)
├── item_component.gd         # 组件基类
├── components/
│   ├── glowing_component.gd      # 发光组件
│   └── degradable_component.gd   # 降解组件
└── examples/
    └── create_items_example.gd   # 使用示例
```

## GDScript 面向对象概念

### 1. 继承 (Inheritance)
使用 `extends` 关键字继承父类：
```gdscript
extends ItemBase
class_name ConsumableItem
```

**特点：**
- 子类继承父类的所有属性和方法
- 使用 `super.方法名()` 调用父类方法
- 可以重写 (override) 父类方法
- 适合 "是一个" 的关系 (如：药水 **是一个** 物品)

**示例：**
```gdscript
# 子类重写父类方法
func use(user: Node) -> bool:
    # 调用父类逻辑
    if not super.use(user):
        return false
    # 添加子类特有逻辑
    user.current_health += restore_health
    return true
```

### 2. 组合 (Composition)
通过组件系统为物品添加功能：
```gdscript
var components: Array[ItemComponent] = []
```

**特点：**
- 更灵活，可在运行时添加/移除功能
- 避免深层继承链
- 适合 "有一个" 的关系 (如：物品 **有一个** 发光效果)
- 组件可重用于不同类型的物品

**示例：**
```gdscript
# 为物品添加多个组件
var item = AdvancedItem.new()
item.add_component(GlowingComponent.new())
item.add_component(DegradableComponent.new())
```

### 3. 类型声明
GDScript 支持静态类型：
```gdscript
var item_name: String = "物品"        # 变量类型
func get_value() -> int:              # 返回值类型
var items: Array[ItemBase] = []      # 泛型数组
```

### 4. 导出变量
使用 `@export` 在编辑器中可见和编辑：
```gdscript
@export var item_name: String = "物品"
@export var rarity: Rarity = Rarity.COMMON
```

### 5. class_name
定义全局可访问的类名：
```gdscript
class_name ItemBase  # 可在任何地方使用 ItemBase
```

## 使用方法

### 创建简单物品（继承方式）
```gdscript
# 创建消耗品
var potion = ConsumableItem.new()
potion.item_name = "生命药水"
potion.restore_health = 50
potion.use(player)

# 创建装备
var sword = EquipmentItem.new()
sword.item_name = "铁剑"
sword.damage = 15
sword.equip_slot = EquipmentItem.EquipSlot.MAIN_HAND
```

### 创建复杂物品（组合方式）
```gdscript
# 创建带组件的物品
var magic_item = AdvancedItem.new()
magic_item.item_name = "魔法水晶"

# 添加发光效果
var glow = GlowingComponent.new(magic_item)
glow.glow_color = Color.CYAN
magic_item.add_component(glow)

# 添加降解效果
var degrade = DegradableComponent.new(magic_item)
degrade.degradation_rate = 0.5
magic_item.add_component(degrade)

# 更新物品状态
magic_item.update(delta)
```

### 获取物品信息
```gdscript
var info = item.get_item_info()
print(info)  # 返回 Dictionary

var tooltip = item.get_tooltip_text()
print(tooltip)  # 返回格式化的文本
```

## 继承 vs 组合 - 何时使用？

### 使用继承当：
- 关系明确是 "是一个" (is-a)
- 子类确实是父类的特化版本
- 继承层次较浅 (1-2层)
- 功能固定不变

**例子：** `ConsumableItem` 继承 `ItemBase`

### 使用组合当：
- 关系是 "有一个" (has-a)
- 需要运行时动态添加/移除功能
- 多个类需要相同功能
- 避免复杂的继承链

**例子：** `AdvancedItem` 使用组件系统

### 最佳实践：优先组合，必要时继承
- 使用浅层继承定义核心类型
- 使用组合添加可选功能
- 本系统结合两者优势

## 扩展系统

### 添加新的物品类型
```gdscript
extends ItemBase
class_name QuestItem

@export var quest_id: String = ""
@export var is_key_item: bool = true

func use(user: Node) -> bool:
    # 触发任务相关逻辑
    return true
```

### 添加新的组件
```gdscript
extends ItemComponent
class_name MagicComponent

@export var mana_cost: int = 10

func on_use(user: Node) -> void:
    if user.has("mana"):
        user.mana -= mana_cost
```

## 注意事项

1. **Resource vs Node**: 物品使用 `Resource` 而非 `Node`，因为物品是数据，不需要在场景树中
2. **序列化**: 使用 `Resource` 可以轻松保存/加载物品数据
3. **性能**: 组件系统会有轻微性能开销，但增加了灵活性
4. **类型安全**: 尽量使用类型声明，减少运行时错误
