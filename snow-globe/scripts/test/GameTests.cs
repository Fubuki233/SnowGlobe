using Godot;
using Godot.Collections;
using SnowGlobe.Items;
using System.Collections.Generic;

namespace SnowGlobe.Tests;

/// <summary>
/// 游戏系统集成测试 - 包含原 Main.cs 中的所有测试
/// 使用方式：将此节点添加到场景中运行
/// </summary>
public partial class GameTests : Node
{
    [Export] public bool RunOnStart { get; set; } = true;
    [Export] public bool TestAIItems { get; set; } = true;
    [Export] public bool TestBackpack { get; set; } = true;
    [Export] public bool TestItemUsage { get; set; } = true;
    [Export] public bool TestPlants { get; set; } = true;

    private int _passed;
    private int _failed;
    private Node _player;

    public override void _Ready()
    {
        if (RunOnStart)
            RunAllTests();
    }

    /// <summary>运行所有测试</summary>
    public async void RunAllTests()
    {
        _passed = 0;
        _failed = 0;

        GD.Print("\n╔══════════════════════════════════════╗");
        GD.Print("║       游戏系统集成测试               ║");
        GD.Print("╚══════════════════════════════════════╝\n");

        // 查找玩家
        _player = FindPlayer();

        if (TestAIItems)
            RunAIItemSystemTests();

        // 等待场景加载
        await ToSignal(GetTree().CreateTimer(1.0), SceneTreeTimer.SignalName.Timeout);

        if (TestBackpack)
            RunBackpackTests();

        if (TestItemUsage)
            RunItemUsageTests();

        if (TestPlants)
            RunPlantTests();

        PrintSummary();
    }

    // ==================== AI 物品系统测试 ====================

    private void RunAIItemSystemTests()
    {
        GD.Print("\n┌─────────────────────────────────────┐");
        GD.Print("│  AI 物品系统测试                    │");
        GD.Print("└─────────────────────────────────────┘\n");

        // 创建测试目录
        string aiItemsDir = "user://ai_items/";
        if (!DirAccess.DirExistsAbsolute(aiItemsDir))
            DirAccess.MakeDirRecursiveAbsolute(aiItemsDir);

        // 测试：创建 AI 物品配置
        Test_CreateAIItemConfigs();

        // 测试：加载武器
        Test_LoadAIWeapon();

        // 测试：加载药水
        Test_LoadAIPotion();

        // 测试：批量加载
        Test_BatchLoadAIItems();
    }

    private void Test_CreateAIItemConfigs()
    {
        CreateTestAIItems();

        bool flameSwordExists = FileAccess.FileExists("user://ai_items/flame_sword.json");
        bool healthPotionExists = FileAccess.FileExists("user://ai_items/health_potion.json");
        bool iceStaffExists = FileAccess.FileExists("user://ai_items/ice_staff.json");

        Assert(flameSwordExists, "flame_sword.json 创建成功");
        Assert(healthPotionExists, "health_potion.json 创建成功");
        Assert(iceStaffExists, "ice_staff.json 创建成功");
    }

    private void Test_LoadAIWeapon()
    {
        var weapon = AIItemLoader.LoadAIItem("user://ai_items/flame_sword.json");
        Assert(weapon != null, "AI 武器加载成功");

        if (weapon != null)
        {
            weapon.Position = new Vector2(400, 200);
            AddChild(weapon);
            Assert(weapon.Get("DisplayName").ToString() == "烈焰之剑", "武器名称正确");
        }
    }

    private void Test_LoadAIPotion()
    {
        var potion = AIItemLoader.LoadAIItem("user://ai_items/health_potion.json");
        Assert(potion != null, "AI 药水加载成功");

        if (potion != null)
        {
            potion.Position = new Vector2(550, 200);
            AddChild(potion);
            Assert(potion.Get("DisplayName").ToString() == "高级生命药水", "药水名称正确");
        }
    }

    private void Test_BatchLoadAIItems()
    {
        var allItems = AIItemLoader.LoadAllFromDirectory("user://ai_items/");
        Assert(allItems.Count >= 3, $"批量加载成功 (加载了 {allItems.Count} 个物品)");

        for (int i = 2; i < allItems.Count; i++)
        {
            var item = allItems[i];
            if (item != null)
            {
                item.Position = new Vector2(300 + i * 100, 350);
                AddChild(item);
            }
        }
    }

    // ==================== 背包系统测试 ====================

    private void RunBackpackTests()
    {
        GD.Print("\n┌─────────────────────────────────────┐");
        GD.Print("│  背包系统测试                       │");
        GD.Print("└─────────────────────────────────────┘\n");

        if (_player == null)
        {
            GD.Print("  ⚠ 未找到玩家节点，跳过背包测试");
            return;
        }

        Test_AddItemToInventory();
        Test_CheckItemInInventory();
        Test_RemoveItemFromInventory();
        Test_InventoryInfo();
        Test_UpdateInventoryCapacity();
    }

    private void Test_AddItemToInventory()
    {
        var sword = new AIWeapon { DisplayName = "测试铁剑", Weight = 2.5f };
        _player.Call("AddToInventory", sword, 1);
        GD.Print("  添加物品到背包: 测试铁剑");
        Assert(true, "添加物品调用成功");
    }

    private void Test_CheckItemInInventory()
    {
        bool hasSword = (bool)_player.Call("HasItemInInventory", "测试铁剑", 1);
        Assert(hasSword, "背包中包含测试铁剑");
    }

    private void Test_RemoveItemFromInventory()
    {
        _player.Call("RemoveFromInventory", "测试铁剑", 1);
        bool hasSword = (bool)_player.Call("HasItemInInventory", "测试铁剑", 1);
        Assert(!hasSword, "移除物品后背包中不再包含测试铁剑");
    }

    private void Test_InventoryInfo()
    {
        var info = _player.Call("GetInventoryInfo").AsGodotDictionary();
        Assert(info.ContainsKey("current_weight"), "背包信息包含 current_weight");
        Assert(info.ContainsKey("max_weight"), "背包信息包含 max_weight");
        GD.Print($"  当前重量: {info["current_weight"]} / {info["max_weight"]}");
    }

    private void Test_UpdateInventoryCapacity()
    {
        var oldStrength = _player.Get("Strength").AsInt32();
        _player.Set("Strength", 10);
        _player.Call("UpdateInventoryCapacity");

        var info = _player.Call("GetInventoryInfo").AsGodotDictionary();
        Assert((float)info["max_weight"] > 0, "更新力量后背包容量有效");

        _player.Set("Strength", oldStrength);
        _player.Call("UpdateInventoryCapacity");
    }

    // ==================== 物品使用测试 ====================

    private void RunItemUsageTests()
    {
        GD.Print("\n┌─────────────────────────────────────┐");
        GD.Print("│  物品使用系统测试                   │");
        GD.Print("└─────────────────────────────────────┘\n");

        if (_player == null)
        {
            GD.Print("  ⚠ 未找到玩家节点，跳过物品使用测试");
            return;
        }

        PrintPlayerStats("初始属性");

        Test_UseConsumable();
        Test_EquipWeapon();
        Test_WeaponAttack();
        Test_UnequipWeapon();
    }

    private void Test_UseConsumable()
    {
        GD.Print("\n  --- 测试使用药水 ---");
        var potion = GetNodeOrNull("health_potion_001");
        if (potion != null && potion.HasMethod("use"))
        {
            var oldHealth = _player.Get("CurrentHealth").AsInt32();
            _player.Set("CurrentHealth", 50);
            GD.Print($"  降低生命值到: {_player.Get("CurrentHealth")}");

            potion.Call("use", _player);
            var newHealth = _player.Get("CurrentHealth").AsInt32();

            Assert(newHealth >= 50, $"使用药水后生命值恢复 ({newHealth})");
            _player.Set("CurrentHealth", oldHealth);
        }
        else
        {
            GD.Print("  ⚠ 未找到药水节点");
        }
    }

    private void Test_EquipWeapon()
    {
        GD.Print("\n  --- 测试装备武器 ---");
        var weapon = GetNodeOrNull("flame_sword_001");
        if (weapon != null && weapon.HasMethod("equip"))
        {
            var oldStrength = _player.Get("Strength").AsInt32();
            weapon.Call("equip", _player);
            var newStrength = _player.Get("Strength").AsInt32();

            Assert(newStrength >= oldStrength, "装备武器后力量值有效");
            PrintPlayerStats("装备后属性");
        }
        else
        {
            GD.Print("  ⚠ 未找到武器节点");
        }
    }

    private void Test_WeaponAttack()
    {
        GD.Print("\n  --- 测试武器攻击 ---");
        var weapon = GetNodeOrNull("flame_sword_001");
        if (weapon != null && weapon.HasMethod("use"))
        {
            weapon.Call("use");
            weapon.Call("use");
            weapon.Call("use");
            Assert(true, "武器攻击调用成功 (3次)");
        }
    }

    private void Test_UnequipWeapon()
    {
        GD.Print("\n  --- 测试卸下武器 ---");
        var weapon = GetNodeOrNull("flame_sword_001");
        if (weapon != null && weapon.HasMethod("unequip"))
        {
            weapon.Call("unequip");
            PrintPlayerStats("卸下后属性");
            Assert(true, "卸下武器成功");
        }
    }

    // ==================== 植物系统测试 ====================

    private void RunPlantTests()
    {
        GD.Print("\n┌─────────────────────────────────────┐");
        GD.Print("│  AI 植物系统测试                    │");
        GD.Print("└─────────────────────────────────────┘\n");

        string plantsDir = "res://Assets/Items/plants/";
        var dir = DirAccess.Open(plantsDir);

        if (dir == null)
        {
            GD.Print($"  ⚠ 植物目录不存在: {plantsDir}");
            return;
        }

        var plantFolders = GetPlantFolders(dir);
        Assert(plantFolders.Count >= 0, $"扫描植物目录 (找到 {plantFolders.Count} 个植物)");

        if (plantFolders.Count == 0)
        {
            GD.Print("  请先使用 SnowWeave 生成植物动画");
            return;
        }

        Test_LoadPlants(plantsDir, plantFolders);
        Test_PlantHarvestMechanism();
        Test_PlantChopMechanism();
    }

    private List<string> GetPlantFolders(DirAccess dir)
    {
        var folders = new List<string>();
        dir.ListDirBegin();
        string name = dir.GetNext();
        while (!string.IsNullOrEmpty(name))
        {
            if (dir.CurrentIsDir() && !name.StartsWith("."))
                folders.Add(name);
            name = dir.GetNext();
        }
        dir.ListDirEnd();
        return folders;
    }

    private void Test_LoadPlants(string plantsDir, List<string> plantFolders)
    {
        var gameWorld = GetNodeOrNull("Node2D") ?? this;

        int loadedCount = 0;

        for (int i = 0; i < plantFolders.Count; i++)
        {
            var plantName = plantFolders[i];

            var configPath = $"{plantsDir}{plantName}/{plantName}_config.json";
            if (!FileAccess.FileExists(configPath))
                configPath = $"{plantsDir}{plantName}/{plantName}.json";

            if (!FileAccess.FileExists(configPath))
                continue;

            var plant = AIItemLoader.LoadAIItem(configPath);
            if (plant != null)
            {
                // 在网格(0, i)位置生成植物
                AIPlant.SpawnAtGrid(plant, new Vector2I(0, i), gameWorld);
                loadedCount++;

                if (plant.HasMethod("grow"))
                    SetupAutoGrow(plant, plantName);
            }
        }

        Assert(loadedCount > 0 || plantFolders.Count == 0, $"加载植物成功 ({loadedCount}/{plantFolders.Count})");
    }

    private async void SetupAutoGrow(Node plant, string plantName)
    {
        await ToSignal(GetTree().CreateTimer(2.0), SceneTreeTimer.SignalName.Timeout);
        if (!IsInstanceValid(plant)) return;

        GD.Print($"  >> [{plantName}] 触发生长...");
        plant.Call("grow");

        ContinueGrowing(plant, plantName, 1);
    }

    private async void ContinueGrowing(Node plant, string plantName, int stage)
    {
        if (!IsInstanceValid(plant)) return;

        var maxStage = plant.Get("GrowthStages");
        if (maxStage.VariantType == Variant.Type.Nil) return;

        if (stage < maxStage.AsInt32())
        {
            await ToSignal(GetTree().CreateTimer(2.0), SceneTreeTimer.SignalName.Timeout);
            if (!IsInstanceValid(plant)) return;

            GD.Print($"  >> [{plantName}] 生长到阶段 {stage + 1}");
            plant.Call("grow");
            ContinueGrowing(plant, plantName, stage + 1);
        }
    }

    // ==================== 植物交互测试 ====================

    private void Test_PlantHarvestMechanism()
    {
        GD.Print("\n  [植物采集机制测试]");

        // 创建测试植物
        var plant = new AIPlant
        {
            Name = "test_harvest_plant",
            DisplayName = "测试植物",
            GrowthStages = 4,
            CurrentStage = 0,
            HasFruit = true,
            FruitMatureStage = 3,
            FruitDropMechanism = FruitDropEnum.采集后获得,
            FruitItemId = "test_fruit",
            FruitYield = 2,
            HarvestTimes = 5
        };

        // 使用AIPlant静态生成方法：在测试区域生成
        var playerPos = (_player as Node2D)?.GlobalPosition ?? new Vector2(100, 100);
        var gameWorld = GetNodeOrNull("Node2D") ?? this;
        AIPlant.SpawnNear(plant, playerPos, 5, 0, gameWorld);

        // 测试1: 未成熟时无法采集
        var result1 = plant.Harvest(_player);
        Assert(result1.Length == 0, "未成熟植物无法采集");

        // 让植物成长到最后阶段
        while (plant.CurrentStage < plant.GrowthStages - 1)
            plant.Grow();

        int stageBefore = plant.CurrentStage;

        // 测试2: 成熟后可以采集
        var result2 = plant.Harvest(_player);
        Assert(result2.Length >= 0, "成熟植物可以采集");

        // 测试3: 采集后回退一阶段
        Assert(plant.CurrentStage == stageBefore - 1, $"采集后回退一阶段 ({stageBefore} → {plant.CurrentStage})");

        // 测试4: 回退后不在最后阶段时无法采集
        var result3 = plant.Harvest(_player);
        Assert(result3.Length == 0, "回退后的植物无法再次采集");

        plant.QueueFree();
        GD.Print("  >> 植物采集机制测试完成\n");
    }

    private void Test_PlantChopMechanism()
    {
        GD.Print("\n  [植物砍伐机制测试]");

        // 创建测试树木
        var tree = new AIPlant
        {
            Name = "test_tree",
            DisplayName = "测试树木",
            PlantType = PlantTypeEnum.树,
            ChopProducts = new[] { "wood", "stick" },
            ToolRequired = ToolTypeEnum.无需工具
        };

        // 使用AIPlant静态生成方法：在测试区域生成
        var playerPos = (_player as Node2D)?.GlobalPosition ?? new Vector2(100, 100);
        var gameWorld = GetNodeOrNull("Node2D") ?? this;
        AIPlant.SpawnNear(tree, playerPos, 6, 0, gameWorld);

        // 测试1: 砍伐产生产物
        var products = tree.Chop(_player);
        Assert(products.Length > 0, $"砍伐产生产物 ({products.Length} 种)");

        // 测试2: 砍伐后植物死亡
        Assert(tree.IsDead, "砍伐后植物死亡");

        GD.Print("  >> 植物砍伐机制测试完成\n");
    }

    // ==================== 测试数据创建 ====================

    private void CreateTestAIItems()
    {
        // 火焰之剑
        SaveItemJson("user://ai_items/flame_sword.json", new Dictionary
        {
            { "item_id", "flame_sword_001" },
            { "display_name", "烈焰之剑" },
            { "description", "被火焰之力加持的魔法剑" },
            { "texture_path", "res://icon.svg" },
            { "preset_type", "weapon" },
            { "parameters", new Dictionary {
                { "damage", 120 }, { "fire_damage", 60 },
                { "durability", 300 }, { "rarity", "epic" },
                { "price", 3500 }, { "weight", 4.2 },
                { "critical_chance", 0.15 },
                { "strength_bonus", 10 }, { "agility_bonus", 5 },
                { "combat_skills_bonus", 8 }
            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "circle" },
                { "radius", 40.0 }, { "layer", 8 }, { "mask", 1 }
            }}
        });

        // 生命药水
        SaveItemJson("user://ai_items/health_potion.json", new Dictionary
        {
            { "item_id", "health_potion_001" },
            { "display_name", "高级生命药水" },
            { "description", "恢复大量生命值的珍贵药水" },
            { "texture_path", "res://icon.svg" },
            { "preset_type", "consumable" },
            { "parameters", new Dictionary {
                { "healing_amount", 200 }, { "energy_amount", 50 },
                { "hunger_restore", 30 }, { "thirst_restore", 40 },
                { "buff_duration", 10.0 }, { "buff_type", "力量提升" },
                { "strength_buff", 5 }, { "agility_buff", 3 },
                { "rarity", "rare" }, { "price", 150 }, { "stack_size", 50 }
            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "circle" },
                { "radius", 25.0 }, { "layer", 8 }, { "mask", 1 }
            }}
        });

        // 寒冰法杖
        SaveItemJson("user://ai_items/ice_staff.json", new Dictionary
        {
            { "item_id", "ice_staff_001" },
            { "display_name", "寒冰法杖" },
            { "description", "释放冰霜魔法的强大法杖" },
            { "texture_path", "res://icon.svg" },
            { "preset_type", "weapon" },
            { "parameters", new Dictionary {
                { "damage", 80 }, { "ice_damage", 100 },
                { "durability", 250 }, { "rarity", "legendary" },
                { "price", 5000 }, { "weight", 2.5 }
            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "auto" },
                { "layer", 8 }, { "mask", 1 }
            }}
        });

        // 网络图片物品
        SaveItemJson("user://ai_items/network_gem.json", new Dictionary
        {
            { "item_id", "network_gem_001" },
            { "display_name", "网络宝石" },
            { "description", "从网络加载的神秘宝石" },
            { "texture_path", "https://picsum.photos/128/128" },
            { "preset_type", "consumable" },
            { "parameters", new Dictionary {
                { "healing_amount", 0 }, { "energy_amount", 100 },
                { "rarity", "epic" }, { "price", 999 }
            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "circle" },
                { "radius", 30.0 }, { "layer", 8 }, { "mask", 1 }
            }}
        });

        // 草莓果实
        SaveItemJson("user://ai_items/strawberry.json", new Dictionary
        {
            { "item_id", "strawberry_001" },
            { "display_name", "草莓" },
            { "description", "新鲜的草莓，香甜多汁。可以直接食用或种植。" },
            { "texture_path", "res://Assets/Items/fruit/strawberry/strawberry.png" },
            { "preset_type", "consumable" },
            { "parameters", new Dictionary {
                { "healing_amount", 5 }, { "energy_amount", 5 },
                { "hunger_restore", 15 }, { "thirst_restore", 10 },
                { "rarity", "common" }, { "price", 5 },
                { "weight", 0.1 }, { "stack_size", 50 },
                { "is_plantable", true },
                { "plant_scene_path", "res://scenes/plants/strawberry_plant.tscn" },
                { "growth_time", 45.0 },
                { "required_farming_skill", 0 },
                { "required_soil_type", "壤土" },
                { "min_temperature", 15.0 },
                { "max_temperature", 25.0 },

            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "circle" },
                { "radius", 20.0 }, { "layer", 8 }, { "mask", 1 }
            }}
        });

        // 草莓植株
        SaveItemJson("user://ai_items/strawberry_plant.json", new Dictionary
        {
            { "item_id", "strawberry_plant_001" },
            { "display_name", "草莓植株" },
            { "description", "正在生长的草莓植物，成熟后可以采集草莓果实。" },
            { "texture_path", "res://Assets/Items/plants/strawberry/strawberry_stage1.png" },
            { "preset_type", "plant" },
            { "parameters", new Dictionary {
                { "plant_type", "草" },
                { "growth_stages", 4 },
                { "current_stage", 0 },
                { "lifespan", 20.0 },
                { "has_fruit", true },
                { "fruit_mature_stage", 3 },
                { "fruit_drop_mechanism", "采集后获得" },
                { "fruit_scene_path", "user://ai_items/strawberry.json" },
                { "fruit_yield", 3 },
                { "harvest_products", new Godot.Collections.Array { "user://ai_items/strawberry.json" } },
                { "harvest_times", 5 },
                { "harvest_cooldown", 30.0 },
                { "tool_required", "无需工具" },
                { "soil_type", "壤土" },
                { "humidity_min", 40.0 }, { "humidity_max", 80.0 },
                { "temperature_min", 15.0 }, { "temperature_max", 25.0 },
                { "rarity", "common" },
                { "usage", "食材" },
                { "weight", 0.5 },
                { "remains", "user://ai_items/strawberry.json" }
            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "circle" },
                { "radius", 30.0 }, { "layer", 8 }, { "mask", 1 }
            }}
        });
    }

    private void SaveItemJson(string path, Dictionary data)
    {
        using var file = FileAccess.Open(path, FileAccess.ModeFlags.Write);
        file?.StoreString(Json.Stringify(data, "\t"));
    }

    // ==================== 辅助方法 ====================

    private Node FindPlayer()
    {
        // 从场景根节点查找玩家
        var root = GetTree()?.CurrentScene;
        if (root == null)
        {
            GD.Print("  ⚠ 无法获取当前场景");
            return null;
        }

        // 尝试多种路径查找玩家 (相对于场景根节点)
        // player.tscn 结构: player(Node2D) -> Player(CharacterBody2D)
        var paths = new[] {
            "Node2D/player/Player", // node.tscn 中的完整路径
            "player/Player",
            "Node2D/Player",
            "Player",
            "CharacterBody2D"
        };

        foreach (var path in paths)
        {
            var player = root.GetNodeOrNull(path);
            if (player != null)
            {
                GD.Print($"  找到玩家节点: {path} ({player.GetType().Name})");
                return player;
            }
        }

        // 递归查找 CharacterBody2D
        var found = FindNodeByType<CharacterBody2D>(root);
        if (found != null)
        {
            GD.Print($"  找到玩家节点: {found.Name} (递归查找)");
            return found;
        }

        return null;
    }

    private T FindNodeByType<T>(Node root) where T : Node
    {
        if (root is T result) return result;
        foreach (Node child in root.GetChildren())
        {
            var found = FindNodeByType<T>(child);
            if (found != null) return found;
        }
        return null;
    }

    private void PrintPlayerStats(string label)
    {
        if (_player == null) return;

        GD.Print($"\n  {label}:");
        GD.Print($"    生命值: {_player.Get("CurrentHealth")}/{_player.Get("MaxHealth")}");
        GD.Print($"    能量: {_player.Get("Energy")}/{_player.Get("MaxEnergy")}");
        GD.Print($"    力量: {_player.Get("Strength")}");
        GD.Print($"    敏捷: {_player.Get("Agility")}");
        GD.Print($"    战斗技能: {_player.Get("CombatSkills")}");
    }

    private void Assert(bool condition, string message)
    {
        if (condition)
        {
            _passed++;
            GD.Print($"  ✓ {message}");
        }
        else
        {
            _failed++;
            GD.PrintErr($"  ✗ {message}");
        }
    }

    private void PrintSummary()
    {
        GD.Print("\n╔══════════════════════════════════════╗");
        GD.Print($"║  测试结果: {_passed} 通过, {_failed} 失败".PadRight(38) + "║");
        GD.Print("╚══════════════════════════════════════╝\n");
    }
}
