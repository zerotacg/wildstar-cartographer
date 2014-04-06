local Apollo  = require "Apollo"
local LibStub = _G["LibStub"]

--------------------------------------------------------------------------------
local M = LibStub:NewLibrary( "Gathermate/Collector-0", 0 )
if ( not M ) then return end

--------------------------------------------------------------------------------
function M:init()
    self.db = Apollo.GetAddon("Gathermate")
    self:createCategories();

    Apollo.RegisterEventHandler( "UnitCreated", "OnUnitCreated", self )
end

--------------------------------------------------------------------------------
function M:createCategories()
    local db = self.db
    for id, types in pairs( self.categories ) do
        local category = db:create( id, { name = id } )
        for id, type in pairs( types ) do
            types[id] = category:create( id, type )
        end
    end
end

--------------------------------------------------------------------------------
function M:save()
    local data = {}
    for id, type in pairs( self.types ) do
        data[id] = type:save();
    end

    return data
end

--------------------------------------------------------------------------------
return M
