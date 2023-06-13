function QYUnitCanHavePromotion(iPlayer, iUnit, iPromotionType)
	local pPlayer = Players[iPlayer]
	if not pPlayer:IsMajorCiv() then
		return
	end
	local pUnit = pPlayer:GetUnitByID(iUnit)
	if pUnit == nil then
		return
	end

	--限制部分晋升不可选择
	if GameInfo.UnitPromotions[iPromotionType].CannotChooseInPT == 1 then
		return false
	end

	--限制破坏射击需要间接火力
	if iPromotionType == GameInfoTypes.PROMOTION_CANNON_DAMAGE_SHOT then
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_INDIRECT_FIRE"].ID) then
			return true
		end
		return false
	end

	--限制斯巴达才可选血战到底
	if iPromotionType == GameInfoTypes.PROMOTION_SPARTAN300_FIGHT_TO_THE_END then
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_ELITE_DEFENSE"].ID) then
			return true
		end
		return false
	end

	--限制俾斯麦需要舰炮齐射才可选齐射强化
	if iPromotionType == GameInfoTypes.PROMOTION_SHIPBORNE_GUN_SALVO_2 then
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_UNIT_ELITE_BATTLECRUISER_MARK"].ID) then
			return true
		end
		return false
	end

	--限制穿甲弹额外前置旗舰
	if iPromotionType == GameInfoTypes.PROMOTION_BATTLESHIP_ARMOUR_PIERCING_PROJECTILE then
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_CAPITAL_SHIP"].ID) then
			return true
		end
		return false
	end

	--重型机甲不能选冲锋
	if iPromotionType == GameInfoTypes.PROMOTION_CHARGE_1 then
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_HEAVY_ROBORT"].ID) then
			return false
		end
		return true
	end

	--限制铁甲舰之前的海军近战选择主炮强化和雷击战术，并设置这两个晋升互斥
	if iPromotionType == GameInfoTypes.PROMOTION_DESTROYER_MAIN_GUN_REINFORCEMENT then  --主炮强化
		if pUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_NAVALMELEE then
			if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_DESTROYER_LIGHTNING_STRIKE_TACTICS"].ID)
			then
				return false
			end
			return true
		end
		return false
	end
	if iPromotionType == GameInfoTypes.PROMOTION_DESTROYER_LIGHTNING_STRIKE_TACTICS then--雷击战术
		if pUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_NAVALMELEE then
			if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_DESTROYER_MAIN_GUN_REINFORCEMENT"].ID)
			then
				return false
			end
			return true
		end
		return false
	end

	return true
end
GameEvents.CanHavePromotion.Add(QYUnitCanHavePromotion)

local FlagShipLock0 =GameInfo.UnitPromotions["PROMOTION_FLAGSHIP_LOCKING"].ID
function QYAIUnitCreatedBonus(iPlayer, iUnit, iUnitType, iPlotX, iPlotY)

    local pPlayer = Players[iPlayer]
    local pUnit = pPlayer:GetUnitByID(iUnit)
    if not pPlayer:IsMajorCiv() or pUnit == nil or pPlayer:IsHuman() or pPlayer:GetCurrentEra() <2 then
        return
    end
	local QYRandomNum = Game.Rand(8, "ExPromotion AI Unit Created Buff Bonus")
	--print("AI Unit Created Buff Bonus Random Num:",QYRandomNum)

	if (pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_SHIP"].ID) --海军远程晋升
	or pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_CRUISER"].ID)) --巡洋舰晋升
	then
        local getBuffPossibility = -2
		getBuffPossibility = getBuffPossibility + pPlayer:GetCurrentEra() +1
		
		if QYRandomNum < getBuffPossibility then
			pUnit:SetHasPromotion((GameInfo.UnitPromotions["PROMOTION_SHIPBORNE_GUN_SALVO"].ID), true)
		end
	end

	if (pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_HIT_AND_RUN"].ID) --游猎晋升
	or pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SUBMARINE_COMBAT"].ID)) --潜艇晋升
	then
        local getBuffPossibility = -3
		getBuffPossibility = getBuffPossibility + pPlayer:GetCurrentEra() +1
		
		if QYRandomNum < getBuffPossibility then
			pUnit:SetHasPromotion(FlagShipLock0, true)
		end
	end

	if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_AIR_ATTACK"].ID) --攻击机晋升
	then
        local getBuffPossibility = -5
		getBuffPossibility = getBuffPossibility + pPlayer:GetCurrentEra() +1
		
		if QYRandomNum < getBuffPossibility then
			--海空神剑
			pUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_AIR_EXCALIBUR"].ID, true)
			local getBuffPossibility2 = -6
			getBuffPossibility2 = getBuffPossibility2 + pPlayer:GetCurrentEra() +1
			if QYRandomNum < getBuffPossibility2 then
				--向死而生
				pUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_AIR_TO_DIE_AND_LIVE"].ID, true)
			end	
		end
	end
end
GameEvents.UnitCreated.Add(QYAIUnitCreatedBonus)

print("ExPromotion Base Rules Check Pass!")
