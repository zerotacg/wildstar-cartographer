local LibStub   = _G["LibStub"]
local Constants = LibStub:GetLibrary( "Gathermate/Constants-0", 0 )

--------------------------------------------------------------------------------
local Zone = LibStub:NewLibrary( "Gathermate/Zone-0", 0 )
if ( not Zone ) then return end

--------------------------------------------------------------------------------
local M = {
}
setmetatable( Zone, { __index = M } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
    self.nodes = Constants.Container:new()
end

--------------------------------------------------------------------------------
function M:load( data )
    self.nodes:load( data )
end

--------------------------------------------------------------------------------
function M:save()
    return self.nodes.data
end

--------------------------------------------------------------------------------
function M:add( node )
    local nodes = self.nodes
    local nearest, distance = nodes:nearest( node )
    
    if distance < Constants.MIN_NODE_DISTANCE_SQUARED then
        nodes:insert( node )
    end
end

--------------------------------------------------------------------------------
return M
