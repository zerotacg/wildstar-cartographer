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
local function axisPositionXYZ( self, ...)
    return LibSpatial.axisXYZ( self.position, ... )
end 

--------------------------------------------------------------------------------
-- @type Gathermate
-- @field #wildstar.Window wndSettings
-- @field #wildstar.TreeControl wndDataTree
-- @field #table database
-- @field #table nodes
local M = {
    VERSION = { MAJOR = 0, MINOR = 0, PATCH = 0 }
  , MIN_NODE_DISTANCE = 1.0
  , Container = LibSpatial.kdtree:template( 3, axisPositionXYZ )
  , enabled = {
        ["Collectible"]           = false
      , ["Harvest/Mining"]        = true
      , ["Harvest/Relic Hunter"]  = true
      , ["Harvest/Farmer"]        = true
      , ["Harvest/Survivalist"]   = true
      , ["Harvest"]               = true
      , ["All"]                   = false
    }
} 
M.MIN_NODE_DISTANCE_SQUARED = M.MIN_NODE_DISTANCE * M.MIN_NODE_DISTANCE

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
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
function M:subPath( fullPath, subPath )
    local folder = subPath .. "/"
    return fullPath == subPath or string.sub( fullPath, 1, string.len( folder ) ) == folder
end

--------------------------------------------------------------------------------
function M:clear( strPath )
    local database = self.database
    strPath = strPath or ""

    for path in pairs( database ) do
        if self:subPath( path, strPath ) then
            database[path] = nil
        end
    end
    
    local nodes = self.nodes
    local wndTree = self.wndDataTree
    if strPath == "" then
        nodes = {}
        wndTree:DeleteAll()
        return
    end
    
    local tNode, parent, folder
    for strFolder in string.gmatch( strPath, "([^/]+)" ) do
        parent = nodes
        folder = strFolder
        if not nodes[strFolder] then
            return
        end
        tNode = nodes[strFolder].tNode
        nodes = nodes[strFolder].children
    end
    
    wndTree:DeleteNode( tNode )
    parent[folder] = nil
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
        
        self:buildTree()
    end
end

--------------------------------------------------------------------------------
function M:OnSave(eLevel) 
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end 
    
    local database = {}
    for path, entries in pairs( self.database ) do
        database[path] = entries.data
    end
    
    return {
        VERSION = self.VERSION
      , database = database
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
function M:buildTree()
    self.nodes = {}
    self.wndDataTree:DeleteAll()
    for path, entries in pairs( self.database ) do
        self:addPath( path )
    end
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
    if self:accepts( unit ) then
        local path    = table.concat( self:path( unit ), "/" )
        local data    = self:data( unit )
        return self:add( path, data )
    end
end 

--------------------------------------------------------------------------------
function M:addPath( strPath )
    local nodes = self.nodes
    local wndTree = self.wndDataTree
    local current = {}
    local tNode = 0
    
    if not wndTree then return end 

    for strFolder in string.gmatch( strPath, "([^/]+)" ) do
        table.insert( current, strFolder )
        if not nodes[strFolder] then
            local strIcon = nil
            local tData = { strPath = table.concat( current, "/" ) }
            tNode = wndTree:AddNode( tNode, strFolder, strIcon, tData )
            nodes[strFolder] = { tNode = tNode, children = {} }
            wndTree:CollapseNode( tNode )
        end
        tNode = nodes[strFolder].tNode
        nodes = nodes[strFolder].children
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
    local path    = { unit:GetType() }
    local folders = {
        unit:GetHarvestRequiredTradeskillName()
      , unit:GetName()
    }
    for i, folder in ipairs( folders) do
        if folder then
            table.insert( path, folder )
        end
    end
    return path
end

-------------------------------------------------------------------------------
function M:data( unit )
    return {
        id = unit:GetId()
      , name = unit:GetName()
      , position = unit:GetPosition()
      , skill_name = unit:GetHarvestRequiredTradeskillName()
      , skill_tier = unit:GetHarvestRequiredTradeskillTier()
      , minimap_marker = unit:GetMiniMapMarker()
   }
end

--------------------------------------------------------------------------------
function M:entries( path )
    local database = self.database
    self:addPath( path )
    database[path] = database[path] or self.Container:new()
    return database[path]
end 

--------------------------------------------------------------------------------
function M:marker( data )
    local tInfo =
    {   strIcon       = data.minimap_marker or "MiniMapMarkerTiny"
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
    self:addMarker( data )
end 

--------------------------------------------------------------------------------
function M:addMarker( data )
    local objectType = self.objectType
    local tMarkerOptions = { bNeverShowOnEdge = true, bAboveOverlay = false }
    local marker = self:marker( data )

    self.map:AddObject( objectType, data.position, data.name, marker, tMarkerOptions )
end 

--------------------------------------------------------------------------------
function M:contains( entries, entry )
    local nearest, distance = entries:nearest( entry )
    
    return nearest and distance < self.MIN_NODE_DISTANCE_SQUARED
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
