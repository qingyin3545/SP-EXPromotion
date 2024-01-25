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
INSERT INTO ROG_GlobalUserSettings(Type, Value) SELECT 'EXPromtionsForWP', 0;

--DROP TRIGGER EXPromtionsForWP1;
--DROP TRIGGER EXPromtionsForWP2;
CREATE TRIGGER EXPromtionsForWP1
AFTER UPDATE ON ROG_GlobalUserSettings
WHEN NEW.Type = 'EXPromtionsForWP' AND NEW.Value= 1
BEGIN
	--世界强权穿甲弹增强
    UPDATE UnitPromotions_PromotionModifiers SET Attack = 225
    WHERE PromotionType = 'PROMOTION_BATTLESHIP_ARMOUR_PIERCING_PROJECTILE' 
    AND OtherPromotionType = 'PROMOTION_CITADEL_DEFENSE';

    --世界强权兼容-晋升前置
    INSERT INTO UnitCombatInfosEx(CombatClass,Description,DefaultUnitType,IsDefault,BasePromotion)
    --机械步兵
    SELECT 'UNITCOMBAT_MELEE','TXT_KEY_PROMOTION_ROBORT_COMBAT','UNIT_FW_BATTLESUIT','false','PROMOTION_ROBORT_COMBAT' UNION ALL
    --重型机甲
    SELECT 'UNITCOMBAT_ARMOR','TXT_KEY_PROMOTION_HEAVY_ROBORT','UNIT_AEGIS','false','PROMOTION_HEAVY_ROBORT';
END;

--开启兼容
UPDATE ROG_GlobalUserSettings SET Value = 1 WHERE Type = 'EXPromtionsForWP' AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'WORLD_POWER_PATCH' AND Value = 1);
CREATE TRIGGER EXPromtionsForWP2
AFTER UPDATE ON ROG_GlobalUserSettings
WHEN NEW.Type = 'WORLD_POWER_PATCH' AND NEW.Value= 1
BEGIN
    UPDATE ROG_GlobalUserSettings SET Value = 1 WHERE Type = 'EXPromtionsForWP' AND EXISTS (SELECT * FROM ROG_GlobalUserSettings WHERE Type= 'EXPromtionsForWP' AND Value = 0);
END;