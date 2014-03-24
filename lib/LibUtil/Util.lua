--------------------------------------------------------------------------------
local M = {
    VERSION = { MAJOR = 0, MINOR = 0, PATCH = 0 }
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
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = {}
    Apollo.RegisterAddon( self, bHasConfigureFunction, strConfigureButtonText, tDependencies )
end

--------------------------------------------------------------------------------
function M.join( tArray, strSeperator )
    local strResult = ""
    local strSep = ""
    
    for i, item in ipairs( tArray ) do
        strResult = strPath .. strSep .. item
        strSep = strSeperator
    end

    return strResult
end 

--------------------------------------------------------------------------------
function M.join( tArray, strSeperator )
    local strResult = ""
    local strSep = ""
    
    for i, item in ipairs( tArray ) do
        strResult = strPath .. strSep .. item
        strSep = strSeperator
    end

    return strResult
end 

--------------------------------------------------------------------------------
return M:new()
