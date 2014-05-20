local GameLib   = require "GameLib"
local LibStub   = _G["LibStub"]
local Constants = LibStub:GetLibrary( "gathermate/Constants-0", 0 )

--------------------------------------------------------------------------------
local Zone = LibStub:NewLibrary( "gathermate/Zone-0", 0 )
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
function M:OnRestore( eLevel, tData )
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end
    
    self.nodes:load( tData )
end

--------------------------------------------------------------------------------
function M:OnSave( eLevel )
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end

    return self.nodes.data
end

--------------------------------------------------------------------------------
function M:add( node )
    local nodes = self.nodes
    local nearest, distance = nodes:nearest( node )
    
    if nearest and distance < Constants.MIN_NODE_DISTANCE_SQUARED then
        return
    end
    nodes:insert( node )
end

--------------------------------------------------------------------------------
return M
