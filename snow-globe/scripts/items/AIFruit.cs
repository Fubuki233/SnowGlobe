using Godot;
using System;

/// <summary>
/// AI 生成的果实类 - 继承自 AIConsumable，支持食用和种植功能
/// </summary>
public partial class AIFruit : AIConsumable
{
    [ExportGroup("种植属性")]
    [Export] public bool IsPlantable { get; set; } = true;
    [Export] public string PlantScenePath { get; set; } = "";
    [Export] public float GrowthTime { get; set; } = 60.0f;
    [Export] public int RequiredFarmingSkill { get; set; } = 0;
    [Export] public string RequiredSoilType { get; set; } = "壤土";
    [Export] public float MinTemperature { get; set; } = 10.0f;
    [Export] public float MaxTemperature { get; set; } = 30.0f;

    protected PackedScene LinkedPlantTemplate = null;

    public override void _Ready()
    {
        base._Ready();
        GD.Print($"果实已创建: {DisplayName} (可种植: {IsPlantable})");
        if (IsPlantable && !string.IsNullOrEmpty(PlantScenePath))
            LoadPlantTemplate();
    }

    protected void LoadPlantTemplate()
    {
        if (ResourceLoader.Exists(PlantScenePath))
        {
            LinkedPlantTemplate = GD.Load<PackedScene>(PlantScenePath);
            if (LinkedPlantTemplate != null)
                GD.Print($"   已加载植物模板: {PlantScenePath}");
        }
    }

    /// <summary>检查角色是否能种植此果实</summary>
    public bool CanPlant(Node character)
    {
        if (!IsPlantable) return false;
        if (!IsInInventory(character)) return false;

        if (LinkedPlantTemplate == null && !string.IsNullOrEmpty(PlantScenePath))
            LoadPlantTemplate();
        if (LinkedPlantTemplate == null) return false;

        // 检查农业技能
        if (HasProp(character, "survival_skills"))
        {
            int survivalSkills = GetInt(character, "survival_skills");
            if (survivalSkills < RequiredFarmingSkill) return false;
        }
        return true;
    }

    /// <summary>种植果实</summary>
    public Node Plant(Node character, Vector2 position = default)
    {
        if (!CanPlant(character)) return null;

        Vector2 plantPosition = position;
        if (plantPosition == Vector2.Zero)
            plantPosition = ((Node2D)character).GlobalPosition;

        // 从背包移除果实
        var invVariant = character.Get("inventory");
        if (invVariant.VariantType != Variant.Type.Nil)
        {
            var inventory = invVariant.As<Node>();
            if (inventory != null && !(bool)inventory.Call("remove_item", DisplayName, 1))
                return null;
        }

        // 实例化植物
        var plantInstance = LinkedPlantTemplate.Instantiate();
        if (plantInstance == null)
        {
            // 失败时退还果实
            var inv = character.Get("inventory");
            if (inv.VariantType != Variant.Type.Nil)
            {
                var inventory = inv.As<Node>();
                inventory?.Call("add_item", this, 1);
            }
            return null;
        }

        if (plantInstance is Node2D plant2D)
            plant2D.GlobalPosition = plantPosition;

        // 设置植物初始状态
        plantInstance.Set("current_stage", 0);
        if (HasProp(plantInstance, "rarity"))
            plantInstance.Set("rarity", Rarity);

        // 添加到场景树
        var gameWorld = FindGameWorld();
        if (gameWorld != null) gameWorld.AddChild(plantInstance);
        else character.GetTree().Root.AddChild(plantInstance);

        string characterName = HasProp(character, "npc_name") ? GetStr(character, "npc_name") : character.Name;
        GD.Print($"[种植] {characterName} 种植了 {DisplayName}");

        // 触发种植技能提升
        if (HasProp(character, "survival_skills"))
        {
            int skills = GetInt(character, "survival_skills");
            character.Set("survival_skills", skills + 1);
        }

        return plantInstance;
    }

    protected Node FindGameWorld()
    {
        var root = GetTree()?.Root;
        if (root == null) return null;

        foreach (Node child in root.GetChildren())
        {
            var node2D = child.GetNodeOrNull("Node2D");
            if (node2D != null) return node2D;
            if (child is Node2D && child.Name != "CanvasLayer") return child;
        }
        return null;
    }

    public override void Use(Node user = null)
    {
        if (user == null) { base.Use(user); return; }

        string userName = HasProp(user, "npc_name") ? GetStr(user, "npc_name") : "未知";
        if (IsPlantable && CanPlant(user))
            GD.Print($"[提示] {userName} 可以食用或种植 {DisplayName}");
        else
            Eat(user);
    }

    public void Eat(Node user) => base.Use(user);

    public Godot.Collections.Dictionary GetPlantInfo()
    {
        return new Godot.Collections.Dictionary
        {
            { "is_plantable", IsPlantable },
            { "plant_scene_path", PlantScenePath },
            { "has_template", LinkedPlantTemplate != null },
            { "growth_time", GrowthTime },
            { "required_skill", RequiredFarmingSkill },
            { "soil_type", RequiredSoilType }
        };
    }
}
