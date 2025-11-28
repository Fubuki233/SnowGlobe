# save_as: rpc_sample_with_mock.py
import asyncio
import sys
import os

# 添加项目根目录到Python路径
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

try:
    from lib.gdrpc import GodotRPCClient
    USE_REAL_CLIENT = True
    print("✅ 使用真实的Godot RPC客户端")
except ImportError as e:
    print(f"❌ 导入错误: {e}")
    sys.exit(1)

class MockGodotRPCClient:
    """模拟Godot RPC客户端，用于开发和测试"""
    
    def __init__(self, uri: str = "ws://localhost:8765"):
        self.uri = uri
        print(f"🔧 模拟客户端 - 配置URI: {uri}")
    
    async def __aenter__(self):
        print("🔧 模拟Godot RPC客户端已启动")
        print("💡 注意: 这是模拟客户端，Godot服务器未连接")
        return self
    
    async def __aexit__(self, *args):
        print("🔧 模拟客户端已关闭")
    
    async def call(self, instance_id: str, method_name: str, *args):
        print(f"🔧 模拟RPC调用: {instance_id}.{method_name}{args}")
        
        # 返回模拟数据
        if method_name == "get_status":
            return {"health": 100, "position": [5, 5], "state": "idle"}
        elif method_name == "get_nearby_blocks":
            return ["grass", "stone", "dirt", "wood", "water"]
        elif method_name == "move_to_position":
            return {"success": True, "new_position": args[1]}
        else:
            return {"success": True, "message": f"调用 {method_name} 完成"}

async def main():
    try:
        print("正在连接到Godot RPC服务器...")
        async with GodotRPCClient() as client:
            print("✅ 连接成功！开始执行RPC调用...")
            
            # 执行RPC调用
            status = await client.call("player_1", "get_status")
            print(f"玩家状态: {status}")
            
            blocks = await client.call("tile_map_layer", "get_nearby_blocks", [10, 10], 5)
            print(f"附近区块: {blocks}")
            
            move_result = await client.call("external_controller", "move_to_position", "player_1", [6, 7])
            print(f"移动结果: {move_result}")
            
    except ConnectionRefusedError:
        print("\n❌ 无法连接到Godot服务器!")
        print("💡 切换到模拟模式进行开发测试...\n")
        
        # 切换到模拟客户端
        async with MockGodotRPCClient() as mock_client:
            status = await mock_client.call("player_1", "get_status")
            print(f"模拟玩家状态: {status}")
            
            blocks = await mock_client.call("tile_map_layer", "get_nearby_blocks", [10, 10], 5)
            print(f"模拟附近区块: {blocks}")
            
            move_result = await mock_client.call("external_controller", "move_to_position", "player_1", [6, 7])
            print(f"模拟移动结果: {move_result}")
            
    except Exception as e:
        print(f"❌ 发生错误: {e}")

if __name__ == "__main__":
    print("=== Godot RPC 示例 ===")
    asyncio.run(main())