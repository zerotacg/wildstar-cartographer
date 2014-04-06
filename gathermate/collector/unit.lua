local Apollo    = require "Apollo"
local GameLib   = require "GameLib"
local LibStub   = _G["LibStub"]
local Collector = LibStub:GetLibrary( "Gathermate/Collector-0", 0 )

--------------------------------------------------------------------------------
local M = LibStub:NewLibrary( "Gathermate/Unit-0", 0 )
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
    if self.type ~= unit:GetType() then return end
    
    local type = self:type( unit )
    if not type then return end
    
    local tZoneInfo = GameLib.GetCurrentZoneMap()
    if not tZoneInfo then return end
    
    type:addNode( tZoneInfo.strName, self:data( unit ) )
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
      , minimap_marker = unit:GetMiniMapMarker()
   }
end

--------------------------------------------------------------------------------
return M
