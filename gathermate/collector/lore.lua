local LibStub = _G["LibStub"]
local Unit    = LibStub:GetLibrary( "Gathermate/Unit-0", 0 )

-------------------------------------------------------------------------------
local Simple = LibStub:NewLibrary( "Gathermate/Simple-0", 0 )
if ( not Simple ) then return end

-------------------------------------------------------------------------------
local M = {
    type = "Simple"
  , categories = {
        ["Lore"] = {
            ["DATACUBE"]  = { name= "Datacube", strIcon = "MiniMapMarkerTiny" }
          , ["TALES"]     = { name= "Tales"   , strIcon = "MiniMapMarkerTiny" }
        }
    }
}
local super = Unit
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:new()
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
M:new( Simple )

return M
