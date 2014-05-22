local LibStub = _G["LibStub"]
local ANode = LibStub:GetLibrary( "cartographer/ANode-0", 0 )
local Type  = LibStub:GetLibrary( "cartographer/Type-0", 0 )
local M = LibStub:NewLibrary( "cartographer/Category-0", 0 )
if ( not M ) then return end

setmetatable( M, { __index = ANode } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o.Type = Type
    o:init()

    return o
end

--------------------------------------------------------------------------------
return M
