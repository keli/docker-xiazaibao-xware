
local consts = {}

local _M = consts

_M.__index = _M

function _M:__private_new()
	local self = {}
    
	setmetatable(self, _M)

--[[
-- define some status error number
-- the function to query module status
-- nil    the default return value, supper class return this
-- 0xfff  
-- 0      the module is stopped
-- 1      the module is active
-- 2      the module is error/exception
-- 3      the module is busy
-- other  all other value are reserved, do not use
--]]    
    self.status_unknown = 0
    self.status_stopped = 1
    self.status_running = 2
    self.status_active = 3
    self.status_error = 4
    self.status_busy = 5
    
    self.platforms = {}
    local ports = {}
 
	--[[
    -- the ports config for xiazaibao
    ports = {} -- clear the table
    ports.xctl = 8200
    ports.mps = 81
    ports.http = 80
    self.platforms.xzb = {}    
    self.platforms.xzb.ports = ports
   
    -- the ports config for zhuanqianbao2
    ports = {} -- clear the table
    ports.xctl = 8200
    ports.mps = 8100
    ports.http = 8000
    self.platforms.zqb2 = {}    
    self.platforms.zqb2.ports = ports
    --]]
	
    return self
end

function _M:instance_get()
    if self.inst == nil then
        self.inst = self:__private_new()
    end
    
    return self.inst
end

return _M
