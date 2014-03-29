--------------------------------------------------------------------------------
local LibStub = _G["LibStub"]
local M = LibStub:NewLibrary( "LibSpatial-0", 0 )
if ( not M ) then return end

--------------------------------------------------------------------------------
function M:axisXYZ( axis )
    if axis == 1 then
        return self.x
    end
    if axis == 2 then
        return self.y
    end
    if axis == 3 then
        return self.z
    end
end 

--------------------------------------------------------------------------------
M.kdtree = (function()
    require "math"
    require "table"
    
    ----------------------------------------------------------------------------
    local M = {} 
    
    ----------------------------------------------------------------------------
    function M:template( dimensions, axis )
        local T = {
            DIMENSIONS = dimensions
          , axis = axis
        }
        setmetatable( T, { __index = self } )
        
        return T
    end
    
    ----------------------------------------------------------------------------
    function M:new( o )
        o = o or {}
        setmetatable( o, { __index = self } )
        assert( o.DIMENSIONS )
        o:init()
    
        return o
    end
    
    ----------------------------------------------------------------------------
    function M:init()
        self.data = {}
        self.size = 0
    end
    
    ----------------------------------------------------------------------------
    function M:axis( axis )
        return self[axis]
    end
    
    ----------------------------------------------------------------------------
    function M:distance( a, b )
        local distance = 0
        for i = 1, self.DIMENSIONS do
            local coord_a = self.axis(a, i)
            local coord_b = self.axis(b, i)
            distance = distance + math.pow( ( coord_a - coord_b ), 2 )
        end
        return distance
    end
    
    ----------------------------------------------------------------------------
    function M:load( points )
        self:clear()
        self.root = self:node( points, 0 )
    end
    
    ----------------------------------------------------------------------------
    function M:clear()
        self.root = nil
        self.data = {}
        self.size = 0
    end
    
    ----------------------------------------------------------------------------
    function M:reindex()
        self:load( self.data )
    end
    
    ----------------------------------------------------------------------------
    function M:split( points, first, last )
        local result = {}
    
        for i = first, last do
            table.insert( result, points[i] )
        end
    
        return result
    end
    
    ----------------------------------------------------------------------------
    function M:node( points, depth )
        local len = #points
        if len < 1 then return nil end
        
        local axis = ( depth % self.DIMENSIONS ) + 1
        local function cmp( a, b )
            return self.axis( a, axis ) < self.axis( b, axis )
        end
        points = self:split( points, 1, len )
        table.sort( points, cmp )
        local median = math.ceil( len / 2 )
        depth = depth + 1
        self.size = self.size + 1
        table.insert( self.data, points[median] )
        local node = {
            location = points[median]
          , left = self:node( self:split( points, 1, median - 1 ), depth )
          , right = self:node( self:split( points, median + 1, len ), depth )
        }
        return node
    end
    
    ----------------------------------------------------------------------------
    function M:find( point )
        local parent  = self
        local side    = "root"
        local depth   = 0
        local axis    = 1
        
        while parent[side] ~= nil do
            parent = parent[side]
            local coord_point = self.axis( point, axis )
            local coord_parent = self.axis( parent.location, axis )
            if coord_point > coord_parent then
                side = "right"
            else
                side = "left"
            end
            depth = depth + 1
            axis = ( depth % self.DIMENSIONS ) + 1
        end
    
        return parent, side
    end
    
    ----------------------------------------------------------------------------
    function M:insert( point )
        local parent, side  = self:find( point )
        parent[side] = { location = point }
        self.size = self.size + 1
        table.insert( self.data, point )
    end
    
    ----------------------------------------------------------------------------
    function M:min( point, depth, next, current, distance )
        if next ~= nil then
            next = self:nearest( point, next, depth + 1 )
            local distance_next = self:distance( point, next )
            if distance_next < distance then
                current = next
                distance = distance_next
            end
        end
        
        return current, distance
    end
    
    ----------------------------------------------------------------------------
    function M:nearest( point, current, depth )
        current = current or self.root
        depth = depth or 0
    
        if current == nil then return nil end
        
        local axis  = ( depth % self.DIMENSIONS ) + 1
        local coord_point = self.axis( point, axis )
        local coord_current = self.axis( current.location, axis )
        local dir, next, other
        if coord_point > coord_current then
            dir  = -1
            next = current.right
            other = current.left
        else
            dir  = 1
            next = current.left
            other = current.right
        end
        current = current.location
        local distance  = self:distance( point, current )
        
        current, distance = self:min( point, depth, next, current, distance )
        coord_current = self.axis( current, axis )
        if other ~= nil then
            local coord_overlap = coord_point + math.sqrt( distance ) * dir
            if coord_overlap > self.axis( current, axis ) then
                current, distance = self:min( point, depth, other, current, distance )
            end
        end
        
        return current, distance 
    end
    
    ----------------------------------------------------------------------------
    function M:containedSphere( point, radius )
        local points = {}
        self:containedSphereStep( point, radius, radius*radius, points, self.root, 0 )
        return points 
    end
    
    ----------------------------------------------------------------------------
    function M:containedSphereStep( point, radius, radius_square, points, current, depth )
        if current == nil then return end
    
        local axis  = ( depth % self.DIMENSIONS ) + 1
        local coord_point = self.axis( point, axis )
        local coord_current = self.axis( current.location, axis )
        local coord_overlap, next, other
        if coord_point > coord_current then
            coord_overlap = coord_point - radius
            next = current.right
            other = current.left
        else
            coord_overlap = coord_point + radius
            next = current.left
            other = current.right
        end
        current = current.location
    
        if self:distance( point, current ) < radius_square then
            table.insert( points, current )
        end
        self:containedSphereStep( point, radius, radius_square, points, next, depth + 1 )
        if ( other ~= nil ) and ( coord_overlap > self.axis( current, axis ) ) then
            self:containedSphereStep( point, radius, radius_square, points, other, depth + 1 )
        end
    end
    
    ----------------------------------------------------------------------------
    return M
end)()

--------------------------------------------------------------------------------
return M
