import asyncio

from lib.gdrpc import GodotRPCClient


async def main():
    async with GodotRPCClient() as client:
        status = await client.call("player_1", "get_status")
        print(f"状态: {status}")
        blocks = await client.call("tile_map_layer", "get_nearby_blocks", [10, 10], 5)
        print(f"附近的区块: {blocks}")
        await client.call("external_controller", "move_to_position", "player_1" ,[6, 7])
        print(f"移动")

if __name__ == "__main__":
    asyncio.run(main())