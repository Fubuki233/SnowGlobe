using Godot;

/// <summary>
/// 游戏主控制器 - 管理游戏初始化和 Python 服务器
/// 测试代码已移至 scripts/test/GameTests.cs
/// </summary>
public partial class Main : Node
{
    [Export] public bool RunTests { get; set; } = false;
    
    private int _pythonServerPid = 0;

    public override void _Ready()
    {
        StartPythonServer();
        
        if (RunTests)
            RunGameTests();
    }
    
    /// <summary>运行游戏测试（可选）</summary>
    private void RunGameTests()
    {
        var tests = new SnowGlobe.Tests.GameTests();
        AddChild(tests);
    }

    /// <summary>启动 Python RPC 服务器</summary>
    private void StartPythonServer()
    {
        string scriptPath = "scripts/static/godot_rpc_server.py";
        string fullPath = ProjectSettings.GlobalizePath($"res://{scriptPath}");

        GD.Print("启动 Python RPC 服务器...");
        var args = new string[] { fullPath };
        _pythonServerPid = OS.CreateProcess("python", args);

        if (_pythonServerPid > 0)
            GD.Print($"Python 服务器已启动 (PID: {_pythonServerPid})");
        else
            GD.PushError("Python 服务器启动失败");
    }

    /// <summary>停止 Python 服务器</summary>
    private void StopPythonServer()
    {
        if (_pythonServerPid > 0)
        {
            OS.Kill(_pythonServerPid);
            GD.Print("Python 服务器已停止");
            _pythonServerPid = 0;
        }
    }

    public override void _ExitTree()
    {
        StopPythonServer();
    }
}
