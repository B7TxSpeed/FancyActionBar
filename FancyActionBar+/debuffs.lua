local FAB             = FancyActionBar
local EM              = EVENT_MANAGER
local NAME
local SV
local time            = GetFrameTimeSeconds
local currentTarget   = { name = '', id = 0 }
local targetDebuffs   = {}
local activeDebuffs   = {}
local debuffTargets   = {}
local enemyDebuffs    = {}

local groupUnit = {
  ["group1"]		= true,
  ["group2"]		= true,
  ["group3"]		= true,
  ["group4"]		= true,
  ["group5"]		= true,
  ["group6"]		= true,
  ["group7"]		= true,
  ["group8"]		= true,
  ["group9"]		= true,
  ["group10"]		= true,
  ["group11"]		= true,
  ["group12"]		= true,
  ["group13"]		= true,
  ["group14"]		= true,
  ["group15"]		= true,
  ["group16"]		= true,
  ["group17"]		= true,
  ["group18"]		= true,
  ["group19"]		= true,
  ["group20"]		= true,
  ["group21"]		= true,
  ["group22"]		= true,
  ["group23"]		= true,
  ["group24"]		= true,
}
---------------------------------
-- Debug
---------------------------------
local function OnNewTarget()
  local tag = 'reticleover'

  local name = zo_strformat("<<t:1>>", GetUnitName(tag))
  d(name .. ' -> ' .. GetUnitType(tag) .. ' -> ' .. GetUnitNameHighlightedByReticle())
end

-- /script zo_callLater(function() d(tostring(GetUnitType('reticleover'))) end, 2000)
local function PostReticleTargetInfo(uName, eName, gain, fade, eSlot, stacks, icon, bType, eType, aType, seType, aId, canClickOff, castByPlayer)

  -- if aType == 0 then return end -- passives (annoying when bar swapping)

  local ts    = tostring
  local dur, s
  if (fade ~= nil and gain ~= nil) then dur = string.format(' %0.1f', fade - gain)..'s'
  else dur = 0 end

  if (stacks and stacks > 0)
  then s = ' x'..ts(stacks)..'.'
  else s = '.' end

  d(eName.." ("..ts(aId)..")".." || stacks: "..ts(stacks).." || duration: "..ts(dur).." || slot: "..ts(eSlot).." || unit: "..ts(uName).." || effectType: "..ts(eType).." || abilityType: "..ts(aType).." || statusEffectType: "..ts(seType)..'\n===================')
end
---------------------------------
-- Checking
---------------------------------
function FAB.IsAbilityActiveOnCurrentTarget(id)
  if not FAB.HasEnemyTarget() then return false end

  local isActive  = false
  local nBuffs    = GetNumBuffs('reticleover')
  local data      = { endTime = 0, stacks = 0}

  if nBuffs > 0 then
    for i = 1, nBuffs do
      local _, _, endTime, _, stacks, _, _, _, _, _, abilityId, _, castByPlayer = GetUnitBuffInfo('reticleover', i)

      if abilityId == id and castByPlayer then
        isActive = true
        data.endTime  = endTime
        data.stacks   = stacks or 0
        break
      end
    end
  end

  if isActive
  then return true, data
  else return false end
end

-- function FAB.IsToggled(id)
--   return toggled[id] and true or false
-- end

function FAB.IsGroupUnit(tag)
  if tag == nil or tag == '' then return false end
  if groupUnit[tag] ~= nil then return true else return false end
end

function FAB.IsPlayer(tag, name)
  if tag == nil or tag == '' then return false end
  if AreUnitsEqual('player', tag) then return true end
  return false
end

function FAB.IsEnemy(tag, id)
  if FAB.IsGroupUnit(tag) then return false end

  local isEnemy = false

  if tag ~= nil and tag ~= '' then
    if GetUnitType(tag) == 12 then isEnemy = true -- target dummy
    else
      local reaction  = GetUnitReaction(tag)
      if (reaction == 1) then isEnemy = true end
    end
  end
  return isEnemy
end

function FAB.IsLocalPlayerOrEnemy(tag, name, id)
  if FAB.IsEnemy(tag) then return true end
  if FAB.IsPlayer(tag) then return true end
  return false
end

function FAB.HasEnemyTarget()
  local tag = 'reticleover'

  if (DoesUnitExist(tag) and not IsUnitDead(tag)) then
    if FAB.IsEnemy(tag, nil) then return true end
  end
  return false

  -- return (currentTarget.name == '') and false or true
end
---------------------------------
-- Tracking
---------------------------------
local function ClearDebuff(effect)
  if effect then
    -- effect.activeOnTarget = false

    local stacks = false
    -- if effect.hideOnNoTarget then
      if FAB.stackMap[effect.id] then
        FAB.stackMap[effect.id] = 0
        stacks = true
      end
    -- end

    FAB.HandleDebuffUpdate(effect, stacks)
  end
end

local function ClearTargetEffects()
  for id, debuff in pairs(FAB.debuffs) do
    local effect = FAB.effects[id]
    if effect then
      ClearDebuff(effect)
    end
  end
end

local function ClearDebuffsIfNotOnTarget()
  for id, debuff in pairs(FAB.debuffs) do
    debuff.activeOnTarget = false
    debuff.endTime = 0
    local hasStacks = false
    if FAB.stacks[debuff.id] then
      hasStacks = true
      FAB.stacks[debuff.id] = 0
    end
    FAB.HandleDebuffUpdate(debuff, hasStacks)
  end

  for index in pairs(FAB.tauntSlots) do
    if FAB.tauntSlots[index] ~= nil then
      FAB.tauntSlots[index].activeOnTarget = false
      FAB.UpdateTaunt(index)
    end
  end
end

local function ClearAllDebuffs()
  ClearTargetEffects()
  activeDebuffs = {}
  FAB.debuffs   = {}
  debuffTargets = {}
  enemyDebuffs  = {}
end

-- local function GetActiveDebuff(abilityId, unitId)
--   local debuff = activeDebuffs[abilityId]
--
--   if debuff == nil then return nil end
--
--   local debuffKey = ZO_CachedStrFormat('<<1>>,<<2>>', abilityId, unitId)
--
--   local target = debuff[debuffKey]
--   if target ~= nil then
--     return target
--   end
--   return nil
-- end

-- local function TrackDebuff(effect, abilityId, endTime, stacks, name, id)
--   if not effect then return end
--
--   if not activeDebuffs[abilityId] then
--     local db  = { id = effect.id, targets = {} }
--     activeDebuffs[abilityId] = db
--   end
--
--   local debuff = activeDebuffs[abilityId]
--
--   if id == nil then id = 0 end
--
--   local debuffKey = ZO_CachedStrFormat('<<1>>,<<2>>', abilityId, id)
--
--   if not debuff.targets[debuffKey] then
--     local e = { endTime = 0, stacks = 0, id = 0, name = '' }
--     debuff.targets[debuffKey] = e
--   end
--
--   local target    = debuff.targets[debuffKey]
--
--   target.endTime  = endTime
--   target.stacks   = stacks
--   target.id       = id or 0
--   target.name     = name
-- end

-- local function CancelDebuff(abilityId, name, id)
--   local debuff = activeDebuffs[abilityId]
--
--   if debuff then
--     local debuffKey = ZO_CachedStrFormat('<<1>>,<<2>>', abilityId, id)
--     if debuff[debuffKey] then
--       debuff[debuffKey] = nil
--     end
--   end
-- end

-- local function IsTargetDebuff(abilityId, t, endTime, name, id)
--   local isTarget = false
--   local debuff = activeDebuffs[abilityId]
--   if debuff then
--     local debuffKey = ZO_CachedStrFormat('<<1>>,<<2>>', abilityId, id)
--     local target = debuff[debuffKey]
--     if target then
--       if target.endTime == endTime then
--         isTarget = true
--       else
--         if target.endTime <= t then
--           debuff[debuffKey] = nil
--         end
--       end
--     end
--   end
--   return isTarget
-- end

local numEffects = 0
local function GetTargetEffects()
  local tag = 'reticleover'

  numEffects = GetNumBuffs(tag)

  local debuffs   = {}
  local debuffNum = 0

  if numEffects <= 0 then
    return nil, 0
  else
    for i = 1, numEffects do
      local abilityName, startTime, endTime, buffSlot, stacks, icon, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo(tag, i)

      if castByPlayer then

        -- PostReticleTargetInfo(name, abilityName, startTime, endTime, buffSlot, stacks, icon, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer)

        debuffNum = debuffNum + 1
        local db = {
          id      = abilityId,
          endTime = endTime or 0,
          stacks  = stacks or 0
        }
        table.insert(debuffs, db)
      end
    end
  end
  return debuffs, debuffNum
end

local function UpdateDebuff(effect, t, stacks, unitId, isTarget)
  if not effect then return end

  -- effect.activeOnTarget = isTarget or false

  -- if not isTarget and effect.hideOnNoTarget
  -- then effect.endTime = 0
  -- else effect.endTime = t end

  local updateStacks = false

  if stacks ~= nil and FAB.stackMap[effect.id] then
    FAB.stacks[FAB.stackMap[effect.id]] = stacks
    updateStacks = true
  end

  FAB.HandleDebuffUpdate(effect, updateStacks)
end

local function OnReticleTargetChanged()
  local tag = 'reticleover'

  if (DoesUnitExist(tag) and not IsUnitDead(tag)) then

    if not FAB.IsEnemy(tag) then return end -- GetUnitType(tag), GetUnitNameHighlightedByReticle()

    local name  = zo_strformat('<<t:1>>', GetUnitName(tag))
    local tId   = 0
    local keep  = {}

    currentTarget.name = name

    local debuffs, debuffNum = GetTargetEffects()

    if debuffNum > 0 then
      for i = 1, debuffNum do
        local debuff = debuffs[i]

        local ID = debuff.id

        if debuff.id == FAB.hCurse2 then
          ID = FAB.hCurse1
        end

        keep[ID] = true

        if ID == FAB.tauntId then -- taunt is handled separately.
          local unit, index = FAB.IdentifyTaunt(debuff.endTime)
          if index > 0 then
            tId = unit
            FAB.tauntSlots[index].endTime         = debuff.endTime
            FAB.tauntSlots[index].unit            = unit
            FAB.tauntSlots[index].activeOnTarget  = true
            FAB.UpdateTaunt(index)
          end
        else -- update durations for active effects on the target.
          if FAB.debuffs[ID] then
            FAB.debuffs[ID].activeOnTarget = true
            FAB.debuffs[ID].endTime        = debuff.endTime
            UpdateDebuff(FAB.debuffs[ID], debuff.endTime, debuff.stacks, tId, true)
          end
        end
      end
    end

    for id, debuff in pairs(FAB.debuffs) do
      if FAB.traps[id] then return end
      if keep[id] == nil then -- update debuffs that are not active on the target according to settings.
        debuff.activeOnTarget = false
        debuff.endTime = 0
        UpdateDebuff(FAB.debuffs[debuff.id], debuff.endTime, 0, tId, false)
      end
    end
    -- OnNewTarget()
  else
    currentTarget = { name = '', id = 0 }
    if SV.keepLastTarget == false then
      ClearDebuffsIfNotOnTarget()
    end
  end
end

function FAB.OnDebuffChanged(effect, t, eventCode, change, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)

  local tag = ''

  if unitTag ~= nil and unitTag ~= '' then tag = unitTag end

  -- if ((effect.activeOnTarget and tag ~= 'reticleover') or (not effect.activeOnTarget and effect.hideOnNoTarget)) then
  --   FAB:dbg(1, '<<1>> duration <<2>>s ignored on: <<3>>.', effectName, string.format(' %0.1f', endTime - t), tag )
  --   return
  -- end

  if tag ~= 'reticleover' then return end

  if change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED then

    if FAB.activeCasts[effect.id] then FAB.activeCasts[effect.id].begin = beginTime end

    if ((endTime > t + FAB.durationMin and endTime < t + FAB.durationMax) or (effect.duration > FAB.durationMin)) then

      if abilityId == 24330 then -- haunting curse
        FAB.SetFixedDuration(abilityId, t + 12)
        FAB.debuffs[abilityId].activeOnTarget = true
        -- effect.endTime = t + 12
        UpdateDebuff(effect, t + 12, nil, unitId, true)
      else
        effect.endTime = endTime
        UpdateDebuff(effect, endTime, stackCount, unitId, true)
      end
    else
      FAB:dbg(1, '<<1>> duration <<2>>s ignored.', effectName, string.format(' %0.1f', endTime - t))
    end
  elseif (change == EFFECT_RESULT_FADED) then

    if abilityId == 24330 then return end

    if (FAB.activeCasts[effect.id] and FAB.activeCasts[effect.id].begin < (t - 0.7)) then

      if effect.instantFade
      then effect.endTime = 0
      else effect.endTime = t end

      UpdateDebuff(effect, t, 0, unitId, false)
    end
  end
end

-- function FAB.OnDebuffTargetDeath( eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId )
--
--   if targetUnitId == nil or targetUnitId == 0 then return end
--
--   if result ~= ACTION_RESULT_DIED and result ~= ACTION_RESULT_DIED_XP then return end
--
-- end

local function ClearDebuffsOnCombatEnd()
  local t = time()
  if not IsUnitInCombat('player') then
    for i, x in pairs(FAB.debuffs) do
      local debuff = FAB.debuffs[i]
      if debuff then
        if debuff.endTime > t then
          debuff.endTime = t
          UpdateDebuff(debuff, t, 0, 0, false)
        end
      end
    end

    for index in pairs(FAB.tauntSlots) do
      if FAB.tauntSlots[index] ~= nil then
        FAB.tauntSlots[index].activeOnTarget = false
        FAB.tauntSlots[index].endTime        = 0
        FAB.UpdateTaunt(index)
      end
    end

    ClearAllDebuffs()
  end
end

function FAB:UpdateDebuffTracking()
  ClearAllDebuffs()


  -- EVENT_TARGET_CHANGED (number eventCode, string unitTag)
  -- EVENT_RETICLE_TARGET_CHANGED (number eventCode)
  -- EVENT_RETICLE_TARGET_PLAYER_CHANGED (number eventCode)
  EM:UnregisterForEvent(NAME .. 'ReticleTaget', EVENT_RETICLE_TARGET_CHANGED)
  EM:UnregisterForEvent(NAME .. 'DebuffCombat', EVENT_PLAYER_COMBAT_STATE)
  -- EM:UnregisterForEvent(NAME .. "EnemyDeath_1", EVENT_COMBAT_EVENT)
  -- EM:UnregisterForEvent(NAME .. "EnemyDeath_2", EVENT_COMBAT_EVENT)

  if SV.advancedDebuff then
    EM:RegisterForEvent(  NAME .. 'DebuffCombat', EVENT_PLAYER_COMBAT_STATE,    ClearDebuffsOnCombatEnd)
    EM:RegisterForEvent(  NAME .. 'ReticleTaget', EVENT_RETICLE_TARGET_CHANGED, OnReticleTargetChanged)

    -- EM:RegisterForEvent(  NAME .. "EnemyDeath_1", EVENT_COMBAT_EVENT, FAB.OnDebuffTargetDeath )
    -- EM:AddFilterForEvent( NAME .. "EnemyDeath_1", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED,    REGISTER_FILTER_IS_ERROR, false )
    --
    -- EM:RegisterForEvent(  NAME .. "EnemyDeath_2", EVENT_COMBAT_EVENT, FAB.OnDebuffTargetDeath )
    -- EM:AddFilterForEvent( NAME .. "EnemyDeath_2", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP, REGISTER_FILTER_IS_ERROR, false )
  end
end

function FAB:InitializeDebuffs(name, sv)
  NAME  = name
  SV    = sv
  FAB:UpdateDebuffTracking()
end
