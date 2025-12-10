import asyncio
import websockets
import json
from typing import Dict, Any, Optional


class GodotRPCServer:
    """Godot RPC 服务器 - 转发方法调用"""
    
    def __init__(self):
        self.godot_ws = None  # Godot 连接
        self.clients = {}  # {websocket: set of pending_call_ids}
        self.pending_calls = {}  # {call_id: websocket}
    
    async def handle_connection(self, websocket):
        """处理新连接"""
        print(f"[连接] {websocket.remote_address}")
        
        try:
            async for message in websocket:
                data = json.loads(message)
                msg_type = data.get("type")
                
                # 判断连接类型
                if msg_type == "godot_ready":
                    # Godot 游戏连接
                    self.godot_ws = websocket
                    print("[Godot] 游戏已连接")
                    await websocket.send(json.dumps({"type": "ready_ack"}))
                
                elif msg_type == "call_method":
                    # 客户端请求调用方法
                    await self._handle_call_request(websocket, data)
                
                elif msg_type == "method_result":
                    # Godot 返回方法结果
                    await self._handle_method_result(data)
        
        except websockets.exceptions.ConnectionClosed:
            print(f"[断开] {websocket.remote_address}")
        finally:
            if websocket == self.godot_ws:
                self.godot_ws = None
                print("[Godot] 已断开")
            if websocket in self.clients:
                del self.clients[websocket]
    
    async def _handle_call_request(self, client_ws, data):
        """处理客户端的方法调用请求"""
        if not self.godot_ws:
            # Godot 未连接
            await client_ws.send(json.dumps({
                "type": "method_result",
                "call_id": data.get("call_id"),
                "success": False,
                "error": "Godot 未连接"
            }))
            return
        
        call_id = data.get("call_id")
        instance_id = data.get("instance_id")
        method_name = data.get("method_name")
        args = data.get("args", [])
        
        print(f"[RPC] {instance_id}.{method_name}({args})")
        
        # 记录调用来源
        self.pending_calls[call_id] = client_ws
        if client_ws not in self.clients:
            self.clients[client_ws] = set()
        self.clients[client_ws].add(call_id)
        
        # 转发给 Godot
        await self.godot_ws.send(json.dumps({
            "type": "call_method",
            "call_id": call_id,
            "instance_id": instance_id,
            "method_name": method_name,
            "args": args
        }))
    
    async def _handle_method_result(self, data):
        """处理 Godot 返回的方法结果"""
        call_id = data.get("call_id")
        success = data.get("success")
        result = data.get("result")
        error = data.get("error")
        
        if success:
            print(f"[结果]  {result}")
        else:
            print(f"[错误]  {error}")
        
        # 转发给对应的客户端
        if call_id in self.pending_calls:
            client_ws = self.pending_calls[call_id]
            
            try:
                await client_ws.send(json.dumps(data))
            except:
                pass  # 客户端可能已断开
            
            # 清理
            del self.pending_calls[call_id]
            if client_ws in self.clients:
                self.clients[client_ws].discard(call_id)


async def main():
    """启动服务器"""
    server = GodotRPCServer()
    print("监听: ws://localhost:8765")
    print("等待连接...\n")
    
    async with websockets.serve(server.handle_connection, "localhost", 8765):
        await asyncio.Future()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n服务器已停止")
