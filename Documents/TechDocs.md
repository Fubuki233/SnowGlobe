# 技术文档

## Python 脚本控制 Godot

开发了一个 Godot RPC 客户端,可以通过Python脚本来调用 任意Godot方法,并获取返回值.

### 使用方法

首先启动godot项目,此时godot项目会自动加载RPC服务器脚本:

加载方式:

```GDscript
#project.godot内:
[autoload]
GodotRPC="*res://scripts/static/godot_rpc.gd"

#scripts/static/main.gd内:
func _ready() -> void:
	start_python_server()

```

当完全启动后,控制台应该有以下输出:

```powershell

[GodotRPC] 初始化
[GodotRPC] 注册实例: tile_map_layer
TileMapLayer ready, AStar region: [P: (-8, -4), S: (27, 16)]
[GodotRPC] 注册实例: player_1
[GodotRPC] 注册实例: external_controller
启动 Python RPC 服务器...
Python 服务器已启动 (PID: 89616)
[GodotRPC] 已连接到服务器
[GodotRPC] 服务器确认连接

```

随后就可以通过Python脚本来调用Godot方法了,示例代码在LLMController/sample/rpc_sample.py内:

```python
import asyncio
from lib.gdrpc import GodotRPCClient  # 导入 Godot RPC 客户端


async def main():　 # 异步主函数,大多数情况下需要异步调用 否则程序会阻塞  
    async with GodotRPCClient() as client:
        status = await client.call("player_1", "get_status")
        print(f"状态: {status}")
        blocks = await client.call("tile_map_layer", "get_nearby_blocks", [10, 10], 5)
        print(f"附近的区块: {blocks}")
        await client.call("external_controller", "move_to_position", "player_1" ,[6, 7])
        print(f"移动")

if __name__ == "__main__":
    
    asyncio.run(main())
    
```