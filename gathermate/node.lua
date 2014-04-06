local LibStub = _G["LibStub"]
local M = LibStub:NewLibrary( "Gathermate/Node-0", 0 )
if ( not M ) then return end

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
return M
