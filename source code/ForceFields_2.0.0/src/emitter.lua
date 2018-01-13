require 'src/settings'
require 'src/utilities'


Emitter = {}


function Emitter.onEmitterBuilt(self, createdEntity)
  local newEmitter = {}
  local surface = createdEntity.surface
  if not global.forcefields then
    global.forcefields = {}
  end
  if global.forcefields.emitters == nil then
    global.forcefields.emitters = {}
    global.forcefields.emitterNEI = 1 -- NextEmitterIndex
  end

  newEmitter["entity"] = createdEntity
  newEmitter["active"] = false
  newEmitter["damaged-fields"] = nil
  newEmitter["build-scan"] = true
  newEmitter["emitter-NEI"] = "I" .. global.forcefields.emitterNEI
  newEmitter["width"] = Settings.emitterDefaultWidth
  newEmitter["distance"] = Settings.emitterDefaultDistance
  newEmitter["build-tick"] = 0
  newEmitter["type"] = Settings.defaultFieldType
  newEmitter["direction"] = defines.direction.north
  newEmitter["generating-fields"] = nil
  newEmitter["width-upgrades"] = 0
  newEmitter["distance-upgrades"] = 0
  newEmitter["disabled"] = false

  -- Simulates reviving killed emitters => it copies old settings
  if global.forcefields.killedEmitters ~= nil then
    for k,killedEmitter in pairs(global.forcefields.killedEmitters) do
      if killedEmitter["surface"] == surface and killedEmitter["position"].x == createdEntity.position.x and killedEmitter["position"].y == createdEntity.position.y then
        newEmitter["width"] = killedEmitter["width"]
        newEmitter["distance"] = killedEmitter["distance"]
        newEmitter["type"] = killedEmitter["type"]
        newEmitter["direction"] = killedEmitter["direction"]
        self:removeKilledEmitter(k)
        break
      end
    end
  end

  global.forcefields.emitters["I" .. global.forcefields.emitterNEI] = newEmitter
  global.forcefields.emitterNEI = global.forcefields.emitterNEI + 1

  self:setActive(newEmitter, true, true)
end



function Emitter.onEmitterMined(self, emitter, playerIndex)
  local emitterTable = self:findEmitter(emitter)
  local player

  if emitterTable ~= nil then
    self:removeEmitterID(emitterTable["emitter-NEI"])
  end
  if playerIndex then
    player = game.players[playerIndex]
  end

  if emitterTable["width-upgrades"] ~= 0 then
    if player then
      transferToPlayer(player, {name = "advanced-circuit", count = emitterTable["width-upgrades"]})
    else
      dropOnGround(emitterTable["entity"].surface, emitterTable["entity"].position, {name = "advanced-circuit", count = emitterTable["width-upgrades"]}, true, emitterTable["entity"].force)
    end
  end
  if emitterTable["distance-upgrades"] ~= 0 then
    if player then
      transferToPlayer(player, {name = "processing-unit", count = emitterTable["distance-upgrades"]})
    else
      dropOnGround(emitterTable["entity"].surface, emitterTable["entity"].position, {name = "processing-unit", count = emitterTable["distance-upgrades"]}, true, emitterTable["entity"].force)
    end
  end
end



function Emitter.onEmitterDied(self, emitter)
  local emitterTable = self:findEmitter(emitter)
  if emitterTable ~= nil then
    self:removeEmitterID(emitterTable["emitter-NEI"])
    self:storeKilledEmitter(emitterTable)
  end
end



function Emitter.findEmitter(self, emitter)
  if global.forcefields.emitters ~= nil then
    for k,v in pairs(global.forcefields.emitters) do
      if v["entity"] == emitter then
        return v
      end
    end
  end
end



function Emitter.setActive(self, emitterTable, enableCheckBuildingFields, skipResetTimer)
  if emitterTable["disabled"] == true then
    return
  end

  if enableCheckBuildingFields then
    emitterTable["build-scan"] = true
    if not skipResetTimer and emitterTable["build-tick"] > Settings.forcefieldTypes[emitterTable["type"]]["respawnRate"] or not emitterTable["active"] then
      emitterTable["build-tick"] = Settings.forcefieldTypes[emitterTable["type"]]["respawnRate"]
    end
  end

  if not emitterTable["active"] then
    emitterTable["active"] = true
    if global.forcefields.activeEmitters == nil then
      global.forcefields.activeEmitters = {}
    end
    table.insert(global.forcefields.activeEmitters, emitterTable)
    self:activateTicker()
  end
end



function Emitter.activateTicker(self)
  if not global.forcefields.ticking then
    global.forcefields.ticking = Settings.tickRate
    script.on_event(defines.events.on_tick, function(_) Emitter:onTick() end)
  end
end



function Emitter.onTick(self)
  if global.forcefields.ticking == 0 then
    global.forcefields.ticking = Settings.tickRate - 1
    self:updateTick()
  else
    global.forcefields.ticking = global.forcefields.ticking - 1
  end
end



function Emitter.updateTick(self)
  local shouldKeepTicking
  -- Active emitters tick
  if global.forcefields.activeEmitters ~= nil then
    local shouldRemainActive
    local emitterTable
    shouldKeepTicking = true

    -- For each active emitter check if they have fields to repair or fields to build
    for k,emitterTable in pairs(global.forcefields.activeEmitters) do
      if emitterTable["entity"].valid then
        -- By default let us not keep it active, if its needed we re-activate it
        shouldRemainActive = false

        if emitterTable["disabled"] == false then
          if emitterTable["build-scan"] ~= nil then
            -- The function will toggle index 4 (build-scan) if it finishes building fields.
            if Forcefield:scanAndBuildFields(emitterTable) then
              shouldRemainActive = true
            end
          end
        end
        if emitterTable["generating-fields"] then
          -- The function will toggle index 11 (generating-fields) if it finishes generating fields.
          if Forcefield:generateFields(emitterTable) then
            shouldRemainActive = true
          end
        end

        if emitterTable["damaged-fields"] then
          -- The function will toggle index 3 (emitterTable) if it finishes repairing fields.
          if Forcefield:regenerateFields(emitterTable) then
            shouldRemainActive = true
          end
        end

        if not shouldRemainActive then
          -- Index 2 (active) is the active state of the emitter
          emitterTable["active"] = false
          if not self:removeActiveEmitterID(k) then
            break
          end
        end
      else
        self:removeEmitterID(emitterTable["emitter-NEI"])
        if not self:removeActiveEmitterID(k) then
          break
        end
      end
    end
  end

  -- Degrading force fields tick - happens when a emitter dies or is mined.
  if global.forcefields.degradingFields ~= nil then
    shouldKeepTicking = true
    for k,v in pairs(global.forcefields.degradingFields) do
      if v["entity"].valid then
        v["entity"].health = v["entity"].health - (Settings.forcefieldTypes[v["entity"].name]["degradeRate"] * Settings.tickRate)
        if v["entity"].health == 0 then
          v["entity"].destroy()
          if not Forcefield:removeDegradingFieldID(k) then
            break
          end
        end
      else
        if not Forcefield:removeDegradingFieldID(k) then
          break
        end
      end
    end
  end

  if global.forcefields.searchDamagedPos ~= nil then
    shouldKeepTicking = true
    for index,xs in pairs (global.forcefields.searchDamagedPos) do
      local surface = game.surfaces[index]
      for sx,ys in pairs(xs) do
        for sy in pairs(ys) do
          local foundFields = Forcefield:findForcefieldsRadius(surface, {x = sx + 0.5, y = sy + 0.5}, 1)
          if foundFields ~= nil then
            Forcefield:handleDamagedFields(foundFields)
          end
          table.remove(ys, sy)
        end
        table.remove(global.forcefields.searchDamagedPos, sx)
      end
      table.remove(global.forcefields.searchDamagedPos, index)
    end

    if #global.forcefields.searchDamagedPos == 0 then
      global.forcefields.searchDamagedPos = nil
    end
  end

  if not shouldKeepTicking then
    global.forcefields.ticking = nil
    script.on_event(defines.events.on_tick, nil)
  end
end



function Emitter.removeEmitterID(self, emitterID)
  if global.forcefields.emitters ~= nil then
    if global.forcefields.emitters[emitterID] ~= nil then
      Forcefield:degradeLinkedFields(global.forcefields.emitters[emitterID])
      global.forcefields.emitters[emitterID] = nil
      if tableIsEmpty(global.forcefields.emitters) then
        global.forcefields.emitters = nil
        global.forcefields.emitterNEI = nil
      else
        return true
      end
    end
  end
end



function Emitter.removeActiveEmitterID(self, activeEmitterID)
  -- Returns true if the global.forcefields.activeEmitters table isn't empty
  if global.forcefields.activeEmitters ~= nil then
    table.remove(global.forcefields.activeEmitters, activeEmitterID)
    if #global.forcefields.activeEmitters == 0 then
      global.forcefields.activeEmitters = nil
    else
      return true
    end
  end
end



function Emitter.removeKilledEmitter(self, index)
  table.remove(global.forcefields.killedEmitters, index)
  if #global.forcefields.killedEmitters == 0 then
    global.forcefields.killedEmitters = nil
  end
end



function Emitter.storeKilledEmitter(self, emitterTable)
  local newKilledEmitter = {}
  if global.forcefields.killedEmitters == nil then
    global.forcefields.killedEmitters = {}
  end
  newKilledEmitter["surface"] = emitterTable["entity"].surface
  newKilledEmitter["position"] = emitterTable["entity"].position
  newKilledEmitter["width"] = emitterTable["width"]
  newKilledEmitter["distance"] = emitterTable["distance"]
  newKilledEmitter["type"] = emitterTable["type"]
  newKilledEmitter["direction"] = emitterTable["direction"]
  table.insert(global.forcefields.killedEmitters, newKilledEmitter)
end
