using Godot;

/// <summary>
/// 玩家反应控制器 - 处理按钮交互等
/// </summary>
[Tool]
public partial class PlayerReact : Node2D
{
    public override void _Ready()
    {
        // 初始化
    }

    public override void _Process(double delta)
    {
        // 处理每帧逻辑
    }

    /// <summary>按钮点击时触发移动到随机位置</summary>
    public void OnButtonPressed()
    {
        var player = GetNodeOrNull<PlayerPhysics>("Player");
        if (player != null && player.HasMethod("MoveToRandomPosition"))
        {
            player.MoveToRandomPosition();
        }
        else
        {
            GD.Print("找不到 Player 或方法");
        }
    }
}
