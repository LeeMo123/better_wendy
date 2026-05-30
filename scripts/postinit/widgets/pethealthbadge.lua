local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

AddClassPostConstruct("widgets/pethealthbadge", function(self, owner, colour, iconbuild, bonuscolor)
    -- Badge._ctor(self, nil, owner, colour, iconbuild, nil, nil, true, bonuscolor)
	self.default_symbol_build1 = iconbuild
	self.default_symbol_build3 = iconbuild

	self.inst:DoTaskInTime(0.1,function()
		self.underNumber:MoveToFront()
	end)
    
    self.bufficon1 = self.underNumber:AddChild(UIAnim())
    self.bufficon1:GetAnimState():SetBank("status_abigail")
    self.bufficon1:GetAnimState():SetBuild("status_abigail")
    self.bufficon1:GetAnimState():PlayAnimation("buff_none")
	self.bufficon1:GetAnimState():AnimateWhilePaused(false)
    self.bufficon1:SetClickable(false)
    self.bufficon1:SetRotation(28)
	self.buffsymbol1 = 0	

    -- 两种治疗药剂用的
    self.bufficon3 = self.underNumber:AddChild(UIAnim())
    self.bufficon3:GetAnimState():SetBank("status_abigail")
    self.bufficon3:GetAnimState():SetBuild("status_abigail")
    self.bufficon3:GetAnimState():PlayAnimation("buff_none")
	self.bufficon3:GetAnimState():AnimateWhilePaused(false)
    self.bufficon3:SetClickable(false)
    self.bufficon3:SetRotation(28)
    self.bufficon3:SetScale(-1,1,1)
	self.buffsymbol3 = 0	

    function self:ShowBuff1(symbol)
        if symbol == 0 then
            if self.buffsymbol1 ~= 0 then
                self.bufficon1:GetAnimState():PlayAnimation("buff_deactivate")
                self.bufficon1:GetAnimState():PushAnimation("buff_none", false)
            end
        elseif symbol ~= self.buffsymbol1 then
            self.bufficon1:GetAnimState():OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[symbol] or self.default_symbol_build1, symbol)
    
            self.bufficon1:GetAnimState():PlayAnimation("buff_activate")
            self.bufficon1:GetAnimState():PushAnimation("buff_idle", false)
        end
    
        self.buffsymbol1 = symbol
    end

    function self:ShowBuff3(symbol)
        if symbol == 0 then
            if self.buffsymbol3 ~= 0 then
                self.bufficon3:GetAnimState():PlayAnimation("buff_deactivate")
                self.bufficon3:GetAnimState():PushAnimation("buff_none", false)
            end
        elseif symbol ~= self.buffsymbol3 then
            self.bufficon3:GetAnimState():OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[symbol] or self.default_symbol_build3, symbol)
    
            self.bufficon3:GetAnimState():PlayAnimation("buff_activate")
            self.bufficon3:GetAnimState():PushAnimation("buff_idle", false)
        end
    
        self.buffsymbol3 = symbol
    end


    function self:SetValues(symbol, symbol1, symbol2,  symbol3, percent, arrowdir, max_health, pulse, bonusmax, bonuspercent)
        self:ShowBuff(symbol)
        self:ShowBuff1(symbol1)
        self:ShowBuff2(symbol2)
        self:ShowBuff3(symbol3)
    
        if self.arrowdir ~= arrowdir then
            self.arrowdir = arrowdir
            self.arrow:GetAnimState():PlayAnimation((arrowdir >= 2  and "arrow_loop_increase_most") or
                                                    (arrowdir == 1  and "arrow_loop_increase") or
                                                    (arrowdir == -1 and "arrow_loop_decrease") or
                                                    (arrowdir <= -2 and "arrow_loop_decrease_most") or
                                                    "neutral",
                                                    true)
        end
    
        percent = percent == 0 and 0 or math.max(percent, 1/max_health)
        local health = percent * max_health
    
        if pulse == 1 then
            self:PulseGreen()
        elseif pulse == 2 then
            self:PulseRed()
        end
    
        self:SetPercent(percent, max_health, bonuspercent)
    end
end)