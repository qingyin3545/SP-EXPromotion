/*--强权已经更改了图标UI，不再需要另外插入了
--新图标触发器
CREATE TRIGGER QY_EXPromotion_IconStringWP
AFTER INSERT ON UnitPromotions
WHEN NEW.IconAtlas = 'QY_EXPROMOTION_ATLAS'
BEGIN
    UPDATE UnitPromotions SET IconString2 = '[ICON_PROMOTION_QY_EXPROMOTION_' || CAST(NEW.PortraitIndex+1 AS TEXT)|| ']'
    WHERE Type = NEW.Type;
END;
UPDATE UnitPromotions SET IconString2 = '[ICON_PROMOTION_QY_EXPROMOTION_' || CAST(PortraitIndex+1 AS TEXT)|| ']'
WHERE IconAtlas = 'QY_EXPROMOTION_ATLAS';*/

--世界强权兼容
CREATE TABLE IF NOT EXISTS ROG_GlobalUserSettings (Type text default null, Value integer default 0);
INSERT INTO ROG_GlobalUserSettings(Type, Value)
SELECT 'EXPromtionsForWP', 1;

--世界强权穿甲弹增强
UPDATE UnitPromotions_PromotionModifiers SET Attack = 225
WHERE PromotionType = 'PROMOTION_BATTLESHIP_ARMOUR_PIERCING_PROJECTILE' 
AND OtherPromotionType = 'PROMOTION_CITADEL_DEFENSE'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE Language_zh_CN SET Text = '攻击[COLOR_POSITIVE_TEXT]固定炮台[ENDCOLOR]+225%[ICON_STRENGTH]战斗力。'
WHERE Tag = 'TXT_KEY_PROMOTION_BATTLESHIP_ARMOUR_PIERCING_PROJECTILE_HELP' 
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--世界强权假晋升显示屏蔽
UPDATE UnitPromotions SET ShowInUnitPanel = CASE
	WHEN Type = 'PROMOTION_UNIT_ELITE_BATTLECRUISER_MARK' THEN 0
	WHEN Type = 'PROMOTION_UNIT_HORNET_MARK' THEN 0
	ELSE ShowInUnitPanel
	END
WHERE EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--世界强权兼容-晋升前置以及整合
INSERT INTO UnitCombatInfosEx(CombatClass,Description,DefaultUnitType,IsDefault,BasePromotion)
--机械步兵
SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_ROBORT_COMBAT','UNIT_FW_BATTLESUIT','false','PROMOTION_ROBORT_COMBAT' 
WHERE EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1) UNION ALL
--重型机甲
SELECT 'UNITCOMBAT_ARMOR','TXT_KEY_PROMOTION_HEAVY_ROBORT','UNIT_AEGIS','false','PROMOTION_HEAVY_ROBORT'
WHERE EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--断掉近战的防御晋升线
--DELETE FROM UnitPromotions_UnitCombats WHERE PromotionType = 'PROMOTION_ARMOR_TURTLESHIP_3' AND UnitCombatType = 'UNITCOMBAT_MELEE'
--AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--战略轰炸机晋升线整合:规避能力->航程拓展->空中维修
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_EVASION' WHERE Type = 'PROMOTION_AIR_RANGE_EXTEND'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_AIR_RANGE_EXTEND' WHERE Type = 'PROMOTION_AIR_REPAIR'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--重骑兵/坦克/重型机甲晋升线整合:机动能力->猛烈冲锋->攻坚
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_MOBILITY' WHERE Type = 'PROMOTION_HEAL_KILL_ENEMY'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr2 = NULL WHERE Type = 'PROMOTION_HEAL_KILL_ENEMY'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr3 = NULL WHERE Type = 'PROMOTION_HEAL_KILL_ENEMY'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_HEAL_KILL_ENEMY' WHERE Type = 'PROMOTION_SIEGE6'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr2 = NULL WHERE Type = 'PROMOTION_SIEGE6'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr3 = NULL WHERE Type = 'PROMOTION_SIEGE6'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--冲锋前置坦克或重骑兵(ID=94)(机甲没有这条线)
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_KNIGHT_COMBAT' WHERE Type = 'PROMOTION_CHARGE_1'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr2 = 'PROMOTION_TANK_COMBAT' WHERE Type = 'PROMOTION_CHARGE_1'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--装甲单位和机甲晋升线整合:操练1级->操练2级->操练3级-->修理能力
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_HEAVY_DRILL_3' WHERE Type = 'PROMOTION_REPAIR'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--航母晋升线整合:补给一级-->防御1级->防御2级->防御3级
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_CARRIER_SUPPLY_1' WHERE Type = 'PROMOTION_ARMOR_TURTLESHIP_3'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--陆军AOE和攻城单位晋升线整合:机动能力-->防御1级->防御2级->防御3级
UPDATE UnitPromotions SET PromotionPrereqOr3 = 'PROMOTION_MOBILITY' WHERE Type = 'PROMOTION_ARMOR_TURTLESHIP_3'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr2 = NULL WHERE Type = 'PROMOTION_ARMOR_TURTLESHIP_3'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--火力覆盖前置集束弹一级
UPDATE UnitPromotions SET PromotionPrereqOr1 = 'PROMOTION_CLUSTER_ROCKET_1' WHERE Type = 'PROMOTION_EQUICK'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--把强权旗舰的后勤补给换成闪击战术
UPDATE UnitPromotions SET PromotionPrereqOr7 = NULL WHERE Type = 'PROMOTION_LOGISTICS'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
UPDATE UnitPromotions SET PromotionPrereqOr7 = 'PROMOTION_PENETRATES' WHERE Type = 'PROMOTION_BLITZ'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
INSERT INTO UnitPromotions_UnitCombats(PromotionType,UnitCombatType)
SELECT 'PROMOTION_BLITZ', 'UNITCOMBAT_NAVALRANGED'
WHERE EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);