--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require'lxp'
require'lpeg'
require 'utils'

local childIterator = utils.childIterator
local ascedent = utils.ascedent

local m = lpeg
local lxp = lxp

local print    = print
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local table = table
local type = type
local tonumber = tonumber

module (... or 'selector')

local selectorFunctions = {}

function selectorFunctions.universalSel()
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) return true end)
		end
		return nil
	end
end

function selectorFunctions.typeSel(elementName)
	local E = elementName
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) return item.name == E end )
		end
		return nil
	end
end

function selectorFunctions.descendantSel(ascendantName, elementName)
	local E, F = ascendantName, elementName
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function(item)
				if F~='*' and item.name~=F then
					return false
				else
					local itens = ascedent({},item.parent)
					for _,v in ipairs(itens) do
						if E=='*' or v.name==E then
							return true
						end
					end
					return false
				end
			end )
		end
		return nil
	end
end

function selectorFunctions.childSel(parentName, elementName)
	local E, F = parentName, elementName
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) return (item.name==F or F=='*') and item.parent and (item.parent.name==E or E=='*') end)
		end
		return nil
	end
end

-- seleciona o i-ésimo filho de um elemento
function selectorFunctions.pseudoChildSel(elementName, childNum)
	local E, child = elementName, tonumber(childNum)
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) return (item.name==E or E=='*') and item.parent and item.parent.child[child]==item end)
		end
		return nil
	end
end

function selectorFunctions.adjacentSel(precededElement, elementName)
	local E, F = precededElement, elementName
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item)
				if item.name ~= F and F ~= '*' then
					return false
				end
				if item.parent then
					for k,v in ipairs(item.parent.child) do
						if k > 1 and v == item then
							if item.parent.child[k-1].name==E or E=='*' then
								return true
							end
						end
					end
				end
			end)
		end
		return nil
	end
end

function selectorFunctions.hasAttSel(elementName, attName)
	local E, att = elementName, attName
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) 
				if item.name~=E and E~='*' then
					return false
				end
				return item.atts[att] ~= nil
			end)
		end
		return nil
	end
end

function selectorFunctions.hasAttValue(elementName, attName, attValue)
	local E, att, val = elementName, attName, attValue
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) 
				if item.name~=E and E~='*' then
					return false
				end
				return item.atts[att] == val
			end)
		end
		return nil
	end
end

function selectorFunctions.hasCommaAttValue(elementName, attName, attValue)
	local E, att, val = elementName, attName, attValue
	return function(dictionary)
		if dictionary then
			return childIterator({}, dictionary.root, function (item) 
				
				if (E~='*' and E~=item.name) or not item.atts[att] then
					return false
				else
					local CSV = {
						'initial';
						initial = m.V'SPACE' * m.V'VALList' * m.V'SPACE' * -1,
						SPACE	= (m.S'\n \t\r\f')^0,
						VAL   	= m.C( (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^1 ),
						VALList = m.V'VAL' * m.Ct( ( m.V'SPACE' * m.V'VAL' * m.V'SPACE')^0 ) /
								  function(v, t)
									 if v==attValue then
										return true
									 end
									 if type(t)=='table' then
										for _,v in pairs(t) do
											if v==attValue then
												return true
											end
										end
									 end
									 return false
								  end
					}
					return m.match(CSV, item.atts[att])
				end
			end)
		end
		return nil
	end
end

-- parse(sel)
-- Input
--    sel: string with selector value
-- Returns a selectior function, when sel is valid OR nil otherwise

function parse(sel)
	
	local S = m.V'SPACE'
	local ID = m.V'IDENTIFIER'
	local grammar =
	{
		'INITIAL';
		SPACE		= (m.S'\n \t\r\f')^0,
		IDENTIFIER	= m.C( (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^1 + m.P'*' ),
		INTEGER		= m.C(m.R'09'^1) / function(v) return tonumber(v) end,
		INITIAL		= S * m.V'PATT' *S* -1,
		CLASS		= m.C( m.P'tal:'^-1 * (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^1 ),
		PATT		=
					  ( ID *S* ID
					    / function(E, F)  return selectorFunctions.descendantSel(E,F) end
					  )
					  +
					  ( ID *S* (m.P'>' + m.P'&gt;') *S* ID
					    / function(E, F)  return selectorFunctions.childSel(E,F) end
					  )
					  +
					  ( ID *S* m.P':' *S* m.V'INTEGER' * m.P'-child'
					    / function(E, childCount)
						    if childCount==0 then return nil
							else return selectorFunctions.pseudoChildSel(E, childCount) end
						  end
					  )
					  +
					  ( ID *S* m.P'+' *S* ID
					    / function(E, F)  return selectorFunctions.adjacentSel(E,F) end
					  )
					  +
					  ( ID *S* m.P'[' *S* m.V'CLASS' *S* m.P']'
					    / function(E, att)  return selectorFunctions.hasAttSel(E,att) end
					  )
					  +
					  ( ID *S* m.P'[' *S* m.V'CLASS' *S* m.P'=' *S* ID *S* m.P']'
					    / function(E,attName,attVal) return selectorFunctions.hasAttValue(E,attName,attVal) end
					  )
					  +
					  ( ID *S* m.P'[' *S* m.V'CLASS' *S* m.P'~=' *S* ID *S* m.P']'
					    / function(E,attName,attVal)  return selectorFunctions.hasCommaAttValue(E,attName,attVal) end
					  )
					  +
					  ( ID *S* m.P'.' *S* m.V'CLASS'
					  	/ function(E,attVal)  return selectorFunctions.hasCommaAttValue(E,'class',attVal) end
					  )
					  +
					  ( ID *S* m.P'#' *S* ID
					    / function(E,id)  return selectorFunctions.hasAttValue(E,'id',id) end
					  )
					  +
					  ID / function(E)  return (E=='*' and selectorFunctions.universalSel()) or selectorFunctions.typeSel(E) end
	}
	return m.match(grammar, sel)
end
