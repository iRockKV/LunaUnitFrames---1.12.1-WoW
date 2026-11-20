local Range = {}
local L = LunaUF.L
LunaUF:RegisterModule(Range, "range", L["Range"])
local ZoneWatch = CreateFrame("Frame")

-- ============================================================================
-- 1. INDEPENDENT LoS BORDER SYSTEM
-- ============================================================================

local function CreateSolidEdge(parent, r, g, b, a)
	local tex = parent:CreateTexture(nil, "OVERLAY")
	tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	tex:SetVertexColor(r, g, b, a)
	return tex
end

local function GetIndependentLoSBorder(frame)
	if frame.independentLoSBorder then
		return frame.independentLoSBorder
	end

	local border = CreateFrame("Frame", nil, UIParent)
	border:SetFrameStrata(frame:GetFrameStrata())
	border:SetFrameLevel(frame:GetFrameLevel() + 5)
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
	border:Hide()

	local thickness = 1
	local r, g, b, a = 0.55, 0.90, 0.15, 1 -- Apple green (R, G, B, Alpha)

	local top = CreateSolidEdge(border, r, g, b, a)
	top:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
	top:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
	top:SetHeight(thickness)

	local bottom = CreateSolidEdge(border, r, g, b, a)
	bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(thickness)

	local left = CreateSolidEdge(border, r, g, b, a)
	left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, -thickness)
	left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, thickness)
	left:SetWidth(thickness)

	local right = CreateSolidEdge(border, r, g, b, a)
	right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, -thickness)
	right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, thickness)
	right:SetWidth(thickness)

	-- Hide border immediately if parent frame is hidden
	border:SetScript("OnUpdate", function()
		if not frame:IsVisible() then
			this:Hide()
		end
	end)

	frame.independentLoSBorder = border
	return border
end

-- Check if unit is visible, <= 42.5y away, and out of LoS
local function CheckAndToggleLoSBorder(frame)
	local unit = frame.unit
	local shouldShow = false

	if frame:IsVisible() and unit and UnitExists(unit) and not UnitIsUnit("player", unit) then
		if UnitIsVisible(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
			-- 1. Check 2D distance
			local inRange = false
			if UnitPosition then
				local px, py = UnitPosition("player")
				local ux, uy = UnitPosition(unit)
				if px and ux and (px ~= 0 or py ~= 0) and (ux ~= 0 or uy ~= 0) then
					local dist = sqrt((px - ux)^2 + (py - uy)^2)
					if dist <= 42.5 then
						inRange = true
					end
				end
			end

			-- 2. Check LoS via UnitXP if in range
			if inRange and UnitXP then
				local success, inSight = pcall(UnitXP, "inSight", "player", unit)
				if success and inSight == false then
					shouldShow = true
				end
			end
		end
	end

	-- Toggle border directly
	if shouldShow then
		local border = GetIndependentLoSBorder(frame)
		if not border:IsShown() then
			border:Show()
		end
	elseif frame.independentLoSBorder and frame.independentLoSBorder:IsShown() then
		frame.independentLoSBorder:Hide()
	end
end

-- ============================================================================
-- 2. EXISTING FADER & RANGE LOGIC
-- ============================================================================

local function OnUpdate()
	local parent = this:GetParent()
	CheckAndToggleLoSBorder(parent)
	Range:FullUpdate(parent)
end

local function OnEvent()
	if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
		-- Zone change reset logic if needed
	end
end

ZoneWatch:SetScript("OnEvent", OnEvent)
ZoneWatch:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ZoneWatch:RegisterEvent("PLAYER_ENTERING_WORLD")

function Range:GetRange(UnitID)
	if not UnitExists(UnitID) then
		return 100
	end

	-- 1. C++ LoS check via UnitXP
	if UnitXP then
		local success, inSight = pcall(UnitXP, "inSight", "player", UnitID)
		if success and inSight == false then
			return 999 -- Instant fade when LoS blocked
		end
	end

	-- 2. Standard visibility fallback
	if not UnitIsVisible(UnitID) or not UnitIsConnected(UnitID) then
		return 999
	end

	-- 3. 2D distance (ignores Z-axis)
	if UnitPosition then
		local px, py = UnitPosition("player")
		local ux, uy = UnitPosition(UnitID)
		if px and ux then
			local dist = sqrt((px - ux)^2 + (py - uy)^2)
			return dist
		end
	end

	-- 4. Fallback
	if CheckInteractDistance(UnitID, 1) or CheckInteractDistance(UnitID, 3) then
		return 10
	elseif CheckInteractDistance(UnitID, 4) then
		return 30
	else
		return 45
	end
end

function Range:OnEnable(frame)
	if not frame.range then
		frame.range = CreateFrame("Frame", nil, frame)
	end
	frame.range.lastUpdate = GetTime() - 5
	frame.range:SetScript("OnUpdate", OnUpdate)
end

function Range:OnDisable(frame)
	if frame.independentLoSBorder then
		frame.independentLoSBorder:Hide()
	end
	if frame.range then
		frame.range.lastUpdate = nil
		frame.range:SetScript("OnUpdate", nil)
	end
end

function Range:FullUpdate(frame)
	if frame.DisableRangeAlpha or (GetTime() - frame.range.lastUpdate) < (LunaUF.db.profile.RangePolRate or 1.0) then return end
	frame.range.lastUpdate = GetTime()
	
	local range = self:GetRange(frame.unit)

	-- 42.5y 2D range cutoff + LoS (999)
	local isOutOfRange = (range > 42.5)

	local healththreshold = LunaUF.db.profile.units.raid.healththreshold
	if (not healththreshold.enabled) then
		if not isOutOfRange then
			frame:SetAlpha(LunaUF.db.profile.units[frame.unitGroup].fader.enabled and LunaUF.db.profile.units[frame.unitGroup].fader.combatAlpha or 1)
		else
			frame:SetAlpha(LunaUF.db.profile.units[frame.unitGroup].range.alpha)
		end
	else 
		local percent = UnitHealth(frame.unit) / UnitHealthMax(frame.unit)
		if not isOutOfRange then
			if (percent <= healththreshold.threshold) then				
				frame:SetAlpha(healththreshold.inRangeBelowAlpha)
			else
				frame:SetAlpha(healththreshold.inRangeAboveAlpha)
			end
		else
			if (percent <= healththreshold.threshold) then
				frame:SetAlpha(healththreshold.outOfRangeBelowAlpha)
			else
				frame:SetAlpha(LunaUF.db.profile.units[frame.unitGroup].range.alpha)
			end
		end
	end
end