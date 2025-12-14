using Godot;

/// <summary>
/// 图标演示脚本 - 旋转和移动的精灵
/// </summary>
public partial class IconDemo : Sprite2D
{
    [Export] public float MoveSpeed { get; set; } = 400f;
    [Export] public float AngularSpeed { get; set; } = Mathf.Pi;

    public override void _Ready()
    {
        GD.Print("Hello, world!");

        var timer = GetNodeOrNull<Timer>("Timer");
        if (timer != null)
            timer.Timeout += OnTimerTimeout;
    }

    public override void _Process(double delta)
    {
        Rotation += AngularSpeed * (float)delta;
        var velocity = Vector2.Up.Rotated(Rotation) * MoveSpeed;
        Position += velocity * (float)delta;
    }

    /// <summary>按钮点击时切换处理状态</summary>
    public void OnButtonPressed()
    {
        SetProcess(!IsProcessing());
    }

    /// <summary>计时器超时时切换可见性</summary>
    private void OnTimerTimeout()
    {
        Visible = !Visible;
    }
}
