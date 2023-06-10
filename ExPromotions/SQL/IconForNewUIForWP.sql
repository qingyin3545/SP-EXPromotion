/*CREATE TRIGGER QY_EXPromotion_IconStringWP
AFTER INSERT ON UnitPromotions
WHEN NEW.IconAtlas = 'QY_EXPROMOTION_ATLAS'
BEGIN
    UPDATE UnitPromotions SET IconString2 = '[ICON_PROMOTION_QY_EXPROMOTION_' || CAST(NEW.PortraitIndex+1 AS TEXT)|| ']'
    WHERE Type = NEW.Type;
END;*/

UPDATE UnitPromotions SET IconString2 = '[ICON_PROMOTION_QY_EXPROMOTION_' || CAST(PortraitIndex+1 AS TEXT)|| ']'
WHERE IconAtlas = 'QY_EXPROMOTION_ATLAS';