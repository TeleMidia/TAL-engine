--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

---
--
-- Funções comuns - de uso geral
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

module(... or 'utils')

function relativeUrl(mainUrl, relativeUrl)
	local _,_, url= mainUrl:find(  "(.+[/\\]).-" )
	
	url = url..relativeUrl
	
	url = url:gsub( '/', '\\' )
	
	return url
end

function saveToFile(file, content)
	local fileHnd, err = io.open(file, 'w')
	if err then
		error(err)
	else
		fileHnd:write(content)
		fileHnd:close()
	end
end

function templateUrlRefer(templateUrl)
	local url, templateID = nil, nil
	
	local pos = templateUrl:find('#')
	
	if pos then
		
		templateID = templateUrl:sub(pos+1)
		
		url = templateUrl:sub(0,pos-1)
		
	end
	
	return url, templateID 
end

function decodeCommand(command)
	local language, input, output = nil, nil, nil
	
	local i = 1
	while i <= #command do
		if ( command[i] == '--i' or command[i] == '-input' ) and not input then
			i = i+1
			input = command[i]
		elseif ( command[i] == '--l' or command[i] == '-language' ) and not language then
			i = i+1
			language = command[i]
		elseif ( command[i] == '--o' or command[i] == '-output' ) and not output then
			i = i+1
			output = command[i]
		else
			error ('comando não reconhecido')
		end
		i = i+1
	end
	
	return language, input,output
end 

function showStructure (talLibrary)
	print ('TAL ID: '..talLibrary.id)
	for k, v in pairs(talLibrary.templates) do
		print ('Template: '..k)
		print ()
		showTemplate(v)
		print ()
	end
end

function showTemplate(template)
	print ('TEMPLATE ID: '..template.id)
	print ('TEMPLATE COMPONENTS NUMBER: '..#template.components)
	for k, v in pairs(template.components) do
		print ('\tcomponent: '..k)
		showComponent(v)
	end
	print ('TEMPLATE LINKS NUMBER: '..#template.links)
	for k, v in pairs(template.links) do
		print ('\tcomponent: '..k)
		showLink(v)
	end
	print ('TEMPLATE INTERFACES NUMBER: '..#template.interfaces)
	for k, v in pairs(template.interfaces) do
		print ('\tcomponent: '..k)
		showInterface(v)
	end
	print ('TEMPLATE RELATIONS NUMBER: '..#template.relations)
	for k, v in pairs(template.relations) do
		print ('\tcomponent: '..k)
		showRelation(v)
	end
	print ('TEMPLATE CONTRAINTS NUMBER: '..#template.constraints)
	for k, v in ipairs(template.constraints) do
		print ('\tcomponent: '..k)
		showConstraint(v)
	end
end

function showRelation(relation)
	print ()
	print ('\trelation: '..relation.id )
	print ('\tselects: '..relation.selects )
	print ('\trelLanguage: '.. relation.relLaguage)
	print ()
end

function showComponent(component)
	print ()
	print ('\tComponent ID: '..component.id)
	--print ('\t\tselector: '..component.selector)
	for k,v in pairs(component.components) do
		print ()
		print ('\t\tComponent Interno '..k)
		showComponent(v)
	end
	for k,v in pairs(component.interfaces) do
		print ()
		print ('\t\tInterface Interna '..k)
		showInterface(v)
	end
	print ()
end

function showInterface(interface)
	print ()
	print ('\tInterface ID: '..interface.id)
	--print ('\t\tselector: '..interface.selector)
	print ()
end

function showConstraint(constraint)
	print ()
	print ('\tContraint: '..constraint.test)
	print ('\tmsg: '..constraint.msg)
	print ('\tname: '..constraint.name)
	print ()
end

function showLink(link)
	print ()
	print ('\tLink ID: '..link.id)
	print ()
end

function childIterator(list, item, test)
	if list and item then 
		
		if test(item) then
			local notFound = true
			for k,v in ipairs(list) do
				if v == item then
					notFound = false
				end
			end
			if notFound then table.insert(list,item) end
		end
		
		for k,v in ipairs(item.child) do
			if v then
				childIterator(list, v, test)
			end
		end
		
		return list
	end
	
	return nil
end

function ascedent(list, item)
	if list and item then 
		table.insert(list,item)
		
		if item.parent then
			ascedent(list, item.parent)
		end
		
	end
	
	return list
end