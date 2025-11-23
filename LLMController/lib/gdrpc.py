import asyncio
import websockets
import json
from typing import Any


class GodotRPCClient:
    
    def __init__(self, uri: str = "ws://localhost:8765"):
        self.uri = uri
        self.ws = None
        self.pending_calls = {}
        self.call_id_counter = 0
        self._receive_task = None
    
    async def connect(self):
        self.ws = await websockets.connect(self.uri)
        self._receive_task = asyncio.create_task(self._receive_loop())
        return self
    
    async def _receive_loop(self):
        try:
            async for message in self.ws:
                data = json.loads(message)
                
                if data.get("type") == "method_result":
                    call_id = data.get("call_id")
                    
                    if call_id in self.pending_calls:
                        future = self.pending_calls[call_id]
                        
                        if data.get("success"):
                            future.set_result(data.get("result"))
                        else:
                            future.set_exception(Exception(data.get("error")))
                        
                        del self.pending_calls[call_id]
        except:
            pass
    
    async def call(self, instance_id: str, method_name: str, *args) -> Any:

        self.call_id_counter += 1
        call_id = f"call_{self.call_id_counter}"
        future = asyncio.Future()
        self.pending_calls[call_id] = future
        
        await self.ws.send(json.dumps({
            "type": "call_method",
            "call_id": call_id,
            "instance_id": instance_id,
            "method_name": method_name,
            "args": list(args)
        }))
        
        try:
            return await asyncio.wait_for(future, timeout=10.0)
        except asyncio.TimeoutError:
            if call_id in self.pending_calls:
                del self.pending_calls[call_id]
            raise TimeoutError(f"调用 {instance_id}.{method_name}() 超时")
    
    async def close(self):
        if self._receive_task:
            self._receive_task.cancel()
        if self.ws:
            await self.ws.close()
    
    async def __aenter__(self):
        await self.connect()
        return self
    
    async def __aexit__(self, *args):
        await self.close()



async def call_method(instance_id: str, method_name: str, *args) -> Any:
    async with GodotRPCClient() as client:
        return await client.call(instance_id, method_name, *args)




