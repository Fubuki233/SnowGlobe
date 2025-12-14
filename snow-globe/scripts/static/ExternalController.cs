using Godot;

/// <summary>
/// 外部控制器 - 用于通过 RPC 远程控制游戏实例
/// </summary>
public partial class ExternalController : Node
{
    [Export] public string Id { get; set; } = "external_controller";

    public override void _Ready()
    {
        GodotRPC.Instance?.RegisterInstance(Id, this);
    }

    /// <summary>移动指定实例到目标位置</summary>
    public void MoveToPosition(string instanceId, Godot.Collections.Array pos)
    {
        var instance = GodotRPC.Instance?.GetInstance(instanceId);
        if (instance != null && instance.HasMethod("move_to_position"))
        {
            instance.Call("move_to_position", pos);
        }
        else
        {
            GD.Print($"找不到 ID 为 '{instanceId}' 的实例或方法");
        }
    }
}
