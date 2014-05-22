local Apollo    = require "Apollo"
local LibStub   = _G["LibStub"]
local Collector = LibStub:GetLibrary( "cartographer/Collector-0", 0 )

--------------------------------------------------------------------------------
local M = LibStub:NewLibrary( "cartographer/collector/Unit-0", 0 )
if ( not M ) then return end
local super = Collector
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:init()
    super.init( self )
    Apollo.RegisterEventHandler( "UnitCreated", "OnUnitCreated", self )
end

--------------------------------------------------------------------------------
function M:OnUnitCreated( unit )
    if self.unit_type ~= unit:GetType() then return end
    
    local type = self:type( unit )
    if not type then return end
    
    type:addNode( self:zone(), self:data( unit ) )
end

--------------------------------------------------------------------------------
function M:type( unit )
    return nil
end

--------------------------------------------------------------------------------
function M:data( unit )
    return {
        id = unit:GetId()
      , name = unit:GetName()
      , position = unit:GetPosition()
      , skill_name = unit:GetHarvestRequiredTradeskillName()
      , skill_tier = unit:GetHarvestRequiredTradeskillTier()
      , minimap_marker = unit:GetMiniMapMarkers()[1]
   }
end

--------------------------------------------------------------------------------
return M
