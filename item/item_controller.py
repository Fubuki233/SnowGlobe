# item_controller.py
import asyncio
import json
from lib.gdrpc import GodotRPCClient

class ItemController:
    def __init__(self):
        self.client = None
    
    async def connect(self):
        self.client = await GodotRPCClient().connect()
        return self
    
    async def register_item(self, item_data):
        """注册新物品"""
        return await self.client.call("item_manager", "register_item", item_data)
    
    async def update_item(self, item_id, item_data):
        """更新物品"""
        return await self.client.call("item_manager", "update_item", item_id, item_data)
    
    async def remove_item(self, item_id):
        """移除物品"""
        return await self.client.call("item_manager", "remove_item", item_id)
    
    async def get_item(self, item_id):
        """获取物品信息"""
        return await self.client.call("item_manager", "get_item", item_id)
    
    async def get_all_items(self):
        """获取所有物品"""
        return await self.client.call("item_manager", "get_all_items")
    
    async def create_item_instance(self, item_id, quantity=1):
        """创建物品实例"""
        return await self.client.call("item_manager", "create_item_instance", item_id, quantity)

# 使用示例
async def demo():
    controller = ItemController()
    await controller.connect()
    
    # 注册新武器
    sword_data = {
        "item_id": "iron_sword",
        "display_name": "铁剑",
        "description": "一把锋利的铁剑",
        "max_stack": 1,
        "item_type": "weapon",
        "rarity": "uncommon",
        "custom_properties": {
            "damage": 15,
            "attack_speed": 1.2,
            "weapon_type": "sword"
        }
    }
    
    result = await controller.register_item(sword_data)
    print(f"注册武器: {result}")
    
    # 注册消耗品
    potion_data = {
        "item_id": "health_potion",
        "display_name": "生命药水", 
        "description": "恢复50点生命值",
        "max_stack": 5,
        "item_type": "consumable",
        "rarity": "common",
        "custom_properties": {
            "effect_type": "heal",
            "effect_value": 50.0
        }
    }
    
    result = await controller.register_item(potion_data)
    print(f"注册药水: {result}")
    
    # 获取所有物品
    items = await controller.get_all_items()
    print(f"所有物品: {json.dumps(items, indent=2, ensure_ascii=False)}")

if __name__ == "__main__":
    asyncio.run(demo())