--------------------------------------------------------------------------------
local LibStub = _G["LibStub"]
local M = LibStub:NewLibrary( "LibVentilator-0", 0 )
if ( not M ) then return end

local function index( table, name )
    local v = rawget( table, name )
    if v ~= nil then
        return v
    end
  
    return function(self, ... )
        local subs = self.subs
        local result = {}

        for k, sub in pairs( subs ) do
          result[k] = sub[name](sub, ...)
        end

        return result
    end
end 
setmetatable( M, { __index = index } )

--------------------------------------------------------------------------------
function M:new( subs )
    local o = { subs = subs or {} }
    setmetatable( o, { __index = self } )

    return o
end

--------------------------------------------------------------------------------
return M
