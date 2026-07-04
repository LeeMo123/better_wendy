local function light_add(inst, time)
    inst._light = SpawnPrefab("lanternlight")
    inst._light.Light:SetIntensity(.8)
    inst._light.Light:SetRadius(inst:HasTag("abigail") and 7 or 4.5)
    inst._light.Light:SetFalloff(.9)

    inst._light.entity:SetParent(inst.entity)

    if inst:HasTag("abigail") then
        if inst.components.follower and inst.components.follower.leader then 
            inst.components.follower.leader.components.talker:Say(GetString(inst, "ANNOUNCE_ENTER_DARK"))
        end
    elseif inst:HasTag("player") then
        inst:DoTaskInTime(time - 10,function()
            if inst.components.talker ~= nil then
                inst.components.talker:Say(GetString(inst, "ANNOUNCE_ENTER_DARK"))
            end
        end)
    end    
end

local function light_remove(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
end

local potion_tunings =
{
	ghostlyelixir_light =
	{
		DURATION = TUNING.GHOSTLYELIXIR_LIGHT_DURATION,
		ONAPPLY = function(inst, target)
            light_add(target, TUNING.GHOSTLYELIXIR_LIGHT_DURATION)
            -- target.
		end,
		ONDETACH = function(inst, target)
            light_remove(target)
		end,
        FLOATER = {"small", 0.2, 0.4},
		fx = "ghostlyelixir_light_fx",
		dripfx = "ghostlyelixir_light_dripfx",
		skill_modifier_long_duration = true,

		--PLAYER CONTENT
		DURATION_PLAYER = TUNING.GHOSTLYELIXIR_PLAYER_LIGHT_DURATION,
		ONAPPLY_PLAYER = function(inst, target)
            light_add(target, TUNING.GHOSTLYELIXIR_PLAYER_LIGHT_DURATION)
		end,
		ONDETACH_PLAYER = function(inst, target)
            light_remove(target)
		end,
		fx_player = "ghostlyelixir_player_light_fx",
		dripfx_player = "ghostlyelixir_player_light_dripfx",
	},
}

-- buff type 获取
local function GetBufftype(inst, target)
    local elixirbuff = target:GetDebuff("elixir_buff")
    local elixirextrabuff = target:GetDebuff("elixir_extra_buff")

    local has_skill = false
    if target.components.skilltreeupdater and target.components.skilltreeupdater:IsActivated("wendy_potion_yield") then
        has_skill = true
    elseif target._playerlink and target._playerlink.components.skilltreeupdater and target._playerlink.components.skilltreeupdater:IsActivated("wendy_potion_yield") then
        has_skill = true
    end

    print("has_skill", has_skill)
    print("is attack_buff", inst.buff_prefab == "ghostlyelixir_attack_buff")
    print("elixirbuff", elixirbuff and elixirbuff.prefab == inst.buff_prefab)

    if  elixirbuff == nil                                                       -- 当前作用对象没有上任何buff       
        or not has_skill                                                        -- 当前作用对象没有技能   
        or inst.buff_prefab == "ghostlyelixir_attack_buff"                      -- 当前作用对象已经上了攻击药剂
        or (elixirbuff and elixirbuff.prefab == inst.buff_prefab) 
    then                                                                        -- 当前作用对象已经上了同药剂
        return "elixir_buff"
    end

    if not elixirextrabuff                                                      -- 当前作用对象没有占用elixir_extra_buff
        or elixirbuff.prefab == inst.buff_prefab                                -- 同药剂替换2 
    then 
        return "elixir_extra_buff" 
    end                 

    local shield = inst.potion_tunings.shield_prefab        -- 如果是护盾药剂时特殊处理；
    if shield then                                          -- 两种护盾是上/下位药剂，优先相互替换
        if elixirbuff.potion_tunings.shield_prefab then return "elixir_buff" end
        if elixirextrabuff.potion_tunings.shield_prefab then return "elixir_extra_buff" end
    end

    -- 否则替换当前剩余时间短的药剂buff
    return elixirbuff.components.timer:GetTimeLeft("decay") < elixirextrabuff.components.timer:GetTimeLeft("decay") and "elixir_buff" or "elixir_extra_buff"
end

-- 所有药剂种类
-- TUNING.GHOSTLYELIXIRS
local function Doapplyelixer(inst, giver, target)
    -- 位面药剂和两种治疗药剂独立出来
    local buff_type = inst.potion_tunings.super_elixir and "super_elixir_buff" or inst.potion_tunings.ghostly_healing and "ghostly_healing_buff" or nil

    -- 获取buff类型
    if buff_type == nil then
        buff_type = GetBufftype(inst, target)
    end

    local buff = target:AddDebuff(buff_type, inst.buff_prefab, nil, nil, function()
        local cur_buff = target:GetDebuff(buff_type)
        if cur_buff ~= nil and cur_buff.prefab ~= inst.buff_prefab then
            target:RemoveDebuff(buff_type)
        end
    end)

    if buff ~= nil then
        local new_buff = target:GetDebuff(buff_type)
        new_buff:buff_skill_modifier_fn(giver, target)
        return buff
    end
end

local function potion_fn(anim, potion_tunings, buff_prefab)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ghostly_elixirs")
    inst.AnimState:SetBuild("ghostly_elixirs")
    inst.AnimState:PlayAnimation(anim)
    inst.scrapbook_anim = anim
    inst.scrapbook_specialinfo = "GHOSTLYELIXER".. string.upper(anim)
    inst.elixir_buff_type = anim

    if potion_tunings.FLOATER ~= nil then
        MakeInventoryFloatable(inst, potion_tunings.FLOATER[1], potion_tunings.FLOATER[2], potion_tunings.FLOATER[3])
    else
        MakeInventoryFloatable(inst)
    end

	inst:AddTag("ghostlyelixir")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

	inst.buff_prefab = buff_prefab
	inst.potion_tunings = potion_tunings

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "ghostlyelixir_"..anim
	inst.components.inventoryitem.atlasname = "images/inventoryimages/ghostlyelixir_".. anim..".xml" 

    inst:AddComponent("stackable")

    inst:AddComponent("ghostlyelixir")
	inst.components.ghostlyelixir.doapplyelixerfn = Doapplyelixer

    -- Players can haunt the speed potion to get a temporary speed boost.
    -- Shh it's a secret.
	MakeHauntableLaunch(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    return inst
end

local function buff_OnTick(inst, target)
    if target.components.health ~= nil and not target.components.health:IsDead() then
		if target:HasTag("player") then
			inst.potion_tunings.TICK_FN_PLAYER(inst, target)
		else
			inst.potion_tunings.TICK_FN(inst, target)
		end
    else
        inst.components.debuff:Stop()
    end
end

local function buff_DripFx(inst, target)
	local prefab = (target:HasTag("player") and inst.potion_tunings.dripfx_player) or inst.potion_tunings.dripfx

    if not target.inlimbo and not target.sg:HasStateTag("busy") then
		SpawnPrefab(prefab).Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function buff_OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0) --in case of loading

	if target:HasTag("player") then
		if inst.potion_tunings.ONAPPLY_PLAYER ~= nil then
			inst.potion_tunings.ONAPPLY_PLAYER(inst, target)
		end
	else
		if inst.potion_tunings.ONAPPLY ~= nil then
			inst.potion_tunings.ONAPPLY(inst, target)
		end
	end

	if inst.potion_tunings.TICK_RATE ~= nil then
	    inst.task = inst:DoPeriodicTask(inst.potion_tunings.TICK_RATE, buff_OnTick, nil, target)
	end

    inst.driptask = inst:DoPeriodicTask(TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY, buff_DripFx, TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY * 0.25, target)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)

	if inst.potion_tunings.fx ~= nil and not target.inlimbo then
		local fx = SpawnPrefab((target:HasTag("player") and inst.potion_tunings.fx_player) or inst.potion_tunings.fx)
	    fx.entity:SetParent(target.entity)
	end
end

local function buff_OnTimerDone(inst, data)
    if data.name == "decay" then
        inst.components.debuff:Stop()
    end
end

local function buff_OnExtended(inst, target)
	local duration = (target:HasTag("player") and inst.potion_tunings.DURATION_PLAYER) or inst.potion_tunings.DURATION

    if inst.duration_extended_by_skill then
		duration = duration * inst.duration_extended_by_skill
    end

	inst.components.timer:StopTimer("decay")
	inst.components.timer:StartTimer("decay", duration)

	if inst.task ~= nil then
		inst.task:Cancel()
		inst.task = inst:DoPeriodicTask(inst.potion_tunings.TICK_RATE, buff_OnTick, nil, target)
	end

	if inst.potion_tunings.fx ~= nil and not target.inlimbo and not target:HasTag("player") then
		local fx = SpawnPrefab(inst.potion_tunings.fx)
	    fx.entity:SetParent(target.entity)
	end

	inst.slowed = nil
end

local function buff_OnDetached(inst, target)
	if inst.task ~= nil then
		inst.task:Cancel()
		inst.task = nil
	end
	if inst.driptask ~= nil then
		inst.driptask:Cancel()
		inst.driptask = nil
	end

	if target:HasTag("player") then
		if inst.potion_tunings.ONDETACH_PLAYER ~= nil then
			inst.potion_tunings.ONDETACH_PLAYER(inst, target)
		end
	else
		if inst.potion_tunings.ONDETACH ~= nil then
			inst.potion_tunings.ONDETACH(inst, target)
		end
	end
	inst:Remove()
end

local function buff_skill_modifier_fn(inst,doer,target)
	local duration_mult = 1

	if inst.potion_tunings.skill_modifier_long_duration and doer.components.skilltreeupdater:IsActivated("wendy_potion_duration") then
		duration_mult = duration_mult + TUNING.SKILLS.WENDY.POTION_DURATION_MOD
		inst.duration_extended_by_skill = TUNING.SKILLS.WENDY.POTION_DURATION_MOD
	end

	local duration = (target:HasTag("player") and inst.potion_tunings.DURATION_PLAYER) or inst.potion_tunings.DURATION
    inst.components.timer:StopTimer("decay")
    inst.components.timer:StartTimer("decay", duration * duration_mult )

	if target:HasTag("ghost") then
		target:updatehealingbuffs()
	end
end

local function buff_fn(tunings, dodelta_fn)
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.buff_skill_modifier_fn = buff_skill_modifier_fn
    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

	inst.potion_tunings = tunings

    inst:AddTag("CLASSIFIED")

    local debuff = inst:AddComponent("debuff")
    debuff:SetAttachedFn(buff_OnAttached)
    debuff:SetDetachedFn(buff_OnDetached)
    debuff:SetExtendedFn(buff_OnExtended)
    debuff.keepondespawn = true

    local timer = inst:AddComponent("timer")
    timer:StartTimer("decay", tunings.DURATION)
    inst:ListenForEvent("timerdone", buff_OnTimerDone)

    return inst
end

local function AddPotion(potions, name, anim)
	local potion_prefab = "ghostlyelixir_"..name
	local buff_prefab = potion_prefab.."_buff"

	local assets = 	{
		Asset("ANIM", "anim/ghostly_elixirs.zip"),
		Asset("ANIM", "anim/abigail_buff_drip.zip"),
		Asset("ANIM", "anim/player_elixir_buff_drip.zip"),
		Asset("ANIM", "anim/player_vial_fx.zip"),
		Asset("ANIM", "anim/abigail_vial_fx.zip"),

		Asset("ATLAS", "images/inventoryimages/ghostlyelixir_"..name..".xml"),
		Asset("IMAGE", "images/inventoryimages/ghostlyelixir_"..name..".tex"),
	}

	local prefabs = {
		buff_prefab,
		potion_tunings[potion_prefab].fx,
		potion_tunings[potion_prefab].dripfx,
		potion_tunings[potion_prefab].fx_player,
		potion_tunings[potion_prefab].dripfx_player,
		"ghostvision_buff",
	}

	local function _buff_fn() return buff_fn(potion_tunings[potion_prefab]) end
	local function _potion_fn() return potion_fn(anim, potion_tunings[potion_prefab], buff_prefab) end

	table.insert(potions, Prefab(potion_prefab, _potion_fn, assets, prefabs))
	table.insert(potions, Prefab(buff_prefab, _buff_fn))
end

local potions = {}
AddPotion(potions, "light", "light")

return unpack(potions)
