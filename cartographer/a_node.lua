local GameLib = require "GameLib"
local LibStub = _G["LibStub"]

--------------------------------------------------------------------------------
local ANode = LibStub:NewLibrary( "cartographer/ANode-0", 0 )
if ( not ANode ) then return end

--------------------------------------------------------------------------------
local M = {
    enabled = true
}
setmetatable( ANode, { __index = M } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
    self.children = {}
end

--------------------------------------------------------------------------------
function M:clear()
    for id, child in pairs( self.children ) do
        child:clear()
    end
end

--------------------------------------------------------------------------------
function M:create( id, data )
    local instance = self.children[id] or self.Type:new( data )
    self.children[id] = instance
    return instance
end

--------------------------------------------------------------------------------
function M:getNodes( ... )
    local nodes = {}
    for id, child in pairs( self.children ) do
        if child.enabled then
            for i, node in ipairs( child:getNodes( ... ) ) do
                table.insert( nodes, node )
            end
        end
    end
    
    return nodes
end

--------------------------------------------------------------------------------
function M:OnRestore( eLevel, tData )
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end
    if ( not tData ) then return end
    
    for id, child in pairs( self.children ) do
        child:OnRestore( eLevel, tData[id] )
    end
end

--------------------------------------------------------------------------------
function M:OnSave( eLevel )
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end

    local data = {}
    for id, child in pairs( self.children ) do
        data[id] = child:OnSave( eLevel )
    end

    return data
end

--------------------------------------------------------------------------------
return M
