local testSpell = {
    ["WAR"] = 6552,
    ["PAL" ] = 35395,
    ["ROGUE"] = 1766,
    ["DK"] = 49998,
    ["MONK"] = 100780,
    ["SHAMAN"] = 17364,
    ["DRUIDBC"] = 106832,
    ["DHH"] = 162794,
    ["DHV"] = 214743,
    ["SHUNTER"] = 185855
}

function getDistance(Unit1,Unit2,option)
    currentDist = 100
    local meleeSpell = nil
    if testSpell[select(2,UnitClass("player"))] ~= nil then
        meleeSpell = testSpell[select(2,UnitClass("player"))]
    elseif select(2,UnitClass("player")) == "DRUID" and (GetShapeshiftForm()==1 or GetShapeshiftForm()==3)  then
        meleeSpell = testSpell["DRUIDBC"]
    elseif select(1,GetSpecializationInfo(GetSpecialization())) == 255 then
        meleeSpell = testSpell["SHUNTER"]
    elseif select(1,GetSpecializationInfo(GetSpecialization())) == 263 then
        meleeSpell = testSpell["SHAMAN"]
    elseif select(1,GetSpecializationInfo(GetSpecialization())) == 577 then
        meleeSpell = testSpell["DHH"]
    elseif select(1,GetSpecializationInfo(GetSpecialization())) == 581 then
        meleeSpell = testSpell["DHV"]
    end
    -- If Unit2 is nil we compare player to Unit1
    if Unit2 == nil then
        Unit2 = Unit1
        Unit1 = "player"
    end
    if Unit1 == nil or Unit2 == nil then return 100 end
    if option == nil then option = "none" end
    -- Check if objects exists and are visible
    if (GetUnitIsUnit(Unit1,"player") or (GetObjectExists(Unit1) and GetUnitIsVisible(Unit1) == true))
        and (GetUnitIsUnit(Unit2,"player") or (GetObjectExists(Unit2) and GetUnitIsVisible(Unit2) == true))
    then
        -- Modifier for Balance Affinity range change (Druid - Not Balance)
        local rangeMod = 0
        if br.player ~= nil then
            if br.player.talent.balanceAffinity ~= nil then
                if br.player.talent.balanceAffinity and option ~= "noMod" then
                    if hasEquiped(137015) then
                        rangeMod = 3 + (3 * .75)
                    else
                        rangeMod = 3
                    end
                end
            end
        end
        --See if we already have a position, else get position
        local X1,Y1,Z1,X2,Y2,Z2 = 0,0,0,0,0,0
        if not string.find(Unit1,"0x") then Unit1 = GetObjectWithGUID(UnitGUID(Unit1)) end
        if not string.find(Unit2,"0x") then Unit2 = GetObjectWithGUID(UnitGUID(Unit2)) end
        --Unit1 Position
        local unit1GUID = select(2,getGUID(Unit1))
        if br.unitSetup ~= nil and br.unitSetup.cache[Unit1] ~= nil and br.unitSetup.cache[Unit1].posX ~= nil then
          X1,Y1,Z1 = br.unitSetup.cache[Unit1].posX, br.unitSetup.cache[Unit1].posY, br.unitSetup.cache[Unit1].posZ
        elseif GetUnitIsUnit(Unit1,"player") and br.player ~= nil and br.player.posX ~= nil then
          X1,Y1,Z1 = br.player.posX, br.player.posY, br.player.posZ
        elseif isChecked("HE Active") and br.memberSetup ~= nil and br.memberSetup.cache[unit1GUID] ~= nil and br.memberSetup.cache[unit1GUID].x ~= nil then
          X1,Y1,Z1 = br.memberSetup.cache[unit1GUID].x, br.memberSetup.cache[unit1GUID].y, br.memberSetup.cache[unit1GUID].z
        else
          X1,Y1,Z1 = GetObjectPosition(Unit1)
        end
        --Unit2 Position
        local unit2GUID = select(2,getGUID(Unit2))
        if br.unitSetup ~= nil and br.unitSetup.cache[Unit2] ~= nil and br.unitSetup.cache[Unit2].posX ~= nil then
          X2,Y2,Z2 = br.unitSetup.cache[Unit2].posX, br.unitSetup.cache[Unit2].posY, br.unitSetup.cache[Unit2].posZ
        elseif GetUnitIsUnit(Unit2,"player") and br.player ~= nil and br.player.posX ~= nil then
          X2,Y2,Z2 = br.player.posX, br.player.posY, br.player.posZ
        elseif isChecked("HE Active") and br.memberSetup ~= nil and br.memberSetup.cache[unit2GUID] ~= nil and br.memberSetup.cache[unit2GUID].x ~= nil then
          X2,Y2,Z2 = br.memberSetup.cache[unit2GUID].x, br.memberSetup.cache[unit2GUID].y, br.memberSetup.cache[unit2GUID].z
        else
          X2,Y2,Z2 = GetObjectPosition(Unit2)
        end
        -- Get the distance
        local TargetCombatReach = UnitCombatReach(Unit2) or 0
        local PlayerCombatReach = UnitCombatReach(Unit1) or 0
        local MeleeCombatReachConstant = 4/3
        if isMoving(Unit1) and isMoving(Unit2) then
            IfSourceAndTargetAreRunning = 8/3
        else
            IfSourceAndTargetAreRunning = 0
        end

        local dist = math.sqrt(((X2-X1)^2) + ((Y2-Y1)^2) + ((Z2-Z1)^2)) - (PlayerCombatReach + TargetCombatReach) - rangeMod
        local dist2 = dist + 0.03 * ((13 - dist) / 0.13)
        local dist3 = dist + 0.05 * ((8 - dist) / 0.15) + 1
        local dist4 = dist + (PlayerCombatReach + TargetCombatReach)
        local meleeRange = max(5, PlayerCombatReach + TargetCombatReach + MeleeCombatReachConstant + IfSourceAndTargetAreRunning)
        if option == "dist" then return dist end
        if option == "dist2" then return dist2 end
        if option == "dist3" then return dist3 end
        if option == "dist4" then return dist4 end
        if option == "meleeRange" then return meleeRange end
        if GetSpecializationInfo(GetSpecialization()) == 255 then
            if dist > meleeRange then
                currentDist = dist
            else
                currentDist = 0
            end
        elseif dist > 13 then
            currentDist = dist
        elseif dist2 > 8 and dist3 > 8 then
            currentDist = dist2
        elseif dist3 > 5 and dist4 > 5 then
            currentDist = dist3
        elseif dist4 > meleeRange then -- Thanks Ssateneth
            currentDist = dist4
        else
            currentDist = 0
        end
    -- Modifier for Mastery: Sniper Training (Hunter - Marksmanship)
        if currentDist < 100 and isKnown(193468) and option ~= "noMod" then
            currentDist = currentDist - (currentDist * 0.12)
        end
        if meleeSpell ~= nil then
            if IsSpellInRange(select(1,GetSpellInfo(meleeSpell)),Unit2) == 1 then
                currentDist = 0
            end
        end
    end
    return currentDist
end
function isInRange(spellID,unit)
	return LibStub("SpellRange-1.0").IsSpellInRange(spellID,unit)
end
function getDistanceToObject(Unit1,X2,Y2,Z2)
	if Unit1 == nil then
		Unit1 = "player"
	end
	if GetObjectExists(Unit1) and GetUnitIsVisible(Unit1) then
		local X1,Y1,Z1 = GetObjectPosition(Unit1)
		return math.sqrt(((X2-X1)^2) + ((Y2-Y1)^2) + ((Z2-Z1)^2))
	else
		return 100
	end
end
function inRange(spellID,unit)
	local SpellRange = LibStub("SpellRange-1.0")
	local inRange = SpellRange.IsSpellInRange(spellID,unit)
	if inRange == 1 then
		return true
	else
		return false
	end
end
function getFacingDistance()
    if GetUnitIsVisible("player") and GetUnitIsVisible("target") then
        --local targetDistance = getRealDistance("target")
        local targetDistance = getDistance("target")
        local Y1,X1,Z1 = GetObjectPosition("player");
        local Y2,X2,Z2 = GetObjectPosition("target");
        local Angle1 = GetObjectFacing("player")
        local deltaY = Y2 - Y1
        local deltaX = X2 - X1
        Angle1 = math.deg(math.abs(Angle1-math.pi*2))
        if deltaX > 0 then
            Angle2 = math.deg(math.atan(deltaY/deltaX)+(math.pi/2)+math.pi)
        elseif deltaX <0 then
            Angle2 = math.deg(math.atan(deltaY/deltaX)+(math.pi/2))
        end
        local Dist = round2(math.tan(math.abs(Angle2 - Angle1)*math.pi/180)*targetDistance*10000)/10000
        if ObjectIsFacing("player","target") then
            return Dist
        else
            return -(math.abs(Dist))
        end
    else
        return 1000
    end
end
-- /dump getTotemDistance("target")
function getTotemDistance(Unit1)
  if Unit1 == nil then
    Unit1 = "player"
  end

  if GetUnitIsVisible(Unit1) then
    -- local objectCount = GetObjectCount() or 0
    for i = 1,GetObjectCount() do
      if GetUnitIsUnit(UnitCreator(GetObjectWithIndex(i)), "Player") and (UnitName(GetObjectWithIndex(i)) == "Searing Totem" or UnitName(GetObjectWithIndex(i)) == "Magma Totem") then
        X2,Y2,Z2 = GetObjectPosition(GetObjectIndex(i))
      end
    end
    local X1,Y1,Z1 = GetObjectPosition(Unit1)
    TotemDistance = math.sqrt(((X2-X1)^2)+((Y2-Y1)^2)+((Z2-Z1)^2))
    --Print(TotemDistance)
    return TotemDistance
  else
    return 0
  end
end
-- if isInMelee() then
function isInMelee(Unit)
  if Unit == nil then
    Unit = "target"
  end
  if getDistance(Unit) < 4 then
    return true
  else
    return false
  end
end

function isSafeToAoE(spellID,Unit,effectRng,minUnits,aoeType)
    if not isChecked("Safe Damage Check") then return true end 
    local maxRange = select(6,GetSpellInfo(spellID))
    if effectRng == nil then effectRng = 5 end
    if maxRange == nil or maxRange == 0 then maxRange = tonumber(effectRng) else maxRange = tonumber(maxRange) end
    if minUnits == nil then minUnits = 1 end
    if aoeType == "rect" then
        enemiesValid    = getEnemiesInRect(effectRng,maxRange,false)
        enemiesAll      = getEnemiesInRect(effectRng,maxRange,false,true)
    elseif aoeType == "cone" then
        enemiesValid    = getEnemiesInCone(effectRng,maxRange,false)
        enemiesAll      = getEnemiesInCone(effectRng,maxRange,false,true)
    else
        enemiesValid    = #getEnemies(Unit,effectRng)
        enemiesAll      = #getEnemies(Unit,effectRng,true)
    end
    return enemiesValid >= minUnits and enemiesValid >= enemiesAll
end

function inRange(spellID,unit)
    local spellName = GetSpellInfo(spellID)
    if unit == nil then unit = "target" end
    local inRange = IsSpellInRange(spellName,unit)
    if inRange ~= nil then
        return IsSpellInRange(spellName,unit) == 1
    else
        return false
    end
end
