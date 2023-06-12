--BUG规避
--统一前置
UPDATE UnitPromotions SET PromotionPrereqOr1 = PromotionPrereq
WHERE PromotionPrereq IS NOT NULL AND PromotionPrereqOr1 IS NULL;
UPDATE UnitPromotions SET PromotionPrereq=NULL;
--删除重复列
DELETE FROM UnitPromotions_UnitCombats
WHERE rowid NOT IN (SELECT min(rowid) FROM UnitPromotions_UnitCombats GROUP BY PromotionType,UnitCombatType);
--断掉近战的防御晋升线
DELETE FROM UnitPromotions_UnitCombats WHERE PromotionType = 'PROMOTION_ARMOR_TURTLESHIP_3' AND UnitCombatType = 'UNITCOMBAT_MELEE'
AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

--有部分晋升，其前置晋升已经和前一个晋升不相似,需要额外处理,否则无法正确显示
--DROP TABLE SpecialRulePromotion;
CREATE TABLE IF NOT EXISTS SpecialRulePromotion(SpecialPromotion text PRIMARY KEY DEFAULT NULL);
INSERT INTO SpecialRulePromotion(SpecialPromotion)
--空中修理
SELECT 'PROMOTION_AIR_REPAIR' UNION ALL
--装甲一级
SELECT 'PROMOTION_ARMOR_7' UNION ALL
--舰炮齐射
SELECT 'PROMOTION_SHIPBORNE_GUN_SALVO' UNION ALL
--攻坚
SELECT 'PROMOTION_SIEGE6' UNION ALL
--天空神剑
SELECT 'PROMOTION_AIR_EXCALIBUR';


CREATE TABLE IF NOT EXISTS UnitCombatInfosEx (
    CombatClass text DEFAULT NULL, 
    --Description text REFERENCES Language_zh_CN(Tag),
    --DefaultUnitType text REFERENCES Units(Type),
    Description text ,
    DefaultUnitType text ,
    IsDefault boolean DEFAULT false,
    --BasePromotion text DEFAULT NULL REFERENCES UnitPromotions(Type));
    BasePromotion text DEFAULT NULL );

INSERT INTO UnitCombatInfosEx(CombatClass,Description,DefaultUnitType,IsDefault,BasePromotion)
--民兵(包括绿水海军)
SELECT 'UNITCOMBAT_RECON','TXT_KEY_PROMOTION_MILITIA_COMBAT','UNIT_WARRIOR','true','PROMOTION_MILITIA_COMBAT' UNION ALL
--侦察单位(包括轻帆船)
SELECT 'UNITCOMBAT_RECON','TXT_KEY_PROMO_MOD_DESC_RECON','UNIT_SCOUT','false','PROMOTION_RECON_UNIT' UNION ALL

--重装步兵
SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_INFANTRY_COMBAT','UNIT_SWORDSMAN','false','PROMOTION_INFANTRY_COMBAT' UNION ALL
--火药步兵
SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_GUNPOWDER_INFANTRY_COMBAT','UNIT_MUSKETMAN','false','PROMOTION_GUNPOWDER_INFANTRY_COMBAT' UNION ALL
--方针步兵
SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_ANTI_MOUNTED','UNIT_SPEARMAN','false','PROMOTION_ANTI_MOUNTED' UNION ALL
--反装甲单位
SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_ANTI_TANK','UNIT_ANTI_TANK_GUN','false','PROMOTION_ANTI_TANK' UNION ALL
--陆军远程
SELECT 'UNITCOMBAT_SIEGE','TXT_KEY_PROMOTION_ARCHERY_COMBAT','UNIT_ARCHER','false','PROMOTION_ARCHERY_COMBAT' UNION ALL
--防空单位
SELECT 'UNITCOMBAT_SIEGE','TXT_KEY_PROMOTION_ANTI_AIR','UNIT_ANTI_AIRCRAFT_GUN','false','PROMOTION_ANTI_AIR' UNION ALL
--攻城武器
SELECT 'UNITCOMBAT_SIEGE','TXT_KEY_PROMOTION_CITY_SIEGE','UNIT_CATAPULT','false','PROMOTION_CITY_SIEGE' UNION ALL
--重装骑兵
SELECT 'UNITCOMBAT_MOUNTED','TXT_KEY_PROMOTION_KNIGHT_COMBAT','UNIT_HORSEMAN','false','PROMOTION_KNIGHT_COMBAT' UNION ALL
--坦克
SELECT 'UNITCOMBAT_ARMOR','TXT_KEY_PROMOTION_TANK_COMBAT','UNIT_WWI_TANK','false','PROMOTION_TANK_COMBAT' UNION ALL
--陆军游猎
SELECT 'UNITCOMBAT_HELICOPTER','TXT_KEY_PROMOTION_HITANDRUN','UNIT_CHARIOT_ARCHER','false','PROMOTION_HITANDRUN' UNION ALL
--直升机
SELECT 'UNITCOMBAT_HELICOPTER','TXT_KEY_PROMOTION_HELI_ATTACK','UNIT_HELICOPTER_GUNSHIP','false','PROMOTION_HELI_ATTACK' UNION ALL
--陆军AOE
SELECT 'UNITCOMBAT_BOMBER','TXT_KEY_PROMOTION_SPLASH_DAMAGE','UNIT_KATYUSHA','false','PROMOTION_SPLASH_DAMAGE' UNION ALL
--陆军特战
SELECT 'UNITCOMBAT_GUN','TXT_KEY_PROMOTION_SPECIAL_FORCES_COMBAT','UNIT_NATIONAL_GUARD','false','PROMOTION_SPECIAL_FORCES_COMBAT' UNION ALL

--海军近战
SELECT 'UNITCOMBAT_NAVALMELEE','TXT_KEY_PROMOTION_NAVALMELEE_COMBAT','UNIT_GALLEASS','false','PROMOTION_NAVALMELEE_COMBAT' UNION ALL
--驱逐舰
SELECT 'UNITCOMBAT_NAVALMELEE','TXT_KEY_PROMOTION_DESTROYER_COMBAT','UNIT_DESTROYER','false','PROMOTION_DESTROYER_COMBAT' UNION ALL
--海军远程
SELECT 'UNITCOMBAT_NAVALRANGED','TXT_KEY_PROMOTION_NAVAL_RANGED_SHIP','UNIT_VENETIAN_GALLEASS','false','PROMOTION_NAVAL_RANGED_SHIP' UNION ALL
--巡洋舰
SELECT 'UNITCOMBAT_NAVALRANGED','TXT_KEY_PROMOTION_NAVAL_RANGED_CRUISER','UNIT_HEAVY_CRUISER','false','PROMOTION_NAVAL_RANGED_CRUISER' UNION ALL
--海军游猎
SELECT 'UNITCOMBAT_SUBMARINE','TXT_KEY_PROMOTION_NAVAL_HIT_AND_RUN','UNIT_BYZANTINE_DROMON','false','PROMOTION_NAVAL_HIT_AND_RUN' UNION ALL
--潜艇
SELECT 'UNITCOMBAT_SUBMARINE','TXT_KEY_PROMOTION_SUBMARINE_COMBAT','UNIT_SUBMARINE','false','PROMOTION_SUBMARINE_COMBAT' UNION ALL
--航母
SELECT 'UNITCOMBAT_CARRIER','TXT_KEY_PROMOTION_CARRIER_UNIT','UNIT_CARRIER','false','PROMOTION_CARRIER_UNIT' UNION ALL
--旗舰
SELECT 'UNITCOMBAT_NAVALRANGED','TXT_KEY_PROMOTION_NAVAL_CAPITAL_SHIP','UNIT_BATTLESHIP','false','PROMOTION_NAVAL_CAPITAL_SHIP' UNION ALL

--战斗机
SELECT 'UNITCOMBAT_FIGHTER','TXT_KEY_PROMOTION_ANTI_AIR_II','UNIT_FIGHTER','false','PROMOTION_ANTI_AIR_II' UNION ALL
--攻击机
SELECT 'UNITCOMBAT_ARCHER','TXT_KEY_PROMOTION_AIR_ATTACK','UNIT_DIVE_BOMBER','false','PROMOTION_AIR_ATTACK' UNION ALL
--战略轰炸机
SELECT 'UNITCOMBAT_ARCHER','TXT_KEY_PROMOTION_STRATEGIC_BOMBER','UNIT_JET_BOMBER','false','PROMOTION_STRATEGIC_BOMBER' ;


--世界强权兼容-晋升前置以及整合
INSERT INTO UnitCombatInfosEx(CombatClass,Description,DefaultUnitType,IsDefault,BasePromotion)
--机械步兵
SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_ROBORT_COMBAT','UNIT_FW_BATTLESUIT','false','PROMOTION_ROBORT_COMBAT' 
WHERE EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1) UNION ALL
--重型机甲
SELECT 'UNITCOMBAT_ARMOR','TXT_KEY_PROMOTION_HEAVY_ROBORT','UNIT_AEGIS','false','PROMOTION_HEAVY_ROBORT'
WHERE EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);

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

