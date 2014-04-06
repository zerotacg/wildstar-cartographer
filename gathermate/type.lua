local GameLib = require "GameLib"
local LibStub = _G["LibStub"]
local ANode   = LibStub:GetLibrary( "gathermate/ANode-0", 0 )
local Zone    = LibStub:GetLibrary( "gathermate/Zone-0", 0 )

--------------------------------------------------------------------------------
local Type = LibStub:NewLibrary( "gathermate/Type-0", 0 )
if ( not Type ) then return end

--------------------------------------------------------------------------------
local M = {
    strIcon = "MiniMapMarkerTiny"
  , strIconEdge   = ""
  , crObject      = CColor.new(1, 1, 1, 1)
  , crEdge        = CColor.new(1, 1, 1, 1)
  , bAboveOverlay = false
}
setmetatable( Type, { __index = M } )
setmetatable( M, { __index = ANode } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o.Type = Zone
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:addNode( strZone, data )
    local zone = self:create( strZone )
    zone:add( data )
end

--------------------------------------------------------------------------------
function M:getNodes( strZone )
    local nodes = {}
    if strZone then
        local zone = self:create( strZone )
        for i, node in ipairs( zone.nodes.data ) do
            table.insert( nodes, { type = self, position = node.position } )
        end
    end
    return nodes
end

-------------------------------------------------------------------------------
function M:marker( data )
    local tInfo =
    {   strIcon       = self.strIcon
      , strIconEdge   = self.strIconEdge
      , crObject      = self.crObject
      , crEdge        = self.crEdge
      , bAboveOverlay = self.bAboveOverlay
    }
    return tInfo
end

--------------------------------------------------------------------------------
function M:OnRestore( eLevel, tData )
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end
    if ( not tData ) then return end
    
    for id, data in pairs( tData ) do
        local zone = self:create( id )
        zone:OnRestore( eLevel, data )
    end
end

-------------------------------------------------------------------------------
return M
