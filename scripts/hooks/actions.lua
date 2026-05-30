-----------------
-- 重写官方旧动作
-----------------
-- 喝药
-- local _actions = GLOBAL.ACTIONS
-- local function find_elixirable_fn(item) return item.components.ghostlyelixirable ~= nil end
-- _actions.APPLYELIXIR.fn = function(act)
--     local doer = act.doer
--     local object = act.invobject
--     local hat = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
--     if doer and object and doer.components.inventory then
--         local elixirable_item = doer.components.inventory:FindItem(find_elixirable_fn)

--         if hat.prefab == "ghostflowerhat" and not elixirable_item then
--             if object:HasTag("super_elixir") then
--                 return false, "TOO_SUPER"
--             else
--                 object.components.ghostlyelixir:Apply(doer, hat)
--                 return true
--             end
--         else
--             if elixirable_item then
--                 return object.components.ghostlyelixir:Apply(doer, elixirable_item)
--             else
--                 return false, "NO_ELIXIRABLE"
--             end
--         end
--     end
-- end


-----------------
-- 添加自定义动作
-----------------
local queueractlist={}--可兼容排队论的动作
local actions_status,actions_data = pcall(require,"wendy_actions")

if actions_status then
    -- 导入自定义动作
    if actions_data.actions then
        for _,act in pairs(actions_data.actions) do
            local action = AddAction(act.id,act.str,act.fn)
            if act.actiondata then
                for k,data in pairs(act.actiondata) do
                    action[k] = data
                end
            end
			--兼容排队论
			if act.canqueuer then
				queueractlist[act.id]=act.canqueuer
				-- table.insert(queueractlist,act.id)
			end
			if not act.nobind then
				AddStategraphActionHandler("wilson",GLOBAL.ActionHandler(action, act.state))
            	AddStategraphActionHandler("wilson_client",GLOBAL.ActionHandler(action,act.state))
			end
        end
    end
    -- 导入动作与组件的绑定
    if actions_data.component_actions then
        for _,v in pairs(actions_data.component_actions) do
            local testfn = function(...)
                local rank = v.type=="POINT" and -3 or -2
				local actions = GLOBAL.select (rank,...)
                for _,data in pairs(v.tests) do
                    if data and data.testfn and data.testfn(...) then
                        data.action = string.upper( data.action )
                        table.insert( actions, GLOBAL.ACTIONS[data.action] )
                    end
                end
            end
            AddComponentAction(v.type, v.component, testfn)
        end
    end
end

--动作兼容行为排队论
local actionqueuer_status,actionqueuer_data = pcall(require,"components/actionqueuer")
if actionqueuer_status then
	if AddActionQueuerAction and next(queueractlist) then
    	for k,v in pairs(queueractlist) do
    		AddActionQueuerAction(v,k,true)
    	end
    end
end