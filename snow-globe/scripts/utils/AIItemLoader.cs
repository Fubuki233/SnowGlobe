using Godot;
using Godot.Collections;
using System.Collections.Generic;

/// <summary>
/// AI 物品加载器
/// 功能:
/// 1. 从 JSON 配置文件加载 AI 生成的物品
/// 2. 实例化预制场景并应用参数
/// 3. 支持从 user:// 路径加载图片
/// </summary>
public partial class AIItemLoader : Node
{
    // 预制场景路径映射
    private static readonly System.Collections.Generic.Dictionary<string, string> PresetPaths = new()
    {
        { "weapon", "res://scenes/item_presets/weapon_preset.tscn" },
        { "consumable", "res://scenes/item_presets/consumable_preset.tscn" },
        { "equipment", "res://scenes/item_presets/equipment_preset.tscn" },
        { "block", "res://scenes/item_presets/block_preset.tscn" },
        { "plant", "res://scenes/item_presets/plant_preset.tscn" },
        { "default", "res://scenes/item_presets/default_preset.tscn" }
    };

    /// <summary>从 JSON 文件加载并实例化物品</summary>
    public static Node2D LoadAIItem(string jsonPath)
    {
        // 1. 读取 JSON 配置
        var config = LoadJsonConfig(jsonPath);
        if (config.Count == 0)
        {
            GD.PushError($"无法加载 JSON 配置: {jsonPath}");
            return null;
        }

        var displayName = config.ContainsKey("display_name") ? config["display_name"].AsString() : "未命名";
        GD.Print($"\n=== 加载 AI 物品: {displayName} ===");

        // 2. 加载预制场景
        var presetType = config.ContainsKey("preset_type") ? config["preset_type"].AsString() : "default";
        var instance = InstantiatePreset(presetType);
        if (instance == null)
        {
            GD.PushError($"无法实例化预制场景: {presetType}");
            return null;
        }

        // 3. 设置基础属性
        instance.Name = config.ContainsKey("item_id") ? config["item_id"].AsString() : "ai_item";

        // 4. 加载并应用贴图
        var texturePath = config.ContainsKey("texture_path") ? config["texture_path"].AsString() : "";
        var animConfig = config.ContainsKey("animation") ? config["animation"].AsGodotDictionary() : new Dictionary();
        if (!string.IsNullOrEmpty(texturePath))
            ApplyTexture(instance, texturePath, animConfig);

        // 4.5. 加载植物生长阶段动画
        if (presetType == "plant")
            SetupPlantAnimations(instance, config);

        // 5. 应用参数
        var parameters = config.ContainsKey("parameters") ? config["parameters"].AsGodotDictionary() : new Dictionary();
        ApplyParameters(instance, parameters);

        // 6. 生成碰撞体积
        var collisionConfig = config.ContainsKey("collision") ? config["collision"].AsGodotDictionary() : new Dictionary();
        if (collisionConfig.ContainsKey("enabled") && collisionConfig["enabled"].AsBool())
            GenerateCollision(instance, texturePath, collisionConfig);

        // 7. 配置组件
        var components = config.ContainsKey("components") ? config["components"].AsGodotDictionary() : new Dictionary();
        ConfigureComponents(instance, components);

        GD.Print($" AI 物品加载成功: {displayName}");
        return instance;
    }

    /// <summary>批量加载多个 AI 物品</summary>
    public static List<Node2D> LoadAIItemsBatch(Godot.Collections.Array jsonPaths)
    {
        var items = new List<Node2D>();
        foreach (var path in jsonPaths)
        {
            var item = LoadAIItem(path.AsString());
            if (item != null)
                items.Add(item);
        }
        return items;
    }

    /// <summary>从目录加载所有 AI 物品</summary>
    public static List<Node2D> LoadAllFromDirectory(string directoryPath)
    {
        var items = new List<Node2D>();
        var dir = DirAccess.Open(directoryPath);

        if (dir == null)
        {
            GD.PushError($"无法打开目录: {directoryPath}");
            return items;
        }

        dir.ListDirBegin();
        string fileName = dir.GetNext();

        while (!string.IsNullOrEmpty(fileName))
        {
            if (fileName.EndsWith(".json"))
            {
                string fullPath = directoryPath.PathJoin(fileName);
                var item = LoadAIItem(fullPath);
                if (item != null)
                    items.Add(item);
            }
            fileName = dir.GetNext();
        }

        GD.Print($"从目录 {directoryPath} 加载了 {items.Count} 个 AI 物品");
        return items;
    }

    /// <summary>读取并解析 JSON 配置文件</summary>
    private static Dictionary LoadJsonConfig(string jsonPath)
    {
        if (!FileAccess.FileExists(jsonPath))
        {
            GD.PushError($"JSON 文件不存在: {jsonPath}");
            return new Dictionary();
        }

        using var file = FileAccess.Open(jsonPath, FileAccess.ModeFlags.Read);
        if (file == null)
        {
            GD.PushError($"无法打开 JSON 文件: {jsonPath}");
            return new Dictionary();
        }

        var jsonText = file.GetAsText();
        var json = new Json();
        var error = json.Parse(jsonText);

        if (error != Error.Ok)
        {
            GD.PushError($"JSON 解析失败 (行 {json.GetErrorLine()}): {json.GetErrorMessage()}");
            return new Dictionary();
        }

        return json.Data.AsGodotDictionary();
    }

    /// <summary>根据类型实例化预制场景</summary>
    private static Node2D InstantiatePreset(string presetType)
    {
        var presetPath = PresetPaths.ContainsKey(presetType) ? PresetPaths[presetType] : PresetPaths["default"];

        if (!FileAccess.FileExists(presetPath))
        {
            GD.PushWarning($"预制场景不存在: {presetPath}，使用默认预制");
            presetPath = PresetPaths["default"];
        }

        var scene = GD.Load<PackedScene>(presetPath);
        if (scene == null)
        {
            GD.PushError($"无法加载预制场景: {presetPath}");
            return null;
        }

        var instance = scene.Instantiate<Node2D>();
        GD.Print($"  实例化预制场景: {presetType}");
        return instance;
    }

    /// <summary>加载并应用贴图</summary>
    private static void ApplyTexture(Node2D instance, string texturePath, Dictionary animConfig)
    {
        // 存储贴图路径，使用 Ready 信号确保节点完全初始化
        instance.SetMeta("pending_texture_path", texturePath);
        instance.Ready += () => OnInstanceReadyForTexture(instance);
    }

    /// <summary>当实例 Ready 时，加载并应用贴图</summary>
    private static void OnInstanceReadyForTexture(Node2D instance)
    {
        if (!instance.HasMeta("pending_texture_path"))
            return;

        var texturePath = instance.GetMeta("pending_texture_path").AsString();
        instance.RemoveMeta("pending_texture_path");

        GD.Print($"  [Ready] 开始加载贴图: {texturePath}");

        if (texturePath.StartsWith("http://") || texturePath.StartsWith("https://"))
        {
            // 网络图片
            GD.Print($"  开始下载网络图片: {texturePath}");
            var httpRequest = new HttpRequest();
            instance.AddChild(httpRequest);
            httpRequest.Timeout = 30.0;
            httpRequest.SetMeta("instance", instance);
            httpRequest.SetMeta("url", texturePath);

            httpRequest.RequestCompleted += (result, responseCode, headers, body) =>
                OnTextureDownloaded(result, responseCode, body, httpRequest);

            var error = httpRequest.Request(texturePath);
            if (error != Error.Ok)
            {
                GD.PushError($"网络请求失败: {texturePath}");
                httpRequest.QueueFree();
            }
        }
        else
        {
            // 本地图片
            var texture = LoadTexture(texturePath);
            if (texture != null)
            {
                ApplyTextureToSprite(instance, texture, texturePath);
            }
            else
            {
                GD.PushWarning($"无法加载本地贴图: {texturePath}");
            }
        }
    }

    /// <summary>加载贴图</summary>
    private static Texture2D LoadTexture(string texturePath)
    {
        GD.Print($"  尝试加载贴图: {texturePath}");

        if (texturePath.StartsWith("res://"))
        {
            var tex = GD.Load<Texture2D>(texturePath);
            if (tex != null)
                GD.Print($"  成功加载 res:// 贴图: {tex.GetWidth()}x{tex.GetHeight()}");
            else
                GD.PushError($"  无法加载 res:// 贴图: {texturePath}");
            return tex;
        }

        if (!FileAccess.FileExists(texturePath))
        {
            GD.PushError($"  贴图文件不存在: {texturePath}");
            return null;
        }

        var image = new Image();
        var error = image.Load(texturePath);

        if (error != Error.Ok)
        {
            GD.PushError($"图片加载失败: {texturePath}");
            return null;
        }

        GD.Print($"  成功加载外部贴图: {image.GetWidth()}x{image.GetHeight()}");
        return ImageTexture.CreateFromImage(image);
    }

    /// <summary>将贴图应用到 Sprite2D</summary>
    private static void ApplyTextureToSprite(Node2D instance, Texture2D texture, string texturePath)
    {
        GD.Print($"  查找 Sprite2D 节点...");
        var sprite = instance.GetNodeOrNull<Sprite2D>("Sprite2D");
        if (sprite == null)
        {
            GD.Print($"  直接子节点未找到，递归查找...");
            sprite = FindNodeByType<Sprite2D>(instance);
        }

        if (sprite != null)
        {
            sprite.Texture = texture;
            sprite.Visible = true;
            sprite.ZIndex = 0;
            sprite.Modulate = new Color(1, 1, 1, 1);
            sprite.SelfModulate = new Color(1, 1, 1, 1);
            instance.ZIndex = 0;
            instance.Visible = true;

            GD.Print($"已应用贴图到 Sprite2D: {texturePath.GetFile()}, 尺寸: {texture.GetWidth()}x{texture.GetHeight()}");
            GD.Print($"    Sprite位置: {sprite.GlobalPosition}, 可见: {sprite.Visible}, ZIndex: {sprite.ZIndex}");
            GD.Print($"    Instance位置: {instance.GlobalPosition}, 可见: {instance.Visible}");
        }
        else
        {
            GD.Print($"  实例子节点列表:");
            foreach (var child in instance.GetChildren())
                GD.Print($"    - {child.Name} ({child.GetClass()})");
            GD.PushWarning("未找到 Sprite2D 节点，无法应用贴图");
        }
    }

    /// <summary>处理网络图片下载完成</summary>
    private static void OnTextureDownloaded(long result, long responseCode, byte[] body, HttpRequest httpRequest)
    {
        var instance = httpRequest.GetMeta("instance").As<Node2D>();
        var url = httpRequest.GetMeta("url").AsString();
        httpRequest.QueueFree();

        if (result != (long)HttpRequest.Result.Success || responseCode != 200 || body.Length == 0)
        {
            GD.PushError($"网络图片下载失败: {url}");
            return;
        }

        var image = new Image();
        var error = image.LoadJpgFromBuffer(body);
        if (error != Error.Ok)
            error = image.LoadPngFromBuffer(body);
        if (error != Error.Ok)
            error = image.LoadWebpFromBuffer(body);

        if (error != Error.Ok)
        {
            GD.PushError($"图片解析失败: {url}");
            return;
        }

        var texture = ImageTexture.CreateFromImage(image);
        ApplyTextureToSprite(instance, texture, url);
        GD.Print($" 网络图片加载成功: {image.GetWidth()}x{image.GetHeight()}");
    }

    /// <summary>应用参数到实例</summary>
    private static void ApplyParameters(Node instance, Dictionary parameters)
    {
        if (parameters.Count == 0) return;

        GD.Print("  应用参数:");
        foreach (var key in parameters.Keys)
        {
            var value = parameters[key];
            var keyStr = key.AsString();

            // 转换为 PascalCase
            var pascalName = ToPascalCase(keyStr);

            // 直接尝试设置属性
            var propList = instance.GetPropertyList();
            string foundProp = null;

            foreach (var prop in propList)
            {
                var propName = prop["name"].AsString();
                // 精确匹配或忽略大小写匹配
                if (propName == keyStr || propName == pascalName ||
                    propName.Equals(keyStr, System.StringComparison.OrdinalIgnoreCase) ||
                    propName.Equals(pascalName, System.StringComparison.OrdinalIgnoreCase))
                {
                    foundProp = propName;
                    break;
                }
            }

            if (foundProp != null)
            {
                try
                {
                    instance.Set(foundProp, value);
                    GD.Print($"    {keyStr} -> {foundProp} = {value}");

                    // 特别调试 remains 属性
                    if (keyStr == "remains")
                    {
                        var actualValue = instance.Get(foundProp);
                        GD.Print($"    [调试] remains 设置后的实际值: '{actualValue}'");
                    }
                }
                catch (System.Exception ex)
                {
                    GD.PrintErr($"    设置属性 {foundProp} 失败: {ex.Message}");
                }
            }
            else
            {
                // 静默跳过常见的非属性参数
                var skipParams = new[] {
                    "rarity", "price", "weight", "stack_size", "buff_type",
                    "is_permanent_buff", "remove_stress", "critical_chance",
                    "strength_bonus", "agility_bonus", "combat_skills_bonus",
                    "intelligence_bonus", "charisma_bonus", "endurance_bonus",
                    "luck_bonus", "perception_bonus", "wisdom_bonus",
                    "strength_buff", "agility_buff", "healing_amount",
                    "energy_amount", "hunger_restore", "thirst_restore", "buff_duration",
                    // 果实种植相关参数（在AIFruit中通过专门属性处理）
                    "is_plantable", "plant_scene_path", "growth_time",
                    "required_farming_skill", "required_soil_type",
                    "min_temperature", "max_temperature",
                    // 植物环境参数（使用FloatRange类型，需要特殊处理）
                    "humidity_min", "humidity_max", "temperature_min", "temperature_max"
                };
                if (!System.Array.Exists(skipParams, p => p == keyStr))
                {
                    GD.PushWarning($"    属性 '{keyStr}' (尝试: {pascalName}) 不存在于实例中，已跳过");
                }
            }
        }
    }

    /// <summary>将 snake_case 转换为 PascalCase</summary>
    private static string ToPascalCase(string snakeCase)
    {
        if (string.IsNullOrEmpty(snakeCase)) return snakeCase;

        var words = snakeCase.Split('_');
        for (int i = 0; i < words.Length; i++)
        {
            if (!string.IsNullOrEmpty(words[i]))
            {
                words[i] = char.ToUpper(words[i][0]) + words[i].Substring(1).ToLower();
            }
        }
        return string.Join("", words);
    }

    /// <summary>配置组件</summary>
    private static void ConfigureComponents(Node instance, Dictionary components)
    {
        if (components.Count == 0) return;

        foreach (var key in components.Keys)
        {
            var enabled = components[key].AsBool();
            var node = instance.GetNodeOrNull(key.AsString());

            if (node != null)
            {
                if (node is Node2D node2D)
                    node2D.Visible = enabled;
                else if (node is Control control)
                    control.Visible = enabled;
                else
                    node.ProcessMode = enabled ? Node.ProcessModeEnum.Inherit : Node.ProcessModeEnum.Disabled;

                GD.Print($"  配置组件: {key} = {(enabled ? "启用" : "禁用")}");
            }
            // 静默跳过不存在的组件节点
        }
    }

    /// <summary>设置植物动画</summary>
    private static void SetupPlantAnimations(Node2D instance, Dictionary config)
    {
        GD.Print("  设置植物动画...");

        // 获取 AnimatedSprite2D 节点
        var animatedSprite = instance.GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D");
        if (animatedSprite == null)
        {
            GD.PushWarning("  未找到 AnimatedSprite2D 节点");
            return;
        }

        // 获取植物 ID 和贴图目录
        var plantId = config.ContainsKey("item_id") ? config["item_id"].AsString() : "plant";
        var textureDir = config.ContainsKey("texture_directory") ? config["texture_directory"].AsString() : "";

        if (string.IsNullOrEmpty(textureDir))
        {
            GD.PushWarning("  未指定 texture_directory");
            return;
        }

        // 获取动画配置
        var animationsConfig = config.ContainsKey("animations") ? config["animations"].AsGodotDictionary() : new Dictionary();
        var growthStages = config.ContainsKey("growth_stages") ? config["growth_stages"].AsInt32() : 4;

        // 创建 SpriteFrames
        var spriteFrames = new SpriteFrames();

        // 为每个生长阶段创建动画
        for (int stage = 1; stage <= growthStages; stage++)
        {
            // 创建 idle 动画
            string idleAnimName = $"stage{stage}_idle";
            CreatePlantAnimation(spriteFrames, textureDir, plantId, stage, "idle",
                animationsConfig.ContainsKey(idleAnimName) ? animationsConfig[idleAnimName].AsGodotDictionary() : new Dictionary());

            // 创建 transition 动画
            string transAnimName = $"stage{stage}_transition";
            CreatePlantAnimation(spriteFrames, textureDir, plantId, stage, "transition",
                animationsConfig.ContainsKey(transAnimName) ? animationsConfig[transAnimName].AsGodotDictionary() : new Dictionary());
        }

        // 应用 SpriteFrames 到 AnimatedSprite2D
        animatedSprite.SpriteFrames = spriteFrames;

        // 默认播放第一阶段的 idle 动画
        if (spriteFrames.HasAnimation("stage1_idle"))
        {
            animatedSprite.Play("stage1_idle");
            GD.Print($"  ✓ 播放默认动画: stage1_idle");
        }

        GD.Print($"  ✓ 植物动画设置完成 ({growthStages} 个阶段)");
    }

    /// <summary>为植物创建单个动画</summary>
    private static void CreatePlantAnimation(SpriteFrames spriteFrames, string textureDir, string plantId, int stage, string animType, Dictionary animConfig)
    {
        string animName = $"stage{stage}_{animType}";
        int frameCount = animConfig.ContainsKey("frames") ? animConfig["frames"].AsInt32() : 24;
        bool loop = animConfig.ContainsKey("loop") ? animConfig["loop"].AsBool() : (animType == "idle");
        float fps = animConfig.ContainsKey("fps") ? animConfig["fps"].AsSingle() : 12.0f;

        // 添加新动画
        spriteFrames.AddAnimation(animName);
        spriteFrames.SetAnimationLoop(animName, loop);
        spriteFrames.SetAnimationSpeed(animName, fps);

        // 收集所有成功加载的贴图
        var loadedTextures = new System.Collections.Generic.List<Texture2D>();

        // 加载每一帧
        for (int frame = 1; frame <= frameCount; frame++)
        {
            // 文件命名格式: {plant_id}-stage{X}-{type}-frame{Y}.png
            string framePath = $"{textureDir}/{plantId}-stage{stage}-{animType}-frame{frame}.png";

            var texture = ResourceLoader.Load<Texture2D>(framePath);
            if (texture != null)
            {
                loadedTextures.Add(texture);
                spriteFrames.AddFrame(animName, texture);
            }
            else
            {
                GD.PushWarning($"    无法加载帧: {framePath}");
            }
        }

        // 如果是循环动画，添加反向帧实现乒乓效果
        if (loop && loadedTextures.Count > 2)
        {
            // 添加反向帧（不包括首尾帧，避免重复）
            for (int i = loadedTextures.Count - 2; i >= 1; i--)
            {
                spriteFrames.AddFrame(animName, loadedTextures[i]);
            }
            GD.Print($"    {animName}: 加载 {loadedTextures.Count} 帧 + {loadedTextures.Count - 2} 反向帧 (乒乓循环, fps={fps})");
        }
        else
        {
            GD.Print($"    {animName}: 加载 {loadedTextures.Count}/{frameCount} 帧 (loop={loop}, fps={fps})");
        }
    }

    /// <summary>生成碰撞体积</summary>
    private static void GenerateCollision(Node2D instance, string texturePath, Dictionary config)
    {
        var collisionType = config.ContainsKey("type") ? config["type"].AsString() : "auto";

        switch (collisionType)
        {
            case "circle":
                GenerateCircleCollision(instance, config);
                break;
            case "rect":
                GenerateRectCollision(instance, config);
                break;
            default:
                GenerateCircleCollision(instance, config);
                break;
        }
    }

    /// <summary>生成圆形碰撞</summary>
    private static void GenerateCircleCollision(Node2D instance, Dictionary config)
    {
        var radius = config.ContainsKey("radius") ? config["radius"].AsSingle() : 32.0f;

        var area = new Area2D { Name = "CollisionArea" };
        area.CollisionLayer = (uint)(config.ContainsKey("layer") ? config["layer"].AsInt32() : 8);
        area.CollisionMask = (uint)(config.ContainsKey("mask") ? config["mask"].AsInt32() : 1);

        var shape = new CircleShape2D { Radius = radius };
        var collisionShape = new CollisionShape2D { Name = "CollisionShape", Shape = shape };

        area.AddChild(collisionShape);
        instance.AddChild(area);

        GD.Print($"  已生成圆形碰撞体 (半径: {radius:F1})");
    }

    /// <summary>生成矩形碰撞</summary>
    private static void GenerateRectCollision(Node2D instance, Dictionary config)
    {
        var size = config.ContainsKey("size") ? config["size"].AsVector2() : new Vector2(64, 64);

        var area = new Area2D { Name = "CollisionArea" };
        area.CollisionLayer = (uint)(config.ContainsKey("layer") ? config["layer"].AsInt32() : 8);
        area.CollisionMask = (uint)(config.ContainsKey("mask") ? config["mask"].AsInt32() : 1);

        var shape = new RectangleShape2D { Size = size };
        var collisionShape = new CollisionShape2D { Name = "CollisionShape", Shape = shape };

        area.AddChild(collisionShape);
        instance.AddChild(area);

        GD.Print($"  已生成矩形碰撞体 (尺寸: {size})");
    }

    /// <summary>生成示例 JSON 配置</summary>
    public static bool GenerateExampleJson(string savePath)
    {
        var exampleConfig = new Dictionary
        {
            { "item_id", "magic_sword_001" },
            { "display_name", "炎之魔剑" },
            { "description", "燃烧着烈焰的魔法剑" },
            { "texture_path", "user://ai_items/textures/magic_sword_001.png" },
            { "preset_type", "weapon" },
            { "parameters", new Dictionary {
                { "damage", 150 }, { "fire_damage", 50 },
                { "durability", 200 }, { "rarity", "legendary" },
                { "price", 5000 }, { "weight", 3.5 }
            }},
            { "collision", new Dictionary {
                { "enabled", true }, { "type", "circle" },
                { "layer", 8 }, { "mask", 1 }, { "radius", 32.0 }
            }},
            { "components", new Dictionary {
                { "ParticleEffect", true }, { "SoundEffect", true }, { "GlowEffect", true }
            }}
        };

        using var file = FileAccess.Open(savePath, FileAccess.ModeFlags.Write);
        if (file == null)
        {
            GD.PushError($"无法创建示例 JSON 文件: {savePath}");
            return false;
        }

        file.StoreString(Json.Stringify(exampleConfig, "\t"));
        GD.Print($"示例 JSON 已生成: {savePath}");
        return true;
    }

    /// <summary>递归查找特定类型的节点</summary>
    private static T FindNodeByType<T>(Node root) where T : Node
    {
        foreach (Node child in root.GetChildren())
        {
            if (child is T result)
                return result;
            var found = FindNodeByType<T>(child);
            if (found != null)
                return found;
        }
        return null;
    }
}
