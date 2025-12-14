using Godot;
using Godot.Collections;
using System;
using System.Collections.Generic;

namespace SnowGlobe.Items;

// ==================== 枚举定义 ====================
public enum PlantTypeEnum { 草, 树, 仙人掌 }
public enum SoilTypeEnum { 沙土, 壤土, 岩石 }
public enum FruitDropEnum { 自动掉落, 采集后获得 }
public enum ToolTypeEnum { 无需工具, 镰刀, 斧头, 锄头 }
public enum DeathConditionEnum { 寿命耗尽, 季节结束, 环境不适 }
public enum RarityEnum { 普通, 稀有, 史诗 }
public enum UsageEnum { 药材, 食材, 建材, 观赏 }

// ==================== 数据结构 ====================
/// <summary>表示一个数值范围</summary>
[GlobalClass]
public partial class FloatRange : Resource
{
    [Export] public float Min { get; set; }
    [Export] public float Max { get; set; }

    public FloatRange() { }
    public FloatRange(float min, float max) => (Min, Max) = (min, max);

    public bool Contains(float value) => value >= Min && value <= Max;
    public float Clamp(float value) => Mathf.Clamp(value, Min, Max);
    public void Deconstruct(out float min, out float max) => (min, max) = (Min, Max);
}

public partial class AIPlant : Node2D
{
    // ==================== 基础属性 ====================
    [Export] public string DisplayName { get; set; } = "NULL Plant";
    [Export(PropertyHint.MultilineText)] public string Description { get; set; } = "NULL Description";
    [Export] public PlantTypeEnum PlantType { get; set; } = PlantTypeEnum.草;
    [Export] public int GrowthStages { get; set; } = 4;
    [Export] public int CurrentStage { get; set; }
    [Export] public bool HasFruit { get; set; }
    [Export] public float Lifespan { get; set; } = 100.0f;
    [Export] public string DeathTexturePath { get; set; } = "";
    [Export] public string[] HarvestProducts { get; set; } = [];
    [Export] public string[] ChopProducts { get; set; } = [];

    // ==================== 生长环境 ====================
    [ExportGroup("生长环境")]
    [Export] public SoilTypeEnum SoilType { get; set; } = SoilTypeEnum.壤土;
    [Export] public FloatRange HumidityRange { get; set; } = new(30f, 70f);
    [Export] public FloatRange TemperatureRange { get; set; } = new(10f, 30f);

    // ==================== 果实属性 ====================
    [ExportGroup("果实属性")]
    [Export] public int FruitMatureStage { get; set; } = -1;
    [Export] public FruitDropEnum FruitDropMechanism { get; set; } = FruitDropEnum.采集后获得;
    [Export] public string FruitItemId { get; set; } = "";
    [Export] public string FruitScenePath { get; set; } = "";
    [Export] public int FruitYield { get; set; } = 1;

    // ==================== 采集交互 ====================
    [ExportGroup("采集交互")]
    [Export] public ToolTypeEnum ToolRequired { get; set; } = ToolTypeEnum.无需工具;
    [Export] public int HarvestTimes { get; set; } = 1;
    [Export] public float HarvestCooldown { get; set; }
    [Export] public string SpecialEvent { get; set; } = "";

    // ==================== 生命周期 ====================
    [ExportGroup("生命周期")]
    [Export] public DeathConditionEnum DeathCondition { get; set; } = DeathConditionEnum.寿命耗尽;
    [Export] public string Remains { get; set; } = "";
    [Export] public bool IsDead { get; set; }

    // ==================== 特殊属性 ====================
    [ExportGroup("特殊属性")]
    [Export] public RarityEnum Rarity { get; set; } = RarityEnum.普通;
    [Export] public UsageEnum Usage { get; set; } = UsageEnum.观赏;
    [Export] public bool Regeneration { get; set; }
    [Export] public float Weight { get; set; } = 0.5f;

    // ==================== 运行时状态 ====================
    protected float Age;
    protected float GrowthTimer;
    protected int HarvestedCount;
    protected float CooldownTimer;
    protected AnimatedSprite2D AnimatedSprite;
    protected PackedScene LinkedFruitTemplate;
    protected bool IsInTransition;
    protected bool IsIdleReversed;
    protected string CurrentIdleAnim = "";
    public Texture2D[] StageTextures { get; set; } = [];

    // ==================== 辅助方法 ====================
    protected static bool HasProp(Node node, string prop) => node.Get(prop).VariantType != Variant.Type.Nil;
    protected static int GetInt(Node node, string prop) => node.Get(prop).AsInt32();
    protected static string GetStr(Node node, string prop) => node.Get(prop).AsString();

    public override void _Ready()
    {
        GD.Print($"植物已创建: {Name} (类型: {PlantType}, 生长阶段: {GrowthStages})");
        AnimatedSprite = GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D") ?? FindNodeByType<AnimatedSprite2D>(this);

        // 调整植物图片偏移：256x256图片，地皮底角在y=182
        // 需要对齐到等轴tile中心，同时修正x轴偏移
        if (AnimatedSprite != null)
        {
            AnimatedSprite.Offset = new Vector2(0, -65); // x向左偏移64px修正等轴投影
        }

        UpdateVisualStage();
        if (!string.IsNullOrEmpty(FruitScenePath)) LoadFruitTemplate();

        // 添加调试黑框显示植物应该在的位置
        QueueRedraw();
    }

    public override void _Draw()
    {
        // 获取tilemap来绘制网格边框
        var tilemap = GetNodeOrNull<TileMapLayer>("/root/main/Node2D/BaseLayer");
        if (tilemap != null)
        {
            // 获取当前植物所在的网格坐标
            var gridPos = tilemap.LocalToMap(tilemap.ToLocal(GlobalPosition));
            // 将网格坐标转回tilemap本地坐标（网格中心）
            var gridCenterLocal = tilemap.MapToLocal(gridPos);
            // 转换为全局坐标
            var gridCenterGlobal = tilemap.ToGlobal(gridCenterLocal);
            // 转换为相对于植物节点的本地坐标
            var localCenter = ToLocal(gridCenterGlobal);

            // 等轴瓦片尺寸 256x128，绘制菱形边框
            var halfWidth = 128f;  // 256 / 2
            var halfHeight = 64f;  // 128 / 2

            // 绘制等轴菱形网格边框
            var points = new Vector2[] {
                localCenter + new Vector2(0, -halfHeight),      // 上
                localCenter + new Vector2(halfWidth, 0),        // 右
                localCenter + new Vector2(0, halfHeight),       // 下
                localCenter + new Vector2(-halfWidth, 0),       // 左
                localCenter + new Vector2(0, -halfHeight)       // 回到上（闭合）
            };

            DrawPolyline(points, Colors.Black, 2.0f);
            // 绘制中心点
            DrawCircle(localCenter, 4, Colors.Red);
        }
        else
        {
            // 如果找不到tilemap，绘制简单的十字标记
            DrawLine(new Vector2(-16, 0), new Vector2(16, 0), Colors.Red, 2.0f);
            DrawLine(new Vector2(0, -16), new Vector2(0, 16), Colors.Red, 2.0f);
        }
    }

    protected void LoadFruitTemplate()
    {
        // JSON文件不需要预加载，在使用时通过AIItemLoader动态加载
        if (FruitScenePath.EndsWith(".json"))
        {
            if (FileAccess.FileExists(FruitScenePath))
                GD.Print($"   植物已绑定果实(JSON): {FruitScenePath}");
            return;
        }

        // 场景文件可以预加载
        if (ResourceLoader.Exists(FruitScenePath))
        {
            LinkedFruitTemplate = GD.Load<PackedScene>(FruitScenePath);
            if (LinkedFruitTemplate != null)
                GD.Print($"   植物已绑定果实(场景): {FruitScenePath}");
        }
    }

    // ==================== 背包检测方法 ====================
    public bool IsInInventory(Node character = null)
    {
        if (character != null)
        {
            var inv = character.Get("inventory");
            if (inv.VariantType != Variant.Type.Nil)
            {
                var inventory = inv.As<Node>();
                if (inventory != null)
                    return (bool)inventory.Call("has_item", DisplayName, 1);
            }
            return false;
        }
        return GetOwnerCharacter() != null;
    }

    public Node GetOwnerCharacter()
    {
        var root = GetTree()?.Root;
        if (root == null) return null;

        foreach (var character in FindAllCharacters(root))
        {
            var inv = character.Get("inventory");
            if (inv.VariantType != Variant.Type.Nil)
            {
                var inventory = inv.As<Node>();
                if (inventory != null && (bool)inventory.Call("has_item", DisplayName, 1))
                    return character;
            }
        }
        return null;
    }

    public int GetQuantityInInventory(Node character)
    {
        if (character == null) return 0;
        var inv = character.Get("inventory");
        if (inv.VariantType == Variant.Type.Nil) return 0;
        var inventory = inv.As<Node>();
        return inventory != null ? (int)inventory.Call("get_item_quantity", DisplayName) : 0;
    }

    protected List<Node> FindAllCharacters(Node node)
    {
        var characters = new List<Node>();
        if (node.Get("inventory").VariantType != Variant.Type.Nil)
            characters.Add(node);
        foreach (Node child in node.GetChildren())
            characters.AddRange(FindAllCharacters(child));
        return characters;
    }

    public override void _Process(double delta)
    {
        if (IsDead) return;

        Age += (float)delta;
        if (Lifespan > 0 && Age >= Lifespan) { Die(); return; }

        if (CurrentStage < GrowthStages - 1)
        {
            GrowthTimer += (float)delta;
            float stageDuration = Lifespan > 0 ? Lifespan / GrowthStages : 10.0f;
            if (GrowthTimer >= stageDuration) { GrowToNextStage(); GrowthTimer = 0.0f; }
        }

        if (HasFruit && FruitDropMechanism == FruitDropEnum.自动掉落 && CurrentStage >= FruitMatureStage)
            AutoDropFruit((float)delta);

        if (CooldownTimer > 0) CooldownTimer -= (float)delta;
    }

    /// <summary>生长到下一阶段</summary>
    public void Grow() => GrowToNextStage();

    protected void GrowToNextStage()
    {
        if (CurrentStage >= GrowthStages - 1) return;
        CurrentStage++;
        UpdateVisualStage();
        GD.Print($"{Name} 进入生长阶段 {CurrentStage + 1}/{GrowthStages}");
        if (HasFruit && CurrentStage == FruitMatureStage)
            GD.Print($"{Name} 的果实已成熟！");
    }

    protected void UpdateVisualStage()
    {
        if (AnimatedSprite?.SpriteFrames == null) return;

        if (!AnimatedSprite.IsConnected(AnimatedSprite2D.SignalName.AnimationFinished, Callable.From(OnAnimationFinished)))
            AnimatedSprite.AnimationFinished += OnAnimationFinished;

        // 动画命名格式: stage{X}_transition 和 stage{X}_idle (1-based)
        int stageNum = CurrentStage + 1;
        string transitionAnim = $"stage{stageNum}_transition";
        string idleAnim = $"stage{stageNum}_idle";
        CurrentIdleAnim = idleAnim;

        if (AnimatedSprite.SpriteFrames.HasAnimation(transitionAnim))
        {
            IsInTransition = true;
            IsIdleReversed = false;
            AnimatedSprite.Animation = transitionAnim;
            AnimatedSprite.Play();
        }
        else if (AnimatedSprite.SpriteFrames.HasAnimation(idleAnim))
        {
            StartIdleAnimation(idleAnim);
        }
    }

    protected void StartIdleAnimation(string idleAnim)
    {
        IsInTransition = false;
        IsIdleReversed = false;
        CurrentIdleAnim = idleAnim;
        AnimatedSprite.Animation = idleAnim;
        AnimatedSprite.Frame = 0;
        AnimatedSprite.Play();
    }

    protected void OnAnimationFinished()
    {
        if (AnimatedSprite == null) return;

        if (IsInTransition)
        {
            IsInTransition = false;
            if (AnimatedSprite.SpriteFrames.HasAnimation(CurrentIdleAnim))
                StartIdleAnimation(CurrentIdleAnim);
            return;
        }

        if (AnimatedSprite.Animation.ToString().Contains("_idle"))
        {
            IsIdleReversed = !IsIdleReversed;
            int frameCount = AnimatedSprite.SpriteFrames.GetFrameCount(AnimatedSprite.Animation);
            if (IsIdleReversed)
            {
                AnimatedSprite.Frame = frameCount - 1;
                AnimatedSprite.PlayBackwards();
            }
            else
            {
                AnimatedSprite.Frame = 0;
                AnimatedSprite.Play();
            }
        }
    }

    /// <summary>采集植物</summary>
    public string[] Harvest(Node harvester = null)
    {
        if (IsDead) return [];

        // 只有最后阶段可以收获
        if (CurrentStage < GrowthStages - 1)
        {
            GD.Print($"[采集] {DisplayName} 尚未成熟 ({CurrentStage + 1}/{GrowthStages})");
            return [];
        }

        if (HarvestTimes > 0 && HarvestedCount >= HarvestTimes) return [];
        if (CooldownTimer > 0) return [];
        if (ToolRequired != ToolTypeEnum.无需工具 && harvester != null && !HasRequiredTool(harvester))
            return [];

        var products = new List<string>();

        // 收集果实
        GD.Print($"[采集调试] HasFruit={HasFruit}, CurrentStage={CurrentStage}, FruitMatureStage={FruitMatureStage}");
        if (HasFruit && CurrentStage >= FruitMatureStage && FruitDropMechanism == FruitDropEnum.采集后获得)
        {
            GD.Print($"[采集调试] 开始生成果实，数量={FruitYield}, FruitScenePath={FruitScenePath}");
            for (int i = 0; i < FruitYield; i++)
            {
                Node2D fruitInstance = null;

                // 优先从场景模板实例化
                if (LinkedFruitTemplate != null)
                {
                    GD.Print($"[采集调试] 从场景模板实例化果实 #{i + 1}");
                    fruitInstance = LinkedFruitTemplate.Instantiate<Node2D>();
                }
                // 尝试从JSON路径加载
                else if (!string.IsNullOrEmpty(FruitScenePath))
                {
                    GD.Print($"[采集调试] 从JSON加载果实 #{i + 1}: {FruitScenePath}");
                    fruitInstance = AIItemLoader.LoadAIItem(FruitScenePath);
                }

                if (fruitInstance != null)
                {
                    GD.Print($"[采集调试] 果实 #{i + 1} 实例化成功: {fruitInstance.Name}");
                    bool stored = harvester != null && TryAddToInventory(harvester, fruitInstance);
                    if (!stored)
                    {
                        GD.Print($"[采集调试] 果实 #{i + 1} 背包满，放置地面");
                        PlaceOnGround(fruitInstance);
                    }
                    else
                    {
                        GD.Print($"[采集调试] 果实 #{i + 1} 已放入背包");
                        products.Add(fruitInstance.Name);
                    }
                }
                else
                {
                    GD.Print($"[采集调试] 果实 #{i + 1} 实例化失败");
                    if (!string.IsNullOrEmpty(FruitItemId))
                    {
                        GD.Print($"[采集调试] 使用FruitItemId: {FruitItemId}");
                        products.Add(FruitItemId);
                    }
                }
            }
        }

        // 收集其他收获物（支持JSON路径和场景路径）
        GD.Print($"[采集调试] HarvestProducts数量={HarvestProducts.Length}");
        foreach (var productPath in HarvestProducts)
        {
            if (string.IsNullOrEmpty(productPath))
            {
                GD.Print($"[采集调试] 跳过空路径");
                continue;
            }

            GD.Print($"[采集调试] 处理收获物: {productPath}");
            Node2D productInstance = null;

            // 尝试作为JSON路径加载
            if (productPath.EndsWith(".json"))
            {
                bool exists = FileAccess.FileExists(productPath);
                GD.Print($"[采集调试] JSON文件存在={exists}: {productPath}");
                if (exists)
                {
                    productInstance = AIItemLoader.LoadAIItem(productPath);
                    GD.Print($"[采集调试] JSON加载结果: {(productInstance != null ? "成功" : "失败")}");
                }
            }
            // 尝试作为场景路径加载
            else if (ResourceLoader.Exists(productPath))
            {
                GD.Print($"[采集调试] 从场景加载: {productPath}");
                var template = GD.Load<PackedScene>(productPath);
                if (template != null)
                    productInstance = template.Instantiate<Node2D>();
                GD.Print($"[采集调试] 场景加载结果: {(productInstance != null ? "成功" : "失败")}");
            }
            else
            {
                GD.Print($"[采集调试] 路径不存在: {productPath}");
            }

            // 如果成功加载，尝试放入背包或地面
            if (productInstance != null)
            {
                GD.Print($"[采集调试] 收获物实例化成功: {productInstance.Name}");
                bool stored = harvester != null && TryAddToInventory(harvester, productInstance);
                if (!stored)
                {
                    GD.Print($"[采集调试] 收获物放置地面");
                    PlaceOnGround(productInstance);
                }
                else
                {
                    GD.Print($"[采集调试] 收获物放入背包");
                }
                products.Add(productInstance.Name);
            }
            else
            {
                GD.Print($"[采集调试] 作为物品ID记录: {productPath}");
                // 作为物品ID记录
                products.Add(productPath);
            }
        }

        HarvestedCount++;
        CooldownTimer = HarvestCooldown;

        string harvesterName = harvester != null && HasProp(harvester, "npc_name")
            ? GetStr(harvester, "npc_name") : "未知";
        GD.Print($"[采集] {harvesterName} 采集了 {DisplayName}，获得 {products.Count} 种产物");

        // 收获后回退一阶段
        if (CurrentStage > 0)
        {
            CurrentStage--;
            UpdateVisualStage();
            GD.Print($"[生长] {DisplayName} 回退到阶段 {CurrentStage + 1}/{GrowthStages}");
        }

        return products.ToArray();
    }

    /// <summary>尝试放入玩家背包；失败则返回 false</summary>
    private bool TryAddToInventory(Node harvester, Node item)
    {
        if (harvester == null || item == null) return false;

        // C# 背包接口
        if (harvester.HasMethod("AddToInventory"))
            return harvester.Call("AddToInventory", item, 1).AsBool();

        // GDScript 背包接口
        var inv = harvester.Get("inventory");
        if (inv.VariantType != Variant.Type.Nil)
        {
            var inventory = inv.As<Node>();
            if (inventory != null && inventory.HasMethod("add_item"))
                return inventory.Call("add_item", item, 1).AsBool();
        }

        return false;
    }

    /// <summary>将物品放到地面（植物所在位置，对齐tilemap网格）</summary>
    private void PlaceOnGround(Node2D item)
    {
        var sceneRoot = GetTree()?.CurrentScene ?? GetParent();
        if (sceneRoot == null)
        {
            item.QueueFree();
            return;
        }

        sceneRoot.AddChild(item);

        // 查找tilemap并对齐网格
        var tilemap = GetNodeOrNull<TileMapLayer>("/root/main/Node2D/BaseLayer");
        if (tilemap != null)
        {
            // 将当前位置转换为网格坐标，再转回世界坐标（对齐网格）
            var gridPos = tilemap.LocalToMap(GlobalPosition);
            item.GlobalPosition = tilemap.MapToLocal(gridPos);
            GD.Print($"[采集] 背包满，物品掉落地面: {item.Name} @ 网格{gridPos} (世界坐标{item.GlobalPosition})");
        }
        else
        {
            // 没有tilemap时使用绝对坐标
            item.GlobalPosition = GlobalPosition;
            GD.Print($"[采集] 背包满，物品掉落地面: {item.Name} @ {item.GlobalPosition}");
        }
    }

    /// <summary>砍伐植物</summary>
    public string[] Chop(Node chopper = null)
    {
        if (PlantType != PlantTypeEnum.树 || IsDead) return [];
        if (chopper != null && !HasRequiredTool(chopper, ToolTypeEnum.斧头)) return [];

        string chopperName = chopper != null && HasProp(chopper, "npc_name")
            ? GetStr(chopper, "npc_name") : "未知";
        GD.Print($"[砍伐] {chopperName} 砍伐了 {DisplayName}");

        var products = new List<string>();

        // 尝试将砍伐产物放入背包或地上
        foreach (var productId in ChopProducts)
        {
            // 如果有对应的场景模板，实例化并放置
            string scenePath = $"res://scenes/items/{productId}.tscn";
            if (ResourceLoader.Exists(scenePath))
            {
                var template = GD.Load<PackedScene>(scenePath);
                if (template != null)
                {
                    var itemInstance = template.Instantiate<Node2D>();
                    if (itemInstance != null)
                    {
                        bool stored = chopper != null && TryAddToInventory(chopper, itemInstance);
                        if (!stored) PlaceOnGround(itemInstance);
                        products.Add(productId);
                    }
                }
            }
            else
            {
                products.Add(productId);
            }
        }

        Die();
        return products.ToArray();
    }

    protected void Die()
    {
        if (IsDead) return;
        IsDead = true;
        GD.Print($"{Name} 已枯死 (原因: {DeathCondition})");
        GD.Print($"[死亡调试] Remains 值: '{Remains}' (是否为空: {string.IsNullOrEmpty(Remains)})");
        GD.Print($"[死亡调试] 植物当前位置: GlobalPosition={GlobalPosition}, Position={Position}");

        // 在原地生成遗留物
        if (!string.IsNullOrEmpty(Remains))
        {
            GD.Print($"[死亡调试] 准备调用 SpawnRemains()");
            SpawnRemains();
        }
        else
        {
            GD.Print($"[死亡调试] Remains 为空，跳过生成遗留物");
        }

        // 直接回收整个实例
        QueueFree();
    }

    protected void SpawnRemains()
    {
        GD.Print($"[死亡调试] 开始生成遗留物: {Remains}");
        // 尝试加载遗留物场景或从JSON加载
        Node2D remainItem = null;

        // 优先尝试作为JSON路径加载
        if (Remains.EndsWith(".json"))
        {
            bool exists = FileAccess.FileExists(Remains);
            GD.Print($"[死亡调试] JSON文件存在={exists}: {Remains}");
            if (exists)
            {
                remainItem = AIItemLoader.LoadAIItem(Remains);
                GD.Print($"[死亡调试] JSON加载结果: {(remainItem != null ? "成功" : "失败")}");
            }
            else
            {
                GD.Print($"[死亡调试] JSON文件不存在: {Remains}");
            }
        }
        // 尝试作为场景路径加载
        else if (ResourceLoader.Exists(Remains))
        {
            GD.Print($"[死亡调试] 从场景加载: {Remains}");
            var template = GD.Load<PackedScene>(Remains);
            if (template != null)
            {
                remainItem = template.Instantiate<Node2D>();
                GD.Print($"[死亡调试] 场景实例化: {(remainItem != null ? "成功" : "失败")}");
            }
        }
        else
        {
            GD.Print($"[死亡调试] 路径不存在: {Remains}");
        }

        if (remainItem == null)
        {
            GD.Print($"[植物死亡] 无法加载遗留物: {Remains}");
            return;
        }

        GD.Print($"[死亡调试] 遗留物实例化成功: {remainItem.Name}");

        // 将遗留物放置在植物当前位置
        var sceneRoot = GetTree()?.CurrentScene ?? GetParent();
        GD.Print($"[死亡调试] sceneRoot: {(sceneRoot != null ? sceneRoot.Name : "null")}");
        if (sceneRoot == null)
        {
            GD.PrintErr($"[死亡调试] sceneRoot 为 null，无法添加遗留物");
            remainItem.QueueFree();
            return;
        }

        sceneRoot.AddChild(remainItem);
        GD.Print($"[死亡调试] 遗留物已添加到场景树，父节点: {remainItem.GetParent()?.Name}");
        GD.Print($"[死亡调试] 遗留物在场景树中: {remainItem.IsInsideTree()}");
        GD.Print($"[死亡调试] 遗留物可见: {remainItem.Visible}");
        GD.Print($"[死亡调试] 设置位置前 - 遗留物位置: {remainItem.GlobalPosition}");

        // 查找tilemap并对齐网格
        var tilemap = GetNodeOrNull<TileMapLayer>("/root/main/Node2D/BaseLayer");
        if (tilemap != null)
        {
            // 将当前位置转换为网格坐标，再转回世界坐标（对齐网格）
            var gridPos = tilemap.LocalToMap(GlobalPosition);
            var targetPos = tilemap.MapToLocal(gridPos);
            GD.Print($"[死亡调试] 植物 GlobalPosition: {GlobalPosition} -> 网格: {gridPos} -> 目标位置: {targetPos}");

            remainItem.GlobalPosition = targetPos;
            GD.Print($"[植物死亡] 生成遗留物: {Remains} @ 网格{gridPos} (世界坐标{remainItem.GlobalPosition})");
        }
        else
        {
            // 没有tilemap时使用绝对坐标
            remainItem.GlobalPosition = GlobalPosition;
            GD.Print($"[植物死亡] 生成遗留物: {Remains} @ {remainItem.GlobalPosition}");
        }

        GD.Print($"[死亡调试] 最终检查 - 遗留物位置: {remainItem.GlobalPosition}, Z-Index: {remainItem.ZIndex}, 可见: {remainItem.Visible}");

        // 检查遗留物的子节点（Sprite2D）
        var sprite = remainItem.GetNodeOrNull<Sprite2D>("Sprite2D");
        if (sprite != null)
        {
            GD.Print($"[死亡调试] Sprite2D - Position: {sprite.Position}, Offset: {sprite.Offset}, Visible: {sprite.Visible}");
        }
    }
    protected void AutoDropFruit(float delta) { /* TODO */ }

    protected bool HasRequiredTool(Node user, ToolTypeEnum? requiredTool = null)
    {
        var tool = requiredTool ?? ToolRequired;
        if (tool == ToolTypeEnum.无需工具) return true;
        return user.Get("inventory").VariantType != Variant.Type.Nil;
    }

    protected T FindNodeByType<T>(Node root) where T : Node
    {
        foreach (Node child in root.GetChildren())
        {
            if (child is T result) return result;
            var found = FindNodeByType<T>(child);
            if (found != null) return found;
        }
        return null;
    }

    // ==================== 静态生成方法 ====================

    /// <summary>在指定的tilemap网格位置生成植物</summary>
    /// <param name="plant">植物节点</param>
    /// <param name="gridPos">网格坐标</param>
    /// <param name="parent">父节点</param>
    /// <param name="tilemapPath">TileMapLayer节点路径，默认为"/root/main/Node2D/BaseLayer"</param>
    public static void SpawnAtGrid(Node2D plant, Vector2I gridPos, Node parent, string tilemapPath = "/root/main/Node2D/BaseLayer")
    {
        if (plant == null || parent == null) return;

        var tilemap = parent.GetNodeOrNull<TileMapLayer>(tilemapPath);
        if (tilemap == null)
        {
            GD.PrintErr($"[AIPlant.SpawnAtGrid] 错误：找不到TileMapLayer节点 '{tilemapPath}'");
            return;
        }

        parent.AddChild(plant);

        // MapToLocal返回瓦片中心坐标（通过TileSet的texture_origin配置）
        var localToTilemap = tilemap.MapToLocal(gridPos);
        var globalPos = tilemap.ToGlobal(localToTilemap);
        plant.GlobalPosition = globalPos;

        GD.Print($"[AIPlant.SpawnAtGrid] 网格{gridPos} → Tilemap本地{localToTilemap} → 全局{globalPos}");
    }

    /// <summary>在指定的世界坐标附近的网格位置生成植物</summary>
    /// <param name="plant">植物节点</param>
    /// <param name="nearWorldPos">参考的世界坐标</param>
    /// <param name="offsetX">网格X偏移</param>
    /// <param name="offsetY">网格Y偏移</param>
    /// <param name="parent">父节点</param>
    /// <param name="tilemapPath">TileMapLayer节点路径，默认为"/root/main/Node2D/BaseLayer"</param>
    public static void SpawnNear(Node2D plant, Vector2 nearWorldPos, int offsetX, int offsetY, Node parent, string tilemapPath = "/root/main/Node2D/BaseLayer")
    {
        if (plant == null || parent == null) return;

        var tilemap = parent.GetNodeOrNull<TileMapLayer>(tilemapPath);
        if (tilemap == null)
        {
            GD.PrintErr($"[AIPlant.SpawnNear] 错误：找不到TileMapLayer节点 '{tilemapPath}'");
            return;
        }

        var refGrid = tilemap.LocalToMap(nearWorldPos);
        var gridPos = new Vector2I(refGrid.X + offsetX, refGrid.Y + offsetY);
        SpawnAtGrid(plant, gridPos, parent, tilemapPath);
    }

    public Dictionary GetInfo() => new()
    {
        ["name"] = Name,
        ["type"] = PlantType.ToString(),
        ["stage"] = $"{CurrentStage + 1}/{GrowthStages}",
        ["age"] = Age,
        ["lifespan"] = Lifespan,
        ["is_dead"] = IsDead,
        ["has_fruit"] = HasFruit,
        ["can_harvest"] = HarvestTimes == 0 || HarvestedCount < HarvestTimes,
        ["rarity"] = Rarity.ToString(),
        ["usage"] = Usage.ToString()
    };
}
