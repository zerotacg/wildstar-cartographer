require "string"
require "table"

local Apollo      = require "Apollo"
local GameLib     = require "GameLib"
local XmlDoc      = require "XmlDoc"
local LibStub     = _G["LibStub"]
local LibMarker   = LibStub:GetLibrary( "LibMarker-0", 0 )
local LibSpatial  = LibStub:GetLibrary( "LibSpatial-0", 0 )
local ANode       = LibStub:GetLibrary( "Gathermate/ANode-0", 0 )
local Category    = LibStub:GetLibrary( "Gathermate/Category-0", 0 )
local Constants   = LibStub:GetLibrary( "Gathermate/Constants-0", 0 )

--------------------------------------------------------------------------------
-- @type Gathermate
-- @field #wildstar.Window wndSettings
-- @field #wildstar.TreeControl wndDataTree
-- @field #table database
-- @field #table enabled
-- @field #wildstar.Handle tSelectedNode
local M = {
    loaded = false
  , Container = Constants.Container
  , Type = Category
} 
local super = ANode
setmetatable( M, { __index = super } )

--------------------------------------------------------------------------------
function M:new( o )
    o = o or {}
    setmetatable( o, { __index = self } )
    o:init()

    return o
end

--------------------------------------------------------------------------------
function M:init()
    super.init( self )
    self.current = {}
    self.enabled = {}
    self.tSelectedNode = nil
    self.default_category = self:createCategory( "Other", { name = "Other" })

    local bHasConfigureFunction = true
    local strConfigureButtonText = "Gathermate"
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

    LibMarker:setMap( "MiniMap", MiniMap.wndMiniMap )
    LibMarker:setMap( "ZoneMap", ZoneMap.wndZoneMap )
    self.map = LibMarker
    self.objectType = self.map:CreateOverlayType()
   
    self.xmlDoc = XmlDoc.CreateFromFile("Gathermate.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)

    --Apollo.RegisterSlashCommand("carto", "OnCommand", self)

    Apollo.RegisterTimerHandler( "UpdatePositionTimer", "OnUpdatePosition", self)
    
    Apollo.CreateTimer( "UpdatePositionTimer", 0.5, true )
    Apollo.StopTimer( "UpdatePositionTimer" )
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
        Apollo.StartTimer( "UpdatePositionTimer" )
    end
end

--------------------------------------------------------------------------------
function M:OnSave(eLevel) 
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end 
    
    return {
        VERSION = self.VERSION
      , database = self:save()
    }
end 

--------------------------------------------------------------------------------
function M:OnRestore(eLevel, tData)
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end
    
    self:load( tData.database )
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
    local wndTree = self.wndDataTree

    if not wndTree then return end 
    wndTree:DeleteAll()

    for id, category in pairs( self.database ) do
        local strName = category.name
        local strIcon = category.icon
        local tData = category
        local tNode = wndTree:AddNode( 0, strName, strIcon, tData )
        wndTree:CollapseNode( tNode )
        for id, type in pairs( category.children ) do
            local strName = type.name
            local strIcon = type.icon
            local tData = type
            tNode = wndTree:AddNode( tNode, strName, strIcon, tData )
            wndTree:CollapseNode( tNode )
        end
    end
end

--------------------------------------------------------------------------------
function M:OnDeleteClick()
    local tNode = self.tSelectedNode
    local wndTree = self.wndDataTree
    if tNode ~= nil then
        local tData = wndTree:GetNodeData( tNode )
        tData:clear()
        self.tSelectedNode = nil
    end
    self:updateButtonState()
end

--------------------------------------------------------------------------------
function M:OnUpdatePosition()
    local unit = GameLib.GetPlayerUnit()
    if not unit then return end
    
    for i, entry in ipairs( self.current ) do
        self.map:RemoveObject( entry )
    end
    
    -- GetCurrentZoneIndex

    local data = self:data( unit )
    local show = {}
    for k, entries in pairs( self.database ) do
        for i, entry in ipairs( entries:containedSphere( data, self.MAX_MARKER_DISTANCE) ) do
            table.insert( show, self:addMarker( entry ) )
        end
    end
    
    self.current = show
end 

-------------------------------------------------------------------------------
function M:accepts( unit )
    local tZoneInfo = GameLib.GetCurrentZoneMap()
    if not tZoneInfo then return false end

    if true then return true end

    local path = self:path( unit )
    local enabled = self.enabled[path]
    if enabled ~= nil then return enabled end 
    
    return self.enabled.ALL
end

-------------------------------------------------------------------------------
function M:namePrefix( strName )
    local prefixes = {
        "TALES"
      , "DATACUBE"
    }
    
    for i, prefix in ipairs( prefixes ) do
        if string.sub( strName, 1, string.len( prefix ) ) == prefix then
            return prefix
        end
    end
    return nil
end

-------------------------------------------------------------------------------
function M:type( unit )
    return unit:GetHarvestRequiredTradeskillName() or unit:GetType()
end

-------------------------------------------------------------------------------
function M:subtype( unit )
    return self:namePrefix( unit:GetName() ) or unit:GetMiniMapMarker() or unit:GetName() or ""
end

-------------------------------------------------------------------------------
function M:path( unit )
    local tZoneInfo = GameLib.GetCurrentZoneMap()
    local path      = {}
    local folders   = {
        self:type( unit )
      , self:subtype( unit )
      , tZoneInfo.strName or ""-- id
    }
    for i, folder in ipairs( folders) do
        if folder ~= "" then
            table.insert( path, folder )
        end
    end
    return path
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
end 

--------------------------------------------------------------------------------
function M:addMarker( data )
    local objectType = self.objectType
    local tMarkerOptions = { bNeverShowOnEdge = true, bAboveOverlay = false }
    local marker = self:marker( data )

    return self.map:AddObject( objectType, data.position, data.name, marker, tMarkerOptions )
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
