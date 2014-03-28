require "Apollo"
require "Vector3"

local LibStub = _G["LibStub"]
local LibVentilator = LibStub:GetLibrary( "LibVentilator-0", 3 )

--------------------------------------------------------------------------------
local M = {
    VERSION = { MAJOR = 0, MINOR = 0, PATCH = 0 }
  , MIN_NODE_DISTANCE = 1.0
  , enabled = {
        ["Collectible"]   = true
      , ["ALL"]           = true
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
    self.data = {}
    self.paths = {}

    local bHasConfigureFunction = false
    local strConfigureButtonText = "Cartographer"
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
    local subs = {
        MiniMap = MiniMap.wndMiniMap 
      , ZoneMap = ZoneMap.wndZoneMap
    }
    self.map = LibVentilator.new( subs )
   
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
      , data = self.data
    }
end 

--------------------------------------------------------------------------------
function M:OnRestore(eLevel, tData)
    if ( eLevel ~= GameLib.CodeEnumAddonSaveLevel.General ) then return end
    
    self.data = tData.data or self.data
    self.paths = tData.paths or self.paths

    for i, data in ipairs( self.data.Harvest.Mining.TitaniumNode ) do
        self:addMarker( data )
    end
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
    local type = unit:GetType()
    local category = self.categories[type] or self
    if category:accepts( unit ) then
        local path    = category:path( unit )
        local data    = M.apply( self:data( unit ), category:data( unit ) )
        local marker  = M.apply( self:marker( unit ), category:marker( unit ) )
        self:add( path, data, marker )
    end
end 

--------------------------------------------------------------------------------
function M:addCategory( category )
    self.categories[category:path()] = category
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
    local data = self.data
    path = table.concat( path, "/")
    data[path] = data[path] or {}
    return data[path]
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
    
    self:insert( entries, entry )
    if marker then
        self:addMarker( marker )
    end
end 

--------------------------------------------------------------------------------
function M:addMarker( marker )
    local kstrMiningNodeIcon  = "IconSprites:Icon_TradeskillMisc_Titanium_Ore"
    local kcrMiningNode       = CColor.new(0.2, 1.0, 1.0, 1.0)

    local objectType = self.eObjectTypeMiningNode
    local tMarkerOptions = { bNeverShowOnEdge = true, bAboveOverlay = false }

    self.map:AddObject( objectType, data.position, data.name, tInfo, tMarkerOptions )
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
end 

--------------------------------------------------------------------------------

--[[
function ZoneMap:DrawGroupMembers()
  self:DestroyGroupMarkers()

  local tInfo = {}
  for idx, tMember in pairs(self.tGroupMembers) do
    local tInfo = GroupLib.GetGroupMember(idx)
    if tInfo.bIsOnline then
      local bNeverShowOnEdge = true
      if tMember.bInCombatPvp then
        tInfo.strIconEdge = "sprMM_Group"
        tInfo.crObject    = CColor.new(0, 1, 0, 1)
        tInfo.crEdge    = CColor.new(0, 1, 0, 1)
        bNeverShowOnEdge = false
      else
        tInfo.strIconEdge = ""
        tInfo.crObject    = CColor.new(1, 1, 1, 1)
        tInfo.crEdge    = CColor.new(1, 1, 1, 1)
        bNeverShowOnEdge = true
      end

      local strNameFormatted = string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"ff31fcf6\">%s</T>", tMember.strName)
      strNameFormatted = String_GetWeaselString(Apollo.GetString("ZoneMap_AppendGroupMemberLabel"), strNameFormatted)
      self.tGroupMemberObjects[idx] = self.wndZoneMap:AddObject(1, tMember.tWorldLoc, strNameFormatted, tInfo, {bNeverShowOnEdge = bNeverShowOnEdge})
    end
  end
end

]]

--------------------------------------------------------------------------------
return M:new()
