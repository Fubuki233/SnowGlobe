using Godot;
using System;
using System.Collections.Generic;

/// <summary>
/// AI 生成的消耗品基础脚本
/// </summary>
public partial class AIConsumable : Node2D
{
    // 基础信息
    [Export] public string DisplayName { get; set; } = "未命名消耗品";
    [Export(PropertyHint.MultilineText)] public string Description { get; set; } = "这是一件普通的消耗品";

    // 消耗品属性
    [Export] public int HealingAmount { get; set; } = 50;
    [Export] public int EnergyAmount { get; set; } = 0;
    [Export] public float BuffDuration { get; set; } = 0.0f;
    [Export] public string BuffType { get; set; } = "";
    [Export] public int StackSize { get; set; } = 99;
    [Export] public string Rarity { get; set; } = "common";
    [Export] public int Price { get; set; } = 50;
    [Export] public float Weight { get; set; } = 0.1f;

    // 属性增益
    [Export] public int HungerRestore { get; set; } = 0;
    [Export] public int ThirstRestore { get; set; } = 0;
    [Export] public float SpeedBuff { get; set; } = 0.0f;
    [Export] public float PathSpeedBuff { get; set; } = 0.0f;
    [Export] public float RunningSpeedBuff { get; set; } = 0.0f;
    [Export] public int StrengthBuff { get; set; } = 0;
    [Export] public int AgilityBuff { get; set; } = 0;
    [Export] public int IntelligenceBuff { get; set; } = 0;
    [Export] public int CharismaBuff { get; set; } = 0;
    [Export] public int EnduranceBuff { get; set; } = 0;
    [Export] public int LuckBuff { get; set; } = 0;
    [Export] public int PerceptionBuff { get; set; } = 0;
    [Export] public int WisdomBuff { get; set; } = 0;
    [Export] public int MentalStrengthBuff { get; set; } = 0;
    [Export] public int SocialSkillsBuff { get; set; } = 0;
    [Export] public int CombatSkillsBuff { get; set; } = 0;
    [Export] public int CraftingSkillsBuff { get; set; } = 0;
    [Export] public int SurvivalSkillsBuff { get; set; } = 0;
    [Export] public int StealthSkillsBuff { get; set; } = 0;
    [Export] public int CookingBuff { get; set; } = 0;
    [Export] public bool IsPermanentBuff { get; set; } = false;

    // 状态效果
    [Export] public bool CurePoison { get; set; } = false;
    [Export] public bool CureSickness { get; set; } = false;
    [Export] public bool RemoveStress { get; set; } = false;
    [Export] public bool CureInjury { get; set; } = false;
    [Export] public bool CureTiredness { get; set; } = false;
    [Export] public bool SetResting { get; set; } = false;
    [Export] public bool SetEnergized { get; set; } = false;

    protected Node CurrentUser = null;
    protected Timer BuffTimer = null;

    public override void _Ready()
    {
        GD.Print($"消耗品已创建: 治疗={HealingAmount}, 能量={EnergyAmount}");
    }

    // ==================== 辅助方法 ====================
    protected bool HasProp(Node node, string prop) => node.Get(prop).VariantType != Variant.Type.Nil;
    protected int GetInt(Node node, string prop) => node.Get(prop).AsInt32();
    protected float GetFloat(Node node, string prop) => node.Get(prop).AsSingle();
    protected string GetStr(Node node, string prop) => node.Get(prop).AsString();

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

    // ==================== 使用消耗品 ====================
    public virtual void Use(Node user = null)
    {
        if (user == null)
        {
            GD.Print($"使用消耗品! 治疗: {HealingAmount}, 能量: {EnergyAmount}");
            return;
        }

        CurrentUser = user;
        string userName = HasProp(user, "npc_name") ? GetStr(user, "npc_name") : "未知";
        GD.Print($"{userName} 使用了消耗品: {Name}");

        // 恢复生命值
        if (HealingAmount > 0 && HasProp(user, "current_health"))
        {
            int oldHealth = GetInt(user, "current_health");
            int maxHealth = GetInt(user, "max_health");
            int newHealth = Math.Min(oldHealth + HealingAmount, maxHealth);
            user.Set("current_health", newHealth);
            GD.Print($"   生命值: {oldHealth} → {newHealth}");
        }

        // 恢复能量
        if (EnergyAmount > 0 && HasProp(user, "energy"))
        {
            int oldEnergy = GetInt(user, "energy");
            int maxEnergy = GetInt(user, "max_energy");
            int newEnergy = Math.Min(oldEnergy + EnergyAmount, maxEnergy);
            user.Set("energy", newEnergy);
            GD.Print($"   能量: {oldEnergy} → {newEnergy}");
        }

        // 恢复饥饿度
        if (HungerRestore > 0 && HasProp(user, "hunger"))
        {
            int oldHunger = GetInt(user, "hunger");
            int maxHunger = GetInt(user, "max_hunger");
            user.Set("hunger", Math.Min(oldHunger + HungerRestore, maxHunger));
            if (HasProp(user, "is_hungry")) user.Set("is_hungry", false);
        }

        // 恢复口渴度
        if (ThirstRestore > 0 && HasProp(user, "thirst"))
        {
            int oldThirst = GetInt(user, "thirst");
            int maxThirst = GetInt(user, "max_thirst");
            user.Set("thirst", Math.Min(oldThirst + ThirstRestore, maxThirst));
            if (HasProp(user, "is_thirsty")) user.Set("is_thirsty", false);
        }

        // 治疗状态异常
        if (CurePoison && HasProp(user, "is_sick")) user.Set("is_sick", false);
        if (CureSickness && HasProp(user, "is_sick")) user.Set("is_sick", false);
        if (RemoveStress && HasProp(user, "is_stressed")) user.Set("is_stressed", false);
        if (CureInjury && HasProp(user, "is_injured")) user.Set("is_injured", false);
        if (CureTiredness && HasProp(user, "is_tired")) user.Set("is_tired", false);

        // 设置特殊状态
        if (SetResting && HasProp(user, "is_resting")) user.Set("is_resting", true);
        if (SetEnergized && HasProp(user, "is_tired"))
        {
            user.Set("is_tired", false);
            if (HasProp(user, "energy")) user.Set("energy", user.Get("max_energy"));
        }

        // 应用属性增益
        if (IsPermanentBuff) ApplyPermanentBuffs(user);
        else if (BuffDuration > 0) ApplyTemporaryBuffs(user);

        GD.Print(" 消耗品使用完成");
    }

    protected void ApplyPermanentBuffs(Node user)
    {
        if (SpeedBuff > 0 && HasProp(user, "speed"))
            user.Set("speed", GetFloat(user, "speed") + SpeedBuff);
        if (PathSpeedBuff > 0 && HasProp(user, "path_speed"))
            user.Set("path_speed", GetFloat(user, "path_speed") + PathSpeedBuff);
        if (RunningSpeedBuff > 0 && HasProp(user, "running_speed"))
            user.Set("running_speed", GetFloat(user, "running_speed") + RunningSpeedBuff);

        ApplyStatBuff(user, "strength", StrengthBuff);
        ApplyStatBuff(user, "agility", AgilityBuff);
        ApplyStatBuff(user, "intelligence", IntelligenceBuff);
        ApplyStatBuff(user, "charisma", CharismaBuff);
        ApplyStatBuff(user, "endurance", EnduranceBuff);
        ApplyStatBuff(user, "luck", LuckBuff);
        ApplyStatBuff(user, "perception", PerceptionBuff);
        ApplyStatBuff(user, "wisdom", WisdomBuff);
        ApplyStatBuff(user, "mental_strength", MentalStrengthBuff);
        ApplyStatBuff(user, "social_skills", SocialSkillsBuff);
        ApplyStatBuff(user, "combat_skills", CombatSkillsBuff);
        ApplyStatBuff(user, "crafting_skills", CraftingSkillsBuff);
        ApplyStatBuff(user, "survival_skills", SurvivalSkillsBuff);
        ApplyStatBuff(user, "stealth_skills", StealthSkillsBuff);
        ApplyStatBuff(user, "cooking", CookingBuff);
    }

    protected void ApplyTemporaryBuffs(Node user)
    {
        ApplyPermanentBuffs(user);

        if (BuffTimer != null) BuffTimer.QueueFree();
        BuffTimer = new Timer();
        AddChild(BuffTimer);
        BuffTimer.WaitTime = BuffDuration;
        BuffTimer.OneShot = true;
        BuffTimer.Timeout += () => RemoveTemporaryBuffs(user);
        BuffTimer.Start();
    }

    protected void RemoveTemporaryBuffs(Node user)
    {
        if (user == null || !IsInstanceValid(user)) return;

        if (SpeedBuff > 0 && HasProp(user, "speed"))
            user.Set("speed", GetFloat(user, "speed") - SpeedBuff);
        if (PathSpeedBuff > 0 && HasProp(user, "path_speed"))
            user.Set("path_speed", GetFloat(user, "path_speed") - PathSpeedBuff);
        if (RunningSpeedBuff > 0 && HasProp(user, "running_speed"))
            user.Set("running_speed", GetFloat(user, "running_speed") - RunningSpeedBuff);

        RemoveStatBuff(user, "strength", StrengthBuff);
        RemoveStatBuff(user, "agility", AgilityBuff);
        RemoveStatBuff(user, "intelligence", IntelligenceBuff);
        RemoveStatBuff(user, "charisma", CharismaBuff);
        RemoveStatBuff(user, "endurance", EnduranceBuff);
        RemoveStatBuff(user, "luck", LuckBuff);
        RemoveStatBuff(user, "perception", PerceptionBuff);
        RemoveStatBuff(user, "wisdom", WisdomBuff);
        RemoveStatBuff(user, "mental_strength", MentalStrengthBuff);
        RemoveStatBuff(user, "social_skills", SocialSkillsBuff);
        RemoveStatBuff(user, "combat_skills", CombatSkillsBuff);
        RemoveStatBuff(user, "crafting_skills", CraftingSkillsBuff);
        RemoveStatBuff(user, "survival_skills", SurvivalSkillsBuff);
        RemoveStatBuff(user, "stealth_skills", StealthSkillsBuff);
        RemoveStatBuff(user, "cooking", CookingBuff);

        if (BuffTimer != null) { BuffTimer.QueueFree(); BuffTimer = null; }
    }

    private void ApplyStatBuff(Node user, string stat, int value)
    {
        if (value > 0 && HasProp(user, stat))
            user.Set(stat, GetInt(user, stat) + value);
    }

    private void RemoveStatBuff(Node user, string stat, int value)
    {
        if (value > 0 && HasProp(user, stat))
            user.Set(stat, GetInt(user, stat) - value);
    }

    public Node GetUser() => CurrentUser;
}
