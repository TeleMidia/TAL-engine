--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require'lxp'
local lxp = lxp

require'lpeg'
local m = lpeg

require'template'
local tParser = template.parse

require'LuaXml'
local xml = xml

local io      = io
local pairs   = pairs
local ipairs  = ipairs
local type    = type
local table   = table
local print   = print

module(... or 'ClassificationBase')


local connectors, tBase, out = {}, nil, nil

local dic = {}

local Class = {
	name = '',
	item = {}
}

function Class:new(name)
	local o = {
		name = name,
		item = {}
	}
	
	setmetatable(o, self)
	self.__index = self
	return o
end

function Class:addItem(item)
	table.insert(self.item,item)
end

local Item = {
	name = '',
	atts = {},
	child = {}
}

function Item:new(name, atts)
	local o = {
		name = name,
		atts = atts
	}
	
	setmetatable(o, self)
	self.__index = self
	return o
end

function Item:addChild(child)
	table.insert(self.child,child)
end

