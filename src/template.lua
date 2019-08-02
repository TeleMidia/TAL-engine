--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require'templateBase'
local Tal = templateBase.Tal
local Template = templateBase.Template
local Component = templateBase.Component
local Interface = templateBase.Interface
local Node = templateBase.Node
local Anchor = templateBase.Anchor
local Constraint = templateBase.Constraint
local Link = templateBase.Link
local forEach = templateBase.forEach
local Relation = templateBase.Relation
local Recurso = templateBase.Recurso

require'constraint'
local parseConstraint = constraint.parse

require 'selector'
local selector = selector

local io = io
local table = table
local print = print
local error = error
local ipairs = ipairs
local lxp = lxp
local string = string

module(... or 'template')

local docs = {}

local function templateError(msg, line, column, position)
	line = line or 0
	column = column or 0
	position = position or 0
	print('== Template Language Error ==')
	print()
	print('Line/column = ' .. line .. '/' .. column)
	print('Position on file = ' .. position)
	print()
	error(msg)
end

local parseElements =
{
	tal = function(parent, atts, parser)
		if not atts.id then
			templateError('The "id" attribute in <tal> element are mandatory.', parser:pos())
		end
		return Tal:new(atts.id)
	end,
	templateBase = function(parent, atts, parser)
		return parent
	end,
	importTAL = function(parent, atts, parser)
	
		if not atts.documentURI or not atts.alias then
			templateError('The "documentURI" and "alias" attributes are mandatory in <importTAL> element.', parser:pos())
		end
		if not parent.importTAL then
			templateError('The <importTAL> element must be child of a <templateBase> element.', parser:pos())
		end
		local importedTBase = parse(atts.documentURI)
		if not importedTBase then
			templateError('Could not import documentURI="' .. atts.documentURI .. '" on alias="' .. atts.alias ..'"', parser:pos())
		end
		parent:importTAL( importedTBase, atts.alias )
		return importedTBase
	end,
	template = function(parent, atts, parser)
		if not atts.id then
			templateError('The "id" attribute in <template> element are mandatory.', parser:pos())
		end
		local t = Template:new(atts.id)
		if atts.extends then
	
			local templateExtended = parent.templates[atts.extends]
			if not templateExtended then
				templateError('Template "' .. atts.id .. '" cannot find template "' .. atts.extends .. '" to extend.', parser:pos())
			else
				t:makeExtension(templateExtended)
			end
		end
		if not parent.addTemplate then
			templateError('The <template> element must be child of a <templateBase> element.', parser:pos())
		elseif not parent:addTemplate(t) then
			templateError('Could not add to <templateBase> the <template> "' .. atts.id .. '". Duplicate ids?' , parser:pos())
		end
		return t
	end,
	component = function(parent, atts, parser)
		if not atts.id or not atts.selects then
			templateError('The "id" and "selects" attributes in <component> element are mandatory.', parser:pos())
		end
		local sel = selector.parse(atts.selects)
	
		if not sel then templateError('Invalid selector expression "'..atts.selects..'" attribute in <component> element '..atts.id..'.', parser:pos()) end
		local t = Component:new(atts.id, sel)
		if not parent.addComponent then
			templateError('The <component> element must be child of a <template> or a <component> element.', parser:pos())
		elseif not parent:addComponent(t) then
			templateError('Could not add <component> element to parent element. Duplicate ids?', parser:pos())
		end
		return t
	end,
	interface = function(parent, atts, parser)
		if not atts.id or not atts.selects then
			templateError('The "id" and "selects" attributes in <interface> element are mandatory.', parser:pos())
		end
		local sel = selector.parse(atts.selects)
		
		if not sel then templateError('Invalid selector expression "'..atts.selects..'" attribute in <interface> element '..atts.id..'.', parser:pos()) end
		local t = Interface:new(atts.id, sel)
		if not parent.addInterface then
			templateError('The <interface> element is not child of a <template> or a <component> element.', parser:pos())
		elseif not parent:addInterface(t) then
			templateError('Could not add <interface> element to parent element. Duplicate ids?', parser:pos())
		end
		return t
	end,
	relation = function(parent, atts, parser)
		if not atts.id or not atts.selects then
			templateError('The "id" and "selects" attributes are mandatory in <relation> element.', parser:pos())
		end
		local sel = selector.parse(atts.selects)
		-- confirma se o seletor é válido
		if not sel then templateError('Invalid selector expression "'..atts.selects..'" attribute in <relation> element '..atts.id..'.', parser:pos()) end
		local t = Relation:new(atts.id, atts.selects)
		if not parent.addRelation then
			templateError('The <relation> element is no child of a <template> element.', parser:pos())
		elseif not parent:addRelation(t) then
			templateError('Could not addRelation. Duplicate ids?', parser:pos())
		end
		return t
	end,
	assert = function(parent, atts, parser)
		if not atts.test then
			templateError('The "test" attribute in <assert> element is mandatory.', parser:pos())
		end
		--print ('opa')
		local f = parseConstraint(atts.test)
		if not f then
			templateError('Invalid test expression in <assert> element: "' .. atts.test .. '"', parser:pos())
		else
			local t = Constraint:new('assert', atts.test, '', f)
			if not parent.addConstraint then
				templateError('The <assert> element must be a child of a <template> element.', parser:pos())
			elseif not parent:addConstraint(t) then
				templateError('Could not add <assert> element to parent element.', parser:pos())
			end
			return t
		end
	end,
	report = function(parent, atts, parser)
		if not atts.test then
			templateError('The test attribute in <report> element is mandatory.', parser:pos())
		end
		local f = parseConstraint(atts.test)
		if not f then
			templateError('Invalid test expression in <report> element: "' .. atts.test .. '"', parser:pos())
		else
			local t = Constraint:new('report', atts.test, '', f)
			if not parent.addConstraint then
				templateError('The <report> element must be a child of a <template> element.', parser:pos())
			elseif not parent:addConstraint(t) then
				templateError('Could not add <report> element to parent element.', parser:pos())
			end
			return t
		end
	end,
	warning = function(parent, atts, parser)
		if not atts.test then
			templateError('The test attribute in <warning> element is mandatory.', parser:pos())
		end
		local f = parseConstraint(atts.test)
		if not f then
			templateError('Invalid test expression in <report> element: "' .. atts.test .. '"', parser:pos())
		else
			local t = Constraint:new('warning', atts.test, '', f)
			if not parent.addConstraint then
				templateError('The <warning> element must be a child of a <template> element.', parser:pos())
			elseif not parent:addConstraint(t) then
				templateError('Could not add <warning> element to parent element.', parser:pos())
			end
			return t
		end
	end,
	link = function(parent, atts, parser)
		local t = Link:new(atts.id)
		if not parent.addLink then
			
			templateError('The <link> element must be a child of a <template> element.', parser:pos())
		elseif not parent:addLink(t) then
			
			templateError('Could not add link to parent element. Duplicate ids?', parser:pos())
		end
		return t
	end,
	forEach = function(parent, atts, parser)
		
		
		if not atts.instance or not atts.iterator then
			templateError('The "instance" and "iterator" attributes are mandatory in <forEach> element.', parser:pos())
		end
		
		local t = forEach:new(atts.instance, atts.iterator, atts.step)
		if not parent.addForEach then
			templateError('Invalid parent element for <forEach> element.', parser:pos())
		elseif not parent:addForEach(t) then
			templateError('Could not add forEach to parent element. Duplicate ids?', parser:pos())
		end
		return t
	end,
	recurso = function(name, parent, atts, parser)
		
		local t = Recurso:new(name, atts)
		
		return t
	end
}

function parse(templateFileName)
	
	local f = io.open( templateFileName, 'r' )
	
	if not f then
		--print ('merda')
		return false
	end
	
	local source = f:read('*a')
	if not source then
		return false
	end

	local doParse, stack, root = true, {}, nil
	local p = lxp.new ({
	    StartElement = function (parser, name, atts)
	    	if doParse then
		    	if not root then					
		    		if not atts.id then
		    			templateError('Root element must have an "id" attribute.', parser:pos())
		    		elseif docs[atts.id] then
		    			root = docs[atts.id]
		    			doParse = false
		    			return
		    		end
		    	end
				
				local node = nil
				
				if string.find(name:upper(), "TAL:") == 1 then 
					name = name:gsub("tal:",'')
					if not parseElements[name] then
						templateError('Invalid element <' .. name .. '>', parser:pos())
						return false
					else
						local parent = stack[#stack]
						node = parseElements[name](parent, atts, parser)
					end
				else
					
					local parent = stack[#stack]
					node = parseElements['recurso'](name, parent, atts, parser)
				end
				-- stack
				table.insert(stack, node)
				-- root
				root = root or node
		    end
	    end,
	    EndElement = function (parser, name)
			
	    	if doParse then
				table.remove(stack)
		    end
	    end,
	    CharacterData = function(parser, str)
	    	if doParse then
				
		    	local parent = stack[#stack]
		    	if parent.addMessage then
					
		    		parent:addMessage(str)
		    	end
				if parent.addText then
					
					parent:addText(str)
				end
		    end
		end
	}
	)

	if not p:parse(source) then
		return false
	end
	
	p:close()
	return root
end

