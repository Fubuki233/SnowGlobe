using Godot;
using System;

/// <summary>
/// Godot 节点扩展方法 - 简化 Variant 类型处理
/// </summary>
public static class NodeExtensions
{
    /// <summary>
    /// 安全获取属性作为 Node 类型
    /// </summary>
    public static Node GetNodeProp(this Node node, string property)
    {
        var variant = node.Get(property);
        if (variant.VariantType == Variant.Type.Nil)
            return null;
        return variant.As<Node>();
    }

    /// <summary>
    /// 检查属性是否存在且不为 null
    /// </summary>
    public static bool HasProperty(this Node node, string property)
    {
        return node.Get(property).VariantType != Variant.Type.Nil;
    }

    /// <summary>
    /// 安全获取 int 属性值
    /// </summary>
    public static int GetInt(this Node node, string property, int defaultValue = 0)
    {
        var variant = node.Get(property);
        if (variant.VariantType == Variant.Type.Nil)
            return defaultValue;
        return variant.AsInt32();
    }

    /// <summary>
    /// 安全获取 float 属性值
    /// </summary>
    public static float GetFloat(this Node node, string property, float defaultValue = 0f)
    {
        var variant = node.Get(property);
        if (variant.VariantType == Variant.Type.Nil)
            return defaultValue;
        return variant.AsSingle();
    }

    /// <summary>
    /// 安全获取 string 属性值
    /// </summary>
    public static string GetString(this Node node, string property, string defaultValue = "")
    {
        var variant = node.Get(property);
        if (variant.VariantType == Variant.Type.Nil)
            return defaultValue;
        return variant.AsString();
    }

    /// <summary>
    /// 安全获取 bool 属性值
    /// </summary>
    public static bool GetBool(this Node node, string property, bool defaultValue = false)
    {
        var variant = node.Get(property);
        if (variant.VariantType == Variant.Type.Nil)
            return defaultValue;
        return variant.AsBool();
    }
}
