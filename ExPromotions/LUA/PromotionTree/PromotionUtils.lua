--
-- Promotion Utility functions
--
--
-- Unit promotion functions
--
function HasPromotion(pUnit, iPromotion)
    return (pUnit and pUnit:IsHasPromotion(iPromotion))
end

function CanAcquirePromotion(pUnit, iPromotion)
    if (pUnit and pUnit:CanAcquirePromotion(iPromotion)) then
        local iAction = GetActionForPromotion(iPromotion)
        return (iAction and Game.CanHandleAction(iAction))
    end

    return false
end

--
-- Action promotion functions
--

function GetActionForPromotion(iPromotion)
    local promotion = GameInfo.UnitPromotions[iPromotion]

    for iAction, action in pairs(GameInfoActions) do
        if (action.SubType == ActionSubTypes.ACTIONSUBTYPE_PROMOTION and
            action.Type == promotion.Type) then return iAction end
    end

    return nil
end

--
-- Promotions database lookup functions
--
local sMatchRank = "_[0-9IV]+$" --正则表达式，大概是匹配名字中有0-9IV字符的晋升

function IsRankedPromotion(sPromotion) -- UndeadDevel: need a lot more exceptions here...ranked promos without a rank identifier
    return (sPromotion:match(sMatchRank) ~= nil)
end

function GetPromotionBase(sPromotion)
    local sRank = sPromotion:match(sMatchRank) or ""
    return sPromotion:sub(1, sPromotion:len() - sRank:len())
end

function GetNextPromotion(sPromotion, sCombatClass) -- UndeadDevel: we will now be checking whether the chained promos are class compatible as well (needed for Splash II, for example)
    --查找以sPromotion为前置晋升的后续晋升
    --这里到基础晋升的最后一个相似晋升就会结束,例如重骑兵的冲击线只到三级就结束，闪击战术需要由GetDependentPromotions来继续查找
    local sBase = GetPromotionBase(sPromotion)
    local promotions = {}

    --对于某些晋升,他的前置晋升已经不是相似晋升了,需要在这里进行特殊处理
    local sPrereqs = "p1.Type = p2.PromotionPrereqOr1 OR p1.Type = p2.PromotionPrereqOr2 OR p1.Type = p2.PromotionPrereqOr3 OR p1.Type = p2.PromotionPrereqOr4 OR p1.Type = p2.PromotionPrereqOr5 OR p1.Type = p2.PromotionPrereqOr6 OR p1.Type = p2.PromotionPrereqOr7 OR p1.Type = p2.PromotionPrereqOr8 OR p1.Type = p2.PromotionPrereqOr9 OR p1.Type = p2.PromotionPrereqOr10 OR p1.Type = p2.PromotionPrereqOr11 OR p1.Type = p2.PromotionPrereqOr12"
    local sQuery = 
        "SELECT p2.Type FROM UnitPromotions p1, UnitPromotions p2, UnitPromotions_UnitCombats c WHERE p1.Type = ? AND (" 
        .. sPrereqs .. 
        ") AND p2.Type = c.PromotionType AND c.UnitCombatType = ? AND (p2.Type LIKE ? OR EXISTS (SELECT * FROM SpecialRulePromotion WHERE SpecialPromotion = p2.Type))"
    for row in DB.Query(sQuery, sPromotion, sCombatClass, sBase .. "%") do
      table.insert(promotions, row.Type)
    end
    return promotions[1]
end

function GetPromotionChain(sPromotion, sCombatClass)
    local promotions = {}

    repeat
        table.insert(promotions, sPromotion)

        sPromotion = GetNextPromotion(sPromotion, sCombatClass)
    until (sPromotion == nil)

    return promotions
end

function GetBasicPromotions(sCombatClass,sBasePromotion)
    local promotions = {}
    local sPrereqs1 = '"'..sCombatClass..'"'
    local sPrereqs2 = '"'..sBasePromotion..'"'
    local sQuery =
        "SELECT p.Type FROM UnitPromotions p, UnitPromotions_UnitCombats c WHERE c.UnitCombatType = ("
        ..sPrereqs1..
        ") AND c.PromotionType = p.Type AND NOT p.CannotBeChosen AND (p.PromotionPrereqOr1 IS NULL OR p.PromotionPrereqOr1 =("..sPrereqs2..") OR p.PromotionPrereqOr2 =("..sPrereqs2..") OR p.PromotionPrereqOr3 =("..sPrereqs2..") OR p.PromotionPrereqOr4 =("..sPrereqs2..") OR p.PromotionPrereqOr5 =("..sPrereqs2..") OR p.PromotionPrereqOr6 =("..sPrereqs2..") OR p.PromotionPrereqOr7 =("..sPrereqs2..") OR p.PromotionPrereqOr8 =("..sPrereqs2..") OR p.PromotionPrereqOr9 =("..sPrereqs2..") OR p.PromotionPrereqOr10 =("..sPrereqs2..") OR p.PromotionPrereqOr11 =("..sPrereqs2..") OR p.PromotionPrereqOr12 =("..sPrereqs2.."))"
    for row in DB.Query(sQuery) do
        --选择单位类型以及直接选中单位都会屏蔽下面的晋升
        --屏蔽武僧相关晋升
        if row.Type:match("PROMOTION_FIST_[0-9]+$") == nil 
        and row.Type:match("PROMOTION_[A-Z]+_EXTRA") == nil
        --屏蔽立即恢复
        and row.Type ~= "PROMOTION_INSTA_HEAL"
        --屏蔽装甲一级
        and row.Type ~= "PROMOTION_ARMOR_7"
        --屏蔽王国冠军
        and row.Type ~= "PROMOTION_SPUE_KNIGHT_NEW_C"
        then
            table.insert(promotions, row.Type)
        end
    end

    --防空单位和陆军远程具有不完全相同的晋升线，这里单独处理
    if sBasePromotion == "PROMOTION_ANTI_AIR" then
        sPrereqs2 = '"'.."PROMOTION_ARCHERY_COMBAT"..'"'
        sQuery =
        "SELECT p.Type FROM UnitPromotions p, UnitPromotions_UnitCombats c WHERE c.UnitCombatType = ("
        ..sPrereqs1..") AND c.PromotionType = p.Type AND NOT p.CannotBeChosen AND p.Type != 'PROMOTION_INSTA_HEAL' AND (p.PromotionPrereqOr1 IS NULL OR p.PromotionPrereqOr1 =("..sPrereqs2..") OR p.PromotionPrereqOr2 =("..sPrereqs2..") OR p.PromotionPrereqOr3 =("..sPrereqs2..") OR p.PromotionPrereqOr4 =("..sPrereqs2..") OR p.PromotionPrereqOr5 =("..sPrereqs2..") OR p.PromotionPrereqOr6 =("..sPrereqs2..") OR p.PromotionPrereqOr7 =("..sPrereqs2..") OR p.PromotionPrereqOr8 =("..sPrereqs2..") OR p.PromotionPrereqOr9 =("..sPrereqs2..") OR p.PromotionPrereqOr10 =("..sPrereqs2..") OR p.PromotionPrereqOr11 =("..sPrereqs2..") OR p.PromotionPrereqOr12 =("..sPrereqs2.."))"
        for row in DB.Query(sQuery) do
            table.insert(promotions, row.Type)
        end
    end

    return promotions
end

function GetBasePromotions(sCombatClass,sBasePromotion,showMaxPromotion) 
    local promotions = {}

    for _, sPromotion in ipairs(GetBasicPromotions(sCombatClass,sBasePromotion)) do
        table.insert(promotions, GetPromotionChain(sPromotion, sCombatClass))
    end

    return promotions
end

function GetDependentPromotions(sCombatClass, sPromotion) 
    --这里找到的晋升只会从基础晋升的最后一个相似晋升开始，即接着GetNextPromotion开始,并且只会寻找一层
    local promotions = {}
    local sBase = GetPromotionBase(sPromotion)
    local sPrereqs =
        "p1.Type = p2.PromotionPrereqOr1 OR p1.Type = p2.PromotionPrereqOr2 OR p1.Type = p2.PromotionPrereqOr3 OR p1.Type = p2.PromotionPrereqOr4 OR p1.Type = p2.PromotionPrereqOr5 OR p1.Type = p2.PromotionPrereqOr6 OR p1.Type = p2.PromotionPrereqOr7 OR p1.Type = p2.PromotionPrereqOr8 OR p1.Type = p2.PromotionPrereqOr9 OR p1.Type = p2.PromotionPrereqOr10 OR p1.Type = p2.PromotionPrereqOr11 OR p1.Type = p2.PromotionPrereqOr12"
    local sQuery = ""
    sQuery =
        "SELECT p2.Type FROM UnitPromotions p1, UnitPromotions p2, UnitPromotions_UnitCombats c WHERE p1.Type = ? AND (" 
        .. sPrereqs ..
        ") AND p2.Type = c.PromotionType AND c.UnitCombatType = ? AND p2.Type NOT LIKE ?"
    for row in DB.Query(sQuery, sPromotion, sCombatClass, sBase .. "%") do
        table.insert(promotions,GetPromotionChain(row.Type, sCombatClass))
    end
    return promotions
end
