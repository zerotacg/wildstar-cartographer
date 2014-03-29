require "string"
require "table"

require "Apollo"
require "GameLib"
require "Vector3"
require "XmlDoc"

local LibStub = _G["LibStub"]
local LibMarker = LibStub:GetLibrary( "LibMarker-0", 0 )
local LibSpatial = LibStub:GetLibrary( "LibSpatial-0", 0 )

--------------------------------------------------------------------------------
-- @type Gathermate
-- @field #wildstar.Window wndSettings
-- @field #wildstar.TreeControl wndDataTree
-- @field #table database
-- @field #table nodes
local M = {
    VERSION = { MAJOR = 0, MINOR = 0, PATCH = 0 }
  , MIN_NODE_DISTANCE = 1.0
  , Container = LibSpatial.kdtree:template( 3 )
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
    self.nodes = {}
    self.tSelectedNode = nil

    local bHasConfigureFunction = true
    local strConfigureButtonText = "Gathermate"
    local tDependencies = {
        "MiniMap"
      , "ZoneMap"
    }
    Apollo.RegisterAddon( self, bHasConfigureFunction, strConfigureButtonText, tDependencies )
end

--------------------------------------------------------------------------------
function M:clear( strPath )
    local database = self.database
    local nodes = self.nodes
    local wndTree = self.wndDataTree
    strPath = strPath or ""

    for i, path in ipairs( database ) do
        if string.sub( path, 1, string.len(strPath) ) == strPath then
            database[path] = nil
        end
    end

    for i, path in ipairs( nodes ) do
        if string.sub( path, 1, string.len(strPath) ) == strPath then
            wndTree:DeleteNode( nodes[path] )
            nodes[path] = nil
        end
    end
end

--------------------------------------------------------------------------------
function M:OnLoad()
    local MiniMap = Apollo.GetAddon("MiniMap")
    local ZoneMap = Apollo.GetAddon("ZoneMap")

    LibMarker:setMap( "MiniMap", MiniMap.wndMiniMap )
    LibMarker:setMap( "ZoneMap", ZoneMap.wndZoneMap )
    self.map = LibMarker
    self.objectType = self.map:CreateOverlayType()
   
    self.xmlDoc = XmlDoc.CreateFromFile("Gathermate.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)

    Apollo.LoadSprites("harvest_sprites.xml")
    --Apollo.RegisterSlashCommand("carto", "OnCommand", self)

    Apollo.RegisterEventHandler( "UnitCreated", "OnUnitCreated", self )
    --Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
    --Apollo.RegisterEventHandler("UnitActivationTypeChanged", "OnUnitChanged", self)
end

--------------------------------------------------------------------------------
function M:OnDocLoaded() 
    if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
        self.wndSettings = Apollo.LoadForm( self.xmlDoc, "SettingsWindow", nil, self )
        if self.wndSettings == nil then
            Apollo.AddAddonErrorText( self, "Could not load the settings window for some reason." )
            return
        end
        self.wndDataTree = self.wndSettings:FindChild( "DataTree" )
        if self.wndDataTree == nil then
            Apollo.AddAddonErrorText( self, "Could not load the settings window for some reason." )
            return
        end
      
        self.wndSettings:Show( false, true )
        self.xmlDoc = nil

        for path, entries in pairs( self.database ) do
            self:addPath( path )
        end
    end
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
    
    for path, database in pairs( tData.database ) do
        local entries = self:entries( path )
        entries:load( database )
    end
end 

--------------------------------------------------------------------------------
function M:OnConfigure()
    self.wndSettings:Show( true )
end 

--------------------------------------------------------------------------------
function M:OnCommand(strCommand, strParam)
end

--------------------------------------------------------------------------------
function M:OnOkClick()
    self.wndSettings:Show( false )
end

--------------------------------------------------------------------------------
function M:OnCancelClick()
    self.wndSettings:Show( false )
end

--------------------------------------------------------------------------------
function M:OnDataTreeSelectionChanged( wndHandler, wndTree, tNewNode, tOldNode )
    self.tSelectedNode = tNewNode
    self:updateButtonState()
end

--------------------------------------------------------------------------------
function M:updateButtonState()
    self.wndSettings:FindChild("DeleteButton"):Enable( self.tSelectedNode ~= nil )
end

--------------------------------------------------------------------------------
function M:OnDeleteClick()
    local tNode = self.tSelectedNode
    local wndTree = self.wndDataTree
    if tNode ~= nil then
        local tData = wndTree:GetNodeData( tNode )
        local strPath = tData.strPath
        self:clear( strPath )
        self.tSelectedNode = nil
    end
    self:updateButtonState()
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

--------------------------------------------------------------------------------
function M:addPath( strPath )
    local nodes = self.nodes
    local tCurrent = {}
    local wndTree = self.wndDataTree
    local tNode = 0
    
    if not wndTree then return end 

    for strFolder in string.gmatch( strPath, "([^/]+)" ) do
        table.insert( tCurrent, strFolder )
        local strPath = table.concat( tCurrent, "/")
        if not nodes[strPath] then
            local strIcon = nil
            local tData = { strPath = strPath }
            tNode = wndTree:AddNode( tNode, strFolder, strIcon, tData )
            nodes[strPath] = tNode
            wndTree:CollapseNode( tNode )
        end
        tNode = nodes[strPath]
    end
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
    self:addPath( path )
    database[path] = database[path] or self.Container:new()
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
    entries:insert( entry )
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
