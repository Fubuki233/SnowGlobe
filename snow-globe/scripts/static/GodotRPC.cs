using Godot;
using Godot.Collections;
using System;

/// <summary>
/// Godot RPC 客户端 - 提供 WebSocket 方法调用功能
/// 极简设计，自动连接到 Python RPC 服务器
/// </summary>
public partial class GodotRPC : Node
{
    private WebSocketPeer _wsClient;
    private bool _connected = false;
    private Dictionary<string, Node> _registeredInstances = new();

    // 单例模式
    private static GodotRPC _instance;
    public static GodotRPC Instance => _instance;

    public override void _Ready()
    {
        _instance = this;
        GD.Print("[GodotRPC] 初始化");
        ConnectToServer();
    }

    public override void _Process(double delta)
    {
        if (_wsClient == null) return;

        _wsClient.Poll();
        var state = _wsClient.GetReadyState();

        if (state == WebSocketPeer.State.Open)
        {
            if (!_connected)
            {
                _connected = true;
                GD.Print("[GodotRPC] 已连接到服务器");
                SendReady();
            }

            // 接收消息
            while (_wsClient.GetAvailablePacketCount() > 0)
            {
                var packet = _wsClient.GetPacket();
                var message = packet.GetStringFromUtf8();
                HandleMessage(message);
            }
        }
        else if (state == WebSocketPeer.State.Closed)
        {
            if (_connected)
            {
                _connected = false;
                GD.Print("[GodotRPC] 连接断开，5秒后重连...");
                ReconnectAfterDelay();
            }
        }
    }

    private async void ReconnectAfterDelay()
    {
        await ToSignal(GetTree().CreateTimer(5.0), SceneTreeTimer.SignalName.Timeout);
        ConnectToServer();
    }

    /// <summary>连接到服务器</summary>
    public void ConnectToServer()
    {
        _wsClient = new WebSocketPeer();
        var err = _wsClient.ConnectToUrl("ws://localhost:8765");
        if (err != Error.Ok)
            GD.Print($"[GodotRPC] 连接失败: {err}");
    }

    /// <summary>发送就绪信号</summary>
    private void SendReady()
    {
        SendMessage(new Dictionary { { "type", "godot_ready" } });
    }

    /// <summary>发送消息</summary>
    public void SendMessage(Dictionary data)
    {
        if (_wsClient != null && _wsClient.GetReadyState() == WebSocketPeer.State.Open)
        {
            var jsonString = Json.Stringify(data);
            _wsClient.SendText(jsonString);
        }
    }

    /// <summary>处理接收到的消息</summary>
    private void HandleMessage(string message)
    {
        var json = new Json();
        var parseResult = json.Parse(message);

        if (parseResult != Error.Ok)
        {
            GD.Print("[GodotRPC] JSON 解析错误");
            return;
        }

        var data = json.Data.AsGodotDictionary();
        var msgType = data.ContainsKey("type") ? data["type"].AsString() : "";

        switch (msgType)
        {
            case "ready_ack":
                GD.Print("[GodotRPC] 服务器确认连接");
                break;

            case "call_method":
                var callId = data.ContainsKey("call_id") ? data["call_id"].AsString() : "";
                var instanceId = data.ContainsKey("instance_id") ? data["instance_id"].AsString() : "";
                var methodName = data.ContainsKey("method_name") ? data["method_name"].AsString() : "";
                var args = data.ContainsKey("args") ? data["args"].AsGodotArray() : new Godot.Collections.Array();

                var result = CallInstanceMethod(instanceId, methodName, args);

                // 返回结果
                SendMessage(new Dictionary
                {
                    { "type", "method_result" },
                    { "call_id", callId },
                    { "instance_id", instanceId },
                    { "method_name", methodName },
                    { "success", result["success"] },
                    { "result", result["value"] },
                    { "error", result["error"] }
                });
                break;
        }
    }

    /// <summary>注册实例</summary>
    public void RegisterInstance(string id, Node instance)
    {
        _registeredInstances[id] = instance;
        GD.Print($"[GodotRPC] 注册实例: {id}");
    }

    /// <summary>获取注册的实例</summary>
    public Node GetInstance(string id)
    {
        return _registeredInstances.TryGetValue(id, out var instance) ? instance : null;
    }

    /// <summary>调用实例方法</summary>
    public Dictionary CallInstanceMethod(string instanceId, string methodName, Godot.Collections.Array args)
    {
        if (!_registeredInstances.TryGetValue(instanceId, out var instance))
        {
            return new Dictionary
            {
                { "success", false },
                { "error", $"实例不存在: {instanceId}" },
                { "value", new Variant() }
            };
        }

        if (!instance.HasMethod(methodName))
        {
            return new Dictionary
            {
                { "success", false },
                { "error", $"方法不存在: {methodName}" },
                { "value", new Variant() }
            };
        }

        // 调用方法
        Variant result;
        if (args.Count == 0)
            result = instance.Call(methodName);
        else
            result = instance.Callv(methodName, args);

        GD.Print($"[GodotRPC] {instanceId}.{methodName}({args}) -> {result}");

        return new Dictionary
        {
            { "success", true },
            { "error", new Variant() },
            { "value", result }
        };
    }
}
