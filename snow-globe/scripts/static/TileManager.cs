using Godot;

/// <summary>
/// 瓦片管理器 - 提供瓦片名称获取功能
/// </summary>
public partial class TileManager : TileMapLayer
{
    /// <summary>获取指定位置的瓦片名称</summary>
    public string GetTileName(Vector2I tilePos)
    {
        var tileData = GetCellTileData(tilePos);
        if (tileData != null)
        {
            var customName = tileData.GetCustomData("Name");
            if (customName.VariantType != Variant.Type.Nil)
                return customName.AsString();
        }
        return "";
    }

    public override void _Ready()
    {
        // 初始化
    }
}
