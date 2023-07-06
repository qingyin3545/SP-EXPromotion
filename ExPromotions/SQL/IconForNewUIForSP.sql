/*--新图标触发器
CREATE TRIGGER QY_EXPromotion_IconStringSP8
AFTER INSERT ON UnitPromotions
WHEN NEW.IconAtlas = 'QY_EXPROMOTION_ATLAS'
BEGIN
    UPDATE UnitPromotions SET IconStringSP = '[ICON_PROMOTION_QY_EXPROMOTION_' || CAST(NEW.PortraitIndex+1 AS TEXT)|| ']'
    WHERE Type = NEW.Type;
END;*/

INSERT OR REPLACE INTO IconFontMapping(IconName,IconFontTexture,IconMapping) 
SELECT 'ICON_PROMOTION_QY_EXPROMOTION_' || CAST(PortraitIndex+1 AS TEXT),'ICON_FONT_TEXTURE_QY_EXPROMOTION',PortraitIndex+1 
FROM UnitPromotions WHERE IconAtlas = 'QY_EXPROMOTION_ATLAS';

UPDATE UnitPromotions SET IconStringSP = '[ICON_PROMOTION_QY_EXPROMOTION_' || CAST(PortraitIndex+1 AS TEXT)|| ']'
WHERE IconAtlas = 'QY_EXPROMOTION_ATLAS';

