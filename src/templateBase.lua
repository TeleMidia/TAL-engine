--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require'selector'
local selector = selector

require 'lpeg'
local m = lpeg

require'connector'
local parseConnector = connector.parse

require'constraint'
local parseConstraint = constraint.parse

require 'DataModel'
local DataModel = DataModel

require 'Expression'
local exps = Expression

local setmetatable = setmetatable
local print = print
local table = table
local type = type
local pairs = pairs
local ipairs = ipairs
local error = error
local string = string

module(... or 'templateBase')

-------
----
-- Definição do objeto TAL
----
-------

function fillError(msg)
	print('== Template Fill Document Error ==')
	print()
	error(msg)
end

Tal = {
	id = "",
	templates = {}
}

function Tal:fillTemplate(dictionary, templateID)
	local template = self.templates[templateID]
	
	
	if template then
		local temp = template:fillTemplate(dictionary)
		return temp
	else
		fillError('Template '..templateID..' not not found.')
		return false
	end
	
end

function Tal:addTemplate(template)
	if self.templates[template.id] then
		return nil
	else
		self.templates[template.id] = template
		return template
	end
end


function Tal:importTAL(Tal, alias)
	for k,v in ipairs(Tal.templates) do
	
		if not string.find(k, '#') then
			v.id = alias .. '#' .. v.id
			self:addTemplate(v)
		end
	end
end

function Tal:new(id)
	local o = { id = id, templates={} }
	setmetatable(o, self)
	self.__index = self
	return o
end

------
--
-- Definição do objeto Recurso
--
------

Recurso = DataModel.Node

------
--
-- Definição do objeto template
--
------

Template = {
	id = '',
	components = {},
	interfaces = {},
	relations = {},
	constraints = {},
	links = {},
	resoursces = {}
}

function Template:fillTemplate(dictionary)
	for _,v in pairs(self.components) do
		v:fill(dictionary)
	end
	for _,v in pairs(self.interfaces) do
		v:fill(dictionary)
	end
	for _,v in pairs(self.relations) do
		v:fill(dictionary)
	end
	for _,v in pairs(self.constraints) do
		v:fill(dictionary, self)
	end
	for _,v in pairs(self.links) do
		v:fill(dictionary, self)
	end
	return self
end

function Template:makeExtension(templateExtended)
	for k,v in pairs(templateExtended.components) do
		
		self:addComponent( Component:new(v.id, v.selector) )
	end
	for k,v in pairs(templateExtended.interfaces) do
		
		self:addInterface( Interface:new(v.id, v.selector) )
	end
	for k,v in pairs(templateExtended.relations) do
		
		self:addRelation( Relation:new(v.name, v.sequence) )
	end
	for k,v in pairs(templateExtended.constraints) do
		
		self:addConstraint( Constraint:new(v.name, v.test, v.msg, v.evaluatingFunction) )
	end
	for k,v in pairs(templateExtended.resources) do
		
		self:addResource( Recurso:new(v.id, v.src) )
	end
	for k,v in pairs(templateExtended.links) do
		
		link = Link:new(v.id) 
		for _,c in ipairs(v.child) do
			table.insert(link.child, c)
		end
		self:addLink( link)
	end
end

function Template:addComponent(cp)
	if self.components[cp.id] then
		return nil
	else
		self.components[cp.id] = cp
		return cp
	end
end

function Template:addInterface(intf)
	if self.interfaces[intf.id] then
		return nil
	else
		self.interfaces[intf.id] = intf
		return intf
	end
end

function Template:addConstraint(constraint)
	table.insert(self.constraints, constraint)
	return constraint
end

function Template:addLink(link)
	if self.links[link.id] then
		return nil
	else
		self.links[link.id] = link
		return link
	end
end

function Template:addRelation(relation)
	table.insert(self.relations, relation)
	return relation
end

function Template:new(id)
	local o = {
		id = id,
		components = {},
		interfaces = {},
		constraints = {},
		links = {},
		relations = {},
		resources = {}
	}
	o.template = o
	setmetatable(o, self)
	self.__index = self
	return o
end

----
--
--	Definição da classe componentes
--
----

Component = {
	id = '',
	selector = nil,
	nodes = {},
	components = {},
	interfaces = {}
}

function Component:fill(dictionary)
	if not self.selector then return nil end
	
	self.nodes = self.selector(dictionary)

	for _,v in pairs(self.components) do
		v:fill(dictionary)
	end
	for _,v in pairs(self.interfaces) do
		v:fill(dictionary)
	end
end

function Component:addComponent(cp)
	if self.components[cp.id] then
		return nil
	else
		self.components[cp.id] = cp
		return cp
	end
end

function Component:addInterface(intf)
	if self.interfaces[intf.id] then
		return nil
	else
		self.interfaces[intf.id] = intf
		return intf
	end
end

function Component:new(id, selector)
	local o = {
		id=id,
		selector=selector,
		nodes = {},
		components={},
		interfaces={}
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

----
--
--	Definição do objeto Interface
--
----

Interface = {
	id = '',
	selector = nil,
	nodes = {}
}

function Interface:fill(dictionary)
	if not self.selector then return nil end
	self.nodes = self.selector(dictionary)
end

function Interface:new(id, selector)
	local o = {
		id=id,
		selector=selector,
		nodes = {}
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

----
--
--	Definição do Objeto Constraint
--
----

Constraint = {
	test = '',
	msg = '',
	name = '',
	evaluatingFunction=nil
}

function Constraint:fill(dictionary, template)
	local result = self.evaluatingFunction(dictionary, template)
	if result == false and self.name == 'warning' then
		print ('WARNING:\t'..self.msg)
	elseif ( result == true and self.name == 'report' ) or ( result == false and self.name == 'assert' ) then
		error (self.msg)
	end
end

function Constraint:addMessage(msg)
	if type(msg)=='string' then
		self.msg = self.msg .. msg
	end
end

function Constraint:new(name, test, msg, evaluatingFunction)
	local o = {
		name=name,
		test=test,
		msg=(msg or ''),
		evaluatingFunction=evaluatingFunction
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

----
--
--	Definição do objeto Link
--
----

Link = {
	id = '',
	child = nil,
	nodes = nil
}

function Link:fill(dictionary, template)
	local str = ''
	
	for k,v in ipairs( self.child ) do
		str = str .. ' ' .. v:fill(dictionary, template)
	end
	str = str:gsub('||[\n \t\r\f]*end', ' end')
	str = str:gsub(';[\n \t\r\f]*end', ' end')
	local temp = str
	local opr = temp:gmatch('%b[]')
	local trm = opr()
	while trm ~= nil do
		local result = exps.parse(trm, nil, nil, template)
		trm = trm:gsub('%[','%%['):gsub('%]','%%]'):gsub('%+','%%+'):gsub('%-', '%%-'):gsub('%*','%%*')
		str = str:gsub(trm,'['..result..']')
		trm = opr()
	end
	local conn = parseConnector(str)
	self.nodes = conn
	return conn
end

function Link:addMessage(msg)
	local n = TextNode:new(msg)
	table.insert(self.child, n)
	return msg
end

function Link:addForEach(forEach)
	table.insert(self.child, forEach)
	return forEach
end

function Link:new(id)
	local o = { id=id, child = {}, nodes = {}}
	setmetatable(o, self)
	self.__index = self
	return o
end

----
--
--	Definição do objeto forEach
--
----

forEach = {
	instance = '',
	iterator = '',
	step = 1,
	child = {}
}

function forEach:fill(dictionary, template)
	
	local str = ''
	local itrt = nil
	local template = template
	
	itrt = template.components[self.instance] or template.interfaces[self.instance] or nil
	
	if not itrt then error ('instance "'..self.instance..'" not found.') end
	
	for it = 1, #itrt.nodes, self.step do
		for _,v in ipairs ( self.child ) do
			str = str .. ' ' .. v:fill(dictionary, template)
		end
		
		local temp = str
		local opr = temp:gmatch('%b[]')
		local trm = opr()
		while trm ~= nil do
			local result = exps.parse(trm, self.iterator, it, template)
			trm = trm:gsub('%[','%%['):gsub('%]','%%]'):gsub('%+','%%+'):gsub('%-', '%%-'):gsub('%*','%%*')
			str = str:gsub(trm,'['..result..']')
			trm = opr()
		end
	end
	return str
end

function forEach:addForEach(forEach)
	table.insert(self.child, forEach)
	return forEach
end

function forEach:addMessage(t)
	local n = TextNode:new(t)
	table.insert(self.child, n)
	return t
end

function forEach:new(instance, iterator, step)
	if not step or step == 0 then step = 1 end
	local o = {
		instance = instance,
		iterator = iterator,
		step = step,
		child = {}
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

----
--
--	Definição do objeto Node
--
----

TextNode = DataModel.TextNode

function TextNode:fill(dictionary, template)
	return self:toString()
end

----
--
-- Definição do objeto Relation
--
----

Relation = {
	id = "",
	selects = "",
	template = nil,
	relLanguage = ""
}

function Relation:new(id, selects, template)
	local o = { relLanguage = "", id=id, selects=selects, template=template }
	setmetatable(o, self)
	self.__index = self
	return o
end

function Relation:addText(str)
	if type(str)=='string' then
		self.relLanguage = self.relLanguage .. str
	end
end
