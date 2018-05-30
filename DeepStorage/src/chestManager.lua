require 'src/settings'
require 'src/chestDatastructure'

ChestManager = {}

function ChestManager:onInit()
  ChestDatastructure:onInit()
end



function ChestManager:onChestCreated(inventoryEntity)
  -- Create the monitor
  local monitorEntity = inventoryEntity.surface.create_entity{
    name = Settings.storageMonitorName,
    position = inventoryEntity.position,
    force = inventoryEntity.force,
  }

  -- Add data
  ChestDatastructure:addNewChestData(inventoryEntity, monitorEntity)
end



function ChestManager:onChestDeconstruction(deconstructedEntity)
  local surfaceIndex = deconstructedEntity.surface.index
  local surfacePosX = deconstructedEntity.position.x
  local surfacePosY = deconstructedEntity.position.y

  -- Remove other associated entities
  local inventoryEntity = ChestDatastructure:getInventoryEntity(surfaceIndex, surfacePosX, surfacePosY)
  if inventoryEntity.can_be_destroyed() then
    inventoryEntity.destroy()
  end

  -- Remove data
  ChestDatastructure:removeChestData(surfaceIndex, surfacePosX, surfacePosY)
end



function ChestManager:onTick()
  if game.tick % 60 == 0 then
    ChestDatastructure:updateNextChest()
  end
end