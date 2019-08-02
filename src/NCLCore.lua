--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

-----
--
-- Núcleo do processamento da geração do NCL final
--
-----

require'lpeg'
local m = lpeg

require 'DataModel'
local DataModel = DataModel
local Node = DataModel.Node

local io      = io
local pairs   = pairs
local ipairs  = ipairs
local type    = type
local table   = table
local print   = print
local tonumber = tonumber
local tostring = tostring
local error = error

module(... or 'NCLCore')

function getElement(refer, node, templateFill)
	
	local node = node
	local m = m
	local templateFill = templateFill
	local S = m.V'SPACE'
	local ID = m.V'IDENTIFIER'
	local grammar =
	{
		'INITIAL';
		SPACE		= (m.S'\n \t\r\f')^0,
		IDENTIFIER	= m.C( (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^1),
		INTEGER		= m.C(m.R'09'^1) / function(v) return tonumber(v) end,
		INITIAL		= S * m.V'PATT' *S* -1,
		PATT		= ID *( m.P'[' *S* m.V'INTEGER' *S* m.P']')^-1 * ( m.P'.' * ID * ( m.P'[' *S* m.V'INTEGER' *S* m.P']')^-1 )^-1
					    / function(component, i, interface, j)
							if templateFill.components[component] then
								local number
								number = 1
								if i then
									number = i
								end
								
								
								local comp = templateFill.components[component]
								if comp ~= nil then
									local no = comp.nodes[number]
									if no ~= nil then
										id = no.atts['id']
									else
										
										return false
									end
								else
									
									return false
								end
								
								table.insert(node.atts, 'component')
								node.atts.component = id
								
								if interface then
									number = 1
									if j then
										number = j
									end
									
									local comp = templateFill.components[interface]
									if comp ~= nil then
										local no = comp.nodes[number]
										if no ~= nil then
											id = no.atts['id']
										else
									
											return false
										end
									else
									
										return false
									end
									
									table.insert(node.atts, 'interface')
									node.atts.interface = id
								end
								
							end
							return node
						end
	}

	return m.match(grammar, refer)
end

function populate(dictionary, templateFill, root, alias)
	local stackConn = {}
	
	for _,v in pairs(templateFill.links) do
		for _,v1 in ipairs(v.nodes) do
			
			local rel, conn = formarRelacionamento(v1, nil, nil, templateFill)
			
			if rel ~= false and conn ~= false then
				dictionary.root:addChild(rel)
				table.insert(stackConn, conn)
			end
			
		end
	end
	
	for k,v in ipairs(stackConn) do
		v.atts['id'] = alias..k
		v.link.atts['xconnector'] = v.atts['id']
		formataConnector(v, {})
	end
	
	local found = false
	local head = nil
	for _,v in ipairs(root.child) do
		if v.name == 'head' then
			head = v
			for _,v1 in ipairs(v.child) do
				if v1.name == 'connectorBase' then
					found = true
					for _,v2 in ipairs(stackConn) do
						v1:addChild(v2)
					end
					break
				end
			end
			break
		end
	end
	
	if not head then error ('faltou o head.') end
	
	if not found and head then
		local connBase = Node:new('connectorBase',{})
		head:addChild(connBase)
		for _,v in ipairs(stackConn) do
			connBase:addChild(v)
		end
	end
	
	return root:toString()
end





function formataConnector(conn, tipos)

	if conn.name == 'simpleAction' then
		local novo = true
		for _,tipo in ipairs (tipos) do
			
			if conn.atts['role'] == tipo then
				novo = false
				conn.parent:removeChild(conn)
			
			end
		end
		if novo then
			table.insert(tipos, conn.atts['role'])
		end
	elseif conn.name == 'simpleCondition' then
		local novo = true
		for _,tipo in ipairs (tipos) do
			
			if conn.atts['role'] == tipo then
				novo = false
				conn.parent:removeChild(conn)
			
			end
		end
		if novo then
			table.insert(tipos, conn.atts['role'])
		end
	end

	local tempSize, i = #conn.child, 1
	while i <= #conn.child do
		tempSize = #conn.child
		formataConnector(conn.child[i], tipos)
		if tempSize == #conn.child then
			i = i+1
		end
	end
	
	if conn.name == 'compoundCondition' then
		if #conn.child == 1 then
			local parent = conn.parent
			local elm = conn.child[1]
			conn:removeChild(elm)
			parent:addChild(elm)
			parent:removeChild(conn)
		end
	elseif conn.name == 'compoundAction' then
		if #conn.child == 1 then
			local parent = conn.parent
			local elm = conn.child[1]
			conn:removeChild(elm)
			parent:addChild(elm)
			parent:removeChild(conn)
		end
	end
end

function formarRelacionamento(node, parent, connector, templateFill)
	local atts = nil
	local element = parent
	local conn = connector
	
	
	if node.name == 'relation' then
		atts = {[1] = 'xconnector', xconnector = ''}
		element = Node:new('link',atts)
		atts = {[1] = 'id', id = ''}
		conn = Node:new('causalConnector', atts)
		conn.link = element
	elseif node.name == 'condition' then
		
		if node.atts.name then
			atts = {[1] = 'role', role = node.atts.name}
			element = Node:new('bind',atts)
			getElement(node.atts.refer, element, templateFill)
			atts = {[1] = 'role', [2] = 'max', [3] = 'qualifier', role = node.atts.name, max = 'unbounded', qualifier = 'or'}
			conn = Node:new('simpleCondition', atts)
			parent:addChild(element)
			connector:addChild(conn)
			conn = connector
		end
	elseif node.name == 'assessmt' then
		atts = {[1] = 'comparator', comparator = node.atts.operand}
		conn = Node:new('assessmentStatement',atts)
		atts = {[1] = 'role', [2] = 'eventType', [3] = 'attributeType', role = 'test', eventType = 'attribution',  attributeType = 'nodeProperty'}
		conn:addChild(Node:new('attributeAssessment',atts))
		atts={[1] = 'value', value = '$test'}
		conn:addChild(Node:new('valueAssessment', atts))
		local temp = connector
		while temp and temp.name ~= 'causalConnector' do
			temp = temp.parent
		end
		if not temp then error('sem causal connector') end
		atts={[1] = 'name', name = 'test'}
		temp:addChild(Node:new('connectorParam', atts))
		atts={[1] = 'role', role='test'}
		element = Node:new('bind',atts)
		parent:addChild(element)
		connector:addChild(conn)
		conn = connector
	elseif node.name == 'term' then
		if not element.atts.component then
			local el = getElement(node.atts.value, element, templateFill)
			if el == false then
				
				return false
			end
		else
			atts = {[1] = 'name', [2] = 'value', name = 'test', value = node.atts.value}
			element = Node:new('bindParam',atts)
			parent:addChild(element)
		end
	elseif node.name == 'param' then
		atts = {[1] = 'name', name = node.atts.name}
		conn = Node:new('connectorParam', atts)
		connector:addChild(conn)
		if parent and parent.name == 'link' then
			atts = {[1] = 'name', [2] = 'value', name = node.atts.name, value = node.atts.value}
			element = Node:new('linkParam',atts)
		else
			atts = {[1] = 'name', [2] = 'value', name = node.atts.name, value = node.atts.value}
			element = Node:new('bindParam',atts)
		end
		parent:addChild(element)
		conn = connector
	elseif node.name == 'action' then
		atts = {[1] = 'role', [2] = 'max', role = node.atts.name, max = 'unbounded'}
		conn = Node:new('simpleAction', atts)
		connector:addChild(conn)
		atts = {[1] = 'role', role = node.atts.name}
		element = Node:new('bind',atts)
		local el = getElement(node.atts.refer, element, templateFill)
		if el == false then
			return false
		end
		parent:addChild(element)
		if node.atts.name == 'set' then
			atts = {[1] = 'name', [2] = 'value', name = 'var', value = node.atts.value}
			element:addChild(Node:new('bindParam',atts))
			atts = {[1] = 'name', name = 'var'}
			connector:addChild(Node:new('connectorParam', atts))
		end
		conn = connector
	elseif node.name == 'actionList' then
		local tipo = node.atts.operand
		--print ('hjklghjksdfghjkl', tipo)
		if connector.name == 'compoundAction' and connector.atts['operator'] == tipo then
			conn = connector
		else
			atts = {[1] = 'operator', operator = tipo}
			conn = Node:new('compoundAction', atts)
			connector:addChild(conn)
		end
		element = parent
	elseif node.name == 'condList' then
		local tipo = node.atts.operand
		if connector.name == 'compoundCondition' and connector.atts['operator'] == tipo then
			conn = connector
		else
			atts = {[1] = 'operator', operator = tipo}
			conn = Node:new('compoundCondition', atts)
			connector:addChild(conn)
		end
		element = parent
	end
	
	for _,v in ipairs(node.child)do
		if formarRelacionamento(v, element, conn, templateFill) == false then
			
			return false
		end
	end
	
	return element, conn
end
