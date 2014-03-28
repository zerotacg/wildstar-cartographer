require "Apollo"
require "Vector3"

local LibStub = _G["LibStub"]
local LibVentilator = LibStub:GetLibrary( "LibVentilator-0", 0 )
local LibSpatial    = LibStub:GetLibrary( "LibSpatial-0", 0 )

--------------------------------------------------------------------------------
local M = {
    VERSION = { MAJOR = 0, MINOR = 0, PATCH = 0 }
  , MIN_NODE_DISTANCE = 1.0
  , enabled = {
        ["Collectible"] = false
      , ["ALL"]         = false
    }
} 

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
    self.categories = {}
    self.database = {}

    local bHasConfigureFunction = false
    local strConfigureButtonText = "Gathermate"
    local tDependencies = {
        "MiniMap"
      , "ZoneMap"
    }
    Apollo.RegisterAddon( self, bHasConfigureFunction, strConfigureButtonText, tDependencies )
end

--------------------------------------------------------------------------------
function M:clear()
    self.database = {}
end

--------------------------------------------------------------------------------
function M:OnLoad()
    local MiniMap = Apollo.GetAddon("MiniMap")
    local ZoneMap = Apollo.GetAddon("ZoneMap")
    local subs = {
        MiniMap = MiniMap.wndMiniMap 
      , ZoneMap = ZoneMap.wndZoneMap
    }

    self.map = LibVentilator:new( subs )
    self.objectType = self.map:CreateOverlayType()
   
    Apollo.LoadSprites("harvest_sprites.xml")

    --Apollo.RegisterSlashCommand("carto", "OnCommand", self)

    Apollo.RegisterEventHandler( "UnitCreated", "OnUnitCreated", self )
    --Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
    --Apollo.RegisterEventHandler("UnitActivationTypeChanged", "OnUnitChanged", self)
end

--------------------------------------------------------------------------------
function M:OnSave(eLevel) 
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end 
    
    return {
        VERSION = self.VERSION
      , database = self.database
    }
end 

--------------------------------------------------------------------------------
function M:OnRestore(eLevel, tData)
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end
    
    self.database = tData.database or self.database

    --for i, data in ipairs( self.database.Harvest.Mining.TitaniumNode ) do
    --    self:addMarker( data )
    --end
    --self:loadPaths()
end 

--------------------------------------------------------------------------------
function M:OnConfigure()
end 

--------------------------------------------------------------------------------
function M:OnCommand(strCommand, strParam)
end

--------------------------------------------------------------------------------
function M:OnUnitCreated( unit )
    for i, category in ipairs( self.categories ) do
        if category:accepts( unit ) then
            local path    = category:path( unit )
            local data    = M.apply( self:data( unit ), category:data( unit ) )
            local marker  = M.apply( self:marker( unit ), category:marker( unit ) )
            return self:add( path, data, marker )
        end
    end
    
    local category = self
    if category:accepts( unit ) then
        local path    = category:path( unit )
        local data    = M.apply( self:data( unit ), category:data( unit ) )
        local marker  = M.apply( self:marker( unit ), category:marker( unit ) )
        return self:add( path, data, marker )
    end
end 

--------------------------------------------------------------------------------
function M:addCategory( category )
    table.insert( self.categories, category )
end

-------------------------------------------------------------------------------
function M:accepts( unit )
    local type = unit:GetType()
    local enabled = self.enabled[type]
    if enabled ~= nil then return enabled end 

    return self.enabled.ALL
end

-------------------------------------------------------------------------------
function M:path( unit )
    return { unit:GetType() }
end

-------------------------------------------------------------------------------
function M:data( unit )
    return {
        id = unit:GetId()
      , name = unit:GetName()
      , position = unit:GetPosition()
   }
end

--------------------------------------------------------------------------------
function M:entries( path )
    local database = self.database
    path = table.concat( path, "/")
    database[path] = database[path] or {}
    return database[path]
end 

--------------------------------------------------------------------------------
function M:marker()
    local tInfo =
    {   strIcon       = "MiniMapMarkerTiny"
      , strIconEdge   = ""
      , crObject      = CColor.new(1, 1, 1, 1)
      , crEdge        = CColor.new(1, 1, 1, 1)
      , bAboveOverlay = false
    }
    return tInfo
end

--------------------------------------------------------------------------------
function M:add( path, data, marker )
    local entries = self:entries( path )
    
    if self:contains( entries, data ) then return end
    
    self:insert( entries, data )
    if marker then
        self:addMarker( data, marker )
    end
end 

--------------------------------------------------------------------------------
function M:addMarker( data, marker )
    local objectType = 1
    local tMarkerOptions = { bNeverShowOnEdge = true, bAboveOverlay = false }

    self.map:AddObject( objectType, data.position, data.name, marker, tMarkerOptions )
end 

--------------------------------------------------------------------------------
function M:contains( entries, entry )
    for i, other in ipairs( entries ) do
        local pos = Vector3.New( entry.position )
        local dist = pos - Vector3.New( other.position )
        dist = dist:Length()

        if dist < self.MIN_NODE_DISTANCE then
            return true
        end
    end 
    return false
end 

-------------------------------------------------------------------------------
function M:insert( entries, entry )
    table.insert( entries, entry )
end 

--------------------------------------------------------------------------------
function M.apply( tDestination, tSource )
    for k,v in pairs( tSource ) do
        tDestination[k] = tSource[k]
    end
    return tDestination
end 

--------------------------------------------------------------------------------
return M:new()
