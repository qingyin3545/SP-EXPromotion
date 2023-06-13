include("FLuaVector.lua")
--变量
local FlagShipLock0 =GameInfo.UnitPromotions["PROMOTION_FLAGSHIP_LOCKING"].ID
local FlagShipLock1 = GameInfo.UnitPromotions["PROMOTION_FLAGSHIP_LOCKING_PRE_1"].ID
local FlagShipLock2 = GameInfo.UnitPromotions["PROMOTION_FLAGSHIP_LOCKING_PRE_2"].ID
local FlagShipLock3 = GameInfo.UnitPromotions["PROMOTION_FLAGSHIP_LOCKING_PRE_3"].ID

local ShipBorneGunSalvo = GameInfo.UnitPromotions["PROMOTION_SHIPBORNE_GUN_SALVO"].ID
local ShipBorneGunSalvo2 = GameInfo.UnitPromotions["PROMOTION_SHIPBORNE_GUN_SALVO_2"].ID


function QYPlayersIsAtWar(iPlayer,ePlayer)
	local iTeam = Teams[iPlayer:GetTeam()];
	local eTeamIndex = ePlayer:GetTeam();
	if iTeam:IsAtWar(eTeamIndex) then
		return true;
	else
		return false;
	end
end	--战争判定

--心战、心战强化生成新单位
function QYNewUnitCreate(iPlayer,iUnit,iEnemyUnit,plotX,plotY)
	local newUnitType = iEnemyUnit:GetUnitType()
	local newUnit = iPlayer:InitUnit(newUnitType, plotX, plotY)
	--需要消耗20点HP，但不会因此死亡，如果攻击方只有1点HP，生成失败
	local attUnitHPExpend = 20
	if iUnit:GetCurrHitPoints() <= attUnitHPExpend then
		attUnitHPExpend = iUnit:GetCurrHitPoints() -1;
	end
	if iUnit:GetCurrHitPoints() <= 1 then
		print("Attack Unit is at death's door, stop create new Unit");
		return
	end
	iUnit:ChangeDamage(attUnitHPExpend)
	newUnit:ChangeDamage(newUnit:GetMaxHitPoints() - attUnitHPExpend)
	--依据攻击单位的剩余移动力赋予新单位移动力，且至少为1
	local attUnitMoves = iUnit:GetMoves()
	if attUnitMoves < 1 then
		attUnitMoves = 1
	end
	newUnit:SetMoves(attUnitMoves)
	newUnit:JumpToNearestValidPlot()
end

--战斗中伤害加成
function QYBattleCustomDamage(iBattleUnitType, iBattleType,
	iAttackPlayerID, iAttackUnitOrCityID, bAttackIsCity, iAttackDamage,
	iDefensePlayerID, iDefenseUnitOrCityID, bDefenseIsCity, iDefenseDamage,
	iInterceptorPlayerID, iInterceptorUnitOrCityID, bInterceptorIsCity, iInterceptorDamage)

	local attPlayer = Players[iAttackPlayerID]
	local defPlayer = Players[iDefensePlayerID]
	if attPlayer == nil or defPlayer == nil then
		return 0
	end
	if not attPlayer:IsHuman() and not defPlayer:IsHuman() then
		return 0;
	end

	--进攻
	if iBattleUnitType == GameInfoTypes["BATTLEROLE_ATTACKER"] then

		local attUnit = attPlayer:GetUnitByID(iAttackUnitOrCityID)
		if bAttackIsCity or attUnit == nil then
			return 0
		end
		local additionalDamage = 0
		local defUnit = defPlayer:GetUnitByID(iDefenseUnitOrCityID)

		--覆盖轰炸城市伤害加成
		if bDefenseIsCity
		and attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_EXP_COVER_BOMBING"].ID) 
		then
			local defCity = defPlayer:GetCityByID(iDefenseUnitOrCityID) 
			if defCity == nil then return 0 end
			additionalDamage = additionalDamage + defCity:GetMaxHitPoints() * 0.15
			print("覆盖轰炸城市伤害加成!",additionalDamage)
		end

		
		
		if not bDefenseIsCity then
			--饱和打击固定加成
			if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATURATION_STRIKE_1"].ID) 
			and defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CORPS_1"].ID) 
			then

				additionalDamage = additionalDamage+10
				--print ("饱和打击军团伤害加成!",additionalDamage)
			end

			if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATURATION_STRIKE_2"].ID) 
			and defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CORPS_2"].ID) 
			then
				additionalDamage = additionalDamage+10
				--print ("饱和打击集团军伤害加成!",additionalDamage)
			end
		end

		return additionalDamage
	end

	--防御
	if iBattleUnitType == GameInfoTypes["BATTLEROLE_DEFENDER"] then
		--print ("伤害加成防御玩家检测通过!")
		if bAttackIsCity or bDefenseIsCity then
			return 0
		end
		local defUnit = defPlayer:GetUnitByID(iDefenseUnitOrCityID)
		local attUnit = attPlayer:GetUnitByID(iAttackUnitOrCityID)
		if defUnit == nil or attUnit == nil then
			return 0
		end
		--斯巴达血战到底
		if defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SPARTAN300_FIGHT_TO_THE_END"].ID)
		and defUnit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SPARTAN300 
		and not (attUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_MOUNTED) --非重骑兵
		and not (attUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_ARMOR) --非坦克
		and iBattleType == GameInfoTypes["BATTLETYPE_MELEE"]
		and defUnit:GetDomainType() == attUnit:GetDomainType()
		then
			--print ("血战到底伤害条件检测通过!")
			return 10
		end
	end

	return 0
end
GameEvents.BattleCustomDamage.Add(QYBattleCustomDamage)

function QYBattleStarted(iType, iPlotX, iPlotY)
	if iType == GameInfoTypes["BATTLETYPE_MELEE"]
	or iType == GameInfoTypes["BATTLETYPE_RANGED"]
	or iType == GameInfoTypes["BATTLETYPE_AIR"]
	or iType == GameInfoTypes["BATTLETYPE_SWEEP"]
	then
		g_DoQYBattle = {
			attPlayerID = -1,
			attUnitID   = -1,
			defPlayerID = -1,
			defUnitID   = -1,
			attODamage  = 0,
			defODamage  = 0,
			PlotX = iPlotX,
			PlotY = iPlotY,
			bIsCity = false,
			defCityID = -1,
			battleType = iType,
		};
		--print("战斗开始.")
	end
end
GameEvents.BattleStarted.Add(QYBattleStarted)

function QYBattleJoined(iPlayer, iUnitOrCity, iRole, bIsCity)
	local pPlayer = Players[iPlayer]
	if g_DoQYBattle == nil
	or pPlayer == nil or not pPlayer:IsAlive()
	or (not bIsCity and pPlayer:GetUnitByID(iUnitOrCity) == nil)
	or (bIsCity and (pPlayer:GetCityByID(iUnitOrCity) == nil or iRole == GameInfoTypes["BATTLEROLE_ATTACKER"]))
	or iRole == GameInfoTypes["BATTLEROLE_BYSTANDER"]
	then
		return;
	end
	if bIsCity then
		g_DoQYBattle.defPlayerID = iPlayer;
		g_DoQYBattle.defCityID = iUnitOrCity;
		g_DoQYBattle.bIsCity = bIsCity;
	elseif iRole == GameInfoTypes["BATTLEROLE_ATTACKER"] then
		g_DoQYBattle.attPlayerID = iPlayer;
		g_DoQYBattle.attUnitID = iUnitOrCity;
		g_DoQYBattle.attODamage = pPlayer:GetUnitByID(iUnitOrCity):GetDamage();
	elseif iRole == GameInfoTypes["BATTLEROLE_DEFENDER"] or iRole == GameInfoTypes["BATTLEROLE_INTERCEPTOR"] then
		g_DoQYBattle.defPlayerID = iPlayer;
		g_DoQYBattle.defUnitID = iUnitOrCity;
		g_DoQYBattle.defODamage = pPlayer:GetUnitByID(iUnitOrCity):GetDamage();
	end
	--print("加入战斗.")

end
GameEvents.BattleJoined.Add(QYBattleJoined)

local AirExcaliburID = GameInfo.UnitPromotions["PROMOTION_AIR_EXCALIBUR"].ID
local ToDieAndLiveID = GameInfo.UnitPromotions["PROMOTION_AIR_TO_DIE_AND_LIVE"].ID

function QYBattleEffect()
	--Defines and status checks
	if g_DoQYBattle == nil or Players[ g_DoQYBattle.defPlayerID ] == nil
	or Players[ g_DoQYBattle.attPlayerID ] == nil or not Players[ g_DoQYBattle.attPlayerID ]:IsAlive()
	or Players[ g_DoQYBattle.attPlayerID ]:GetUnitByID(g_DoQYBattle.attUnitID) == nil
	or Map.GetPlot(g_DoQYBattle.PlotX, g_DoQYBattle.PlotY) == nil
	then
		return
	end
   
	local attPlayerID = g_DoQYBattle.attPlayerID
	local attPlayer = Players[ attPlayerID ]
	local defPlayerID = g_DoQYBattle.defPlayerID
	local defPlayer = Players[ defPlayerID ]

	local attUnit = attPlayer:GetUnitByID(g_DoQYBattle.attUnitID)
	local attPlot = attUnit:GetPlot()

	local plotX = g_DoQYBattle.PlotX
	local plotY = g_DoQYBattle.PlotY
	local batPlot = Map.GetPlot(plotX, plotY)
	local batType = g_DoQYBattle.battleType

	local bIsCity = g_DoQYBattle.bIsCity
	local defUnit = nil
	local defPlot = nil
	local defCity = nil

	local attFinalUnitDamage = attUnit:GetDamage()
	local defFinalUnitDamage = 0
	local attUnitDamage = attFinalUnitDamage - g_DoQYBattle.attODamage
	local defUnitDamage = 0
   
	if not bIsCity and defPlayer:GetUnitByID(g_DoQYBattle.defUnitID) then
		defUnit = defPlayer:GetUnitByID(g_DoQYBattle.defUnitID)
		defPlot = defUnit:GetPlot()
		defFinalUnitDamage = defUnit:GetDamage()
		defUnitDamage = defFinalUnitDamage - g_DoQYBattle.defODamage
	elseif bIsCity and defPlayer:GetCityByID(g_DoQYBattle.defCityID) then
		defCity = defPlayer:GetCityByID(g_DoQYBattle.defCityID)
	end

	g_DoQYBattle = nil;
	--Complex Effects Only for Human VS AI(reduce time and enhance stability)
	if not attPlayer:IsHuman() and not defPlayer:IsHuman() then
		return;
	end
	--print("战斗结束.")

	--攻击机攻击时受损70+并存活赋予海空神剑
	if attUnit and not attUnit:IsDead()
	and attUnitDamage > 70 
	and attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_AIR_ATTACK"].ID) 
	and not attUnit:IsHasPromotion(AirExcaliburID) 
	then
		print("ExPromotion: 赋予海空神剑晋升!")
		attUnit:SetHasPromotion(AirExcaliburID, true)
		local hex = ToHexFromGrid(Vector2(attUnit:GetX(), attUnit:GetY()))
		Events.AddPopupTextEvent(HexToWorld(hex), Locale.ConvertTextKey("TXT_KEY_PROMOTION_AIR_EXCALIBUR"))
		Events.GameplayFX(hex.x, hex.y, -1)
	end

	--海空神剑攻击死亡复活
	if attUnit:IsHasPromotion(AirExcaliburID) 
	and not attUnit:IsHasPromotion(ToDieAndLiveID)
	and (attUnit:GetDamage() >= attUnit:GetMaxHitPoints() or attUnit:IsDead())
	then
		local unitX = attUnit:GetX()
		local unitY = attUnit:GetY()

		local NewUnit = attPlayer:InitUnit(attUnit:GetUnitType(), unitX, unitY, attUnit:GetUnitAIType())
		NewUnit:SetLevel(attUnit:GetLevel())
		NewUnit:SetExperience(attUnit:GetExperience())
		for unitPromotion in GameInfo.UnitPromotions() do
			local unitPromotionID = unitPromotion.ID 
			if attUnit:IsHasPromotion(unitPromotionID) and not unitPromotion.LostWithUpgrade then
				NewUnit:SetHasPromotion(unitPromotionID, true)
			end
		end
		NewUnit:SetDamage(80)
		NewUnit:SetMoves(1)
		--赋予向死而生，同时也是标记
		NewUnit:SetHasPromotion(ToDieAndLiveID, true)
		local hex = ToHexFromGrid(Vector2(unitX, unitY))
		Events.AddPopupTextEvent(HexToWorld(hex), Locale.ConvertTextKey("TXT_KEY_PROMOTION_AIR_TO_DIE_AND_LIVE"))
		Events.GameplayFX(hex.x, hex.y, -1)
		print("ExPromotion: 向死而生!")
		if attPlayer:IsHuman() then
			Events.GameplayAlertMessage( Locale.ConvertTextKey( "TXT_KEY_MESSAGE_PROMOTION_AIR_TO_DIE_AND_LIVE", NewUnit:GetName()) )
		end
	end

	--攻击移除工事破坏
	if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FORT_DESTRUCTION_OF_WORKS"].ID) then
		attUnit:SetHasPromotion((GameInfo.UnitPromotions["PROMOTION_FORT_DESTRUCTION_OF_WORKS"].ID), false)
	end

	--海军远程获得后勤补给后攻击概率获得舰炮齐射
	if (attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_SHIP"].ID) --海军远程晋升
	or attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_RANGED_CRUISER"].ID)) --巡洋舰晋升
	and attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_LOGISTICS"].ID) --后勤补给
	and not attUnit:IsHasPromotion(ShipBorneGunSalvo) --没有舰炮齐射
	then
		local QYRandomNum = Game.Rand(100, "ExPromotion Ship Borne Gun Salvo Random") +1
		print("获取随机数:",QYRandomNum)
		if attUnit:GetUnitClassType() == GameInfoTypes.UNITCLASS_ELITE_BATTLECRUISER then --俾斯麦号100%获得
			QYRandomNum = 1
		end
		if QYRandomNum < 21 then
			--显示信息
			if attPlayer:IsHuman() then
				Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_SHIPBORNE_GUN_SALVO_ALERT", attUnit:GetName()) )
			end
			attUnit:SetHasPromotion(ShipBorneGunSalvo, true) --赋予晋升
		end
	end

	--*****************************************************************************************--
	--对城市无效部分
	if  bIsCity then return end
	local defUnitType = defUnit:GetUnitType()
	--*****************************************************************************************--

	--适应三级移动力减半
	if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_EXP_ADAPT_3"].ID) 
	and defUnit:GetDomainType() == attUnit:GetDomainType()
	and not defUnit:IsDead()
	then
		local maxMoves = defUnit:GetMoves()
		maxMoves = math.ceil(maxMoves*0.5/60)
		defUnit:ChangeMoves(-maxMoves*60)
		if attPlayer:IsHuman() and maxMoves > 0 then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PROMOTION_EXP_ADAPT_3_ALERT", defUnit:GetName(), attUnit:GetName(), maxMoves) )
		end
	end

	--技能三级
	
	if (GameInfo.Units[defUnitType].ProjectPrereq == nil
	or	GameInfo.Units[defUnitType].HurryCostModifier >= 0)
	and defUnit:IsDead()
	and defUnit:GetDomainType() == attUnit:GetDomainType()
	and attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SP_FORCE_3"].ID) 
	then
		local QYRandomNum = Game.Rand(85, "ExPromotion SP_FORCE_3 Capture the enemy")
		print("QYRandomNum SP_FORCE_3 Capture the enemy:",QYRandomNum,defUnitDamage)
		if QYRandomNum < defUnitDamage then
			print("ExPromotion: Captured the enemy!")
			QYNewUnitCreate(attPlayer,attUnit,defUnit,plotX,plotY)
		end
	end
	
	if GameInfo.Units[defUnitType].ProjectPrereq ~= nil
	and GameInfo.Units[defUnitType].HurryCostModifier == -1
	and defUnit:IsDead()
	and defUnit:GetDomainType() == attUnit:GetDomainType()
	and attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_EXP_ADAPT_3"].ID) 
	and attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SP_FORCE_3"].ID) 
	then
		--单位拥有适应三级以及技能三级后，击败敌方精英获得精通强化
		if not attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_EXP_ADAPT_4"].ID) then
			attUnit:SetHasPromotion(GameInfo.UnitPromotions["PROMOTION_EXP_ADAPT_4"].ID,true)
			if attPlayer:IsHuman() then
				local hex = ToHexFromGrid(Vector2(attPlot:GetX(),attPlot:GetY()))
				Events.AddPopupTextEvent(HexToWorld(hex), Locale.ConvertTextKey("TXT_KEY_PROMOTION_EXP_ADAPT_4"))
				Events.GameplayFX(hex.x, hex.y, -1)
			end
		--若已经拥有精通强化,判断是否捕获
		else
			local eliteID = GameInfo.UnitClasses[defUnit:GetUnitClassType()].ID
			local numOfThisElite = attPlayer:GetUnitClassCount(eliteID)
			print("该单位拥有数:",numOfThisElite)
			if numOfThisElite < 1 then
				print("ExPromotion: Captured the enemy Elite!")
				QYNewUnitCreate(attPlayer,attUnit,defUnit,plotX,plotY)
			end
		end
	end

	--破坏射击赋予工事毁坏
	if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CANNON_DAMAGE_SHOT"].ID)
	and not defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FORT_DESTRUCTION_OF_WORKS"].ID)
	and defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID)
	and not defUnit:IsDead()
	then
		local QYRandomNum = Game.Rand(100, "ExPromotion Cannon Damage Random") +1
		print("获取随机数:",QYRandomNum)
		if QYRandomNum < 50 then
			if attPlayer:IsHuman() then
				Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_CANNON_DAMAGE_SHOT_1",attUnit:GetName(),defUnit:GetName()) )
			elseif defPlayer:IsHuman() then
				Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_CANNON_DAMAGE_SHOT_2",attUnit:GetName(),defUnit:GetName()) )
			end
			defUnit:SetHasPromotion((GameInfo.UnitPromotions["PROMOTION_FORT_DESTRUCTION_OF_WORKS"].ID),true)
		end
	end
	
	--旗舰海军舰载副炮反击
	if defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_BATTLESHIP_SECONDARY_GUN"].ID) then
		if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_HIT_AND_RUN"].ID) then
			local AttUnitRangedCombat = GameInfo.Units[attUnit:GetUnitType()].RangedCombat
			local DefUnitRangedCombat = GameInfo.Units[defUnit:GetUnitType()].RangedCombat
			--向上取整
			local BattleshipBeatBackMax = math.ceil(DefUnitRangedCombat/AttUnitRangedCombat) * 20
			--print("副炮反击最大伤害:",BattleshipBeatBackMax)
			local QYRandomNum = Game.Rand(100, "ExPromotion BattleShip Seconder Gun Random") +1
			print("获取随机数:",QYRandomNum)
			if QYRandomNum < BattleshipBeatBackMax then
				if QYRandomNum >= attUnit:GetCurrHitPoints() then
					QYRandomNum = attUnit:GetCurrHitPoints()
				end
				attUnit:ChangeDamage(QYRandomNum) 
				--显示信息
				if attPlayer:IsHuman() then
					Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_BATTLESHIP_SECONDARY_GUN_ALERT_1",defUnit:GetName(),attUnit:GetName(),QYRandomNum) )
				elseif defPlayer:IsHuman() then
					Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_BATTLESHIP_SECONDARY_GUN_ALERT_2",defUnit:GetName(),attUnit:GetName(),QYRandomNum) )
				end
			end
		end
	end

	--海军游猎累计击杀旗舰海军或者航母获得旗舰锁定晋升
	if (attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_HIT_AND_RUN"].ID) --游猎晋升
	or attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SUBMARINE_COMBAT"].ID)) --潜艇晋升
	and not attUnit:IsHasPromotion(FlagShipLock0) --没有旗舰锁定
	then 
		
		--击杀精英旗舰直接获得晋升
		if defUnit:IsDead() 
		and GameInfo.UnitClasses[defUnit:GetUnitClassType()].MaxPlayerInstances == 1
		and GameInfo.Units[defUnit:GetUnitType()].ProjectPrereq ~= nil
		and defUnit:GetDomainType()==DomainTypes.DOMAIN_SEA
		then
			attUnit:SetHasPromotion(FlagShipLock1, false)
			attUnit:SetHasPromotion(FlagShipLock2, false)
			attUnit:SetHasPromotion(FlagShipLock3, false)
			--显示信息
			if attPlayer:IsHuman() then
				Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_FLAGSHIP_LOCKING_ALERT_2", attUnit:GetName()) )
			end
			attUnit:SetHasPromotion(FlagShipLock0, true) --赋予晋升
			return
		end

		if defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_NAVAL_CAPITAL_SHIP"].ID) --旗舰晋升
		or defUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_CARRIER --航母
		then
			local hex = ToHexFromGrid(Vector2(attPlot:GetX(),attPlot:GetY()))
			if attUnit:IsHasPromotion(FlagShipLock3) then
				--显示信息
				if attPlayer:IsHuman() then
					Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MESSAGE_PROMOTION_FLAGSHIP_LOCKING_ALERT", attUnit:GetName()) )
				end
				attUnit:SetHasPromotion(FlagShipLock3, false) --移除晋升
				attUnit:SetHasPromotion(FlagShipLock0, true) --赋予旗舰锁定晋升
			elseif attUnit:IsHasPromotion(FlagShipLock2) then
				attUnit:SetHasPromotion(FlagShipLock2, false) --移除晋升
				attUnit:SetHasPromotion(FlagShipLock3, true) --赋予晋升3
				Events.AddPopupTextEvent(HexToWorld(hex), Locale.ConvertTextKey("TXT_KEY_PROMOTION_FLAGSHIP_LOCKING_PRE_3"))
			elseif attUnit:IsHasPromotion(FlagShipLock1) then
				attUnit:SetHasPromotion(FlagShipLock1, false) --移除晋升
				attUnit:SetHasPromotion(FlagShipLock2, true) --赋予晋升2
				Events.AddPopupTextEvent(HexToWorld(hex), Locale.ConvertTextKey("TXT_KEY_PROMOTION_FLAGSHIP_LOCKING_PRE_2"))
			else 
				attUnit:SetHasPromotion(FlagShipLock1, true) --赋予晋升1
				Events.AddPopupTextEvent(HexToWorld(hex), Locale.ConvertTextKey("TXT_KEY_PROMOTION_FLAGSHIP_LOCKING_PRE_1"))
			end
			Events.GameplayFX(hex.x, hex.y, -1)
		end
	end

end
GameEvents.BattleFinished.Add(QYBattleEffect)

print("ExPromotion Combat Rules Check Pass!")