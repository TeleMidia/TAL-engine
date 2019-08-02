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

require'LuaXml'
local xml = xml

require 'DataModel'
local DataModel = DataModel

require'Message'
local Message = Message

local setmetatable = setmetatable
local io      = io
local pairs   = pairs
local ipairs  = ipairs
local type    = type
local table   = table
local print   = print

module(... or 'Classification')

local dic = {}

local Dictionary = {
	id = '',
	templateFile = '',
	root = nil
	}

function Dictionary:new(id, templateFile, root)
	local o = {
		id = id,
		templateFile = templateFile,
		root = root
	}
	
	setmetatable(o, self)
	self.__index = self
	return o
end

local Node = DataModel.Node

local parseElements = {
	context = function(parent, name, atts, parser)
		
		local t = Node:new(name, atts)
		
		if atts['tal:template'] then
		
			local temp = Dictionary:new(atts.id or name, atts['tal:template'], t)
			table.insert(dic, temp)
			
		end
		
		if parent then
			
			if parent.addChild then
				parent:addChild(t)
			end
			
		end
		
		return t
	end,
	body = function(parent, name, atts, parser)
		
		local t = Node:new(name, atts)
		
		if atts.template then
			
			local temp = Dictionary:new(atts.id or name, atts.template, t)
			table.insert(dic, temp)
			
		end
		
		if parent then
			
			if parent.addChild then
				parent:addChild(t)
			end
			
		end
		
		return t
	end,
	component = function(parent, name, atts, parser)
		
		local t = Node:new(name, atts)
		
		if parent then
			
			if parent.addChild then
				parent:addChild(t)
			end
			
		end
	
		return t
	end
}

local function fillError(msg, line, column, position)
	line = line or 0
	column = column or 0
	position = position or 0
	
	txt = '== Fill Language Error ==\n\n'
	txt = txt .. 'Line/column = ' .. line .. '/' .. column .. '\n\n'
	txt = txt .. 'Position on file = ' .. position .. '\n\n'
	txt = txt .. msg
	
	Message.addMessage(txt, Message.ERROR)
end

function parse(dataFileName)
	local f = io.open(dataFileName, 'r')
	if not f then
		return false
	end
	local source = f:read('*a')
	if not source then
		return false
	end

	local doParse, stack, root = true, {}, nil
	local p = lxp.new {
	    StartElement = function (parser, name, atts)
	    	if doParse then

		    	if not parseElements[name] then
		    		local parent = stack[#stack]
					
		    		local node = parseElements["component"](parent, name, atts, parser)

		    		table.insert(stack, node)

					root = root or node
		    	else
					local parent = stack[#stack]
		    		local node = parseElements[name](parent, name, atts, parser)

		    		table.insert(stack, node)

					root = root or node
				end
		    end
	    end,
		EndElement = function (parser, name)
	    	if doParse then
				table.remove(stack)
		    end
	    end
	}

	if not p:parse(source) then
		return false
	end
	p:close()
	return root, dic
end