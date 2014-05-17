require "string"
require "table"

local Apollo      = require "Apollo"
local GameLib     = require "GameLib"
local XmlDoc      = require "XmlDoc"
local LibStub     = _G["LibStub"]
local LibMarker   = LibStub:GetLibrary( "LibMarker-0", 0 )
local LibSpatial  = LibStub:GetLibrary( "LibSpatial-0", 0 )
local ANode       = LibStub:GetLibrary( "gathermate/ANode-0", 0 )
local Category    = LibStub:GetLibrary( "gathermate/Category-0", 0 )
local Constants   = LibStub:GetLibrary( "gathermate/Constants-0", 0 )
local Harvest     = LibStub:GetLibrary( "gathermate/collector/Harvest-0", 0 )
local Lore        = LibStub:GetLibrary( "gathermate/collector/Lore-0", 0 )
local Npc         = LibStub:GetLibrary( "gathermate/collector/Npc-0", 0 )

--------------------------------------------------------------------------------
-- @type Gathermate
-- @field #wildstar.Window wndSettings
-- @field #wildstar.TreeControl wndDataTree
-- @field #wildstar.Handle tSelectedNode
local M = {
    loaded = false
  , map = LibMarker
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
    self.current = self.Container:new()
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
function M:OnLoad()
    self.xmlDoc = XmlDoc.CreateFromFile("Gathermate.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
    
    Harvest:new()
    Lore:new()
    Npc:new()

    --Apollo.RegisterSlashCommand("carto", "OnCommand", self)

    Apollo.RegisterEventHandler( "VarChange_ZoneName", "OnZoneChange", self )
    Apollo.RegisterEventHandler( "SubZoneChanged"    , "OnZoneChange", self )
    --Event_FireGenericEvent("GenericEvent_ZoneMap_ZoneChanged", idCurrentZone)

    Apollo.RegisterTimerHandler( "UpdatePositionTimer", "OnUpdatePosition", self)
    
    Apollo.CreateTimer( "UpdatePositionTimer", 0.5, true )
    Apollo.StopTimer( "UpdatePositionTimer" )

    Apollo.RegisterTimerHandler( "MapsLoadedTimer", "OnMapsLoaded", self)
    
    Apollo.CreateTimer( "MapsLoadedTimer", 1.0, true )
    --Apollo.StartTimer( "MapsLoadedTimer" )
end

--------------------------------------------------------------------------------
function M:OnDocLoaded() 
    if not self.xmlDoc or not self.xmlDoc:IsLoaded() then return end

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
    self:OnZoneChange()
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
function M:OnMapsLoaded()
    local MiniMap = Apollo.GetAddon("MiniMap")
    local ZoneMap = Apollo.GetAddon("ZoneMap")
    
    if not MiniMap.wndMiniMap then return; end
    if not ZoneMap.wndZoneMap then return; end
    Apollo.StopTimer( "MapsLoadedTimer" )

    LibMarker:setMap( "MiniMap", MiniMap.wndMiniMap )
    LibMarker:setMap( "ZoneMap", ZoneMap.wndZoneMap )
    self.objectType = self.map:CreateOverlayType()
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

    for id, category in pairs( self.children ) do
        local strName = category.name
        local strIcon = category.strIcon
        local tData = category
        local tNode = wndTree:AddNode( 0, strName, strIcon, tData )
        local tParentNode = tNode
        wndTree:CollapseNode( tNode )
        for id, type in pairs( category.children ) do
            local strName = type.name
            local strIcon = type.strIcon
            local tData = type
            tNode = wndTree:AddNode( tParentNode, strName, strIcon, tData )
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
function M:OnZoneChange()
    for i, entry in ipairs( self.current.data ) do
        self.map:RemoveObject( entry.marker )
    end
    
    local zone = self:zone() 
    local show = {}
    for i, node in ipairs( self:getNodes( zone ) ) do
        table.insert( show, self:addMarker( node ) )
    end
    self.current:load( show )
end 

--------------------------------------------------------------------------------
function M:OnUpdatePosition()
    local unit = GameLib.GetPlayerUnit()
    if not unit then return end
    
    self:OnZoneChange()
end

--------------------------------------------------------------------------------
function M:zone()
    local tZoneInfo = GameLib.GetCurrentZoneMap()
    if not tZoneInfo then return end
    
    return tZoneInfo.strName
end

--------------------------------------------------------------------------------
function M:addMarker( node )
    local objectType = self.objectType
    local tMarkerOptions = { bNeverShowOnEdge = true, bAboveOverlay = false }
    local entry = {
        node = node
      , position = node.position
      , marker = self.map:AddObject( objectType, node.position, node.name, node.tInfo, tMarkerOptions )
    }

    return entry
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
