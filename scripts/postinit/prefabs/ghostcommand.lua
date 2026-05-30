local GHOSTCOMMAND_DEFS = require("prefabs/ghostcommand_defs")
local upvaluehelper = require("hooks/upvaluehelper")

local ICON_SCALE = .6
local GetGhostCommandsFor = GHOSTCOMMAND_DEFS.GetGhostCommandsFor

local function ReticuleGhostTargetFn(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(7, 0.001, 0))
end

local function StartAOETargeting(inst)
    if ThePlayer.components.playercontroller then
        ThePlayer.components.playercontroller:StartAOETargetingUsing(inst)
    end
end

local function DoGhostSpell(doer, event, state, ...)
	local spellbookcooldowns = doer.components.spellbookcooldowns
	local ghostlybond = doer.components.ghostlybond

	if spellbookcooldowns ~= nil and (spellbookcooldowns:IsInCooldown(event or state)) then
        return false
	end

	if ghostlybond == nil or ghostlybond.ghost == nil then
		return false
	end

	if ghostlybond.ghost.components.health:IsDead() then
		return false
	end

	if event ~= nil then
		ghostlybond.ghost:PushEvent(event, ...)

	elseif state ~= nil then
		ghostlybond.ghost.sg:GoToState(state, ...)
	end

	if spellbookcooldowns ~= nil then
		spellbookcooldowns:RestartSpellCooldown(event or state, TUNING.WENDY_COMMAND_COOLDOWN[event or state])
	end

	return true
end

local function GhostEscapeSpell(inst, doer)
	return DoGhostSpell(doer, "do_ghost_escape", nil)
end

local function GhostAttackAtSpell(inst, doer, pos)
	return DoGhostSpell(doer, "do_ghost_attackat", nil, pos)
end

local function GhostScareSpell(inst, doer)
	return DoGhostSpell(doer, nil, "scare")
end

local function GhostHauntSpell(inst, doer, pos)
	return DoGhostSpell(doer, "do_ghost_hauntat", nil, pos)
end

local NEW_SKILLTREE_COMMAND_DEFS ={
	["wendy_ghostcommand_1"] =
	{
		label = STRINGS.GHOSTCOMMANDS.ESCAPE,
		onselect = function(inst)
			local spellbook = inst.components.spellbook
			spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.ESCAPE)
			spellbook:SetSpellAction(nil)

			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(GhostEscapeSpell)
			end
		end,
		execute = function(inst)
			if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		bank = "spell_icons_wendy",
		build = "spell_icons_wendy",
		anims =
		{
			idle = { anim = "teleport" },
			focus = { anim = "teleport_focus", loop = true },
			down = { anim = "teleport_pressed" },
			disabled = { anim = "teleport_disabled" },
			cooldown = { anim = "teleport_cooldown" },
		},
		widget_scale = ICON_SCALE,
		checkcooldown = function(doer)
			--client safe
			return (doer ~= nil
				and doer.components.spellbookcooldowns
				and doer.components.spellbookcooldowns:GetSpellCooldownPercent("do_ghost_escape"))
				or nil
		end,
		cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
	},
	["wendy_ghostcommand_2"] =
    {
        label = STRINGS.GHOSTCOMMANDS.ATTACK_AT,
        onselect = function(inst)
			local spellbook = inst.components.spellbook
			local aoetargeting = inst.components.aoetargeting

            spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.ATTACK_AT)
			spellbook:SetSpellAction(nil)
            aoetargeting:SetDeployRadius(0)
			aoetargeting:SetRange(20)
            aoetargeting:SetShouldRepeatCastFn(nil)
            aoetargeting.reticule.reticuleprefab = "reticuleaoeghosttarget"
            aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"

            aoetargeting.reticule.mousetargetfn = nil
            aoetargeting.reticule.targetfn = ReticuleGhostTargetFn
            aoetargeting.reticule.updatepositionfn = nil
			aoetargeting.reticule.twinstickrange = 15

            if TheWorld.ismastersim then
                aoetargeting:SetTargetFX("reticuleaoeghosttarget")
                inst.components.aoespell:SetSpellFn(GhostAttackAtSpell)
                spellbook:SetSpellFn(nil)
            end
        end,
        execute = StartAOETargeting,
		bank = "spell_icons_wendy",
		build = "spell_icons_wendy",
		anims =
		{
			idle = { anim = "attack_at" },
			focus = { anim = "attack_at_focus", loop = true },
			down = { anim = "attack_at_pressed" },
			disabled = { anim = "attack_at_disabled" },
			cooldown = { anim = "attack_at_cooldown" },
		},
        widget_scale = ICON_SCALE,
		checkcooldown = function(doer)
			--client safe
			if doer == nil or doer.components.spellbookcooldowns == nil then
				return
			end

			local cooldown = doer.components.spellbookcooldowns:GetSpellCooldownPercent("do_ghost_attackat") or 0

			return cooldown > 0 and cooldown or nil
		end,
		cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
	["wendy_ghostcommand_3"] =
	{
		{
			label = STRINGS.GHOSTCOMMANDS.SCARE,
			onselect = function(inst)
				local spellbook = inst.components.spellbook
				spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.SCARE)
				spellbook:SetSpellAction(nil)

				if TheWorld.ismastersim then
					inst.components.aoespell:SetSpellFn(nil)
					spellbook:SetSpellFn(GhostScareSpell)
				end
			end,
			execute = function(inst)
				if ThePlayer.replica.inventory then
					ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
				end
			end,
			bank = "spell_icons_wendy",
			build = "spell_icons_wendy",
			anims =
			{
				idle = { anim = "scare" },
				focus = { anim = "scare_focus", loop = true },
				down = { anim = "scare_pressed" },
				disabled = { anim = "scare_disabled" },
				cooldown = { anim = "scare_cooldown" },
			},
			widget_scale = ICON_SCALE,
			checkcooldown = function(doer)
				--client safe
				return (doer ~= nil
					and doer.components.spellbookcooldowns
					and doer.components.spellbookcooldowns:GetSpellCooldownPercent("scare"))
					or nil
			end,
			cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
		},
	},
	["wendy_ghostcommand_4"] =
    {
		{
			label = STRINGS.GHOSTCOMMANDS.HAUNT_AT,
			onselect = function(inst)
				local spellbook = inst.components.spellbook
				local aoetargeting = inst.components.aoetargeting

				spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.HAUNT_AT)
				spellbook:SetSpellAction(nil)
				aoetargeting:SetDeployRadius(0)
				aoetargeting:SetRange(20)
				aoetargeting:SetShouldRepeatCastFn(function ()	-- 联系施法
					return true
				end)	
				aoetargeting.reticule.reticuleprefab = "reticuleaoeghosttarget"
				aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"

				aoetargeting.reticule.mousetargetfn = nil
				aoetargeting.reticule.targetfn = ReticuleGhostTargetFn
				aoetargeting.reticule.updatepositionfn = nil
				aoetargeting.reticule.twinstickrange = 15

				if TheWorld.ismastersim then
					aoetargeting:SetTargetFX("reticuleaoeghosttarget")
					inst.components.aoespell:SetSpellFn(GhostHauntSpell)
					spellbook:SetSpellFn(nil)
				end
			end,
			execute = function (inst)
                if ThePlayer.components.playercontroller then
                    ThePlayer.components.playercontroller:StartAOETargetingUsing(inst)
                end
            end,
			bank = "spell_icons_wendy",
			build = "spell_icons_wendy",
			anims =
			{
				idle = { anim = "haunt" },
				focus = { anim = "haunt_focus", loop = true },
				down = { anim = "haunt_pressed" },
				cooldown = { anim = "haunt_cooldown" },
			},
			widget_scale = .6,
			checkcooldown = function(doer)
				--client safe
				return (doer ~= nil
					and doer.components.spellbookcooldowns
					and doer.components.spellbookcooldowns:GetSpellCooldownPercent("do_ghost_hauntat"))
					or nil
			end,
			cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
		}
	}
}

-- 重写
upvaluehelper.Set(GetGhostCommandsFor,"SKILLTREE_COMMAND_DEFS", NEW_SKILLTREE_COMMAND_DEFS)