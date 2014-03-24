-------------------------------------------------------------------------------
local M = {
    type = "Harvest"
  , enabled = {
        ["Mining"]        = true
      , ["Relic Hunter"]  = true
      , ["Farmer"]        = true
      , ["Survivalist"]   = true
      , ["ALL"]           = true
    }
}

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
end

--------------------------------------------------------------------------------
function M:path( unit )
    local path = { self.type }
    if unit then
        table.insert( path, self:skill( unit ) )
        table.insert( path, unit:GetMiniMapMarker() )
    end
    return path
end

--------------------------------------------------------------------------------
function M:skill( unit )
    return unit:GetHarvestRequiredTradeskillName()
end

-------------------------------------------------------------------------------
function M:accepts( unit )
    local type = unit:GetType()
    local skill = self:skill( unit )
    return self.type == type and ( self.enabled.ALL or self.enabled[skill] )
end

-------------------------------------------------------------------------------
function M:data( unit )
    return {
        skill_name = unit:GetHarvestRequiredTradeskillName()
      , skill_tier = unit:GetHarvestRequiredTradeskillTier()
      , minimap_marker = unit:GetMiniMapMarker()
    }
end

-------------------------------------------------------------------------------
local Cartographer = Apollo.GetAddon("Cartographer")
Cartographer:addCategory( M:new() )

-------------------------------------------------------------------------------
return M
