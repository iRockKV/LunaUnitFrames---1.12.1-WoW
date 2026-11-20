local LunaUF = LunaUF
local Squares = {}
local HealComm = LunaUF.HealComm
local banzai = LunaUF.Banzai
local ScanTip = LunaUF.ScanTip
local BS = LunaUF.BS
local buffs = {}
local debuffs = {}
local _,playerclass = UnitClass("player")
LunaUF:RegisterModule(Squares, "squares", LunaUF.L["Status tracker"])

-- ==========================================================
-- CUSTOM BUFF LISTS (Slots 1-3, lowercase, overrides UI)
-- ==========================================================
local SLOT_1_LISTE = {
	"power word: shield", -- Priest
}

local SLOT_2_LISTE = {
	-- Add Slot 2 buffs here
}

local SLOT_3_LISTE = {
	"combustion",   -- Mage
	"arcane power", -- Mage
	"shield wall",  -- Warrior
	"last stand",   -- Warrior
	"innervate",    -- Druid
	"silverwing flag",    -- WSG Flag	
	"warsong flag",    -- WSG Flag		
	
}

-- ==========================================================
-- CUSTOM DEBUFF LISTS (Slots 1-3, lowercase, overrides UI)
-- ==========================================================
local DEBUFF_SLOT_1_LISTE = {
	"weakened soul",            -- Prevents Power Word: Shield (15s) - Priest
	"forbearance",              -- Prevents Divine Shield / BoP (1m) - Paladin
}

local DEBUFF_SLOT_2_LISTE = {

	-- Add Slot 2 debuffs here
}

local DEBUFF_SLOT_3_LISTE = {
	"living bomb",              -- Explodes & knocks up - Baron Geddon (MC)
	"mortal strike",            -- Reduces healing taken - Broodlord Lashlayer (BWL)
	"burning adrenaline",       -- Fatal DoT & explodes on death - Vaelastrasz (BWL)
	"mutating injection",       -- Explodes & spawns slime - Grobbulus (Naxx)
	"necrotic aura",            -- Prevents all healing - Loatheb (Naxx)
	"veil of shadow",           -- Reduces healing by 75% - Nefarian / Gehennas (BWL/MC)
	"conflagration",            -- Fire DoT & disorient - Drakkisath / Razorgore (UBRS/BWL)
	"shadow flame",             -- Heavy Fire DoT - Ebonroc / Flamegor / Nefarian (BWL)
	"brood affliction: bronze", -- Stunned unless Sand is used - Chromaggus (BWL)
	"cause insanity",           -- Un-dispellable Mind Control - Hakkar (ZG)
	"delusions of jin'do",      -- Lets player see & kill Shades - Jin'do (ZG)
	"brain wash",               -- Un-dispellable Mind Control (Totem) - Jin'do (ZG)
	"threatening gaze",         -- Any action triggers lethal charge - Mandokir (ZG)
	"mortal wound",             -- Stacking healing reduction - Kurinnaxx (AQ20)
	"consume",                  -- Pulled to altar & sacrificed - Ayamiss (AQ20)
	"digestive acid",           -- Stacking acid DoT inside stomach - C'Thun (AQ40)
	"true fulfillment",         -- Un-dispellable Mind Control - Prophet Skeram (AQ40)
	"plague",                   -- Explodes & damages nearby allies - Anubisath Defender (AQ40)
	"unbalancing strike",       -- Heavily reduces Defense (Tank swap) - Twin Emperors (AQ40)
	"inevitable doom",          -- Delayed heavy Shadow damage - Loatheb (Naxx)
	"web wrap",                 -- Cocooned on wall & out of fight - Maexxna (Naxx)
	"icebolt",                  -- Frozen solid (LoS shield for Frost Bomb) - Sapphiron (Naxx)
	"chains of kel'thuzad",     -- Un-dispellable Mind Control - Kel'Thuzad (Naxx)
	"frost blast",              -- Frozen in place & lethal DoT - Kel'Thuzad (Naxx)
	"shadow portal",            -- Teleported to side room (Out of range) - Gandling (Scholo)
}

-- ==========================================================

local function OnEvent()
	local frame = this:GetParent()
	if arg1 ~= frame.unit then return end
	Squares:UpdateAuras(frame)
end

local function OnTimer(unit)
	if not unit then return end
	for _,frame in pairs(LunaUF.Units.frameList) do
		if frame.squares and frame.unit and UnitIsUnit(frame.unit,unit) then
			Squares:UpdateTimers(frame)
		end
	end
end

local function OnAggro(unit)
	for _,frame in pairs(LunaUF.Units.frameList) do
		if frame.unit and UnitIsUnit(frame.unit,unit) then
			Squares:UpdateAggro(frame)
			LunaUF.modules.borders:OnAggro(frame)
		end
	end
end

function Squares:OnEnable(frame)
	if( not frame.squares ) then
		frame.squares = CreateFrame("Frame", frame:GetName().."SquareModule", frame)
		frame.squares:SetAllPoints(frame)
		frame.squares:SetFrameLevel(6)
		
		frame.squares.buffs = {}
		frame.squares.debuffs = {}
		frame.squares.trackdebuffs = {}
		frame.squares.centericons = {}
		
		for i = 1, 3 do
			frame.squares.buffs[i] = CreateFrame("Frame", nil, frame.squares)
			frame.squares.buffs[i]:SetBackdrop(LunaUF.constants.backdrop)
			frame.squares.buffs[i]:SetBackdropColor(0,0,0)
			frame.squares.buffs[i].texture = frame.squares.buffs[i]:CreateTexture(nil, "ARTWORK")
			frame.squares.buffs[i].texture:SetAllPoints(frame.squares.buffs[i])

			frame.squares.debuffs[i] = CreateFrame("Frame", nil, frame.squares)
			frame.squares.debuffs[i]:SetBackdrop(LunaUF.constants.backdrop)
			frame.squares.debuffs[i]:SetBackdropColor(0,0,0)
			frame.squares.debuffs[i].texture = frame.squares.debuffs[i]:CreateTexture(nil, "ARTWORK")
			frame.squares.debuffs[i].texture:SetAllPoints(frame.squares.debuffs[i])
			
			frame.squares.trackdebuffs[i] = CreateFrame("Frame", nil, frame.squares)
			frame.squares.trackdebuffs[i]:SetBackdrop(LunaUF.constants.backdrop)
			frame.squares.trackdebuffs[i]:SetBackdropColor(0,0,0)
			frame.squares.trackdebuffs[i].texture = frame.squares.trackdebuffs[i]:CreateTexture(nil, "ARTWORK")
			frame.squares.trackdebuffs[i].texture:SetAllPoints(frame.squares.trackdebuffs[i])
			
			frame.squares.centericons[i] = frame.squares:CreateTexture(nil, "ARTWORK")
			frame.squares.centericons[i]:ClearAllPoints()
			frame.squares.centericons[i].cd = CreateFrame("Model", frame:GetName().."CD"..i, frame.squares , "CooldownFrameTemplate")
			frame.squares.centericons[i].cd:ClearAllPoints()
			frame.squares.centericons[i].cd:SetPoint("TOPLEFT", frame.squares.centericons[i], "TOPLEFT")
			frame.squares.centericons[i].cd:SetHeight(36)
			frame.squares.centericons[i].cd:SetWidth(36)
		end
		
		-- Buffs row (top-right, right to left)
		frame.squares.buffs[1]:SetPoint("TOPRIGHT", frame.squares, "TOPRIGHT")
		frame.squares.buffs[2]:SetPoint("RIGHT", frame.squares.buffs[1], "LEFT")
		frame.squares.buffs[3]:SetPoint("RIGHT", frame.squares.buffs[2], "LEFT")
		
		-- Standard debuffs (top-left)
		frame.squares.debuffs[1]:SetPoint("TOPLEFT", frame.squares, "TOPLEFT")
		frame.squares.debuffs[2]:SetPoint("LEFT", frame.squares.debuffs[1], "RIGHT")
		frame.squares.debuffs[3]:SetPoint("TOP", frame.squares.debuffs[1], "BOTTOM")
		
		-- Custom tracked debuffs row (bottom-right, right to left)
		frame.squares.trackdebuffs[1]:SetPoint("BOTTOMRIGHT", frame.squares, "BOTTOMRIGHT")
		frame.squares.trackdebuffs[2]:SetPoint("RIGHT", frame.squares.trackdebuffs[1], "LEFT")
		frame.squares.trackdebuffs[3]:SetPoint("RIGHT", frame.squares.trackdebuffs[2], "LEFT")
		
		frame.squares.centericons[1]:SetPoint("CENTER", frame.squares, "CENTER", 0, -5)
		frame.squares.centericons[1]:SetTexture("Interface\\Icons\\Spell_Nature_Rejuvenation")
		frame.squares.centericons[2]:SetPoint("RIGHT", frame.squares.centericons[1], "LEFT", 0, -5)
		frame.squares.centericons[2]:SetTexture("Interface\\Icons\\Spell_Holy_Renew")
		frame.squares.centericons[3]:SetPoint("LEFT", frame.squares.centericons[1], "RIGHT", 0, -5)
		frame.squares.centericons[3]:SetTexture("Interface\\Icons\\Spell_Nature_ResistNature")
		
		frame.squares.aggro = CreateFrame("Frame", nil, frame.squares)
		frame.squares.aggro:SetBackdrop(LunaUF.constants.backdrop)
		frame.squares.aggro:SetBackdropColor(0,0,0)
		frame.squares.aggro.texture = frame.squares.aggro:CreateTexture(nil, "ARTWORK")
		frame.squares.aggro.texture:SetAllPoints(frame.squares.aggro)
		frame.squares.aggro:SetPoint("BOTTOMLEFT", frame.squares, "BOTTOMLEFT")
	end
	frame.squares:Show()
	frame.squares:RegisterEvent("UNIT_AURA")
	frame.squares:SetScript("OnEvent", OnEvent)
	if not LunaUF:IsEventRegistered("HealComm_Hotupdate") then
		LunaUF:RegisterEvent("HealComm_Hotupdate", OnTimer)
	end
	if not LunaUF:IsEventRegistered("Banzai_UnitGainedAggro") then
		LunaUF:RegisterEvent("Banzai_UnitGainedAggro", OnAggro)
	end
	if not LunaUF:IsEventRegistered("Banzai_UnitLostAggro") then
		LunaUF:RegisterEvent("Banzai_UnitLostAggro", OnAggro)
	end
end

function Squares:OnDisable(frame)
	if( frame.squares ) then
		frame.squares:Hide()
	end
end

function Squares:UpdateTimers(frame)
	return
end

function Squares:UpdateAggro(frame)
	local aggro = banzai:GetUnitAggroByUnitId(frame.unit)
	if frame.squares then
		if aggro and LunaUF.db.profile.units.raid.squares.aggro then
			frame.squares.aggro:Show()
		else
			frame.squares.aggro:Hide()
		end
	end
end

function Squares:UpdateAuras(frame)
	local config = LunaUF.db.profile.units.raid.squares
	local i = 1
	local num = 1
	local disptype, texture
	local buffname
	
	for _,icon in pairs(frame.squares.centericons) do
		icon:Hide()
	end
	for _,icon in pairs(frame.squares.buffs) do
		icon:Hide()
	end
	for _,icon in pairs(frame.squares.debuffs) do
		icon:Hide()
	end
	for _,icon in pairs(frame.squares.trackdebuffs) do
		icon:Hide()
	end
	for k,_ in pairs(buffs) do
		buffs[k] = nil
	end
	for k,_ in pairs(debuffs) do
		debuffs[k] = nil
	end
	
	while UnitBuff(frame.unit,i) do
		ScanTip:ClearLines()
		ScanTip:SetUnitBuff(frame.unit,i)
		buffname = LunaScanTipTextLeft1:GetText() or ""
		if config.hottracker then
			if buffname == BS["Rejuvenation"] then
				frame.squares.centericons[1]:Show()
			elseif buffname == BS["Renew"] then
				frame.squares.centericons[2]:Show()
			elseif buffname == BS["Regrowth"] then
				frame.squares.centericons[3]:Show()
			end
		end
		
		buffname = string.lower(buffname)
		local iconTexture = UnitBuff(frame.unit, i)

		-- 1. Check custom Lua lists first (priority)
		local matchedInLua = false
		for _, bName in ipairs(SLOT_1_LISTE) do
			if bName ~= "" and buffname == bName then
				buffs[1] = iconTexture
				matchedInLua = true
				break
			end
		end
		for _, bName in ipairs(SLOT_2_LISTE) do
			if bName ~= "" and buffname == bName then
				buffs[2] = iconTexture
				matchedInLua = true
				break
			end
		end
		for _, bName in ipairs(SLOT_3_LISTE) do
			if bName ~= "" and buffname == bName then
				buffs[3] = iconTexture
				matchedInLua = true
				break
			end
		end

		-- 2. Fallback to UI config
		if not matchedInLua and config.buffs and config.buffs.names then
			for key,buff in pairs(config.buffs.names) do
				if buff ~= "" and string.find(buffname, string.lower(buff)) then
					if not buffs[key] then
						buffs[key] = iconTexture
					end
					break
				end
			end
		end
		
		i = i + 1
	end

	-- Render buff slots 1-3
	for slotIndex = 1, 3 do
		if buffs[slotIndex] and frame.squares.buffs[slotIndex] then
			local invert = false
			if slotIndex == 1 and config.invertfirstbuff then invert = true end
			if slotIndex == 2 and config.invertsecondbuff then invert = true end
			if slotIndex == 3 and config.invertthirdbuff then invert = true end

			if not invert then
				if config.buffcolors and config.buffs and config.buffs.colors then
					frame.squares.buffs[slotIndex].texture:SetTexture(config.buffs.colors[slotIndex].r, config.buffs.colors[slotIndex].g, config.buffs.colors[slotIndex].b)
				else
					frame.squares.buffs[slotIndex].texture:SetTexture(buffs[slotIndex])
				end
				frame.squares.buffs[slotIndex]:Show()
			end
		end
	end

	-- Standard debuffs + 3 custom Lua debuff slots
	i = 1
	while UnitDebuff(frame.unit,i) do
		ScanTip:ClearLines()
		ScanTip:SetUnitDebuff(frame.unit,i)
		buffname = LunaScanTipTextLeft1:GetText() or ""

		texture,_,disptype = UnitDebuff(frame.unit,i,config.owndispdebuffs)
		if texture and config.enabledebuffs and (not config.dispellabledebuffs or disptype) and num <= 3 then
			if config.debuffcolors then
				if disptype then
					local r,g,b = unpack(LunaUF.db.profile.magicColors[disptype])
					frame.squares.debuffs[num].texture:SetTexture(r,g,b)
				else
					frame.squares.debuffs[num].texture:SetTexture(0,0,0)
				end
			else
				frame.squares.debuffs[num].texture:SetTexture(texture)
			end
			frame.squares.debuffs[num]:Show()
			num = num + 1
		end
		
		buffname = string.lower(buffname)
		local debuffTexture = UnitDebuff(frame.unit, i)

		-- 1. Check custom Lua lists first (priority)
		local matchedDebuffInLua = false
		for _, dName in ipairs(DEBUFF_SLOT_1_LISTE) do
			if dName ~= "" and buffname == dName then
				debuffs[1] = debuffTexture
				matchedDebuffInLua = true
				break
			end
		end
		for _, dName in ipairs(DEBUFF_SLOT_2_LISTE) do
			if dName ~= "" and buffname == dName then
				debuffs[2] = debuffTexture
				matchedDebuffInLua = true
				break
			end
		end
		for _, dName in ipairs(DEBUFF_SLOT_3_LISTE) do
			if dName ~= "" and buffname == dName then
				debuffs[3] = debuffTexture
				matchedDebuffInLua = true
				break
			end
		end

		-- 2. Fallback to UI config
		if not matchedDebuffInLua and config.debuffs and config.debuffs.names then
			for key,debuff in pairs(config.debuffs.names) do
				if debuff ~= "" and string.find(buffname, string.lower(debuff)) then
					if not debuffs[key] then
						debuffs[key] = debuffTexture
					end
					break
				end
			end
		end

		i = i + 1
	end
	
	for slotIndex = 1, 3 do
		if debuffs[slotIndex] and frame.squares.trackdebuffs[slotIndex] then
			if config.debuffcolors and config.debuffs and config.debuffs.colors then
				frame.squares.trackdebuffs[slotIndex].texture:SetTexture(config.debuffs.colors[slotIndex].r, config.debuffs.colors[slotIndex].g, config.debuffs.colors[slotIndex].b)
			else
				frame.squares.trackdebuffs[slotIndex].texture:SetTexture(debuffs[slotIndex])
			end
			frame.squares.trackdebuffs[slotIndex]:Show()
		end
	end
end

function Squares:FullUpdate(frame)
	if not frame.squares then return end
	local config = LunaUF.db.profile.units.raid.squares
	for i=1, 3 do
		frame.squares.buffs[i]:SetHeight(config.outersize)
		frame.squares.buffs[i]:SetWidth(config.outersize)
		
		frame.squares.debuffs[i]:SetHeight(config.outersize)
		frame.squares.debuffs[i]:SetWidth(config.outersize)
		
		frame.squares.trackdebuffs[i]:SetHeight(config.outersize)
		frame.squares.trackdebuffs[i]:SetWidth(config.outersize)
		
		frame.squares.centericons[i]:SetHeight(config.innersize)
		frame.squares.centericons[i]:SetWidth(config.innersize)
		frame.squares.centericons[i].cd:SetScale(config.innersize/36)
	end
	
	frame.squares.aggro:SetWidth(config.outersize)
	frame.squares.aggro:SetHeight(config.outersize)
	frame.squares.aggro.texture:SetTexture(config.aggrocolor.r,config.aggrocolor.g,config.aggrocolor.b)
	
	Squares:UpdateTimers(frame)
	Squares:UpdateAggro(frame)
	Squares:UpdateAuras(frame)
end