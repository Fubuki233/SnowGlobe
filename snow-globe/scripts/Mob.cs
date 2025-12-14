using Godot;

/// <summary>
/// 怪物/生物控制器
/// </summary>
public partial class Mob : RigidBody2D
{
    private AnimatedSprite2D _animatedSprite;

    public override void _Ready()
    {
        _animatedSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");

        // 随机选择动画
        var mobTypes = _animatedSprite.SpriteFrames.GetAnimationNames();
        var randomIndex = GD.RandRange(0, mobTypes.Length - 1);
        _animatedSprite.Animation = mobTypes[(int)randomIndex];
        _animatedSprite.Play();
    }

    public override void _Process(double delta)
    {
        // 处理每帧逻辑
    }

    /// <summary>当离开屏幕时销毁</summary>
    private void OnVisibleOnScreenNotifier2DScreenExited()
    {
        QueueFree();
    }
}
