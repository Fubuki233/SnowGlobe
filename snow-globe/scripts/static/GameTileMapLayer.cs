using Godot;
using Godot.Collections;

/// <summary>
/// 游戏瓦片地图层 - 提供 A* 寻路和瓦片查询功能
/// </summary>
public partial class GameTileMapLayer : TileMapLayer
{
    [Export] public string Id { get; set; } = "tile_map_layer";
    [Export] public bool ShowDebugGrid { get; set; } = true;

    private AStarGrid2D _aStar = new();

    public override void _Ready()
    {
        GodotRPC.Instance?.RegisterInstance(Id, this);

        // 确保获取正确的 tile_size
        var currentTileSize = TileSet.TileSize;
        GD.Print($"TileSet tile_size: {currentTileSize}");

        // 配置 A* 网格
        _aStar.Region = GetUsedRect();
        _aStar.CellSize = currentTileSize;
        _aStar.DefaultComputeHeuristic = AStarGrid2D.Heuristic.Manhattan;
        _aStar.DefaultEstimateHeuristic = AStarGrid2D.Heuristic.Manhattan;
        _aStar.DiagonalMode = AStarGrid2D.DiagonalModeEnum.Never;
        _aStar.Update();

        var usedRect = GetUsedRect();
        for (int i = usedRect.Position.X; i < usedRect.End.X; i++)
        {
            for (int j = usedRect.Position.Y; j < usedRect.End.Y; j++)
            {
                var tilePos = new Vector2I(i, j);
                if (_aStar.IsInBoundsv(tilePos) && !IsWalkable(tilePos))
                    _aStar.SetPointSolid(tilePos);
            }
        }

        GD.Print("TileMapLayer ready");
        GD.Print($"  Region: {_aStar.Region}");
        GD.Print($"  Cell size: {_aStar.CellSize}");
        GD.Print($"  Offset: {_aStar.Offset}");
    }

    /// <summary>获取随机的可行走位置(网格坐标)</summary>
    public Vector2I GetRandomWalkablePosition()
    {
        var usedRect = GetUsedRect();
        const int maxAttempts = 100;

        for (int i = 0; i < maxAttempts; i++)
        {
            var randomX = GD.RandRange(usedRect.Position.X, usedRect.End.X);
            var randomY = GD.RandRange(usedRect.Position.Y, usedRect.End.Y);
            var tilePos = new Vector2I((int)randomX, (int)randomY);

            if (IsWalkable(tilePos))
                return tilePos;
        }

        // 如果找不到，返回地图中心
        var center = usedRect.GetCenter();
        return new Vector2I((int)center.X, (int)center.Y);
    }

    /// <summary>检查指定方块是否可行走</summary>
    public bool IsWalkable(Vector2I tilePos)
    {
        var tileData = GetCellTileData(tilePos);
        if (tileData == null)
            return false;

        // 检查自定义数据层是否存在
        string blockName = "";
        if (TileSet.GetCustomDataLayerByName("Name") >= 0)
        {
            var customName = tileData.GetCustomData("Name");
            if (customName.VariantType != Variant.Type.Nil)
                blockName = customName.AsString();
        }

        // Grass 可行走，Stone 和 Sea 不可行走
        return blockName == "Grass";
    }

    /// <summary>获取从起点到终点的路径(网格坐标输入，返回世界坐标路径)</summary>
    public Vector2[] GetAstarPath(Vector2I fromGrid, Vector2I toGrid)
    {
        // 检查起点和终点是否在范围内
        if (!_aStar.IsInBoundsv(fromGrid))
        {
            GD.Print($"警告: 起点 {fromGrid} 超出 A* 范围 {_aStar.Region}");
            return System.Array.Empty<Vector2>();
        }

        if (!_aStar.IsInBoundsv(toGrid))
        {
            GD.Print($"警告: 终点 {toGrid} 超出 A* 范围 {_aStar.Region}");
            return System.Array.Empty<Vector2>();
        }

        // 检查起点和终点是否可行走
        if (_aStar.IsPointSolid(fromGrid))
        {
            GD.Print($"警告: 起点 {fromGrid} 是障碍物");
            return System.Array.Empty<Vector2>();
        }

        if (_aStar.IsPointSolid(toGrid))
        {
            GD.Print($"警告: 终点 {toGrid} 是障碍物");
            return System.Array.Empty<Vector2>();
        }

        // 使用 A* 计算路径
        var pathTiles = _aStar.GetIdPath(fromGrid, toGrid);

        if (pathTiles.Count == 0)
        {
            GD.Print($"警告: 无法找到从 {fromGrid} 到 {toGrid} 的路径");
            return System.Array.Empty<Vector2>();
        }

        // 转换为世界坐标
        var pathWorld = new Vector2[pathTiles.Count];
        for (int i = 0; i < pathTiles.Count; i++)
            pathWorld[i] = MapToLocal(pathTiles[i]);

        GD.Print($"路径计算成功: {fromGrid} -> {toGrid}, 步数: {pathTiles.Count}");
        return pathWorld;
    }

    public override void _Draw()
    {
        if (!ShowDebugGrid) return;

        var usedRect = GetUsedRect();
        var currentTileSize = TileSet.TileSize;

        // 绘制网格线
        for (int x = usedRect.Position.X; x <= usedRect.End.X; x++)
        {
            for (int y = usedRect.Position.Y; y <= usedRect.End.Y; y++)
            {
                var tilePos = new Vector2I(x, y);
                var worldPos = MapToLocal(tilePos);

                // 绘制网格边框
                var rectPos = worldPos - (Vector2)currentTileSize / 2;
                DrawRect(new Rect2(rectPos, currentTileSize), new Color(0, 1, 0, 0.3f), false, 1.0f);

                if (x % 2 == 0 && y % 2 == 0)
                {
                    var coordText = $"({x},{y})";
                    DrawString(ThemeDB.FallbackFont, worldPos - new Vector2(15, -5),
                        coordText, HorizontalAlignment.Left, -1, 10, new Color(1, 1, 0));
                }
            }
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
            ToggleDebugGrid();
    }

    /// <summary>切换调试网格显示</summary>
    public void ToggleDebugGrid()
    {
        ShowDebugGrid = !ShowDebugGrid;
        QueueRedraw();
    }

    /// <summary>获取附近的方块</summary>
    public Array GetNearbyBlocks(Array pos, int radius)
    {
        var blocks = new Array();
        var usedRect = GetUsedRect();
        int x = pos[0].AsInt32();
        int y = pos[1].AsInt32();

        for (int ix = x - radius; ix <= x + radius; ix++)
        {
            for (int iy = y - radius; iy <= y + radius; iy++)
            {
                var tilePos = new Vector2I(ix, iy);
                if (usedRect.HasPoint(tilePos))
                {
                    var tileData = GetCellTileData(tilePos);
                    if (tileData != null)
                    {
                        blocks.Add(new Dictionary
                        {
                            { "position", tilePos },
                            { "block_name", tileData.GetCustomData("Block Name") }
                        });
                    }
                }
            }
        }
        return blocks;
    }
}
