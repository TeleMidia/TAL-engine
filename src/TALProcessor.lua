--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

-----
---
-- Núcleo do programa
--
-- Processa o comando recebido e executa a ação gerando o ncl final
---
-----

require 'template'
require 'NCLCore'
require 'Classification'
require 'selector'
require 'constraint'
require 'utils'

local setmetatable = setmetatable
local print = print
local table = table
local type = type
local pairs = pairs
local ipairs = ipairs
local assert = assert

-- argumentos passados na linha de comando --
local arg = arg
local template = template
local classification = Classification

local initFile = nil
local tp = nil
local language
local inFile
local outFile


function help()
	print ('\nCommands\n\nVERSION\t\tinformações sobre a versõa do processador usada\nINPUT\t\tindica o nome do arquivo do documento de preenchimento\nOUTPUT\t\tindica o nome do arquivo a ser gerado\nLANGUAGE\tinforma a linguagem hipermídia do documento\n')
	print()
	print()
	print ('Sample:')
	print ()
	print ('lua TalProcessor.lua [[-version] | [-input "file" [-output "file"] [-language "lang"]]]')
	print ()
end

function version()
	print ('TAL Processor version "0.6"')
	print ('LAWS - Laboratory of Advanced Web Systems')
	print ("TeleMidia - Laboratorio de Sistemas Multimidia")
	print ('------')
	print ('Para ajuda use o comando --help')
end

	
if arg ~= nil and #arg ~= 0 then
	
	if arg[1] == '-version' or arg[1] == '--v' then
		
		version()
		
	elseif arg[1] == '-help' then
	
		help()
	
	else
		
		language, inFile, outFile = utils.decodeCommand(arg)
	
		local root, dic = classification.parse(inFile)
		
		local out
		
		for k,v in ipairs(dic) do
			local doc = v.root:toString()
		
			if v.templateFile then
			
				local tempPath = utils.relativeUrl(inFile, v.templateFile)
				
				local idTemplate
				
				tempPath, idTemplate = utils.templateUrlRefer(tempPath)
				
				local tempRoot = template.parse(tempPath)
				
				local filled = tempRoot:fillTemplate(v, idTemplate)
				
				--print ('dados', v, filled, root, k)
				out = NCLCore.populate(v,filled,root,'_'..k..'_')
			
			end
		end
		
		if outFile then
			if out then
				utils.saveToFile(outFile, out)
			end
			print ()
			print ()
			print ('===Documento gerado com sucesso===')
			print ('documento salvo para: '..outFile)
			print ()
			print ()
		else
			print (out, 'no outFile')
		end
	
	end
	
	
	
else
	
	version()
	
end


