--[[

LICENSE

Copyright (c) 2012 LAWS – Laboratory of Advanced Web Systems
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, IN-CLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTH-ERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-INGS IN THE SOFTWARE.


--]]

require'lpeg'
local m = lpeg

require 'DataModel'
local Node = DataModel.Node
local TextNode = DataModel.TextNode

local table = table
local type = type
local print = print
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local table = table
local setmetatable = setmetatable

module(... or 'Connector')

local S = m.V'SPACE'

local grammar = {
	'INITIAL';
	SPACE		= (m.S'\n \t\r\f')^0,
	INTEGER		= m.R'09'^1,
	INITIAL		= ( S * m.Ct(( m.Cg(m.V'PATT') *S )^1)
				  / function (conn)
						return conn
					end),
	PATT		= (m.Cg( m.V'CONDLIST' ) *S* m.P'then' *S* m.Cg( m.V'ACTIONLIST' ) *S* m.P'end'
				  / function(conditions, actions)
						
						if conditions and type(conditions) == 'table' then
							local relation = nil
							relation = Node:new('relation', {[1]='id', id=''})
							local condition = Node:new('conditions', {})
							relation:addChild(condition)
							
							condition:addChild(conditions)
							
							local action = Node:new('actions', {})
							relation:addChild(action)
							
							action:addChild(actions)
							
						
							return relation
						end
						return nil
					end
					),
	CONDLIST 	= (( m.P'(' *S* m.Cg( m.V'CONDLIST' ) *S* m.P')' *S* m.Cg( m.V'WITHPARAM' ) *S* ( m.Ct( m.C(m.V'LOP') ) *S* m.Ct( m.V'CONDLIST' ) )^0 
					/ function (lCond, params, op, rCond)
						
						if params and type(params) == 'table' then
							lCond:addChild(params)
						end
						
						if op and type(op) == 'table' then
							local conditions = {}
							table.insert(conditions,lCond)
							
							for _,v in ipairs(rCond) do
								table.insert(conditions, v)
							end
							
							local cond = conditions[#conditions]
							table.remove(conditions)
							while #conditions > 0 do
								local aux = conditions[#conditions]
								table.remove(conditions)
								if cond.name == 'condition' then
									if aux.name == 'condition' then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] == op[#op] then
										aux:addChild(cond)
										cond = aux
									elseif aux.name == 'condList' and aux.atts['operand'] ~= op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									end
								elseif cond.name == 'condList' and cond.atts['operand'] == op[#op] then
									if aux.name == 'condition' then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										for _,c in ipairs(cond.child) do
											temp:addChild(c)
										end
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] == op[#op] then
										for _,c in ipairs(cond.child) do
											aux:addChild(c)
										end
										cond = aux
									elseif aux.name == 'condList' and aux.atts['operand'] ~= op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										for _,c in ipairs(cond.child) do
											temp:addChild(c)
										end
										cond = temp
									end
								elseif cond.name == 'condList' and cond.atts['operand'] ~= op[#op] then
									if aux.name == 'condition' then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] == op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										for _,c in ipairs(aux.child) do
											temp:addChild(c)
										end
										temp:addChild(cond)
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] ~= op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									end
								end
								table.remove(op)
							end
							return cond
						else
							return lCond
						end
					  end
					)
					+
					( m.Cg( m.V'CONDITION' ) * ( S* m.Ct( m.C(m.V'LOP') ) *S* m.Ct( m.V'CONDLIST' ) )^0 
					/ function (condition, op, condList) 
						
					
						if op and type(op) == 'table' then
							local conditions = {}
							table.insert(conditions,condition)
							for _,v in ipairs(condList) do
								table.insert(conditions, v)
							end
							
							local cond = conditions[#conditions]
							table.remove(conditions)
							while #conditions > 0 do
								local aux = conditions[#conditions]
								table.remove(conditions)
								if cond.name == 'condition' then
									if aux.name == 'condition' then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] == op[#op] then
										aux:addChild(cond)
										cond = aux
									elseif aux.name == 'condList' and aux.atts['operand'] ~= op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									end
								elseif cond.name == 'condList' and cond.atts['operand'] == op[#op] then
									if aux.name == 'condition' then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										for _,c in ipairs(cond.child) do
											temp:addChild(c)
										end
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] == op[#op] then
										for _,c in ipairs(cond.child) do
											aux:addChild(c)
										end
										cond = aux
									elseif aux.name == 'condList' and aux.atts['operand'] ~= op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										for _,c in ipairs(cond.child) do
											temp:addChild(c)
										end
										cond = temp
									end
								elseif cond.name == 'condList' and cond.atts['operand'] ~= op[#op] then
									if aux.name == 'condition' then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] == op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										for _,c in ipairs(aux.child) do
											temp:addChild(c)
										end
										temp:addChild(cond)
										cond = temp
									elseif aux.name == 'condList' and aux.atts['operand'] ~= op[#op] then
										temp = Node:new('condList', {[1]='operand', operand = op[#op]})
										temp:addChild(aux)
										temp:addChild(cond)
										cond = temp
									end
								end
								table.remove(op)
							end
						
							return cond
						else
						
							return condition
						end
					  end
					)),
	CONDITION	= (	( m.C( m.P'onBeginAttribution' +  m.P'onBegin' + m.P'onEndAttribution' + m.P'onEnd' + m.P'onPause' + m.P'onResume' + m.P'onAbort' + m.P'onSelection' ) *S* m.Cg( m.V'PERSPECTIVE' ) *S* m.Cg( m.V'WITHPARAM' )
					/ function (cond, persp, params) 
						
						local condition = Node:new('condition',{[1] = 'name', [2] = 'refer', name=cond, refer=persp})
						if params and type(params) == 'table' then
							condition:addChild(params)
						end
						
						return condition
					end ) 
					+ 
					(( m.Cg( m.V'ASSESSMENT' ) *S* m.Cg( m.V'WITHPARAM' ) ) 
					/ function (assessmt, params) 
						
						local condition = Node:new('condition', {})
						condition:addChild(assessmt)
						if params and type(params) == 'table' then
							condition:addChild(params)
						end
						return condition
					end)),
	ASSESSMENT	= (m.Cg( m.V'ASSESEXPR' ) *S* m.C( m.V'CMP' ) *S* m.Cg( m.V'ASSESEXPR' )
					/ function (lexp, cmp, rexp)
						
						if cmp == '==' then
							cmp = 'eq'
						elseif cmp == '>=' then
							cmp = 'gte'
						elseif cmp == '<=' then
							cmp = 'lte'
						elseif cmp == '>' then
							cmp = 'gt'
						elseif cmp == '<' then
							cmp = 'lt'
						elseif cmp == '~=' then
							cmp = 'ne'
						end
						local ass = Node:new('assessmt',{[1]='operand', operand=cmp})
						ass:addChild(lexp)
						ass:addChild(rexp)
						return ass
					end),
	ASSESEXPR	= (( m.Cg( m.V'PERSPECTIVE' ) *S* ( m.P'+' *S* m.Cg( m.V'STRING' ) )^-1 
					/ function (id, str)
						local expr = Node:new('expression',{})
						local term = Node:new('term',{[1]='type',[2]='value',type='refer', value=id})
						expr:addChild(term)
						if str ~= nil then
							term = Node:new('term',{[1]='type',[2]='value',type='string', value=str})
							expr:addChild(term)
						end
						return expr
					end
					) 
					+ 
					( m.Cg(m.V'STRING') *S* ( m.P'+' *S* m.Cg(m.V'PERSPECTIVE') )^-1
					/ function (str, id)
						
						local expr = Node:new('expression',{})
						local term = Node:new('term',{[1]='type',[2]='value',type='string', value=str})
						expr:addChild(term)
						
						if id ~= nil then
							term = Node:new('term',{[1]='type',[2]='value',type='refer', value=id})
							expr:addChild(term)
						end
						
						return expr
					end
					)),
	PERSPECTIVE	= ( m.C(m.V'IDREF') * ( m.P'.' * m.C(m.V'IDREF') )^-1
					/ function (id, subId)
						
						local persp = id
						if subId and type(subId) == 'table' then
							persp = persp..'.'..subId
						end
						return persp
					end),
	IDREF		= m.V'NAME' * ( m.P'[' * m.C( (1-m.P']')^1 ) * m.P']' )^-1,
	NAME		= (m.R'AZ' + m.R'az' + m.P'_') * (m.R'AZ' + m.R'az' + m.R'09' + m.P'_')^0,
	ACTION      = (( m.C( m.P'start' + m.P'stop' + m.P'pause' + m.P'resume' + m.P'abort' ) *S* m.Cg( m.V'PERSPECTIVE' ) *S* m.Cg( m.V'WITHPARAM')
					/ function (action, persp, params)
						
						local act = Node:new('action',{[1] = 'name', [2] = 'refer', name=action, refer=persp})
						if params and type(params) =='table' then
							act:addChild(params)
						end
						return act
					end
					) 
					+ 
					( m.P'set' *S* m.Cg( m.V'PERSPECTIVE' ) *S* m.P'=' *S* m.Cg( m.V'STRING' ) *S* m.Cg( m.V'WITHPARAM' )
					/ function (persp , value , params)
						
						local act = Node:new('action',{[1] = 'name', [2] = 'refer', [3] = 'value', name='set', refer=persp, value=value})
						if params and type(params) =='table' then
							act:addChild(params)
						end
						return act
					end
					)
					+
					( m.P'set' *S* m.Cg( m.V'PERSPECTIVE' ) *S* m.P'=' *S* m.Cg( m.V'PERSPECTIVE' ) *S* m.Cg( m.V'WITHPARAM' )
					/ function (lid , rid , params)
						
						local act = Node:new('action',{[1] = 'name', [2] = 'refer', name='set', refer=lid..', '..rid})
						if params and type(params) =='table' then
							act:addChild(params)
						end
						return act
					end
					)),
	ACTIONLIST	= (( m.P'(' *S* m.Cg( m.V'ACTIONLIST' ) *S* m.P')' *S* m.Cg( m.V'WITHPARAM' ) *S* ( m.Ct( m.C(m.V'AOP') ) *S* m.Ct( m.V'ACTIONLIST' ) )^0 
					/ function (lalist, params, op, ralist)
						
						local action = lalist
						
						if params and type(params) == 'table' then
							for _,v in ipairs(params) do
								action:addChild(v)
							end
						end						
						
						if op and type(op) == 'table' then
							for _, act in ipairs(ralist) do
								local operand = 'seq'
								if op[1] == '||' then
									operand = 'par'
								end
								table.remove(op, 1)
								
								local temp = Node:new('actionList', {[1] = 'operand', operand = operand})
								temp:addChild(action)
								if (act.name == 'actionList' and act.atts.operand ~= operand) or act.name == 'action' then
									temp:addChild(act)
								else
						
									for _,v in ipairs(act.child) do
										temp:addChild(v)
									end
								end
								action = temp
							end
						end
						
						return action
					end
					) 
					+ 
					( m.Cg( m.V'ACTION' ) *S* ( m.Ct( m.C(m.V'AOP') ) *S* m.Ct( m.V'ACTIONLIST' ) )^0 
					/ function (action, op, alist)
						
						local actionList = action
						if op and type(op) == 'table' then
							
							for _,act in ipairs(alist) do
								if act.name == 'action'  and actionList.name == 'action' then
									local operand = 'seq'
									if op[1] == '||' then
										operand = 'par'
									end
									table.remove(op, 1)
									local temp = Node:new('actionList', {[1] = 'operand', operand = operand})
									temp:addChild(actionList)
									temp:addChild(act)
									actionList = temp
								elseif act.name == 'actionList' and actionList.name == 'action' then
									local operand = 'seq'
									if op[1] == '||' then
										operand = 'par'
									end
									table.remove(op, 1)
									local temp = Node:new('actionList', {[1] = 'operand', operand = operand})
									if operand == act.atts.operand then
										temp:addChild(actionList)
										for _,v in ipairs(act.child) do
											temp:addChild(v)
										end
										actionList = temp
									else
										temp:addChild(actionList)
										temp:addChild(act)
										actionList = temp
									end
								elseif act.name == 'action' and actionList.name == 'actionList' then
									local operand = 'seq'
									if op[1] == '||' then
										operand = 'par'
									end
									table.remove(op, 1)
									if operand == actionList.atts.operand then
										actionList:addChild(act)
									else
										local temp = Node:new('actionList', {[1] = 'operand', operand = operand})
										temp:addChild(actionList)
										temp:addChild(act)
										actionList = temp
									end
								elseif act.name == 'actionList' and actionList.name == 'actionList' then
									local operand = 'seq'
									if op[1] == '||' then
										operand = 'par'
									end
									table.remove(op, 1)
									if operand ~= actionList.atts.operand then
										local temp = Node:new('actionList', {[1] = 'operand', operand = operand})
										temp:addChild(actionList)
										actionList = temp
									end
									
									if operand == act.atts.operand then
										for _,v in ipairs(act.child) do
											actionList:addChild(v)
										end
									else
										actionList:addChild(act)
									end
								end
								
							end
							
						end
						
						return actionList
					end
					)),
	WITHPARAM	=  (( m.P'with' *S* m.Cg( m.V'PARAMETER' ) *S* ( m.P',' *S* m.Ct(m.V'PARAMETER') )^0)^-1
					/ function (lparam, rparam)
						
						if lparam and type(lparam) == 'table' then
							if rparam and type(rparam) == 'table' then
								local parans = Node:new('parans',{})
								parans:addChild(lparam)
								
								for _,v in ipairs(rparam) do
									parans:addChild(v)
								end
								
								return parans
							else
								local parans = Node:new('parans',{})
								parans:addChild(lparam)
								
								return parans
							end
						end
						return nil
					end
					),
	PARAMETER	= ( m.C( m.V'IDREF' ) *S* m.P'=' *S* m.Cg( m.V'STRING') 
					/ function (name, value)
						
						
						local param = Node:new('param',{[1] = 'name', [2] = 'value', name = name, value= value})
						
						return param
					end ),
	CMP         = m.P'==' + m.P'~=' + m.P'>=' + m.P'<=' + m.P'>' + m.P'<',
	STRING		= ( m.P"'" * m.C((1-m.P"'")^1) * m.P"'" ) / function (str) return str end + ( m.P'"' * m.C((1-m.P'"')^1) * m.P'"' ) / function (str)  return str end,
	LOP 		= m.P'and' + m.P'or' ,
	AOP 		= m.P'||' + (m.P';')^-1
}

function parse(s)
	return m.match(grammar, s)
end
