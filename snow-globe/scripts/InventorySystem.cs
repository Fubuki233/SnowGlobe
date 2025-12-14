using Godot;
using Godot.Collections;
using System;
using System.Linq;

/// <summary>
/// 背包系统
/// 基于角色力量值计算承重上限: max_weight = 10 * strength
/// 支持存储所有 AI 物品类型 (AIWeapon, AIPlant, AIConsumable, AIFruit)
/// </summary>
public partial class InventorySystem : Node
{
    #region Signals
    [Signal]
    public delegate void InventoryChangedEventHandler(Dictionary itemData);
    #endregion

    #region Properties
    /// <summary>最大承重 = 10 * strength</summary>
    public float MaxWeight { get; private set; } = 0.0f;

    /// <summary>当前重量</summary>
    public float CurrentWeight { get; private set; } = 0.0f;

    /// <summary>背包存储: item_id -> {item, quantity, weight, unit_weight, type}</summary>
    private Dictionary<string, Dictionary> items = new Dictionary<string, Dictionary>();
    #endregion

    #region Initialization
    public InventorySystem(int strength = 1)
    {
        UpdateMaxWeight(strength);
        GD.Print($"[背包系统] 初始化完成 | 最大承重: {MaxWeight:F1} kg");
    }

    /// <summary>更新最大承重 (基于力量值)</summary>
    public void UpdateMaxWeight(int strength)
    {
        MaxWeight = strength * 10.0f;
        GD.Print($"[背包系统] 承重上限更新: {MaxWeight:F1} kg (力量: {strength})");
    }
    #endregion

    #region Item Management
    /// <summary>检查是否能添加物品</summary>
    public bool CanAddItem(float weight, int quantity = 1)
    {
        float totalWeight = weight * quantity;
        return (CurrentWeight + totalWeight) <= MaxWeight;
    }

    /// <summary>
    /// 添加物品到背包
    /// </summary>
    /// <param name="item">物品节点 (AIWeapon, AIPlant, AIConsumable, AIFruit)</param>
    /// <param name="quantity">数量</param>
    /// <returns>是否成功添加</returns>
    public bool AddItem(Node item, int quantity = 1)
    {
        if (item == null)
        {
            GD.Print("[背包系统] ❌ 添加失败: 物品为空");
            return false;
        }

        // 获取物品重量 (兼容 C# PascalCase 属性)
        float itemWeight = GetItemWeight(item);

        // 检查承重
        if (!CanAddItem(itemWeight, quantity))
        {
            GD.Print($"[背包系统] ❌ 超重! 当前: {CurrentWeight:F1} kg, 需要: {itemWeight * quantity:F1} kg, 上限: {MaxWeight:F1} kg");
            return false;
        }

        // 获取物品 ID
        string itemId = GetItemId(item);

        // 检查是否已存在
        if (items.ContainsKey(itemId))
        {
            // 堆叠物品
            var itemData = items[itemId];
            int newQuantity = (int)itemData["quantity"] + quantity;
            itemData["quantity"] = newQuantity;
            itemData["weight"] = newQuantity * itemWeight;
        }
        else
        {
            // 新增物品
            items[itemId] = new Dictionary
            {
                { "item", item },
                { "quantity", quantity },
                { "weight", itemWeight * quantity },
                { "unit_weight", itemWeight },
                { "type", GetItemType(item) }
            };
        }

        // 更新总重量
        CurrentWeight += itemWeight * quantity;

        GD.Print($"[背包系统] ✓ 添加成功: {GetItemDisplayName(item)} x{quantity} | 重量: {itemWeight * quantity:F1} kg | 总重: {CurrentWeight:F1} / {MaxWeight:F1} kg");

        // 触发信号并打印背包内容
        PrintInventory();
        EmitSignal(SignalName.InventoryChanged, GetInventoryData());

        return true;
    }

    /// <summary>
    /// 移除物品
    /// </summary>
    /// <param name="itemId">物品 ID</param>
    /// <param name="quantity">移除数量</param>
    /// <returns>是否成功移除</returns>
    public bool RemoveItem(string itemId, int quantity = 1)
    {
        if (!items.ContainsKey(itemId))
        {
            GD.Print($"[背包系统] ❌ 移除失败: 未找到物品 ID '{itemId}'");
            return false;
        }

        var itemData = items[itemId];
        int currentQuantity = (int)itemData["quantity"];

        if (currentQuantity < quantity)
        {
            GD.Print($"[背包系统] ❌ 移除失败: 数量不足 (拥有: {currentQuantity}, 需要: {quantity})");
            return false;
        }

        // 减少数量
        float unitWeight = (float)itemData["unit_weight"];
        float weightRemoved = unitWeight * quantity;
        CurrentWeight -= weightRemoved;

        // 如果数量为 0,移除物品
        if (currentQuantity - quantity <= 0)
        {
            items.Remove(itemId);
            GD.Print($"[背包系统] ✓ 移除成功: {itemId} (全部) | 减少重量: {weightRemoved:F1} kg");
        }
        else
        {
            int newQuantity = currentQuantity - quantity;
            itemData["quantity"] = newQuantity;
            itemData["weight"] = newQuantity * unitWeight;
            GD.Print($"[背包系统] ✓ 移除成功: {itemId} x{quantity} | 剩余: {newQuantity} | 减少重量: {weightRemoved:F1} kg");
        }

        // 触发信号并打印背包内容
        PrintInventory();
        EmitSignal(SignalName.InventoryChanged, GetInventoryData());

        return true;
    }

    /// <summary>检查是否拥有指定数量的物品</summary>
    public bool HasItem(string itemId, int quantity = 1)
    {
        if (!items.ContainsKey(itemId))
            return false;
        return (int)items[itemId]["quantity"] >= quantity;
    }

    /// <summary>获取物品数量</summary>
    public int GetItemQuantity(string itemId)
    {
        if (items.ContainsKey(itemId))
            return (int)items[itemId]["quantity"];
        return 0;
    }

    /// <summary>获取背包数据摘要</summary>
    public Dictionary GetInventoryData()
    {
        return new Dictionary
        {
            { "max_weight", MaxWeight },
            { "current_weight", CurrentWeight },
            { "weight_percent", MaxWeight > 0 ? (CurrentWeight / MaxWeight * 100.0f) : 0.0f },
            { "item_count", items.Count },
            { "items", new Dictionary<string, Dictionary>(items) }
        };
    }

    /// <summary>清空背包</summary>
    public void ClearInventory()
    {
        items.Clear();
        CurrentWeight = 0.0f;
        GD.Print("[背包系统] 背包已清空");
        EmitSignal(SignalName.InventoryChanged, GetInventoryData());
    }
    #endregion

    #region Private Helpers
    /// <summary>打印背包内容到控制台</summary>
    public void PrintInventory()
    {
        GD.Print("\n" + new string('=', 60));
        float weightPercent = MaxWeight > 0 ? (CurrentWeight / MaxWeight * 100.0f) : 0.0f;
        GD.Print($"[背包内容] 重量: {CurrentWeight:F1} / {MaxWeight:F1} kg ({weightPercent:F1}%) | 物品种类: {items.Count}");
        GD.Print(new string('-', 60));

        if (items.Count == 0)
        {
            GD.Print("  (空)");
        }
        else
        {
            int index = 1;
            foreach (var kvp in items)
            {
                var itemData = kvp.Value;
                var item = (Node)itemData["item"];
                GD.Print($"  {index}. {GetItemDisplayName(item)} x{itemData["quantity"]} | 类型: {itemData["type"]} | 重量: {(float)itemData["weight"]:F1} kg");
                index++;
            }
        }

        GD.Print(new string('=', 60) + "\n");
    }

    /// <summary>获取物品重量 - 兼容 C# 属性</summary>
    private float GetItemWeight(Node item)
    {
        // 尝试 C# 属性 (PascalCase)
        if (item.Get("Weight").VariantType != Variant.Type.Nil)
            return (float)item.Get("Weight");

        // 尝试 GDScript 属性 (snake_case)
        if (item.Get("weight").VariantType != Variant.Type.Nil)
            return (float)item.Get("weight");

        GD.Print("[背包系统] ⚠ 物品没有 weight 属性,默认为 0.0");
        return 0.0f;
    }

    /// <summary>获取物品唯一 ID - 兼容 C# 属性</summary>
    private string GetItemId(Node item)
    {
        // 尝试 DisplayName (C#)
        if (item.Get("DisplayName").VariantType != Variant.Type.Nil)
            return item.Get("DisplayName").AsString();

        // 尝试 display_name (GDScript)
        if (item.Get("display_name").VariantType != Variant.Type.Nil)
            return item.Get("display_name").AsString();

        return item.Name;
    }

    /// <summary>获取物品显示名称 - 兼容 C# 属性</summary>
    private string GetItemDisplayName(Node item)
    {
        return GetItemId(item);
    }

    /// <summary>获取物品类型 - 支持 C# 类和 GDScript 类</summary>
    private string GetItemType(Node item)
    {
        string className = item.GetClass();

        // 检查 C# 类型
        if (className == "AIWeapon" || item.Get("Damage").VariantType != Variant.Type.Nil)
            return "weapon";

        if (className == "AIPlant" || item.Get("GrowthStages").VariantType != Variant.Type.Nil)
            return "plant";

        if (className == "AIFruit" || item.Get("IsPlantable").VariantType != Variant.Type.Nil)
            return "fruit";

        if (className == "AIConsumable" || item.Get("HealingAmount").VariantType != Variant.Type.Nil)
            return "consumable";

        return "unknown";
    }
    #endregion
}
