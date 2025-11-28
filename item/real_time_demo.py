# real_time_demo.py
import asyncio
import random
from item_controller import ItemController

async def real_time_demo():
    controller = ItemController()
    await controller.connect()
    
    # 实时注册随机物品
    item_types = ["weapon", "consumable", "material", "armor"]
    rarities = ["common", "uncommon", "rare", "epic"]
    
    for i in range(5):
        item_data = {
            "item_id": f"dynamic_item_{i}",
            "display_name": f"动态物品 {i}",
            "description": f"这是第 {i} 个动态注册的物品",
            "max_stack": random.randint(1, 10),
            "item_type": random.choice(item_types),
            "rarity": random.choice(rarities),
            "custom_properties": {
                "created_at": "runtime",
                "random_value": random.randint(1, 100)
            }
        }
        
        result = await controller.register_item(item_data)
        print(f"实时注册: {result}")
        
        await asyncio.sleep(1)  # 等待1秒
    
    # 验证注册结果
    items = await controller.get_all_items()
    print(f"当前物品数量: {len(items.get('items', {}))}")

if __name__ == "__main__":
    asyncio.run(real_time_demo())