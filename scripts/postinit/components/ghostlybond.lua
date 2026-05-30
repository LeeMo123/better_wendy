
AddComponentPostInit("ghostlybond", function(self)
	-- 设置最大等级
	function self:SetMaxBondLevel(val)
		self.maxbondlevel = val or 3
	end

	-- 保存等级
    function self:OnSave()
		return {
			maxbondlevel = self.maxbondlevel,  -- 增加了这个
			bondlevel = self.bondlevel,
			elapsedtime = self.bondleveltimer,
	
			ghost = self.ghost ~= nil and self.ghost:GetSaveRecord() or nil,
			ghostinlimbo = self.ghost ~= nil and self.ghost.inlimbo or nil,
		}
    end

	-- 加载
	local _OnLoad = self.OnLoad
	function self:OnLoad(data)
		if data ~= nil and data.maxbondlevel ~= nil then
			self:SetMaxBondLevel(data.maxbondlevel)  -- 加载最大等级			
		end
		return _OnLoad(self, data)
	end
end)