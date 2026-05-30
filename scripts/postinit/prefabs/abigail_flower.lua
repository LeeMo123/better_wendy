local upvaluehelper = require("hooks/upvaluehelper")

-- 检查词语
local function getstatus(inst, viewer)
	local _bondlevel = inst._bond_level
	if inst.components.inventoryitem.owner then
		_bondlevel = viewer ~= nil and viewer.components.ghostlybond ~= nil and viewer.components.ghostlybond.bondlevel
	end
	return _bondlevel == 4 and "LEVEL3"
        or _bondlevel == 3 and "LEVEL3"
		or _bondlevel == 2 and "LEVEL2"
		or _bondlevel == 1 and "LEVEL1"
		or nil
end

local function OnPutInInventoryFn(inst)
	if inst.components.inventoryitem.owner then
		local wendy = inst.components.inventoryitem.owner
		local abigail = wendy and wendy.components.ghostlybond and wendy.components.ghostlybond.ghost or nil

		if abigail ~= nil then
			print("level:", wendy.components.ghostlybond.bondlevel)
			inst.components.inventoryitem:ChangeImageName("abigail_flower_level"..wendy.components.ghostlybond.bondlevel == 1 and "0" or wendy.components.ghostlybond.bondlevel)
		end
	end
end

local function update_skin_overrides(inst)
	local image_name = string.gsub(inst.AnimState:GetBuild(), "abigail_", "abigail_flower_")
	if not inst.clientside_imageoverrides[image_name] then
		inst:SetClientSideInventoryImageOverride("bondlevel0", image_name..".tex", image_name.."_level0.tex")
		inst:SetClientSideInventoryImageOverride("bondlevel2", image_name..".tex", image_name.."_level2.tex")
		inst:SetClientSideInventoryImageOverride("bondlevel3", image_name..".tex", image_name.."_level3.tex")
		inst:SetClientSideInventoryImageOverride("bondlevel4", image_name..".tex", image_name.."_level3.tex")
		inst.clientside_imageoverrides[image_name] = true
	end
end

local function OnSkinIDDirty(inst)
	inst.skin_id = inst.flower_skin_id:value()
	inst:DoTaskInTime(0, update_skin_overrides)
end

-- 阿比盖尔之花 与level4相关的错误修复
AddPrefabPostInit("abigail_flower", function(inst)
    inst:SetClientSideInventoryImageOverride("bondlevel4", "abigail_flower.tex", "abigail_flower_level3.tex")

	local Oldabiflowerskiniddirty = upvaluehelper.GetEventHandle(inst, "abiflowerskiniddirty", "prefabs/abigail_flower")
	if Oldabiflowerskiniddirty then
		inst:RemoveEventCallback("abiflowerskiniddirty", Oldabiflowerskiniddirty)
		inst:ListenForEvent("abiflowerskiniddirty", OnSkinIDDirty)
	end
	OnSkinIDDirty(inst)

	if not TheWorld.ismastersim then
		return inst
	end
    
    inst.components.inspectable.getstatus = getstatus
end)