using Godot;
using Godot.Collections;
using SnowGlobe.Items;

/// <summary>
/// 玩家物理控制器 - 管理玩家移动、属性、状态和背包系统
/// </summary>
public partial class PlayerPhysics : CharacterBody2D
{
    [Signal] public delegate void HitEventHandler();
    [Signal] public delegate void PlayerMovedEventHandler(Vector2 newPosition);

    [Export] public string Id { get; set; } = "player_1";

    // ========================= 枚举定义 =========================
    public enum AgeGroup { Child, Teen, Adult, Elder }
    public enum Gender { Male, Female }

    // ========================= 基础信息 =========================
    [Export] public string NpcName { get; set; } = "DefaultNPC";
    [Export] public AgeGroup Age { get; set; } = AgeGroup.Child;
    [Export] public Gender PlayerGender { get; set; } = Gender.Male;

    // ========================= 移动属性 =========================
    [Export] public float Speed { get; set; } = 256.0f;
    [Export] public float PathSpeed { get; set; } = 256.0f;
    [Export] public float RunningSpeed { get; set; } = 400.0f;

    // ========================= 生命属性 =========================
    [Export] public int CurrentHealth { get; set; } = 100;
    [Export] public int MaxHealth { get; set; } = 100;
    [Export] public int Hunger { get; set; } = 10;
    [Export] public int MaxHunger { get; set; } = 10;
    [Export] public int Energy { get; set; } = 10;
    [Export] public int MaxEnergy { get; set; } = 10;
    [Export] public int Thirst { get; set; } = 10;
    [Export] public int MaxThirst { get; set; } = 10;

    // ========================= 基础能力值 =========================
    [Export] public int Intelligence { get; set; } = 1;
    [Export] public int Strength { get; set; } = 1;
    [Export] public int Agility { get; set; } = 1;
    [Export] public int Charisma { get; set; } = 1;
    [Export] public int Endurance { get; set; } = 1;
    [Export] public int Luck { get; set; } = 1;
    [Export] public int Perception { get; set; } = 1;
    [Export] public int Wisdom { get; set; } = 1;

    // ========================= 技能属性 =========================
    [Export] public int MentalStrength { get; set; } = 1;
    [Export] public int SocialSkills { get; set; } = 1;
    [Export] public int CombatSkills { get; set; } = 1;
    [Export] public int CraftingSkills { get; set; } = 1;
    [Export] public int SurvivalSkills { get; set; } = 1;
    [Export] public int StealthSkills { get; set; } = 1;
    [Export] public int Cooking { get; set; } = 1;

    // ========================= 生存状态 =========================
    [Export] public bool IsAlive { get; set; } = true;
    [Export] public bool IsHungry { get; set; } = false;
    [Export] public bool IsThirsty { get; set; } = false;
    [Export] public bool IsInjured { get; set; } = false;
    [Export] public bool IsTired { get; set; } = false;
    [Export] public bool IsSick { get; set; } = false;

    // ========================= 情绪状态 =========================
    [Export] public bool IsStressed { get; set; } = false;

    // ========================= 移动状态 =========================
    [Export] public bool IsMoving { get; set; } = false;
    [Export] public bool IsWandering { get; set; } = false;

    // ========================= 战斗状态 =========================
    [Export] public bool IsAttacking { get; set; } = false;
    [Export] public bool IsStealthing { get; set; } = false;

    // ========================= 社交状态 =========================
    [Export] public bool IsTalking { get; set; } = false;
    [Export] public bool IsTrading { get; set; } = false;

    // ========================= 工作状态 =========================
    [Export] public bool IsWorking { get; set; } = false;
    [Export] public bool IsCrafting { get; set; } = false;
    [Export] public bool IsBuilding { get; set; } = false;
    [Export] public bool IsCookingFood { get; set; } = false;
    [Export] public bool IsResearching { get; set; } = false;

    // ========================= 资源采集状态 =========================
    [Export] public bool IsGathering { get; set; } = false;
    [Export] public bool IsFishing { get; set; } = false;
    [Export] public bool IsHunting { get; set; } = false;
    [Export] public bool IsMining { get; set; } = false;
    [Export] public bool IsWoodcutting { get; set; } = false;
    [Export] public bool IsFarming { get; set; } = false;

    // ========================= 探索状态 =========================
    [Export] public bool IsExploring { get; set; } = false;

    // ========================= 休息状态 =========================
    [Export] public bool IsResting { get; set; } = false;
    [Export] public bool IsSleeping { get; set; } = false;

    // ========================= 娱乐状态 =========================
    [Export] public bool IsPlaying { get; set; } = false;

    // ========================= 综合状态 =========================
    [Export] public bool IsBusy { get; set; } = false;

    // 内部变量
    private bool _isMovingToTarget = false;
    private Vector2[] _targetPath = System.Array.Empty<Vector2>();
    private int _currentPathIndex = 0;
    private InventorySystem _inventory = null;
    private AnimatedSprite2D _animatedSprite = null;

    public override void _Ready()
    {
        GodotRPC.Instance?.RegisterInstance(Id, this);
        PlayerMoved += OnPlayerMoved;
        ZIndex = 10;

        // 初始化背包系统
        _inventory = new InventorySystem(Strength);
        GD.Print($"[{NpcName}] 背包系统已初始化 | 承重上限: {_inventory.MaxWeight:F1} kg");

        _animatedSprite = GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D");
    }

    /// <summary>返回玩家状态</summary>
    public Dictionary GetStatus()
    {
        return new Dictionary
        {
            { "id", Id },
            { "position", new Dictionary { { "x", Position.X }, { "y", Position.Y } } },
            { "velocity", new Dictionary { { "x", Velocity.X }, { "y", Velocity.Y } } }
        };
    }

    // ========================= 数据获取方法 =========================

    public Dictionary GetBasicInfo() => new Dictionary
    {
        { "id", Id }, { "npc_name", NpcName },
        { "age", Age.ToString() }, { "gender", PlayerGender.ToString() }
    };

    public Dictionary GetMovementAttributes() => new Dictionary
    {
        { "speed", Speed }, { "path_speed", PathSpeed }, { "running_speed", RunningSpeed }
    };

    public Dictionary GetVitalAttributes() => new Dictionary
    {
        { "current_health", CurrentHealth }, { "max_health", MaxHealth },
        { "hunger", Hunger }, { "max_hunger", MaxHunger },
        { "energy", Energy }, { "max_energy", MaxEnergy },
        { "thirst", Thirst }, { "max_thirst", MaxThirst }
    };

    public Dictionary GetBaseStats() => new Dictionary
    {
        { "intelligence", Intelligence }, { "strength", Strength },
        { "agility", Agility }, { "charisma", Charisma },
        { "endurance", Endurance }, { "luck", Luck },
        { "perception", Perception }, { "wisdom", Wisdom }
    };

    public Dictionary GetSkillAttributes() => new Dictionary
    {
        { "mental_strength", MentalStrength }, { "social_skills", SocialSkills },
        { "combat_skills", CombatSkills }, { "crafting_skills", CraftingSkills },
        { "survival_skills", SurvivalSkills }, { "stealth_skills", StealthSkills },
        { "cooking", Cooking }
    };

    public Dictionary GetSurvivalStatus() => new Dictionary
    {
        { "is_alive", IsAlive }, { "is_hungry", IsHungry },
        { "is_thirsty", IsThirsty }, { "is_injured", IsInjured },
        { "is_tired", IsTired }, { "is_sick", IsSick }
    };

    public Dictionary GetEmotionalStatus() => new Dictionary { { "is_stressed", IsStressed } };

    public Dictionary GetMovementStatus() => new Dictionary
    {
        { "is_moving", IsMoving }, { "is_wandering", IsWandering }
    };

    public Dictionary GetCombatStatus() => new Dictionary
    {
        { "is_attacking", IsAttacking }, { "is_stealthing", IsStealthing }
    };

    public Dictionary GetSocialStatus() => new Dictionary
    {
        { "is_talking", IsTalking }, { "is_trading", IsTrading }
    };

    public Dictionary GetWorkStatus() => new Dictionary
    {
        { "is_working", IsWorking }, { "is_crafting", IsCrafting },
        { "is_building", IsBuilding }, { "is_cooking", IsCookingFood },
        { "is_researching", IsResearching }
    };

    public Dictionary GetGatheringStatus() => new Dictionary
    {
        { "is_gathering", IsGathering }, { "is_fishing", IsFishing },
        { "is_hunting", IsHunting }, { "is_mining", IsMining },
        { "is_woodcutting", IsWoodcutting }, { "is_farming", IsFarming }
    };

    public Dictionary GetExplorationStatus() => new Dictionary { { "is_exploring", IsExploring } };
    public Dictionary GetRestStatus() => new Dictionary { { "is_resting", IsResting }, { "is_sleeping", IsSleeping } };
    public Dictionary GetEntertainmentStatus() => new Dictionary { { "is_playing", IsPlaying } };
    public Dictionary GetGeneralStatus() => new Dictionary { { "is_busy", IsBusy } };

    public Dictionary GetAllAttributes() => new Dictionary
    {
        { "basic_info", GetBasicInfo() },
        { "movement_attributes", GetMovementAttributes() },
        { "vital_attributes", GetVitalAttributes() },
        { "base_stats", GetBaseStats() },
        { "skill_attributes", GetSkillAttributes() }
    };

    public Dictionary GetAllStatus() => new Dictionary
    {
        { "survival_status", GetSurvivalStatus() },
        { "emotional_status", GetEmotionalStatus() },
        { "movement_status", GetMovementStatus() },
        { "combat_status", GetCombatStatus() },
        { "social_status", GetSocialStatus() },
        { "work_status", GetWorkStatus() },
        { "gathering_status", GetGatheringStatus() },
        { "exploration_status", GetExplorationStatus() },
        { "rest_status", GetRestStatus() },
        { "entertainment_status", GetEntertainmentStatus() },
        { "general_status", GetGeneralStatus() }
    };

    public Dictionary GetCompleteData() => new Dictionary
    {
        { "attributes", GetAllAttributes() },
        { "status", GetAllStatus() },
        { "position", new Dictionary { { "x", Position.X }, { "y", Position.Y } } },
        { "velocity", new Dictionary { { "x", Velocity.X }, { "y", Velocity.Y } } },
        { "inventory", _inventory?.GetInventoryData() ?? new Dictionary() }
    };

    public void Start(Vector2 pos)
    {
        Position = pos;
        Show();
        GetNode<CollisionShape2D>("CollisionShape2D").Disabled = false;
    }

    /// <summary>重置所有属性和状态到默认值</summary>
    public void Reset()
    {
        NpcName = "DefaultNPC";
        Age = AgeGroup.Child;
        PlayerGender = Gender.Male;

        Speed = 256.0f;
        PathSpeed = 256.0f;
        RunningSpeed = 400.0f;

        CurrentHealth = MaxHealth;
        Hunger = MaxHunger;
        Energy = MaxEnergy;
        Thirst = MaxThirst;

        Intelligence = Strength = Agility = Charisma = 1;
        Endurance = Luck = Perception = Wisdom = 1;

        _inventory?.UpdateMaxWeight(Strength);

        MentalStrength = SocialSkills = CombatSkills = 1;
        CraftingSkills = SurvivalSkills = StealthSkills = Cooking = 1;

        IsAlive = true;
        IsHungry = IsThirsty = IsInjured = IsTired = IsSick = false;
        IsStressed = false;
        IsMoving = IsWandering = false;
        IsAttacking = IsStealthing = false;
        IsTalking = IsTrading = false;
        IsWorking = IsCrafting = IsBuilding = IsCookingFood = IsResearching = false;
        IsGathering = IsFishing = IsHunting = IsMining = IsWoodcutting = IsFarming = false;
        IsExploring = false;
        IsResting = IsSleeping = false;
        IsPlaying = false;
        IsBusy = false;

        _targetPath = System.Array.Empty<Vector2>();
        _currentPathIndex = 0;
        Velocity = Vector2.Zero;
    }

    /// <summary>移动到地图上的随机位置</summary>
    public void MoveToRandomPosition()
    {
        var tilemap = GetNodeOrNull<GameTileMapLayer>("/root/main/TileMapLayer");
        if (tilemap == null)
        {
            GD.Print("找不到 TileMapLayer");
            return;
        }

        var targetGrid = tilemap.GetRandomWalkablePosition();
        var currentGrid = tilemap.LocalToMap(GlobalPosition);
        _targetPath = tilemap.GetAstarPath(currentGrid, targetGrid);

        if (_targetPath.Length > 0)
        {
            IsMoving = true;
            _currentPathIndex = 0;
            IsWandering = true;
            GD.Print($"开始移动到网格: {targetGrid} 路径长度: {_targetPath.Length}");
        }
        else
        {
            GD.Print("无法找到路径");
        }
    }

    /// <summary>移动到指定网格位置</summary>
    public void MoveToPosition(Godot.Collections.Array pos)
    {
        int x = pos[0].AsInt32();
        int y = pos[1].AsInt32();

        var tilemap = GetNodeOrNull<GameTileMapLayer>("/root/main/Node2D/BaseLayer");
        if (tilemap == null)
        {
            GD.Print("找不到 TileMapLayer");
            return;
        }

        var targetGrid = new Vector2I(x, y);
        var currentGrid = tilemap.LocalToMap(GlobalPosition);
        _targetPath = tilemap.GetAstarPath(currentGrid, targetGrid);

        if (_targetPath.Length > 0)
        {
            IsMoving = true;
            _currentPathIndex = 0;
            GD.Print($"开始移动到网格: {targetGrid} 路径长度: {_targetPath.Length}");
        }
        else
        {
            GD.Print("无法找到路径");
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        if (IsMoving)
            MoveAlongPath();
        else
            ManualControl();
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
        {
            // Q键 - 采集植物
            if (keyEvent.Keycode == Key.Q)
            {
                var nearestPlant = FindNearestPlant();
                if (nearestPlant != null)
                {
                    float distance = ComputeGridDistance(GlobalPosition, nearestPlant.GlobalPosition);
                    float maxDistance = ComputeMaxInteractDistance();

                    if (distance <= maxDistance)
                    {
                        var result = nearestPlant.Harvest(this);
                        if (result.Length > 0)
                            GD.Print($"[采集] 获得: {string.Join(", ", result)}");
                        else
                            GD.Print("[采集] 植物尚未成熟或已被采集");
                    }
                    else
                    {
                        GD.Print($"[采集] 距离太远 (网格距离{distance:F1} > {maxDistance:F1})");
                    }
                }
                else
                {
                    GD.Print("[采集] 附近没有植物");
                }
            }
            // E键 - 砍伐植物
            else if (keyEvent.Keycode == Key.E)
            {
                var nearestPlant = FindNearestPlant();
                if (nearestPlant != null)
                {
                    float distance = ComputeGridDistance(GlobalPosition, nearestPlant.GlobalPosition);
                    float maxDistance = ComputeMaxInteractDistance();

                    if (distance <= maxDistance)
                    {
                        var result = nearestPlant.Chop(this);
                        if (result.Length > 0)
                            GD.Print($"[砍伐] 获得: {string.Join(", ", result)}");
                        else
                            GD.Print("[砍伐] 不是树木或无法砍伐");
                    }
                    else
                    {
                        GD.Print($"[砍伐] 距离太远 (网格距离{distance:F1} > {maxDistance:F1})");
                    }
                }
                else
                {
                    GD.Print("[砍伐] 附近没有植物");
                }
            }
        }
    }

    /// <summary>查找最近的植物</summary>
    private AIPlant FindNearestPlant()
    {
        var sceneRoot = GetTree()?.CurrentScene;
        if (sceneRoot == null) return null;

        AIPlant nearest = null;
        float minDistance = float.MaxValue;

        FindNearestPlantRecursive(sceneRoot, ref nearest, ref minDistance);
        return nearest;
    }

    private void FindNearestPlantRecursive(Node node, ref AIPlant nearest, ref float minDistance)
    {
        if (node is AIPlant plant && !plant.IsDead)
        {
            float distance = GlobalPosition.DistanceTo(plant.GlobalPosition);
            if (distance < minDistance)
            {
                minDistance = distance;
                nearest = plant;
            }
        }

        foreach (Node child in node.GetChildren())
            FindNearestPlantRecursive(child, ref nearest, ref minDistance);
    }

    /// <summary>沿着路径移动</summary>
    private void MoveAlongPath()
    {
        if (_currentPathIndex >= _targetPath.Length)
        {
            IsMoving = false;
            Velocity = Vector2.Zero;
            _animatedSprite?.Stop();
            GD.Print("到达目标!");
            IsWandering = false;
            return;
        }

        var target = _targetPath[_currentPathIndex];
        var direction = (target - GlobalPosition).Normalized();
        var distance = GlobalPosition.DistanceTo(target);

        const float arrivalThreshold = 10.0f;

        if (distance < arrivalThreshold)
        {
            _currentPathIndex++;
            if (_currentPathIndex >= _targetPath.Length)
                EmitSignal(SignalName.PlayerMoved, GlobalPosition);
        }
        else
        {
            Velocity = direction * PathSpeed;
            _animatedSprite?.Play();
        }

        MoveAndSlide();
    }

    /// <summary>手动控制移动</summary>
    private void ManualControl()
    {
        var inputDirection = Vector2.Zero;

        if (Input.IsActionPressed("move_right")) inputDirection.X += 1;
        if (Input.IsActionPressed("move_left")) inputDirection.X -= 1;
        if (Input.IsActionPressed("move_down")) inputDirection.Y += 1;
        if (Input.IsActionPressed("move_up")) inputDirection.Y -= 1;

        if (inputDirection.Length() > 0)
        {
            Velocity = inputDirection.Normalized() * Speed;
            _animatedSprite?.Play();
        }
        else
        {
            Velocity = Vector2.Zero;
            _animatedSprite?.Stop();
        }

        MoveAndSlide();
    }

    private void OnBodyEntered(Node body)
    {
        Hide();
        EmitSignal(SignalName.Hit);
        GetNode<CollisionShape2D>("CollisionShape2D").SetDeferred("disabled", true);
    }

    private void OnPlayerMoved(Vector2 newPosition)
    {
        GD.Print($"Player moved to: {newPosition}");
    }

    // ==================== 背包管理方法 ====================

    /// <summary>更新背包承重上限 (当力量值变化时调用)</summary>
    public void UpdateInventoryCapacity()
    {
        _inventory?.UpdateMaxWeight(Strength);
    }

    /// <summary>添加物品到背包</summary>
    public bool AddToInventory(Node item, int quantity = 1)
    {
        if (_inventory == null)
        {
            GD.Print($"[{NpcName}] 背包系统未初始化");
            return false;
        }
        return _inventory.AddItem(item, quantity);
    }

    /// <summary>从背包移除物品</summary>
    public bool RemoveFromInventory(string itemId, int quantity = 1)
    {
        if (_inventory == null)
        {
            GD.Print($"[{NpcName}] 背包系统未初始化");
            return false;
        }
        return _inventory.RemoveItem(itemId, quantity);
    }

    /// <summary>
    /// 与实体交互（当前优先支持植物）
    /// </summary>
    /// <param name="targetId">实体唯一标识（通常为节点 Name，如 AI 生成的 item_id）</param>
    /// <param name="methodName">要调用的方法名，例如 "Harvest"、"Chop"、"grow" 等</param>
    /// <param name="args">调用参数列表</param>
    /// <returns>是否成功触发</returns>
    public bool Interact(string targetId, string methodName, Godot.Collections.Array args = null)
    {
        var target = FindEntityById(targetId);
        if (target == null)
        {
            GD.Print($"[交互] 未找到实体: {targetId}");
            return false;
        }

        if (target is not Node2D target2D)
        {
            GD.Print($"[交互] 实体不是2D节点: {targetId}");
            return false;
        }

        // 先适配植物交互
        if (target is not AIPlant)
        {
            GD.Print($"[交互] 目前仅支持植物，目标类型: {target.GetType().Name}");
            return false;
        }

        float maxDistance = ComputeMaxInteractDistance();
        float distance = ComputeGridDistance(GlobalPosition, target2D.GlobalPosition);
        if (distance > maxDistance)
        {
            GD.Print($"[交互] 距离过远: 网格距离{distance:F2} > {maxDistance:F2}");
            return false;
        }

        if (!target.HasMethod(methodName))
        {
            GD.Print($"[交互] 实体不包含方法: {methodName}");
            return false;
        }

        var callArgs = args ?? new Godot.Collections.Array();
        target.Callv(methodName, callArgs);
        GD.Print($"[交互] {Id} -> {targetId}.{methodName} 网格距离 {distance:F2}/{maxDistance:F2}");
        return true;
    }

    /// <summary>检查背包中是否有指定物品</summary>
    public bool HasItemInInventory(string itemId, int quantity = 1)
    {
        return _inventory?.HasItem(itemId, quantity) ?? false;
    }

    /// <summary>获取背包信息</summary>
    public Dictionary GetInventoryInfo()
    {
        return _inventory?.GetInventoryData() ?? new Dictionary();
    }

    /// <summary>打印背包内容</summary>
    public void PrintInventory()
    {
        _inventory?.PrintInventory();
    }

    /// <summary>清空背包</summary>
    public void ClearInventory()
    {
        _inventory?.ClearInventory();
    }

    /// <summary>计算玩家的最大交互距离（网格单位）</summary>
    private float ComputeMaxInteractDistance()
    {
        // Strength 至少为 1，避免 ln(0)
        var strengthSafe = Mathf.Max(Strength, 1);
        var ln = Mathf.Log(strengthSafe);
        var distance = PlayerGender == Gender.Male ? 1.2f * ln : ln;
        // 确保距离至少为1格
        return Mathf.Max(distance, 1.0f);
    }

    /// <summary>计算两个世界坐标之间的网格距离（曼哈顿距离）</summary>
    private float ComputeGridDistance(Vector2 from, Vector2 to)
    {
        var tilemap = GetNodeOrNull<TileMapLayer>("/root/main/Node2D/BaseLayer");
        if (tilemap == null)
        {
            // 如果没有tilemap，回退到像素距离除以一个默认tile大小
            return from.DistanceTo(to) / 64.0f;
        }

        var gridFrom = tilemap.LocalToMap(from);
        var gridTo = tilemap.LocalToMap(to);

        // 曼哈顿距离
        int dx = Mathf.Abs(gridFrom.X - gridTo.X);
        int dy = Mathf.Abs(gridFrom.Y - gridTo.Y);
        float distance = dx + dy;

        // 确保距离至少为1
        return Mathf.Max(distance, 1.0f);
    }

    /// <summary>根据 id 查找实体（遍历场景树）</summary>
    private Node FindEntityById(string id)
    {
        var root = GetTree()?.CurrentScene;
        if (root == null) return null;
        if (root.Name == id) return root;
        return FindNodeByName(root, id);
    }

    private Node FindNodeByName(Node root, string name)
    {
        foreach (Node child in root.GetChildren())
        {
            if (child.Name == name)
                return child;

            var found = FindNodeByName(child, name);
            if (found != null) return found;
        }
        return null;
    }

    /// <summary>种植果实</summary>
    public Node PlantFruit(string fruitName, Vector2 plantPosition = default)
    {
        if (_inventory == null)
        {
            GD.Print($"[{NpcName}] 背包系统未初始化");
            return null;
        }

        var inventoryData = _inventory.GetInventoryData();
        if (!inventoryData.ContainsKey("items"))
        {
            GD.Print($"[{NpcName}] 背包为空");
            return null;
        }

        var items = inventoryData["items"].AsGodotDictionary();
        if (!items.ContainsKey(fruitName))
        {
            GD.Print($"[{NpcName}] 背包中没有 {fruitName}");
            return null;
        }

        var fruitData = items[fruitName].AsGodotDictionary();
        var fruit = fruitData["item"].As<Node>();

        if (fruit == null || (!fruit.HasMethod("Plant") && fruit.GetClass() != "AIFruit"))
        {
            GD.Print($"[{NpcName}] {fruitName} 不是可种植的果实");
            return null;
        }

        var pos = plantPosition == default ? GlobalPosition : plantPosition;
        return fruit.HasMethod("Plant") ? fruit.Call("Plant", this, pos).As<Node>() : null;
    }
}
