--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

---
--
-- Modelo interno de representação dos dados
--
---

local setmetatable = setmetatable
local print = print
local table = table
local type = type
local pairs = pairs
local ipairs = ipairs
local error = error
local io = io
local string = string

module(... or 'DataModel')

Node = {
	name = '',
	atts = {},
	child = {},
	parent = nil
}

function Node:new(name, atts)
	local o = {
		name = name,
		atts = atts,
		child = {},
		parent = nil
	}
	
	setmetatable(o, self)
	self.__index = self
	return o
end

function Node:addChild(child)
	table.insert(self.child,child)
	child.parent = self
end

function Node:removeChild(child)
	if type(child) == 'number' or type(child) == 'string' then
		
		if self.child[child] then
		
			self.child[child].parent = nil
			self.child:remove(child)
			
		
		end
	else
		
		for p, i in ipairs(self.child) do
		
			if i == child then
				
				i.parent = nil
				table.remove(self.child, p)
			
			end
		
		end
		
	end
	
end

function Node:toString()
	local str = ''
	
	str = str..'<'..self.name
	
	for name,attr in ipairs (self.atts) do
		
		
		if not (attr=='template' or attr=='class') then
			str = str..' '..attr..'="'..self.atts[attr]..'"'
		end
	end
	
	if #self.child > 0 then
		str = str..' >'
		
		for _,child in ipairs (self.child) do
			
			str = str..'\n\t'..child:toString()
			
		end
		
		str = str..'\n</'..self.name..'>'
	else
		str = str..' />'
	end
	
	return str
end

---
--
-- Nó de texto
--
---

TextNode = {
	text = ''
}

function TextNode:new(text)
	local o = {
		text = text
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TextNode:toString()
	return self.text
end