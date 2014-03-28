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
function M:init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = {
        "MiniMap"
      , "ZoneMap"
    }
    Apollo.RegisterAddon( self, bHasConfigureFunction, strConfigureButtonText, tDependencies )
end

--------------------------------------------------------------------------------
function M:OnLoad()
    local MiniMap = Apollo.GetAddon("MiniMap")
    local ZoneMap = Apollo.GetAddon("ZoneMap")
    self.subs = {
        MiniMap = MiniMap.wndMiniMap 
      , ZoneMap = ZoneMap.wndZoneMap
    }
end

--------------------------------------------------------------------------------
return M
