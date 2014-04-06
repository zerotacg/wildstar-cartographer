local LibStub     = _G["LibStub"]
local LibSpatial  = LibStub:GetLibrary( "LibSpatial-0", 0 )

--------------------------------------------------------------------------------
local Constants = LibStub:NewLibrary( "Gathermate/Constants-0", 0 )
if ( not Constants ) then return end

--------------------------------------------------------------------------------
local function axis( self, axis )
    self = self.position or self
    if axis == 1 then
        return self.x
    end
    if axis == 2 then
        return self.z
    end
end 

--------------------------------------------------------------------------------
local M = {
    VERSION = { MAJOR = 0, MINOR = 0, PATCH = 0 }
  , MIN_NODE_DISTANCE = 1.0
  , MAX_MARKER_DISTANCE = 4096.0
  , MIN_MARKER_DISTANCE = 128.0
  , Container = LibSpatial.kdtree:template( 2, axis )
}
M.MIN_NODE_DISTANCE_SQUARED = M.MIN_NODE_DISTANCE * M.MIN_NODE_DISTANCE
setmetatable( Constants, { __index = M } )

--------------------------------------------------------------------------------
return M
