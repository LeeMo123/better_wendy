AddStategraphPostInit("wilson", function(sg)
    -- 搬重物不掉速
    if sg.states.run_start then
		local oldonenter = sg.states.run_start.onenter
		sg.states.run_start.onenter = function(inst, ...)
			if inst.components.inventory:IsHeavyLifting() and inst:HasTag("strong_for_heavy") and not (inst.components.rider and inst.components.rider:IsRiding()) then
				inst.sg.statemem.heavy_fast=true
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("heavy_walk_fast_pre")
				inst.sg.mem.footsteps = 0--(inst.sg.statemem.goose or inst.sg.statemem.goosegroggy) and 4 or 0
			elseif oldonenter then
				oldonenter(inst, ...)
			end
		end
	end
	if sg.states.run then
		local oldonenter = sg.states.run.onenter
		sg.states.run.onenter = function(inst, ...)
			if inst.components.inventory:IsHeavyLifting() and inst:HasTag("strong_for_heavy") and not (inst.components.rider and inst.components.rider:IsRiding()) then
				inst.sg.statemem.heavy_fast=true
				inst.components.locomotor:RunForward()
				if not inst.AnimState:IsCurrentAnimation("heavy_walk_fast") then
					inst.AnimState:PlayAnimation("heavy_walk_fast", true)
				end
				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
			elseif oldonenter then
				oldonenter(inst, ...)
			end
		end
	end
	if sg.states.run_stop then
		local oldonenter = sg.states.run_stop.onenter
		sg.states.run_stop.onenter = function(inst, ...)
			if inst.components.inventory:IsHeavyLifting() and inst:HasTag("strong_for_heavy") and not (inst.components.rider and inst.components.rider:IsRiding()) then
				inst.sg.statemem.heavy_fast=true
				inst.components.locomotor:Stop()
				inst.AnimState:PlayAnimation("heavy_walk_fast_pst")
			elseif oldonenter then
				oldonenter(inst, ...)
			end
		end
	end
end)
