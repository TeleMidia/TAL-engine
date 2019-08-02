--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require'lpeg'
local m = lpeg

local table = table
local type = type
local print = print
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local table = table
local setmetatable = setmetatable

module(... or 'Expression')

local S = m.V'SPACE'
local tName = nil
local tValue = nil
local template = nil

local grammar = {
	'INITIAL';
	SPACE		= (m.S'\n \t\r\f')^0,
	INTEGER		= m.R'09'^1,
	OP			= m.S'+-*/',
	NAME		= (m.R'AZ' + m.R'az' + m.P'_') * (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^0,
	VAR			= m.P'#'*m.C(m.V'NAME'),
	INITIAL		= ( (S * m.P'[' *S* m.Cg(m.V'PATT') *S* m.P']' * S)
				  / function (expression)
						return expression
					end),
	PATT		= (m.Cg( m.V'TERM' ) *S* (m.C(m.V'OP') *S* m.Cg( m.V'PATT' ))^0
				  / function(term, op, value)
						if op then
							
							if op == '+' then
								local number = tonumber(value)
								local term2 = tonumber(term)
								if number ~= nil and term2 ~= nil then
									return term2 + number 
								else
									return term..' '..op..' '..value
								end
							elseif op == '-' then
								local number = tonumber(value)
								local term2 = tonumber(term)
								if number ~= nil and term2 ~= nil then
									return term2 - number
								else
									return term..' '..op..' '..value
								end
							elseif op == '*' then
								local number = tonumber(value)
								local term2 = tonumber(term)
								if number ~= nil and term2 ~= nil then
									
									return term2 * number
								else
									
									return term..' '..op..' '..value
								end
							elseif op == '/' then
								local number = tonumber(value)
								local term2 = tonumber(term)
								if number ~= nil and term2 ~= nil then
									
									return term2 / number
								else
									
									return term..' '..op..' '..value
								end
							end
						end
						return term
					end),
	TERM 		= (m.C(m.V'INTEGER')
				  / function (integer)
						return integer
					end)
				+
				(m.Cg(m.V'VAR')
				  / function(varName)
					if template ~= nil then
						if template.components[varName] ~= nil then
							return #template.components[varName].nodes
						elseif template.interfaces[varName] ~= nil then
							return #template.interfaces[varName].nodes
						else
							return varName
						end
					end
				  end)
				+
				(m.C(m.V'NAME')
				  / function(name)
					if (tName ~= nil and tValue ~= nil and tName == name) then
						return tValue
					end
					return name
				  end)
}

function parse(s, name, value, temp)
	tName = name
	tValue = value
	template = temp
	return m.match(grammar, s)
end
