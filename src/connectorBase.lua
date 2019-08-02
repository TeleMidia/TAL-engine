--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

---
--
-- Classes de controle do conector
--
---

local setmetatable = setmetatable
local print = print
local table = table
local type = type
local pairs = pairs

module(... or 'connectorBase')

------ Condition --- uma lista de condições

Condition = {
	
	with = nil,
	name = '',
	persp = '',
	assertment = {},
	operator = ''
	
}

function Condition:new(name, persp, with, assertment)
	local o = {
		with = with,
		name = name,
		persp = persp,
		assertment = assertment,
		operator = ''
	}
	setmetatable(o, self)
	self.__index = self
	o[#o+1] = o
	return o
end

function Condition:addCondition(operator, cond)
	if type(cond) == 'table' then
		print (self)
		print (self[#self])
		print (self.operator)
		print (self[#self].operator)
		self[#self].operator = operator
		self[#self+1] = cond
	end
end

------ Action --- uma lista de ações

Action = {
	name = '',
	set = false,
	operator = '',
	persp = '',
	persp2 = '',
	str = '',
	with = nil
}

function Action:new(name, set, persp, persp2, str, with)
	local o = {
		name = names,
		set = set,
		operator = '',
		persp = persp,
		persp2 = persp2,
		str = str,
		with = with
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Action:addAction(operator, action)
	if type(action) == 'table' then
		self[#self].operator = operator
		self[#self+1] = action
	end
end

------ Param --- uma lista de parametros ( withparam )

Param = {
	id = '',
	value = ''
}

function Param:new(id, value)
	local o = {
		id = id,
		value = value
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Param:addParam( param)
	if type(param) == 'table' then
		self[#self+1] = param
	end
end
