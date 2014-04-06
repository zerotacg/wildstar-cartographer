local LibStub = _G["LibStub"]
local ANode = LibStub:GetLibrary( "Gathermate/ANode-0", 0 )
local Node  = LibStub:GetLibrary( "Gathermate/Node-0", 0 )
local Zone  = LibStub:GetLibrary( "Gathermate/Zone-0", 0 )

--------------------------------------------------------------------------------
local Type = LibStub:NewLibrary( "Gathermate/Type-0", 0 )
if ( not Type ) then return end

--------------------------------------------------------------------------------
local M = {
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
    zone:add( Node:new( data ) )
end

-------------------------------------------------------------------------------
return M
