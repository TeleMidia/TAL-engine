--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

-----
--
-- Módulo responsável pelo controle de avisos ou mensasgens de erro
--
-----

local io      = io
local pairs   = pairs
local ipairs  = ipairs
local type    = type
local table   = table
local print   = print
local tonumber = tonumber
local tostring = tostring
local error = error

module(... or 'message')

local WARNING, ERROR, INFO = 'WARNING','ERROR', 'INFO'

local Msg = {}

local show = true

local Message = {
		txt = nil,
		msgType = nil
	}
	
function Message:new(txt, msgType)
	local o = {
		txt = txt,
		msgType = msgType
	}
	
	setmetatable(o, self)
	self.__index = self
	return o
end
	
function addMessage(txt, msgType)
	if txt and msgType  then
		if msgType == ERROR then
			showLog()
			error(txt)
		end
		table.insert(Msg, Message:new(txt, msgType))
	end
end

function showLog()
	if show then
		for _,message in ipairs(Msg) do
			print ('\t\t'..message.msgType)
			print ('\n'..message.txt..'\t\t')
		end
	end
end