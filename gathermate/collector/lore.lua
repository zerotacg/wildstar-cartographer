local LibStub = _G["LibStub"]
local Unit    = LibStub:GetLibrary( "gathermate/collector/Unit-0", 0 )

-------------------------------------------------------------------------------
local Lore = LibStub:NewLibrary( "gathermate/collector/Lore-0", 0 )
if ( not Lore ) then return end

-------------------------------------------------------------------------------
local M = {
    unit_type = "Simple"
  , categories = {
        ["Lore"] = {
            ["DATACUBE"]  = { name= "Datacube" }
          , ["TALES"]     = { name= "Tales"    }
        }
    }
}
local super = Unit
setmetatable( Lore, { __index = M } )
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:type( unit )
    local category = self.categories.Lore
    local strName = unit:GetName()
    
    for prefix, type in pairs( category ) do
        if string.sub( strName, 1, string.len( prefix ) ) == prefix then
            return type
        end
    end
end 

-------------------------------------------------------------------------------
return M
