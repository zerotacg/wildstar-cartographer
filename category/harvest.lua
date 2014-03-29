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
    local path    = { self.type }
    local folders = {
        self:skill( unit )
      , unit:GetName()
    }
    for i, folder in ipairs( folders) do
        if folder then
            table.insert( path, folder )
        end
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
function M:marker( data )
    local tInfo =
    {   strIcon       = data.minimap_marker
      , strIconEdge   = ""
      , crObject      = CColor.new(1, 1, 1, 1)
      , crEdge        = CColor.new(1, 1, 1, 1)
      , bAboveOverlay = false
    }
    return tInfo
end

-------------------------------------------------------------------------------
local Addon = Apollo.GetAddon("Gathermate")
Addon:addCategory( M:new() )

-------------------------------------------------------------------------------
return M
