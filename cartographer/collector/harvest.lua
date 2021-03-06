local Apollo  = require "Apollo"
local LibStub = _G["LibStub"]
local Unit    = LibStub:GetLibrary( "cartographer/collector/Unit-0", 0 )

-------------------------------------------------------------------------------
local Harvest = LibStub:NewLibrary( "cartographer/collector/Harvest-0", 0 )
if ( not Harvest ) then return end

-------------------------------------------------------------------------------
local M = {
    unit_type = "Harvest"
  , categories = {
        ["Mining"]        = {
            ["IronNode"]        = { label = "Iron Node"       , strIcon = "harvest_sprites:IronNode" }
          , ["TitaniumNode"]    = { label = "Titanium Node"   , strIcon = "harvest_sprites:TitaniumNode" }
          , ["ZephyriteNode"]   = { label = "Zephyrite Node"  , strIcon = "harvest_sprites:ZephyriteNode" }
          , ["PlatinumNode"]    = { label = "Platinum Node"   , strIcon = "harvest_sprites:PlatinumNode" }
          , ["HydrogemNode"]    = { label = "Hydrogem Node"   , strIcon = "harvest_sprites:HydrogemNode" }
          , ["XenociteNode"]    = { label = "Xenocite Node"   , strIcon = "harvest_sprites:XenociteNode" }
          , ["ShadeslateNode"]  = { label = "Shadeslate Node" , strIcon = "harvest_sprites:ShadeslateNode" }
          , ["GalactiumNode"]   = { label = "Galactium Node"  , strIcon = "harvest_sprites:GalactiumNode" }
          , ["NovaciteNode"]    = { label = "Novacite Node"   , strIcon = "harvest_sprites:NovaciteNode" }
        }
      , ["Relic Hunter"]  = {}
      , ["Farmer"]        = {}
      , ["Survivalist"]   = {}
    }
}
local super = Unit
setmetatable( Harvest, { __index = M } )
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:new( o )
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
