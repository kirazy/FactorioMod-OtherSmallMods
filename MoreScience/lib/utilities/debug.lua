
Debug = {}

Debug.enabled = true
Debug.returnValue = 3

function Debug:reseachAllTechnologies()
  force = game.forces["player"]

  local function researchTechnology(technologyName)
    if force.technologies[technologyName] and force.technologies[technologyName].enabled then
      -- check prerequisites
      for _,prerequisite in pairs(force.technologies[technologyName].prerequisites) do
        if not prerequisite.researched then
          return false
        end
      end
      -- do the research
      force.technologies[technologyName].researched = true
      return true
    end
    return false
  end


--------------------------------------------------------------------------------
----- Start of the game: minor defence and automation of power             -----
--------------------------------------------------------------------------------

  -- Automation & Logistics: smelter setup
  researchTechnology("basic-automation")
  researchTechnology("automation")
  researchTechnology("logistics")

  -- Military: first defence systems
  researchTechnology("military")
  researchTechnology("stone-walls")
  researchTechnology("turrets")

  -- Military: bonusses
  researchTechnology("bullet-damage-1")
  researchTechnology("bullet-speed-1")
  researchTechnology("shotgun-shell-damage-1")
  researchTechnology("shotgun-shell-speed-1")

  -- Character management: light and inventory
  researchTechnology("optics")
  researchTechnology("toolbelt")

  if self.returnValue == 1 then
    return
  end



--------------------------------------------------------------------------------
----- Advancing to basic defence and automation of basic (green) science   -----
--------------------------------------------------------------------------------

  -- Science: research green science (and bottling)
  researchTechnology("electronics")
  researchTechnology("automation-2")
  researchTechnology("steel-processing")
  researchTechnology("basic-science-research-1")

  researchTechnology("fluid-handling")
  researchTechnology("bottling-research")

  -- Science: bonusses
  researchTechnology("research-speed-1")
  researchTechnology("research-speed-2")

  -- Power network: beter power poles
  researchTechnology("electric-energy-distribution-1")

  -- Logistics: fluid storage, landfill
  researchTechnology("fluid-handling-2")
  researchTechnology("landfill")

  -- Military: basic defence systems
  researchTechnology("heavy-armor")
  researchTechnology("military-2")
  researchTechnology("gates")

  -- Military: optional research
  researchTechnology("flammables")

  -- Military: bonusses
  researchTechnology("bullet-damage-2")
  researchTechnology("bullet-speed-2")
  researchTechnology("bullet-speed-3")
  researchTechnology("gun-turret-damage-1")
  researchTechnology("gun-turret-damage-2")
  researchTechnology("shotgun-shell-damage-2")
  researchTechnology("shotgun-shell-speed-2")
  researchTechnology("shotgun-shell-speed-3")

  if self.returnValue == 2 then
    return
  end



--------------------------------------------------------------------------------
----- Establishing beter defence systems (gray science)                    -----
--------------------------------------------------------------------------------

  -- Science: research gray science
  researchTechnology("basic-military-science-research")

  -- Military: advanced defence systems
  researchTechnology("flamethrower")


  -- Military: bonusses
  researchTechnology("bullet-damage-3")
  researchTechnology("bullet-damage-4")
  researchTechnology("bullet-speed-4")
  researchTechnology("gun-turret-damage-3")
  researchTechnology("gun-turret-damage-4")
  researchTechnology("shotgun-shell-damage-3")
  researchTechnology("shotgun-shell-damage-4")
  researchTechnology("shotgun-shell-speed-4")
  researchTechnology("grenade-damage-1")
  researchTechnology("grenade-damage-2")
  researchTechnology("grenade-damage-3")

  if self.returnValue == 3 then
    return
  end



--------------------------------------------------------------------------------
----- Get automation to the next level (orange/blue science)               -----
--------------------------------------------------------------------------------

  -- Science: research orange science
  researchTechnology("basic-automation-science-research")

  -- Automation: getting into oil processing
  researchTechnology("circuit-network")
  researchTechnology("oil-processing")
  researchTechnology("plastics")
  researchTechnology("advanced-electronics")
  researchTechnology("sulfur-processing")
  researchTechnology("battery")

  -- Automation: optional research
  researchTechnology("advanced-material-processing")

  -- Science: research blue science
  researchTechnology("basic-science-research-2")

  -- Science: research pink science
  researchTechnology("engine")
  researchTechnology("electric-engine")
  researchTechnology("basic-logistics-science-research")

  -- Logistics: train network
  researchTechnology("railway")
  researchTechnology("automated-rail-transportation")
  researchTechnology("rail-signals")
  researchTechnology("fluid-wagon")
  researchTechnology("logistics-2")

  -- Logistics: robot network
  researchTechnology("robotics")
  researchTechnology("flying")
  researchTechnology("construction-robotics")
  researchTechnology("logistic-robotics")

  if self.returnValue == 4 then
    return
  end



  return
end
