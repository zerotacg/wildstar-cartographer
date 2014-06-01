local GameLib = require "GameLib"
local Apollo  = require "Apollo"
local LibStub = _G["LibStub"]

--------------------------------------------------------------------------------
local M = LibStub:NewLibrary( "cartographer/Collector-0", 0 )
if ( not M ) then return end

--------------------------------------------------------------------------------
function M:init()
    self.db = Apollo.GetAddon("Cartographer")
    self:createCategories();
end

--------------------------------------------------------------------------------
function M:createCategories()
    local db = self.db
    for id, types in pairs( self.categories ) do
        local category = db:create( id, { label = id } )
        for id, type in pairs( types ) do
            types[id] = category:create( id, type )
        end
    end
end

--------------------------------------------------------------------------------
function M:zone()
    local tZoneInfo = GameLib.GetCurrentZoneMap()
    if not tZoneInfo then return end
    
    return tZoneInfo.strName
end

--------------------------------------------------------------------------------
return M
