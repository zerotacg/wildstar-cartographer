local Apollo  = require "Apollo"
local LibStub = _G["LibStub"]
local Unit    = LibStub:GetLibrary( "cartographer/collector/Unit-0", 0 )

-------------------------------------------------------------------------------
local Npc = LibStub:NewLibrary( "cartographer/collector/Npc-0", 0 )
if ( not Npc ) then return end

-------------------------------------------------------------------------------
local M = {
    unit_type = "NonPlayer"
  , categories = {
        ["Npc"]        = {
            ["FlightPathSettler"] = { label = "Taxi", strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Flight"    , bNeverShowOnEdge = true, bFixedSizeMedium = true }
          , ["FlightPath"]        = { label = "Taxi", strIcon = "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered", bNeverShowOnEdge = true, bFixedSizeMedium = true }
          , ["FlightPathNew"]     = { label = "Taxi", strIcon = "IconSprites:Icon_MapNode_Map_Taxi"             , bNeverShowOnEdge = true, bFixedSizeMedium = true }
        }
    }
}
local super = Unit
setmetatable( Npc, { __index = M } )
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:type( unit )
    local category = self.categories.Npc;
    if not category then return end
    
    local type = unit:GetMiniMapMarkers()[1]
    return category[type];
end 

-------------------------------------------------------------------------------
function M:marker( data )
    local tInfo =
    {   strIcon       = "harvest_sprites:" .. data.minimap_marker
      , strIconEdge   = ""
      , crObject      = CColor.new(1, 1, 1, 1)
      , crEdge        = CColor.new(1, 1, 1, 1)
      , bAboveOverlay = false
    }
    return tInfo
end

-------------------------------------------------------------------------------

return M
