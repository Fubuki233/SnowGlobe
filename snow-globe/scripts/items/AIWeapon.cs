using Godot;
using System;
using System.Collections.Generic;

/// <summary>
/// AI 生成的武器基础脚本
/// 这个脚本会被挂载到 weapon_preset.tscn 的根节点
/// </summary>
public partial class AIWeapon : Node2D
{
    // 基础信息
    [Export] public string DisplayName { get; set; } = "未命名武器";
    [Export(PropertyHint.MultilineText)] public string Description { get; set; } = "这是一件普通的武器";

    // 武器基础属性
    [Export] public int Damage { get; set; } = 10;
    [Export] public int FireDamage { get; set; } = 0;
    [Export] public int IceDamage { get; set; } = 0;
    [Export] public int PoisonDamage { get; set; } = 0;
    [Export] public int Durability { get; set; } = 100;
    [Export] public int MaxDurability { get; set; } = 100;
    [Export] public string Rarity { get; set; } = "common";
    [Export] public int Price { get; set; } = 100;
    [Export] public float Weight { get; set; } = 1.0f;

    // 武器特殊属性
    [Export] public float AttackSpeed { get; set; } = 1.0f;
    [Export] public float CriticalChance { get; set; } = 0.05f;
    [Export] public float CriticalDamage { get; set; } = 1.5f;

    // 属性修改效果（装备时生效）- 移动属性
    [Export] public float SpeedBonus { get; set; } = 0.0f;
    [Export] public float PathSpeedBonus { get; set; } = 0.0f;
    [Export] public float RunningSpeedBonus { get; set; } = 0.0f;

    // 基础能力值加成
    [Export] public int StrengthBonus { get; set; } = 0;
    [Export] public int AgilityBonus { get; set; } = 0;
    [Export] public int IntelligenceBonus { get; set; } = 0;
    [Export] public int CharismaBonus { get; set; } = 0;
    [Export] public int EnduranceBonus { get; set; } = 0;
    [Export] public int LuckBonus { get; set; } = 0;
    [Export] public int PerceptionBonus { get; set; } = 0;
    [Export] public int WisdomBonus { get; set; } = 0;

    // 技能属性加成
    [Export] public int MentalStrengthBonus { get; set; } = 0;
    [Export] public int SocialSkillsBonus { get; set; } = 0;
    [Export] public int CombatSkillsBonus { get; set; } = 0;
    [Export] public int CraftingSkillsBonus { get; set; } = 0;
    [Export] public int SurvivalSkillsBonus { get; set; } = 0;
    [Export] public int StealthSkillsBonus { get; set; } = 0;
    [Export] public int CookingBonus { get; set; } = 0;

    // 当前使用者
    protected Node CurrentUser = null;

    public override void _Ready()
    {
        GD.Print($"武器已创建: 伤害={Damage}, 稀有度={Rarity}");
    }

    // ==================== 背包检测方法 ====================

    /// <summary>检测物品是否在角色背包中</summary>
    public bool IsInInventory(Node character = null)
    {
        if (character != null)
        {
            var inventoryVariant = character.Get("inventory");
            if (inventoryVariant.VariantType != Variant.Type.Nil)
            {
                var inventory = inventoryVariant.As<Node>();
                if (inventory != null)
                    return (bool)inventory.Call("has_item", DisplayName, 1);
            }
            return false;
        }
        else
        {
            return GetOwnerCharacter() != null;
        }
    }

    /// <summary>获取拥有此物品的角色</summary>
    public Node GetOwnerCharacter()
    {
        var root = GetTree()?.Root;
        if (root == null)
            return null;

        var characters = FindAllCharacters(root);
        foreach (var character in characters)
        {
            var inventoryVariant = character.Get("inventory");
            if (inventoryVariant.VariantType != Variant.Type.Nil)
            {
                var inventory = inventoryVariant.As<Node>();
                if (inventory != null)
                {
                    if ((bool)inventory.Call("has_item", DisplayName, 1))
                        return character;
                }
            }
        }
        return null;
    }

    /// <summary>获取物品在指定角色背包中的数量</summary>
    public int GetQuantityInInventory(Node character)
    {
        if (character == null)
            return 0;

        var inventoryVariant = character.Get("inventory");
        if (inventoryVariant.VariantType == Variant.Type.Nil)
            return 0;

        var inventory = inventoryVariant.As<Node>();
        if (inventory == null)
            return 0;

        return (int)inventory.Call("get_item_quantity", DisplayName);
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

    // 辅助方法
    protected bool HasProp(Node node, string prop) => node.Get(prop).VariantType != Variant.Type.Nil;
    protected string GetStr(Node node, string prop) => node.Get(prop).AsString();
    protected float GetFloat(Node node, string prop) => node.Get(prop).AsSingle();
    protected int GetInt(Node node, string prop) => node.Get(prop).AsInt32();

    /// <summary>使用武器（攻击）</summary>
    public void Use(Node user = null)
    {
        if (user != null)
            CurrentUser = user;

        if (CurrentUser != null)
        {
            string userName = HasProp(CurrentUser, "npc_name") ? GetStr(CurrentUser, "npc_name") : "未知";
            GD.Print($"{userName} 使用武器攻击! 总伤害: {GetTotalDamage()}");
            // 消耗耐久
            Durability = Math.Max(0, Durability - 1);
            if (Durability == 0)
                GD.Print("武器已损坏！");
        }
        else
        {
            GD.Print($"使用武器攻击! 总伤害: {GetTotalDamage()}");
        }
    }

    /// <summary>装备武器到使用者</summary>
    public void Equip(Node user)
    {
        if (user == null)
        {
            GD.PushError("无效的使用者");
            return;
        }

        // 卸下旧武器
        if (CurrentUser != null)
            Unequip();

        CurrentUser = user;

        // 应用属性加成 - 移动属性
        if (SpeedBonus > 0 && HasProp(user, "speed"))
            user.Set("speed", GetFloat(user, "speed") + SpeedBonus);

        if (PathSpeedBonus > 0 && HasProp(user, "path_speed"))
            user.Set("path_speed", GetFloat(user, "path_speed") + PathSpeedBonus);

        if (RunningSpeedBonus > 0 && HasProp(user, "running_speed"))
            user.Set("running_speed", GetFloat(user, "running_speed") + RunningSpeedBonus);

        // 基础能力值
        ApplyStatBonus(user, "strength", StrengthBonus);
        ApplyStatBonus(user, "agility", AgilityBonus);
        ApplyStatBonus(user, "intelligence", IntelligenceBonus);
        ApplyStatBonus(user, "charisma", CharismaBonus);
        ApplyStatBonus(user, "endurance", EnduranceBonus);
        ApplyStatBonus(user, "luck", LuckBonus);
        ApplyStatBonus(user, "perception", PerceptionBonus);
        ApplyStatBonus(user, "wisdom", WisdomBonus);

        // 技能属性
        ApplyStatBonus(user, "mental_strength", MentalStrengthBonus);
        ApplyStatBonus(user, "social_skills", SocialSkillsBonus);
        ApplyStatBonus(user, "combat_skills", CombatSkillsBonus);
        ApplyStatBonus(user, "crafting_skills", CraftingSkillsBonus);
        ApplyStatBonus(user, "survival_skills", SurvivalSkillsBonus);
        ApplyStatBonus(user, "stealth_skills", StealthSkillsBonus);
        ApplyStatBonus(user, "cooking", CookingBonus);

        string userName = HasProp(user, "npc_name") ? GetStr(user, "npc_name") : "未知";
        GD.Print($"{userName} 装备了武器: {Name}");
    }

    /// <summary>卸下武器</summary>
    public void Unequip()
    {
        if (CurrentUser == null)
            return;

        // 移除属性加成 - 移动属性
        if (SpeedBonus > 0 && HasProp(CurrentUser, "speed"))
            CurrentUser.Set("speed", GetFloat(CurrentUser, "speed") - SpeedBonus);

        if (PathSpeedBonus > 0 && HasProp(CurrentUser, "path_speed"))
            CurrentUser.Set("path_speed", GetFloat(CurrentUser, "path_speed") - PathSpeedBonus);

        if (RunningSpeedBonus > 0 && HasProp(CurrentUser, "running_speed"))
            CurrentUser.Set("running_speed", GetFloat(CurrentUser, "running_speed") - RunningSpeedBonus);

        // 基础能力值
        RemoveStatBonus(CurrentUser, "strength", StrengthBonus);
        RemoveStatBonus(CurrentUser, "agility", AgilityBonus);
        RemoveStatBonus(CurrentUser, "intelligence", IntelligenceBonus);
        RemoveStatBonus(CurrentUser, "charisma", CharismaBonus);
        RemoveStatBonus(CurrentUser, "endurance", EnduranceBonus);
        RemoveStatBonus(CurrentUser, "luck", LuckBonus);
        RemoveStatBonus(CurrentUser, "perception", PerceptionBonus);
        RemoveStatBonus(CurrentUser, "wisdom", WisdomBonus);

        // 技能属性
        RemoveStatBonus(CurrentUser, "mental_strength", MentalStrengthBonus);
        RemoveStatBonus(CurrentUser, "social_skills", SocialSkillsBonus);
        RemoveStatBonus(CurrentUser, "combat_skills", CombatSkillsBonus);
        RemoveStatBonus(CurrentUser, "crafting_skills", CraftingSkillsBonus);
        RemoveStatBonus(CurrentUser, "survival_skills", SurvivalSkillsBonus);
        RemoveStatBonus(CurrentUser, "stealth_skills", StealthSkillsBonus);
        RemoveStatBonus(CurrentUser, "cooking", CookingBonus);

        string userName = HasProp(CurrentUser, "npc_name") ? GetStr(CurrentUser, "npc_name") : "未知";
        GD.Print($"{userName} 卸下了武器: {Name}");

        CurrentUser = null;
    }

    private void ApplyStatBonus(Node user, string statName, int bonusValue)
    {
        if (bonusValue > 0 && HasProp(user, statName))
            user.Set(statName, GetInt(user, statName) + bonusValue);
    }

    private void RemoveStatBonus(Node user, string statName, int bonusValue)
    {
        if (bonusValue > 0 && HasProp(user, statName))
            user.Set(statName, GetInt(user, statName) - bonusValue);
    }

    /// <summary>获取当前使用者</summary>
    public Node GetUser()
    {
        return CurrentUser;
    }

    /// <summary>获取总伤害</summary>
    public int GetTotalDamage()
    {
        return Damage + FireDamage + IceDamage + PoisonDamage;
    }

    /// <summary>修复耐久度</summary>
    public void Repair(int amount)
    {
        Durability = Math.Min(Durability + amount, MaxDurability);
        GD.Print($"武器已修复，当前耐久: {Durability}/{MaxDurability}");
    }
}
