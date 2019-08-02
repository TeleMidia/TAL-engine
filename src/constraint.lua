--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require 'lpeg'
require 'selector'

local m = lpeg
local selector = selector

local ipairs = ipairs
local pairs = pairs
local table = table
local tonumber = tonumber
local print = print
local error = error
local math = math

module(... or 'constraint')

local constraintFunctions = {}

function constraintFunctions.Constraint(lExpr, cmp, rExpr)
	return function (dictionary, template)
		local lVal = lExpr(dictionary, template)
		local rVal = rExpr(dictionary, template)
		
		if cmp == '==' then
			return lVal == rVal
		elseif cmp == '~=' then
			return lVal ~= rVal
		elseif cmp == '<' then
			return lVal < rVal
		elseif cmp == '>' then
			return lVal > rVal
		elseif cmp == '<=' then
			return lVal <= rVal
		elseif cmp == '>=' then
			return lVal >= rVal
		end
	end
end

function constraintFunctions.ExpressionSelector(sel)
	return function (dictionary, template)
		local l = sel(dictionary)
		
		return tonumber(#l)
	end
end

function constraintFunctions.ExpressionId(id)
	return function (dictionary, template)
		if template.components[id] then
			
			return #template.components[id].nodes
		elseif template.interfaces[id] then
			return #template.interfaces[id].nodes
		elseif template.relations[id] then
			return #template.relations[id].nodes
		end
	end
end

function constraintFunctions.ExpressionInteger(integer)
	return function (dictionary, template)
		return tonumber(integer)
	end
end

function constraintFunctions.ExpressionOperation(lExpr, op, rExpr)
	return function (dictionary, template)
		local lVal = lExpr(dictionary, template)
		local rVal = rExpr(dictionary, template)
		if op =='+' then
			return lVal + rVal
		elseif op =='-' then
			return lVal - rVal
		elseif op =='*' then
			return lVal * rVal
		elseif op =='/' then
			if rVal == 0 then error('divisão por zero') end
			return lVal / rVal
		elseif op =='^' then
			return lVal ^ rVal
		end
	end
end

-- parse
-- parameters:
--		testAttribute: string with the test attribute of an <assert>, <report> or <warning> element
-- returns:
--      constraint: posfix expressions and comparators in a table: {lVal, cmp, rVal}
--		selectors: list of selectors found on testAttribute

function parse(testAttribute)
	local S = m.V'SPACE'
	local ID = m.V'IDENTIFIER'
	local selectors = {}

	local grammar =
	{
		'initial';
		SPACE		= (m.S'\n \t\r\f')^0,
		IDENTIFIER	= m.C( (m.R'AZ' + m.R'az' + m.P'_') * (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^0 ),
		INTEGER		= m.C(m.R'09'^1),
		initial		= S* m.V'exp' *S* m.V'cmp' *S* m.V'exp' *S* -1
		              / function(lVal, cmp, rVal)
							if not lVal or not rVal then
								return nil
							end
							return constraintFunctions.Constraint(lVal, cmp, rVal)
		                end,

		exp			= ( m.V'term' * (S* m.V'operand' *S* m.V'exp')^-1 )
		              / function(T, op, E2)
							if not op then
								return T
							end
							return constraintFunctions.ExpressionOperation(T, op, E2)
		              	end,

		term		= ( m.P'(' *S* m.V'exp' *S* m.P')'
					  / function(E)
							return E
					  	end
					  )
		              +
					  ( m.V'INTEGER'
					  / function(integer)
							return constraintFunctions.ExpressionInteger(integer)
					  	end
					  )
					  +
					  ( m.P'#' * (ID + m.C(m.P'*'))
					  / function(id)
					  		return constraintFunctions.ExpressionId(id)
					  	end
					  )
					  +
					  ( m.P'#' *S* m.P'{' * m.C( (1-m.P'}')^1 ) *S* m.P'}'
					  / function(sel)
					  		local f = selector.parse(sel)
							if not f then error('Invalid selector "' .. sel .. '"') end
							return constraintFunctions.ExpressionSelector(f)
						end
					  ),

		cmp			= m.C( m.P'==' + m.P'<=' + m.P'<' + m.P'>=' + m.P'>' + m.P'~=' ), 
		operand		= m.C( m.P'+' + m.P'-' + m.P'*' + m.P'/' + m.P'^' )
	}

	local t = m.match(grammar, testAttribute)
	return t
end
