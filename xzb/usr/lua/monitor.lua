#!/usr/bin/env lua

-- monitor usage:
-- lua monitor.lua module-dir

function usage()
    print("Usage: lua monitor.lua [-s sys-dir] [-m module-dir]")
    print("  sys-dir      the lua system package dir")
    print("  module-dir   the lua module dir")
    print("e.g. lua moinitor.lua -s /usr/lua -s /usr/lib/lua -m /tmp/module")
end

local sys_dir_lua = ""
local sys_dir_so = ""
local module_dir_lua = ""
local module_dir_so = ""
local module_dir_list = {}
local arg_cnt = #arg

if arg_cnt < 2 or arg_cnt % 2 ~= 0 then
    usage()
    os.exit()
end

local i = 1
local j = 1
while i <= #arg do
    if arg[i] == "-s" then
        sys_dir_lua = sys_dir_lua .. ";" .. arg[i + 1] .. "/?.lua"
        sys_dir_so = sys_dir_so .. ";" .. arg[i + 1] .. "/?.so"
    elseif arg[i] == '-m' then
        module_dir_list[j] = arg[i + 1]
        j = j + 1
        module_dir_lua = module_dir_lua .. ";" .. arg[i + 1] .. "/?.lua"
        module_dir_so = module_dir_so .. ";" .. arg[i + 1] .. "/?.so"
    else
        usage()
        os.exit()
    end
    i = i + 2
end

package.path = package.path .. sys_dir_lua .. module_dir_lua
package.cpath = package.cpath .. sys_dir_so .. module_dir_so

print("path  ", package.path)
print("cpath ", package.cpath)

local _consts = require("consts")
local CONSTS = _consts:instance_get()

local socket = require("socket")

local _xlog = require("xlog")
local xlog = _xlog:instance_get("monitor", nil, "\'monitor module, lua version " .. _VERSION .. "\'\n")


local Base = require("XLMonitorBase")


if xlog == nil then
    print("init xlog failed")
end

local Monitor = {}

local _M = Monitor

_M.module_list = {}

function _M:module_add (m)
	self.module_list[m.name] = m
end

function _M:module_del (m)
	self.module_list[m.name] = nil
end

--[[
function _M:module_clear()
	for mk, mv in pairs(Monitor.module_list) do
		package.loaded[mv.name] = nil
	end
	Monitor.module_list = nil
	Monitor.module_list = {}
end
--]]

function _M:basename(path)
	local i = 0
	local last = 0
	while true do
		-- Note, if in windows, change the '/' to '\'
		i = string.find(path, "/", last + 1)
		if i == nil then
			break
		else
			last = i
		end
	end
	if last == 0 then
		return nil
	else
		return string.sub(path, last + 1, -1)
	end
end

--[[
-- the module name format: 
-- m_xxx.lua
-- start with 'm_' prefix
-- end with '.lua' suffix
-- xxx is the module name
--
-- Note: if the module is modified after scan, the monitor can not notify except restart the monitor
--
--]]
function _M:module_scan(module_dir)
	local m_path
	local m_name
	local module_class
	local module_instance
    local module_cnt = 0
	-- the module file format : m_xxx.lua
	-- so we the module name is m_xxx
	local p = io.popen("ls " .. module_dir .. "/m_*.lua")
	if p == nil then
        xlog:xlog(xlog.warning, "monitor: scan monitor module failed\n")
		return 0
	end
	for f in p:lines() do
		--print("file ", f)
		m_path = string.sub(f, 1, -5)
		print("get a module [" .. m_path .. "]")
		xlog:xlog(xlog.debug, "monitor: get a module path [" .. m_path .. "]\n")
		m_name = self:basename(m_path)
		if m_name == nil then
			xlog:xlog(xlog.warning, "monitor: module path [" .. m_path .. "] is invalid module\n")
		else
			module_class = require(m_name)
			module_instance = module_class:new()
			self:module_add(module_instance)
			module_cnt = module_cnt + 1
		end
	end
	p:close()
    
    return module_cnt
end

function _M:check()
	-- check very module
	for mk, mv in pairs(self.module_list) do
		-- call each module status function to get its status
        local need_start = 0
        local need_stop = 0
        local need_restart = 0      
		local stat = mv:status()
		if stat == CONSTS.status_stopped then
			-- module stopped
            print("module is stopped [" .. mv.name .. "]")
            
			need_start = 1
		elseif stat == CONSTS.status_active then
			-- module active
            print("module is active  [" .. mv.name .. "]")
		elseif stat == CONSTS.status_error then
			-- module error
            print("module is error   [" .. mv.name .. "]")
            need_restart = 1
		elseif stat == CONSTS.status_busy then
			-- module busy
            print("module is busy    [" .. mv.name .. "]")
		elseif stat == CONSTS.status_unknown then
			print("module [" .. mv.name .. "] is unknown")
        elseif stat == CONSTS.status_running then
            -- should not run to here
            print("module is running   [" .. mv.name .. "]")
        else
            print("module is bbadd   [" .. mv.name .. "] status = ?")
		end
		
		if need_start == 1 then
            xlog:xlog(xlog.warning, "monitor: start module [" .. mv.name .. "]\n")
			--mv.start()
            mv:restart()
		end
        
        if need_stop == 1 then
            xlog:xlog(xlog.warning, "monitor: stop module [" .. mv.name .. "]\n")
            mv:stop()
        end
        
        if need_restart == 1 then
            xlog:xlog(xlog.warning, "monitor: restart module [" .. mv.name .. "]\n")
            mv:restart()
        end
	end
end


function _M:loop()

    xlog:xlog(xlog.debug, "monitor: start loop and check\n")
	-- rescan all module, if any add or removed
    local module_cnt = 0
    
    for k, v in ipairs(module_dir_list) do
        module_cnt = module_cnt + self:module_scan(v)
    end
   
    if module_cnt <= 0 then
        print("not found any module")
        xlog:xlog(xlog.warning, "monitor: not found any module, exit monitor\n")
        return
    end
    
	Base:sleep(60)

	while true do
		-- check all
		local ok, err = pcall(self.check, self)
        if not ok then
            print(err)
        end
        
		local ok, err = pcall(Base.sleep, Base, 60)
        if not ok then
            print(err)
        end
		
        --Base:sleep(10)
	end
    
    --Monitor:module_clear()
    
    xlog:xlog(xlog.debug, "monitor: stop loop and check\n")
end


_M:loop()

xlog:instance_free()
