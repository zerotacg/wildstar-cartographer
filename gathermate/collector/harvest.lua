local Apollo  = require "Apollo"
local LibStub = _G["LibStub"]
local Unit    = LibStub:GetLibrary( "Gathermate/Unit-0", 0 )

-------------------------------------------------------------------------------
local Harvest = LibStub:NewLibrary( "Gathermate/Harvest-0", 0 )
if ( not Harvest ) then return end

-------------------------------------------------------------------------------
local M = {
    type = "Harvest"
  , categories = {
        ["Mining"]        = {
            ["IronNode"]        = { name= "Iron Node" }
          , ["TitaniumNode"]    = { name= "Titanium Node" }
          , ["ZephyriteNode"]   = { name= "Zephyrite Node" }
          , ["PlatinumNode"]    = { name= "Platinum Node" }
          , ["HydrogemNode"]    = { name= "Hydrogem Node" }
          , ["XenociteNode"]    = { name= "Xenocite Node" }
          , ["ShadeslateNode"]  = { name= "Shadeslate Node" }
          , ["GalactiumNode"]   = { name= "Galactium Node" }
          , ["NovaciteNode"]    = { name= "Novacite Node" }
        }
      , ["Relic Hunter"]  = {}
      , ["Farmer"]        = {}
      , ["Survivalist"]   = {}
    }
}
local super = Unit
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:new()
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
    super.init( self )
    Apollo.LoadSprites("harvest_sprites.xml")
end

--------------------------------------------------------------------------------
function M:type( unit )
    local category = unit:GetHarvestRequiredTradeskillName()
    category = self.categories[category];
    if not category then return end
    
    local category = unit:GetHarvestRequiredTradeskillName()
    category = self.categories[category];
    if not category then return end
    
    local type = unit:GetMiniMapMarker()
    return category[type];
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
M:new( Harvest )

return M
