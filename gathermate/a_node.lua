local LibStub = _G["LibStub"]
local M = LibStub:NewLibrary( "Gathermate/ANode-0", 0 )
if ( not M ) then return end

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
    self:clear()
end

--------------------------------------------------------------------------------
function M:clear()
    for id, child in pairs( self.children ) do
        child:clear()
    end
end

--------------------------------------------------------------------------------
function M:create( id, data )
    local instance = self.types[id] or self.Type:new( data )
    self.children[id] = instance
    return instance
end

--------------------------------------------------------------------------------
function M:load( data )
    if not data then return end
    
    for id, child in pairs( self.children ) do
        child:load( data[id] )
    end
end

--------------------------------------------------------------------------------
function M:save()
    local data = {}
    
    for id, child in pairs( self.children ) do
        data[id] = child:save()
    end

    return data
end

--------------------------------------------------------------------------------
return M
