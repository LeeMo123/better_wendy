-- 获取角色特定的药剂提示字符串
local function GetElixirAnnounceString(doer, announce_type)
    -- announce_type 例如："ANNOUNCE_ELIXIR_TOO_SUPER", "ANNOUNCE_ELIXIR_NO_ELIXIRABLE" 等
    
    if not doer or not announce_type then
        return nil
    end
    
    local prefab = doer.prefab
    if not prefab then
        return nil
    end
    
    local prefix = string.upper(prefab)
    
    -- 尝试获取角色特定的字符串
    local str = STRINGS.CHARACTERS[prefix] and STRINGS.CHARACTERS[prefix][announce_type]
    
    -- 如果角色特定字符串不存在，返回通用字符串
    return str or (STRINGS.CHARACTERS.GENERIC and STRINGS.CHARACTERS.GENERIC[announce_type])
end

-- 使用示例
local function AnnounceTooSuper(doer)
    local str = GetElixirAnnounceString(doer, "ANNOUNCE_ELIXIR_TOO_SUPER")
    
    if doer and doer.components.talker and str then
        doer.components.talker:Say(str)
    end
end

local wendy_actions =
{
    {
        id = "GRAVEDIGIN",
        str = STRINGS.ACTIONS.GRAVEDIG, -- "请君入瓮"
        fn = function(act)
            if act.doer and act.doer:HasTag("ghostlyfriend") 
            and act.invobject and act.invobject.prefab == "graveurn" 
            and act.invobject.components.finiteuses.current < act.invobject.components.finiteuses.total
            and act.target and act.target:IsValid() 
            and (act.target.prefab == "graveguard_ghost" or act.target.prefab == "ghost") then
                -- 移除鬼魂
                act.target:OnDismiss()

                -- 添加骨灰罐耐久
                local invobject = act.invobject.components.finiteuses
                invobject:Repair(1)
                return true
            end
        end,
        state = "domediumaction",
		actiondata = {
            priority = 10, --99999,
			mount_valid = true,
		},
		canqueuer = "allclick",--兼容排队论
    },
    {
        id = "GRAVEDIGOUT",
        str = STRINGS.ACTIONS.DROP.FREESOUL, -- "请君出瓮"
        fn = function(act)
            if act.doer and act.doer:HasTag("ghostlyfriend") 
                and act.invobject and act.invobject.prefab == "graveurn" 
                and act.invobject.components.finiteuses and act.invobject.components.finiteuses.current > 0 then
    
                -- 获取骨灰罐当前耐久度
                local current_durability = act.invobject.components.finiteuses.current
                -- 生成对应数量鬼魂
                for i = 1, current_durability do
                    local ghost = SpawnPrefab("ghost")
                    if ghost then
                        local base_angle = (i-1) * (2*PI/current_durability) -- 圆周均匀分布
                        local radius = 1.5 -- 生成半径
                        local offset = Vector3(math.cos(base_angle)*radius, 0, math.sin(base_angle)*radius)
                        ghost.Transform:SetPosition((act.doer:GetPosition() + offset):Get())
                        ghost.sg:GoToState("appear")

                        -- 召唤
                        ghost:OnSummons(act.doer)
                    end
                end

                -- 清空骨灰罐耐久
                act.invobject.components.finiteuses:SetUses(0)
                                
                return true
            end
        end,
        state = "graveurn_in",
		actiondata = {
            priority = 10, --99999,
			mount_valid=true,
		},
		-- canqueuer = "allclick",-- 不兼容排队论
    },
    {
        id = "GRAVESTONEDIG",
        str = STRINGS.ACTIONS.DEPLOY.GRAVEPLANT, -- 墓碑移除
        fn = function(act)
            local success, reason = false, nil
            local tool = success

            local target = act.target
            if target and target.components.gravediggable and act.doer and act.doer:HasTag("gravedigger_user") then

                success, reason = target.components.gravediggable:DigUp(tool, act.doer)
            end

            return success, reason
        end,
        state = "dolongestaction",
		actiondata = {
            priority = 10, --99999,
			mount_valid = true,
		},
		canqueuer = "rightclick",-- 兼容排队论
    },
    {
        id = "GETGGHOSTLYELIXIR",
        str = STRINGS.ACTIONS.HARVEST, -- 获取药剂
        fn = function(act)
            if act.doer and act.target then
                -- 洞穴里无法使用
                if TheWorld:HasTag("cave") then
                    act.doer.components.talker:Say(STRINGS.CHARACTERS.WILLOW.DESCRIBE.MOONDIAL.CAVE)
                    return
                end

                if TheWorld.state.isnight then
                    local moonstate = TheWorld.state.isnewmoon and "new" or TheWorld.state.isfullmoon and "full" or nil
                    if moonstate ~= nil and not act.doer.hadgetghostlyelixi then
                        act.doer.components.inventory:GiveItem(moonstate == "new" and SpawnPrefab("ghostlyelixir_shadow") or SpawnPrefab("ghostlyelixir_lunar"), nil, act.target:GetPosition())
                        act.doer.hadgetghostlyelixi = act.doer:DoTaskInTime(60*5, function()      -- cd一天
                            -- act.doer.hadgetghostlyelixi:Cancel()
                            act.doer.hadgetghostlyelixi = nil
                        end)
                    else
                        act.doer.components.talker:Say(STRINGS.CHARACTERS.WANDA.ACTIONFAIL.CHANGEIN.GENERIC)
                    end
                else
                    act.doer.components.talker:Say(STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.OCEANFISHINGLURE_SPINNER_BLUE)
                end
            end
            return true
        end,
        state = "dolongaction",
		actiondata = {
            priority = 10, --99999,
			mount_valid = true,
		},
		-- canqueuer = "allclick",-- 不兼容排队论
    },
    {
        id = "CANAPPLYELIXIR",  -- "使用药剂"
        str = STRINGS.UI.BROADCASTING.APPLY,
        fn = function(act)
            local object = act.invobject
            local doer = act.doer
            if doer and doer:HasTag("ghost_ally") and object and object.components.ghostlyelixir ~= nil then
                if object:HasTag("super_elixir") then
                    return false
                else
                    object.components.ghostlyelixir:Apply(doer, doer)
                    return true
                end                
            end
        end,
        state = "drinkelixir",
		actiondata = {
            priority = 15, --99999,
			mount_valid = true,
		},
		-- canqueuer = "allclick",-- 不兼容排队论
    },
    {
        id = "DOAPPLYELIXIR",   -- "使用药剂"
        str = STRINGS.UI.BROADCASTING.APPLY,
        fn = function(act)
            local object = act.invobject
            local target = act.target
            local doer = act.doer
            if doer and doer:HasTag("elixirbrewer") and object and object.components.ghostlyelixir ~= nil and target and target:HasTag("ghostlyelixirable") then
                object.components.ghostlyelixir:Apply(doer, target)
                -- return true
            end
            return true
        end,
        state = "dolongaction",
		actiondata = {
            priority = 10, --99999,
			mount_valid = true,
		},
		-- canqueuer = "allclick",-- 不兼容排队论
    },
}

--动作与组件绑定
local component_actions  = {
    {
        type = "USEITEM",
        component = "inventoryitem",
        tests = {
			{
				action = "GRAVEDIGIN", -- 请君入瓮
				testfn = function(inst, doer, target, actions, right)
					return inst.prefab == "graveurn" and (target.prefab == "graveguard_ghost" or target.prefab == "ghost") 
				end,
			},
			{
				action = "DOAPPLYELIXIR", -- 阿比盖尔/阿比盖尔之花 上药剂
				testfn = function(inst, doer, target, actions, right)
					return doer:HasTag("elixirbrewer") and inst:HasTag("ghostlyelixir") and target:HasTag("ghostlyelixirable")
				end,
			},
        },
    },
    {
        type = "INVENTORY",
        component = "inventoryitem",
        tests = {
			{
				action = "GRAVEDIGOUT", -- 请君出瓮
				testfn = function(inst, doer, target, actions, right)
					return doer:HasTag("ghostlyfriend") and inst.prefab == "graveurn" and not inst:HasTag("usesdepleted")
				end,
			},
			{
				action = "CANAPPLYELIXIR", -- 右键喝药剂药剂
				testfn = function(inst, doer, target, actions, right)
                    if doer:HasTag("ghost_ally") and inst and inst.prefab and string.find(inst.prefab, "ghostlyelixir_") ~= nil then
                        return true
                    end
				end,
			},
        },
    },
    {
        type = "SCENE",
        component = "gravediggable",
        tests = {
			{
				action = "GRAVESTONEDIG", -- 墓碑移除
				testfn = function(inst, doer, actions, right)
					return right and doer:HasTag("player") and doer:HasTag("gravedigger_user") and inst ~= nil and inst.prefab == "gravestone" and inst:HasTag("gravediggable") 
				end,
			},
        },
    },
    {
        type = "SCENE",
        component = "workable",
        tests = {
			{
				action = "GETGGHOSTLYELIXIR", -- 获取药剂
				testfn = function(inst, doer, actions, right)
					return right and inst ~= nil and inst.prefab == "moondial" and doer and
                        doer.components.skilltreeupdater and (doer.components.skilltreeupdater:IsActivated("wendy_lunar_3") or doer.components.skilltreeupdater:IsActivated("wendy_shadow_3") )
				end,
			}
        },
    },
}



return {
	actions = wendy_actions,
	component_actions = component_actions
}