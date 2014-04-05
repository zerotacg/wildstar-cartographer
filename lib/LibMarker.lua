--------------------------------------------------------------------------------
local LibStub     = _G["LibStub"]
local LibSpatial  = LibStub:GetLibrary( "LibSpatial-0", 0 )
local LibMarker   = LibStub:NewLibrary( "LibMarker-0", 0 )
if ( not LibMarker ) then return end

--------------------------------------------------------------------------------
local M = {}

--------------------------------------------------------------------------------
local function index( table, name )
    local v = rawget( table, name )
    if v ~= nil then
        return v
    end
  
    return function( self, ... )
        local maps = self.maps
        local result = {}
    
        for k, map in pairs( maps ) do
            result[k] = map[name](map, ...)
        end
    
        return result
    end
end 
setmetatable( M, { __index = index } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o.maps = {}

    return o
end

--------------------------------------------------------------------------------
function M:setMap( name, wndMap, force )
    self.maps[name] = (not force and self.maps[name]) or wndMap
end

--------------------------------------------------------------------------------
function M:AddObject( objectType, ... )
    local tObjectType = objectType
    if type( tObjectType ) ~= "table" then
        tObjectType = {}
        for k, map in pairs( self.maps ) do
            tObjectType[k] = objectType
        end
    end
    local result = {}
    for k, map in pairs( self.maps ) do
        result[k] = map:AddObject( tObjectType[k], ... )
    end
    return result
end

--------------------------------------------------------------------------------
function M:RemoveObject( id, ... )
    local result = {}
    for k, map in pairs( self.maps ) do
        result[k] = map:RemoveObject( id[k], ... )
    end
    return result
end

--------------------------------------------------------------------------------
function M:GetZoneInfo( ... )
    local map = self.maps.ZoneMap
    return map and map:GetZoneInfo( ... )
end

--------------------------------------------------------------------------------
M:new( LibMarker )

--------------------------------------------------------------------------------
return M
