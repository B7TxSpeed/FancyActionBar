-------------------------------------------------------------------------------
-----------------------------[    Constants   ]--------------------------------
-------------------------------------------------------------------------------
FancyActionBar                    = {}
local NAME                        = 'FancyActionBar+'
local VERSION                     = '2.3.7c'
local slashCommand                = '/fab' or '/FAB'
local FAB                         = FancyActionBar
local EM                          = EVENT_MANAGER
local WM                          = WINDOW_MANAGER
local SM                          = SCENE_MANAGER
local strformat                   = string.format
local time                        = GetFrameTimeSeconds
local MIN_INDEX                   = 3   -- first ability index
local MAX_INDEX                   = 7   -- last ability index
local ULT_INDEX                   = 8   -- ultimate slot index
local SLOT_INDEX_OFFSET           = 20  -- offset for backbar abilities indices
local COMPANION_INDEX_OFFSET      = 30  -- offset for companion ultimate
local SLOT_COUNT                  = MAX_INDEX - MIN_INDEX + 1 -- total number of slots
local ULT_SLOT                    = 8 -- ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
local QUICK_SLOT                  = 9 -- ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1
local COMPANION                   = HOTBAR_CATEGORY_COMPANION
local ACTION_BAR                  = ZO_ActionBar1
local currentWeaponPair           = GetActiveWeaponPairInfo()
local currentHotbarCategory       = GetActiveHotbarCategory()
local GAMEPAD_CONSTANTS           = {
  dimensions          =    64,
  flipCardSize        =    61,
  ultFlipCardSize     =    67,
  abilitySlotWidth    =    64,
  abilitySlotOffsetX  =    10,
  buttonTextOffsetY   =    60,
  actionBarOffset     =   -52,
  attributesOffset    =  -152,
  width               =   606,
  anchorOffsetY       =   -25,
  ultimateSlotOffsetX =    12, --65,
  ultSize             =    70,
  quickslotOffsetX    =     5,
  bindingTextOnUlt    = false,
  showKeybindBG       = false,
  buttonTemplate      = 'ZO_ActionButton_Gamepad_Template',
  ultButtonTemplate   = 'ZO_UltimateActionButton_Gamepad_Template',
  overlayTemplate     = 'FAB_ActionButtonOverlay_Gamepad_Template',
  ultOverlayTemplate  = 'FAB_UltimateButtonOverlay_Gamepad_Template',
  qsOverlayTemplate   = 'FAB_QuickSlotOverlay_Gamepad_Template'
}
local KEYBOARD_CONSTANTS          = {
  dimensions          =    50,
  flipCardSize        =    47,
  ultFlipCardSize     =    47,
  abilitySlotWidth    =    50,
  abilitySlotOffsetX  =     2,
  buttonTextOffsetY   =    50,
  actionBarOffset     =   -22,
  attributesOffset    =  -112,
  width               =   483,
  anchorOffsetY       =     0,
  ultimateSlotOffsetX =     8, --12,
  ultSize             =    50,
  quickslotOffsetX    =     5,
  bindingTextOnUlt    = false,
  showKeybindBG       = false,
  buttonTemplate      = 'ZO_ActionButton_Keyboard_Template',
  ultButtonTemplate   = 'ZO_UltimateActionButton_Keyboard_Template',
  overlayTemplate     = 'FAB_ActionButtonOverlay_Keyboard_Template',
  ultOverlayTemplate  = 'FAB_UltimateButtonOverlay_Keyboard_Template',
  qsOverlayTemplate   = 'FAB_QuickSlotOverlay_Keyboard_Template'
}
local ULTIMATE_BUTTON_STYLE       = {   -- TODO make back bar ult button to display duration.
  type                   = ACTION_BUTTON_TYPE_VISIBLE,
  template               = 'ZO_UltimateActionButton',
  showBinds              = false,
  parentBar              = '',
}
local GROUND_EFFECT               = ABILITY_TYPE_AREAEFFECT
local DEBUFF                      = BUFF_EFFECT_TYPE_DEBUFF
-------------------------------------------------------------------------------
-----------------------------[    Global    ]----------------------------------
-------------------------------------------------------------------------------
FAB.customAbilityConfig           = {}     -- custom ability config
FAB.effects                       = {}    -- currently slotted abilities
FAB.stacks                        = {}    -- ability id => current stack count
FAB.activeCasts                   = {}    -- updating timers to account for delay and expiration ( mostly for debugging )
FAB.toggles                       = {}    -- works together with effects to update toggled abilities activation
FAB.debuffs                       = {}    -- effects for debuffs to update if they are active on target

FAB.lastTaunt                     = nil
--FAB.tauntId                       = 38254
FAB.activeTaunts                  = {}
FAB.tauntSlots                    = {}
FAB.tauntTimers                   = {}

FAB.fixedTimers                   = {}    -- to keep track of certain timers regardless of updates from the game
FAB.trapTimers                    = {}

-- Backbar buttons.
FAB.buttons                       = {}    -- Contains: abilities duration, number of stacks and visual effects.
-- FAB.abilitySlots                  = {} -- TODO enable tooltip, mouse click and drag functions
FAB.overlays                      = {}    -- normal skill button overlays
FAB.ultOverlays                   = {}    -- player and companion ultimate skill button overlays
FAB.style                         = nil   -- Gamepad or Keyboard UI for compatibility

FAB.qsOverlay                     = nil   -- shortcut for.. reasons..

FAB.initialized                   = false -- check before running some functions that can't be run this early
FAB.initialSetup                  = true  -- same as above. not sure why I added both...
FAB.wasMoved                      = false -- don't move action bar if it wasn't moved to begin with
FAB.wasStopped                    = false -- don't register updates if already registered

FAB.zone                          = 0     -- some buffs expire when traveling, and some don't. check active buffs on player
FAB.inCombat                      = false -- for GCD

FAB.weaponFront                   = WEAPONTYPE_NONE -- for getting correct id's for destro staff skills on back bar
FAB.weaponBack                    = WEAPONTYPE_NONE

FAB.durationMin                   = 4
FAB.durationMax                   = 99

FAB.player                        = { name = '', id = 0 } -- might be needed to check for some effects before updating timer

FAB.constants                     = {     -- all current values for the UI and configuration to use. not sure why I called it 'constants' when they are all in fact variables.
  duration  = {
    font    = 'Univers 67',
    size    = 24,
    outline = 'thick-outline',
    y       = 0,
    color   = { 1, 1, 1 }
  },
  stacks    = {
    font    = 'Univers 67',
    size    = 20,
    outline = 'thick-outline',
    x       = 37,
    color   = { 1, 0.8, 0 }
  },
  ult       = {
    duration  = {
      show    = true,
      font    = 'Univers 67',
      size    = 24,
      outline = 'thick-outline',
      x       = 37,
      y       = 0,
      color   = { 1, 1, 1 }
    },
    value     = {
      show    = false,
      mode    = 1,
      font    = 'Univers 67',
      size    = 20,
      outline = 'outline',
      x       = -2,
      y       = -5,
      color   = { 1, 1, 1 }
    },
    companion = {
      show = true,
      mode = 1,
      x    = 0,
      y    = 0
    }
  },
  qs        = {
    show    = true,
    font    = 'Univers 67',
    size    = 24,
    outline = 'outline',
    x       = 0,
    y       = 10,
    color   = { 1, 0.5, 0.2 }
  },
  abScale   = {
    enable = false,
    scale  = 100,
  },
  move      = {
    enable    = false,
    x         = 0,
    y         = 0
  },
  style     = {}
}
-------------------------------------------------------------------------------
-----------------------------[    Tables    ]----------------------------------
-------------------------------------------------------------------------------
local defaultSettings                   -- default settings variables...
local specialIds                  = {}  -- abilities that needs to be updated individually when fired ( cause too special to be tracked by effect changed events, or if I wanna do something more with them )
local fakes                       = {}  -- problematic abilities from current class and shared skill lines ( mostly ground AoE's and traps )
local activeFakes                 = {}  -- enables OnCombatEvent to update timers with hard coded durations if the button for the effect has been pressed (:4House:)
local slottedIds                  = {}  -- to match skills with their tracked effect ( not in use cause I smooth brained the parts that might benefit from this )
local effectSlots                 = {}  -- to indentify slots that track the same effect
local debuffTargets               = {}  -- not used, but might be needed when I get better at writing tracking for debuffs on enemies
local lastAreaTargets             = {}  -- unit id for 'offline' target when casting ground effects always change. check if it was the same target id before fading if before 0
-------------------------------------------------------------------------------
---------------------------[   Local Variables   ]-----------------------------
-------------------------------------------------------------------------------
local SV                                    -- saved variables (accountwide)
local CV                                    -- saved variables (character)
local debug                       = false   -- debug mode

local scale                                 -- default or custom scale of the action bar to use
local showDecimal                           -- setting for decimals from very early versions. TODO: add to constants
local showDecimalStart                      -- same as above
local updateRate                  = 100     -- overlay update interval

local class                       = 0       -- player class for tracking problematic abilities
local lastButton                  = 0       -- for repositioning of skill buttons
local uiModeChanged               = false   -- don't change configuration if not needed
local hideCompanionUlt            = false   -- variable with no settings for now (hide if companion is not currently present or if doesn't have its ultimate ability unlocked - why show empty button ZoS?? )

local guardId                     = 0       -- sync active id for guard on both bars as active and inactive are different

local WEAPONTYPE_NONE             = WEAPONTYPE_NONE             -- just to make sure the game isn't confused by its own constants. ( not sure why this would even happen, but it does.. )
local WEAPONTYPE_FIRE_STAFF       = WEAPONTYPE_FIRE_STAFF
local WEAPONTYPE_FROST_STAFF      = WEAPONTYPE_FROST_STAFF
local WEAPONTYPE_LIGHTNING_STAFF  = WEAPONTYPE_LIGHTNING_STAFF
--------------------------------------------------------------------------------
-----------------------------[ 		Utility    ]----------------------------------
--------------------------------------------------------------------------------
local function dbg(msg, ...)
  if SV.debug then d(strformat(msg, ...)) end
end

function FAB:dbg(...)
  -- if SV.debugAll then return end
	if SV.debug then
		local str = zo_strformat(...)
		d('[FAB+] '.. str)
	end
end

function FAB.SlashCommand(str)
  local setting
  local cmd = string.lower(str)
  if cmd == 'dbg 0' then
    SV.debug    = false
    SV.debugAll = false
    d('[FAB+] debug: Off.')
  elseif cmd == 'dbg 1' then
    SV.debug    = not SV.debug
    if SV.debug then setting = 'On.' else setting = 'Off.' end
    d('[FAB+] debug1: '..setting)
  elseif cmd == 'dbg 2' then
    SV.debugAll = not SV.debugAll
    if SV.debugAll then setting = 'On.' else setting = 'Off.' end
    d('[FAB+] debugAll: '..setting)
  elseif cmd == 'dbg 3' then
    SV.debugVerbose = not SV.debugVerbose
    if SV.debugVerbose then setting = 'On.' else setting = 'Off.' end
    d('[FAB+] Verbose debug: '..setting)
  elseif cmd == 'bar1' then
    FAB.PostSlottedSkills(1)
  elseif cmd == 'bar2' then
    FAB.PostSlottedSkills(2)
  elseif cmd == 'bars' then
    FAB.PostSlottedSkills(3)
  elseif cmd == 'overlay' then
    FAB.PostOverlayEffects()
  elseif cmd == 'track' then
    FAB.PostAbilityConfig()
  elseif cmd == 'stacks' then
    for id, effect in pairs(FAB.stackMap) do
      d('[' .. id .. '] = ' .. effect)
    end
  elseif cmd == 'dbt' then
    d('[FAB+] Registered Debuff IDs:')
    for id in pairs(SV.debuffTable) do
      d(id)
    end
  end
end

local function GetSlotInfoString(index, bar)
  local slot    = index == 8 and "Ult" or tostring(index - 2)
  local string  = '[' .. slot .. '] '
  local id      = GetSlotBoundId(index, bar)
  if id > 0 then
    local name = GetAbilityName(id)
    string = string .. '<' .. name .. '> ' .. id
  end
  return string
end

function FAB.PostAbilityConfig()
  d('FAB+ Ability Configuration:')

  for skill, id in pairs(FAB.customAbilityConfig) do
    local v

    if type(id) == 'table' then
      if id == {} or id[1] == nil
      then v = '{}'
      else v = tostring(id[1]) end
    elseif type(id) == 'boolean' then
      v = 'false'
    else
      v = tostring(id)
    end
    d('[|cffffff' .. tostring(skill) .. '|r] = |cff6600' .. v .. '|r')
  end
end

function FAB.PostSlottedSkills(bar)
  d('[FAB+] Current Skills:')
  if bar == 1 or bar == 3 then
    d('Front Bar')
    for i = 3, 8 do d(GetSlotInfoString(i, 0)) end
  end
  if bar == 2 or bar == 3 then
    d('Back Bar')
    for i = 3, 8 do d(GetSlotInfoString(i, 1)) end
  end
end

function FAB.PostOverlayEffects()
  for i = 3, 7 do
    local o1 = FancyActionBar.overlays[i]
    local o2 = FancyActionBar.overlays[i + 20]
    if o1.effect and o1.effect.id and o1.effect.id > 0 then
      d('[' .. i .. ']: ' .. o1.effect.id)
      for k, v in pairs(o1.effect) do
        d(' - [' .. k .. ']: ' .. tostring(v))
      end
    end
    if o2.effect and o2.effect.id and o2.effect.id > 0 then
      d('[' .. i + 20 .. ']: ' ..o2.effect.id)
      for k, v in pairs(o2.effect) do
        d(' - [' .. k .. ']: ' .. tostring(v))
      end
    end
  end
end

function FAB.IsDebugMode()
	return debug
end

function FAB.SetDebugMode(mode)
	assert(type(mode) == 'boolean', 'Debug mode must be boolean.')
	debug = mode
end

function FAB.GetName()
	return NAME
end

function FAB.GetVersion()
	return VERSION
end

function FAB.GetScale()
  return scale
end

function FAB.GetExternalBlacklist()
  return SV.externalBlackList
end

function FAB:GetMovableVarsForUI()
  local var = FAB.constants.move
  local def = IsInGamepadPreferredMode() and defaultSettings.abMove.gp or defaultSettings.abMove.kb
  return var, def
end

function FAB.GetAbilityDurationLimits()
  return SV.durationMin, SV.durationMax
end

function FAB.UpdateDurationLimits()
  FAB.durationMin, FAB.durationMax = FAB.GetAbilityDurationLimits()
end

function FAB.GetContants()
  if not FAB.initialized then
    FAB.style = IsInGamepadPreferredMode() and 2 or 1
    local s = FAB.style == 1 and KEYBOARD_CONSTANTS or GAMEPAD_CONSTANTS
    FAB.constants.style = s
  end
  return FAB.constants.style
end

function FAB.GetAbilityConfigChanges()
  if CV.useAccountWide
  then return SV.configChanges
  else return CV.configChanges end
end

function FAB.GetAbilityConfigChange(ability)
  if CV.useAccountWide
  then return SV.configChanges[ability]
  else return CV.configChanges[ability] end
end

function FAB.SetAbilityConfigChange(ability, config)
  if CV.useAccountWide
  then SV.configChanges[ability] = config
  else CV.configChanges[ability] = config end
end

function FAB.GetHideOnNoTargetGlobalSetting()
  if CV.useAccountWide
  then return SV.hideOnNoTargetGlobal
  else return CV.hideOnNoTargetGlobal end
end

function FAB.GetHideOnNoTargetList()
  if CV.useAccountWide
  then return SV.hideOnNoTargetList
  else return CV.hideOnNoTargetList end
end

function FAB.GetNoTargetFade()
  if CV.useAccountWide
  then return SV.noTargetFade
  else return CV.noTargetFade end
end

function FAB.SetNoTargetFade(fade)
  if CV.useAccountWide
  then SV.noTargetFade = fade
  else CV.noTargetFade = fade end
  FAB.constants.noTargetFade = fade
end

function FAB.GetNoTargetAlpha()
  if CV.useAccountWide
  then return SV.noTargetAlpha / 100
  else return CV.noTargetAlpha / 100 end
end

function FAB.SetNoTargetAlpha(alpha)
  if CV.useAccountWide
  then SV.noTargetAlpha = alpha
  else CV.noTargetAlpha = alpha end
  FAB.constants.noTargetAlpha = alpha / 100
end

function FAB.UpdateHideOnNoTargetForSkill(id, hide)
  local cfg       = FAB.customAbilityConfig[id]
  local effectId  = 0

  if cfg ~= nil then
    if type(cfg) == 'table' then
      cfg[5]    = hide
      effectId  = cfg[1]
    end

    if effectId > 0 then
      local effect = FAB.effects[effectId]
      if effect then
        effect.hideOnNoTarget = hide
        UpdateEffect(effect)
      end
    end
  end
end

function FAB.OnlyUpdateEffectForUsedSkill(id)

end

function FAB.EditCurrentAbilityConfiguration(id, cfg)
  local isToggled, noTarget = false, false

  if FAB.toggled[id] then
    FAB.toggles[id] = false
    isToggled       = true
  end

  -- if FAB.constants.hideOnNoTargetList[id] then
  --   noTarget = FAB.constants.hideOnNoTargetList[id]
  -- else
  --   noTarget = FAB.GetHideOnNoTargetGlobalSetting()
  -- end

  local cI, rI = id, false

  if type(cfg) == 'table' then
    if cfg[1] then cI = cfg[1] end
  end

  if FAB.removeInstantly[cI] then rI = true end

  if type(cfg) == 'table' then  FAB.customAbilityConfig[id] = {cI, true, isToggled, rI}
  elseif cfg then               FAB.customAbilityConfig[id] = {id, true, isToggled, rI}
  elseif cfg == false then      FAB.customAbilityConfig[id] = false
  else                          FAB.customAbilityConfig[id] = nil end

  if id == 31816 then -- configure stone giant
    FAB.customAbilityConfig[133027] = cfg
    if cI == 31816 then
      FAB.stackMap[31816]   = cI
      FAB.stackMap[134336]  = nil
    elseif cI == 134336 then
      FAB.stackMap[31816]   = nil
      FAB.stackMap[134336]  = cI
    else
      FAB.stackMap[31816]   = nil
      FAB.stackMap[134336]  = nil
    end
  end

  local currentSlots = {}

  for i = MIN_INDEX, MAX_INDEX + 1 do
    local I0 = GetSlotBoundId(i, 0)
    local I1 = GetSlotBoundId(i, 1)
    if I0 == id then currentSlots[i] = true end
    if I1 == id then currentSlots[i + SLOT_INDEX_OFFSET] = true end
  end

  for slot in pairs(currentSlots) do
    if slot then SlotEffect(slot, id) end
  end
end

function FAB.GetActionButton(index)                   -- get actionbutton by index.
  if index > SLOT_INDEX_OFFSET
  then return FAB.buttons[index]
  else return ZO_ActionBar_GetButton(index) end
end

function FAB.GetOverlay(index)
  if (index == ULT_SLOT) or (index == ULT_SLOT + SLOT_INDEX_OFFSET)
  then return FAB.ultOverlays[index]
  else return FAB.overlays[index] end
end

function FAB.GetEffect(id, config, custom, toggled, ignore, instantFade)
  local effect = FAB.effects[id]
  if not effect then
    if config then
      effect = {
        id              = id,
        endTime         = 0,
        custom          = custom,
        toggled         = toggled,
        ignore          = ignore,
        passive         = false,
        isDebuff        = false,
        activeOnTarget  = false,
        instantFade     = instantFade,
        faded           = true
      }
      FAB.effects[id] = effect
    end
  end
  return effect or nil
end

function FAB.GetSlottedEffect(index)
  return slottedIds[index].effect, slottedIds[index].ability
end

function FAB.SetSlottedEffect(index, abilityId, effectId)
  if not slottedIds[index] then
    slottedIds[index] = { ability = 0, effect = 0 }
  end
  slottedIds[index].ability = abilityId or 0
  slottedIds[index].effect  = effectId  or 0
end

local function IsSameEffect(index, abilityId)
  -- local ts      = tostring
  local overlay = FAB.overlays[index]
  if overlay.effect then
    local e, a = FAB.GetSlottedEffect(index)
    if overlay.effect.id == e and abilityId == a then
      -- local o = e or 0
      -- d('overlay '..ts(index)..' effect '..ts(abilityId)..' already slotted ('..ts(o)..')')
      return true
    end
  end
  -- d('overlay '..ts(index)..' new effect: '..ts(abilityId))
  return false
end

local function UpdateCompanionOverlayOnChange()
  if (ZO_ActionBar_GetButton(ULT_SLOT, COMPANION).hasAction and DoesUnitExist('companion') and HasActiveCompanion()) then

    hideCompanionUlt   = false

    local current, _, _ = GetUnitPower('companion', POWERTYPE_ULTIMATE)
    cost3 = GetSlotAbilityCost(ULT_INDEX, COMPANION)

    CompanionUltimateButton:SetHidden(false)
    FAB.UpdateUltimateValueLabels(false, current)

    if FAB.style == 2
    then ZO_ActionBar_GetButton(ULT_SLOT, COMPANION).buttonText:SetHidden(true)
    else ZO_ActionBar_GetButton(ULT_SLOT, COMPANION).buttonText:SetHidden(not SV.showHotkeys) end

  else
    hideCompanionUlt   = true
    if CompanionUltimateButton then
      CompanionUltimateButton:SetHidden(true)
      ZO_ActionBar_GetButton(ULT_SLOT, COMPANION).buttonText:SetHidden(true)
    end
  end
end

local function HandleCompanionStateChanged()          -- prevents quick slot from being moved when a companion is summoned / unsummoned
	local c = ZO_ActionBar_GetButton(ULT_SLOT, COMPANION)
	c:HandleSlotChanged()
	c:UpdateUltimateMeter()
  zo_callLater(function() UpdateCompanionOverlayOnChange() end, 2000)
end

-- ZO_ActionButtons_ToggleShowGlobalCooldown()
function FAB.OnPlayerActivated()                      -- status update after travel.
  FAB.SetMarker()
  FAB.ToggleUltimateValue()
  FAB:UpdateDebuffTracking()

  HandleCompanionStateChanged()

  local zone = GetZoneId(GetUnitZoneIndex('player'))
  if FAB.zone ~= zone then
    FAB.zone = zone
    FAB.RefreshEffects()
  end
  FAB.weaponFront = GetItemLinkWeaponType(GetItemLink(BAG_WORN, EQUIP_SLOT_MAIN_HAND, LINK_STYLE_DEFAULT))
  FAB.weaponBack  = GetItemLinkWeaponType(GetItemLink(BAG_WORN, EQUIP_SLOT_BACKUP_MAIN, LINK_STYLE_DEFAULT))
end
-------------------------------------------------------------------------------
-----------------------------[ 		UI Updates    ]------------------------------
-------------------------------------------------------------------------------
function CheckForActiveEffect(id)                     -- update timer on load / reload.
  local hasEffect     = false
  local duration      = 0
  local currentStacks = 0

  for i = 1, GetNumBuffs('player') do
    local name, startTime, endTime, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo('player', i)

    if --[[not castByPlayer and]] abilityId == id then
      hasEffect     = true
      duration      = endTime - time()
      currentStacks = stackCount or 0
    end
  end

  return hasEffect, duration, currentStacks
end

local function ResolveIdToTrack(type, id)             -- special cases.
  local idToTrack

  -- if eventually other skills will also need this function.
  if type == 1 then
    if (GetAPIVersion() > 101032) then --PTS
      idToTrack = FAB.soulTrap[id][1]
    else
      local sDmg = GetPlayerStat(STAT_SPELL_POWER, STAT_BONUS_OPTION_APPLY_BONUS)
      local wDmg = GetPlayerStat(STAT_POWER, STAT_BONUS_OPTION_APPLY_BONUS)
      if sDmg > wDmg
      then idToTrack = FAB.soulTrap[id][1]      -- mag
      else idToTrack = FAB.soulTrap[id][2] end  -- stam
    end
  end
  return idToTrack
end

function FAB.GetIdForDestroSkill(id, bar)             -- cause too hard for game to figure out.
  local destroId, staffType

  local destroStaves = {
    [WEAPONTYPE_FIRE_STAFF]       = true,
    [WEAPONTYPE_FROST_STAFF]      = true,
    [WEAPONTYPE_LIGHTNING_STAFF]  = true
  }

  local weaponOnBar = bar == 0 and FAB.weaponFront or FAB.weaponBack

  if destroStaves[weaponOnBar]
  then staffType = weaponOnBar
  else staffType = WEAPONTYPE_NONE end

  local skill1 = FAB.destroSkills[id]
  local skill2 = FAB.idsForStaff[skill1.type][skill1.morph]

  if skill2[staffType]
  then destroId = skill2[staffType]
  else destroId = id end

  return destroId
end

function UpdateInactiveBarIcon(index, bar)            -- for bar swapping.
  local id      = GetSlotBoundId(index, bar)
  local iconId  = 0 -- GetEffectiveAbilityIdForAbilityOnHotbar(id, bar)
  local btn     = FAB.buttons[index + SLOT_INDEX_OFFSET]
  local icon    = ''

  if id > 0 --[[TODO: and bar == 0 or bar == 1]] then
    if FAB.destroSkills[id] then
      id = FAB.GetIdForDestroSkill(id, bar)
      icon = GetAbilityIcon(id)
    else
      icon = GetAbilityIcon(GetEffectiveAbilityIdForAbilityOnHotbar(id, bar))
    end
    btn.icon:SetHidden(false)
    btn.icon:SetTexture(icon)
  else
    btn.icon:SetHidden(true)
  end
end

function FAB.IdentifyTaunt(endTime)
  local id, index = 0, 0

  for unit, taunt in pairs(FAB.activeTaunts) do
    if taunt.endTime == endTime then
      index = taunt.overlay
      id    = unit
      break
    end
  end

  return id, index
end

function FAB.SetFixedDuration(id, endTime)
  FAB.fixedTimers[id] = endTime
end

function FAB.GetFixedDuration(id)
  local duration = 0
  local debuff = FAB.debuffs[id]
  if debuff then
    if debuff.activeOnTarget == true then
      if FAB.fixedTimers[id] then
        duration = FAB.fixedTimers[id]
      end
    end
  end
  return duration
end

function FAB.SetTrapDuration(id, endTime)
  FAB.fixedTimers[id] = endTime
end

function FAB.GetTrapDuration(id)
  local duration = 0
  local debuff = FAB.debuffs[id]
  if debuff then
    if debuff.activeOnTarget == true then
      if FAB.fixedTimers[id] then
        duration = FAB.fixedTimers[id]
      end
    end
  end
  return duration
end
--------------
-- abilities
--------------
local function ResetOverlayDuration(overlay)
  if overlay then
    local durationControl = overlay:GetNamedChild('Duration')
    local bgControl       = overlay:GetNamedChild('BG')
    local stacksControl   = overlay:GetNamedChild('Stacks')

    if durationControl  then durationControl:SetText('')  end
    if bgControl        then bgControl:SetHidden(true)    end
    if stacksControl    then stacksControl:SetText('')    end

    if overlay.effect then
      if FAB.stacks[overlay.effect.id] then
        local _, _, currentStacks = CheckForActiveEffect(overlay.effect.id)
        FAB.stacks[overlay.effect.id] = currentStacks
        FAB.HandleStackUpdate(overlay.effect.id)
      end
    -- else
    end
  end
end

function FAB.FadeEffect(effect)                       -- reset effect variables and make sure overlay is cleared
  if effect == nil then return end

  effect.endTime = time()

  if effect.slot1 then
    ResetOverlayDuration(FAB.overlays[effect.slot1])
    effect.slot1 = nil
  end
  if effect.slot2 then
    ResetOverlayDuration(FAB.overlays[effect.slot2])
    effect.slot2 = nil
  end
  -- effect.faded = true

  -- d('Effect <' .. GetAbilityName(effect.id) .. '> (' .. effect.id .. ') faded')
end

local function UpdateTimerLabel(label, text, color)
  label:SetText(text)
  if color ~= nil then
    label:SetColor(unpack(color))
  end

  -- local a = 1
  -- if alpha ~= nil then a = alpha end
  --
  -- label:SetAlpha(a)
end

local function GetHighlightColor(fading, effect)
  local color = nil

  if fading then
    if SV.highlightExpire
    then color = SV.highlightExpireColor
    else
      if SV.showHighlight then color = SV.highlightColor end
    end
  else
    if SV.showHighlight then color = SV.highlightColor end
  end
  return color
end

local bgHidden = {}
local function UpdateBackgroundVisuals(background, color, index)
  if color ~= nil then
    background:SetHidden(false)
    background:SetColor(unpack(color))
  else
    background:SetHidden(true)
  end

  if index > 0 then
    if bgHidden[index] ~= nil then
      local wasHidden = bgHidden[index]
      if wasHidden ~= hide then
        local isHidden = hide and 'hidden' or 'showing'
        -- d('[' .. index .. '] ' .. isHidden)
      end
    end
    bgHidden[index] = hide
  else
    d('Index 0 Error!')
  end
end

local function ShouldShowExpire(duration)
  local u = FAB.constants.update
  if not u.showDecimal then return false end
  if (duration > u.showDecimalStart) then return false end
  return true
end

local function ResolveLabelAlphaForDebuff(debuff)
  local alpha = 1
  if (debuff.activeOnTarget == false and debuff.hideOnNoTarget == false) then
    if (FAB.constants.noTargetFade == true) then alpha = FAB.constants.noTargetAlpha end
  end
  return alpha
end

local function FormatTextForDurationOfActiveEffect(fading, effect, duration)
  local timer, color = '', nil

  if duration <= 0 then
    if (SV.delayFade and not effect.instantFade) then
      local delayEnd = (effect.endTime + SV.fadeDelay) - time()
      if delayEnd > 0 then timer = zo_max(0, zo_ceil(duration)) end
    end

    if effect.id == FAB.sCorch.id1 then
      FAB.stacks[effect.id] = 0
      FAB.HandleStackUpdate(effect)
    end

    if effect.id == FAB.deepFissure.id1 then
      FAB.stacks[effect.id] = 0
      FAB.HandleStackUpdate(effect)
    end

    if effect.id == FAB.subAssault.id1 then
      FAB.stacks[effect.id] = 0
      FAB.HandleStackUpdate(effect)
    end

  else
    if ShouldShowExpire(duration)
    then timer = strformat('%0.1f', duration)
    else timer = strformat('%0.0f', duration) end
  end

  if (fading and SV.showExpire)
  then color = SV.expireColor
  else color = FAB.constants.duration.color end

  return timer, color
end

function UpdateOverlay(index)                         -- timer label updates.
  local overlay = FAB.overlays[index]
  if overlay then
    local effect          = overlay.effect
    local durationControl = overlay:GetNamedChild('Duration')
    local bgControl       = overlay:GetNamedChild('BG')
    local stacksControl   = overlay:GetNamedChild('Stacks')
    local lt, lc, la      =   '', nil, nil
    local bh, bc          = true, nil

    if (effect and not effect.ignore and effect.id > 0) then

      if (effect.toggled or effect.passive) then
      else
        local duration = 0 -- = effect.endTime - time()

        if (effect.id == FAB.tauntId and FAB.tauntSlots[index] ~= nil) then
              duration = FAB.tauntSlots[index].endTime - time()
        elseif FAB.fixedTimers[effect.id] then
              duration = FAB.GetFixedDuration(effect.id) - time()
        else  duration = effect.endTime - time() end

        local isFading = false
        if (duration <= SV.showExpireStart) then isFading = SV.showExpire end

        -- local hasFaded = effect.faded

        lt, lc = FormatTextForDurationOfActiveEffect(isFading, effect, duration)
        if duration > 0 then
          bc = GetHighlightColor(isFading)
        else
          if effect.isDebuff then
            if FAB.stacks[effect.id] then FAB.stacks[effect.id] = 0 end
          end
        end

        -- if duration <= 0 then
        --   if (SV.delayFade and not effect.instantFade) then
        --     local delayEnd = (effect.endTime + SV.fadeDelay) - time()
        --     if delayEnd > 0 then
        --       lt = zo_max(0, zo_ceil(duration))
        --     else
        --     end
        --   else
        --     if effect.id == FAB.subAssault.id1 then
        --       FAB.stacks[effect.id] = 0
        --       FAB.HandleStackUpdate(effect)
        --     end
        --   end
        -- else

          -- bgControl:SetHidden(not SV.showHighlight)
          --
          -- if (showDecimal and (duration <= showDecimalStart)) then
          --   lt = strformat('%0.1f', duration)
          --   durationControl:SetText(strformat('%0.1f', duration))
          -- else
          --   lt = strformat('%0.0f', duration)
          --   durationControl:SetText(strformat('%0.0f', duration))
          -- end
          --
          -- if (duration <= SV.showExpireStart) then
          --   if (SV.showExpire) then
          --     lc = SV.expireColor
          --     durationControl:SetColor(unpack(SV.expireColor))
          --   end
          --   if (SV.highlightExpire) then
          --     bc = SV.highlightExpireColor
          --     bgControl:SetColor(unpack(SV.highlightExpireColor))
          --   end
          -- else
          --   lc = timerColor
          --   bc = SV.highlightColor
          --   bgControl:SetColor(unpack(SV.highlightColor))
          --   durationControl:SetColor(unpack(FAB.constants.duration.color))
          -- end
        -- end

        UpdateTimerLabel(durationControl, lt, lc)
        UpdateBackgroundVisuals(bgControl, bc, index)

        if FAB.trapTimers[effect.id] then
          local tt = FAB.trapTimers[effect.id] - time()
          if tt > 0
          then stacksControl:SetText(zo_max(0, zo_ceil(tt)))
          else stacksControl:SetText('') end
          return
        end
      end
      if not FAB.stacks[effect.id] or (FAB.stacks[effect.id] and FAB.stacks[effect.id] == 0) then stacksControl:SetText('') end
    else
      durationControl:SetText('')
      bgControl:SetHidden(true)
      stacksControl:SetText('')
      -- UpdateTimerLabel(durationControl, lt, lc)
      -- UpdateBackgroundVisuals(bgControl, bh, bc, index)
    end
  end
end

function UpdateStacks(index)                          -- stacks label.
  local overlay = FAB.overlays[index]
  if overlay then
    local stacksControl = overlay:GetNamedChild('Stacks')
    local effect        = overlay.effect
    if effect then
      if FAB.stacks[effect.id] and FAB.stacks[effect.id] > 0 then
        stacksControl:SetText(FAB.stacks[effect.id])
        stacksControl:SetColor(unpack(FAB.constants.stacks.color))
      else stacksControl:SetText('') end
    else stacksControl:SetText('') end
  end
end

function UpdateUltOverlay(index)                      -- update ultimate labels.

  local overlay = FAB.ultOverlays[index]
	if overlay then
		local effect = overlay.effect
		local durationControl = overlay:GetNamedChild('Duration')
		-- local timerColor = IsInGamepadPreferredMode() and SV.ultColorGP or SV.ultColorKB
    local timerColor = FAB.constants.ult.duration.color

    if not FAB.constants.ult.duration.show then durationControl:SetText('') return end

		if effect then
			local duration = effect.endTime - time()
			if duration > -2 then
				if duration > 0 then

          if (showDecimal and (duration <= showDecimalStart))
          then durationControl:SetText(strformat('%0.1f', zo_max(0, duration)))
					else durationControl:SetText(zo_max(0, zo_ceil(duration))) end

          if (duration <= SV.showExpireStart) then
						if (SV.showExpire) then durationControl:SetColor(unpack(SV.expireColor)) end
					else durationControl:SetColor(unpack(timerColor)) end

        else
          if (SV.delayFade and not effect.instantFade) then
            local delayEnd = (effect.endTime + SV.fadeDelay) - time()
            if delayEnd > 0
            then durationControl:SetText(zo_max(0, zo_ceil(duration)))
            else durationControl:SetText('') end
          else durationControl:SetText('') end
        end
      else durationControl:SetText('') end
    else durationControl:SetText('') end
	end
end

function FAB.HandleStackUpdate(id)                    -- find overlays for a specific effect and update stacks.
  local effect = FAB.effects[id]
  if effect then
    if effect.slot1 then UpdateStacks(effect.slot1) end
    if effect.slot2 then UpdateStacks(effect.slot2) end

    if id == 122658 then
      if FAB.effects[id] and FAB.stacks[id] == 0 then
        FAB.effects[122658].endTime = time()
      end
    end
  end
end

function FAB.UpdateTaunt(index)
  if FAB.tauntSlots[index] ~= nil then UpdateOverlay(index) end
end

function UpdateToggledAbility(id, active)             -- toggled effect highligh update.
  local effect = FAB.effects[id]

  if not FAB.toggles[effect.id] then FAB.toggles[effect.id] = false end

  FAB.toggles[effect.id] = active

  if effect.slot1 then FAB.UpdateHighlight(effect.slot1) end
  if effect.slot2 then FAB.UpdateHighlight(effect.slot2) end
end

function UpdatePassiveEffect(id, active)              -- passive effect highligh update.
  for i, overlay in pairs(FAB.overlays) do
    local effect = overlay.effect
    if effect then
      if effect.id == id then
        effect.passive = active
        FAB.UpdateHighlight(i)
      end
    end
  end
end

function UnslotEffect(index)                          -- Remove effect from overlay index.
  local overlay, effect

  if (index == ULT_INDEX) or (index == (ULT_INDEX + SLOT_INDEX_OFFSET)) then
    overlay = FAB.ultOverlays[index]
    if      index == ULT_INDEX then cost1 = 0
    elseif  index == (ULT_INDEX + SLOT_INDEX_OFFSET)
    then    cost2 =  0 end
  else
    overlay = FAB.overlays[index]
  end

  if overlay then
    effect = overlay.effect
    if effect then
      if effect.id then
        if effect.id == FAB.tauntId then  FAB.tauntSlots[index]  = nil end
        if FAB.debuffs[effect.id]   then  FAB.debuffs[effect.id] = nil end
        ResetOverlayDuration(overlay)
      end
      overlay.effect = nil
    end
  end
end

function SlotEffect(index, abilityId)                 -- assign effect and instructions to overlay index.
  if (not abilityId or abilityId == 0) then UnslotEffect(index) return end
  if (GetAbilityCastInfo(abilityId) and not FAB.allowedChanneled[abilityId]) then UnslotEffect(index) return end

  local overlay = FAB.GetOverlay(index)
  if not overlay then return end

  local effectId, duration, custom, toggled, passive, instantFade, ignore

  local cfg    = FAB.customAbilityConfig[abilityId]
  local ignore = false

  if cfg == false then ignore = true end

  if cfg ~= nil then
    if ignore then
      effectId        = abilityId
      custom          = true
      toggled         = false
      instantFade     = false
    else
      if (FAB.soulTrap[abilityId]) then
        if (cfg[1] and cfg[1] == FAB.abilityConfig[abilityId][1]) -- check if tracked id has been altered
        then effectId = ResolveIdToTrack(1, abilityId)
        else effectId = cfg[1] or abilityId end

      elseif abilityId == 81420 then -- guard slot id while active for all morphs
        if guardId > 0 then effectId = guardId end
      else
        effectId = cfg[1] or abilityId
        if FAB.guard.ids[abilityId] then guardId = abilityId end
      end

      custom          = true
      toggled         = cfg[3] or false
      instantFade     = cfg[4] or false
    end
  else
    effectId        = abilityId
    custom          = false
    toggled         = FAB.toggled[effectId] or false
    instantFade     = FAB.removeInstantly[effectId] or false
  end

  FAB.SetSlottedEffect(index, abilityId, effectId)

  if   (toggled == false and ignore == false)
  then duration = (GetAbilityDuration(effectId) or 0) / 1000
  else duration = 0 end

  local effect = FAB.GetEffect(effectId, true, custom, toggled, ignore, instantFade) -- FAB.effects[effectId]

  if not ignore then
    effect.duration = duration and duration > 0 and duration or nil
  end

  if (effect.id > 0 and FAB.activeCasts[effect.id] == nil) then
    FAB.activeCasts[effect.id] = {slot = index, cast = 0, begin = 0, fade = 0 }
  end

  if not SV.advancedDebuff and effect.isDebuff then effect.isDebuff = false end

  if effectId == FAB.tauntId then
    if FAB.tauntSlots[index] == nil then
      FAB.tauntSlots[index] = { unit = 0, endTime = 0, activeOnTarget = false }
    end
  end

  if not effect.isDebuff then
    local has, dur, stacks = CheckForActiveEffect(effect.id)
    if has then effect.endTime = time() + dur end
    if FAB.stackMap[effectId] then FAB.stacks[FAB.stackMap[effectId]] = stacks end
  end

  local isFrontBar = index < SLOT_INDEX_OFFSET and true or false

  if (index == ULT_INDEX or index == (ULT_INDEX + SLOT_INDEX_OFFSET)) then
    if isFrontBar then
      effect.ult1 = index
      if abilityId == 113105 then cost1 = 70 else cost1 = GetAbilityCost(abilityId) end
    elseif index == (ULT_INDEX + SLOT_INDEX_OFFSET) then
      effect.ult2 = index
      if abilityId == 113105 then cost2 = 70 else cost2 = GetAbilityCost(abilityId) end
    end

    local ultOverlay = FAB.ultOverlays[index]
    if ultOverlay then ultOverlay.effect = effect end
    return effect
  end

  if isFrontBar then
    effect.slot1 = index
    if FAB.guard.ids[effect.id] then FAB.guard.slot1 = index end
  else
    effect.slot2 = index
    if FAB.guard.ids[effect.id] then FAB.guard.slot2 = index end
  end
  -- Assign effect to overlay.
  if overlay then overlay.effect = effect end

  if FAB.stacks[effect.id] then
    UpdateOverlay(index)
    UpdateStacks(index)
  end
  return effect
end

function SlotEffects()                                -- slot effects for primary and backup bars.
  if currentHotbarCategory == HOTBAR_CATEGORY_PRIMARY or currentHotbarCategory == HOTBAR_CATEGORY_BACKUP then
    for i = MIN_INDEX, MAX_INDEX do
      SlotEffect(i, GetSlotBoundId(i, HOTBAR_CATEGORY_PRIMARY))
      SlotEffect(i + SLOT_INDEX_OFFSET, GetSlotBoundId(i, HOTBAR_CATEGORY_BACKUP))
    end
    SlotEffect(ULT_INDEX, GetSlotBoundId(ULT_INDEX, HOTBAR_CATEGORY_PRIMARY))
    SlotEffect(ULT_INDEX + SLOT_INDEX_OFFSET, GetSlotBoundId(ULT_INDEX, HOTBAR_CATEGORY_BACKUP))
  else
    -- Unslot all effects, if we are on a special bar.
    for i = MIN_INDEX, ULT_INDEX do
      UnslotEffect(i)
      UnslotEffect(i + SLOT_INDEX_OFFSET)
    end
  end
end

function UpdateEffect(effect)                         -- update overlays linked to the effect.
  if effect then
    if effect.slot1 then UpdateOverlay(effect.slot1) end
    if effect.slot2 then UpdateOverlay(effect.slot2) end
  end
end

function FAB.HandleDebuffUpdate(effect, stacks)       -- incoming updates from debuff.lua
  if effect then
    UpdateEffect(effect)
    if stacks then FAB.HandleStackUpdate(effect.id) end
  end
end

function FAB.StackCheck()                             -- ???
  local t = time()
  local effect = FAB.effects[51392]
  if effect then
    if effect.endTime >= t then
      if FAB.stacks[effect.id] > 0 then
        FAB.stacks[effect.id] = 0
        UpdateEffect(effect)
        FAB.HandleStackUpdate(effect.id)
      end
    end
  end
end
--------------
-- Quick Slot
--------------
function UpdateQuickSlotOverlay()                     -- from LUI. update every 500ms
  local t = FAB.qsOverlay.timer
  local slotIndex = GetCurrentQuickslot()
  local remain, duration, global = GetSlotCooldownInfo(slotIndex, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
  if (duration > 5000) then
    t:SetHidden(false)
    if remain > 86400000 then -- more then 1 day
      t:SetText( string.format('%d d', math.floor( remain/86400000 )) )
    elseif remain > 6000000 then -- over 100 minutes - display XXh
      t:SetText( string.format('%dh', math.floor( remain/3600000 )) )
    elseif remain > 600000 then -- over 10 minutes - display XXm
      t:SetText( string.format('%dm', math.floor( remain/60000 )) )
    elseif remain > 60000 then
      local m = math.floor( remain/60000 )
      local s = remain/1000 - 60*m
      t:SetText( string.format('%d:%.2d', m, s) )
    else
      t:SetText(string.format('%.1d', 0.001 * remain))
    end
  else
    if not FAB.InMenu() then t:SetText('') end
  end
end
--------------
-- GCD
--------------
function FAB.UpdateGCD()
  local cooldown, duration, global, globalSlotType = GetSlotCooldownInfo(MIN_INDEX)
	local cooldown2, duration2, _, _ = GetSlotCooldownInfo(MIN_INDEX + 1)
	if (cooldown2 > cooldown) or (duration2 > duration) then
		cooldown = cooldown2
		duration = duration2
	end
  if duration < 1 then duration = 1 end
  local h = (cooldown / duration) * SV.gcd.sizeY
  FAB_GCD.fill:SetHeight(h)
end
--------------
-- Ultimate
--------------
local function GetValueString(mode, value, cost)      -- format label text
  local string = ''
  if mode == 1 then
    string = value
  elseif mode == 3 then
    string = value .. '/' .. cost
  else
    if value >= cost
    then string = value
    else string = value .. '/' .. cost end
  end
  return string
end

function FAB.UpdateUltimateValueLabels(player, value) -- update ultimate value displays
  local modeP = FAB.constants.ult.value.mode
  local modeC = FAB.constants.ult.companion.mode
  local alpha = (value < 10) and 0 or 1

  if (player and FAB.constants.ult.value.show) then
    ActionButton8LeadingEdge:SetAlpha(alpha)
    -- ActionButton8UltimateBar:SetHidden(false)

    local o1 = FAB.ultOverlays[ULT_INDEX]
    local o2 = FAB.ultOverlays[ULT_INDEX + SLOT_INDEX_OFFSET]

    if o1 and o1.value then o1.value:SetText(GetValueString(modeP, value, cost1)) end
    if o2 and o2.value then o2.value:SetText(GetValueString(modeP, value, cost2)) end
  else
    local o3 = FAB.ultOverlays[ULT_INDEX + COMPANION_INDEX_OFFSET]
    CompanionUltimateButtonLeadingEdge:SetAlpha(alpha)

    if hideCompanionUlt then
      CompanionUltimateButton:SetHidden(true)
      if o3 and o3.value then o3.value:SetText('') end
    else
      CompanionUltimateButton:SetHidden(false)
      if o3 and o3.value then o3.value:SetText(GetValueString(modeC, value, cost3)) end
    end
  end
end

local function OnUltChanged(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
  if powerType == POWERTYPE_ULTIMATE then
    FAB.UpdateUltimateValueLabels(true, powerValue)
  end
end

local function OnUltChangedCompanion(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
  if powerType == POWERTYPE_ULTIMATE then
    FAB.UpdateUltimateValueLabels(false, powerValue)
  end
end

function FAB.UpdateUltimateCost()                     -- manual ultimate value update
  if not FAB.constants.ult.value.show then return end

  local function ResolveUltCost(id)
    local incap = 113105
    local cost  = 0
    if id > 0 then
      if id == incap
      then cost = 70
      else cost = GetAbilityCost(id) end
    end
    return cost
  end

  cost1 = ResolveUltCost(GetSlotBoundId(ULT_INDEX, HOTBAR_CATEGORY_PRIMARY))
  cost2 = ResolveUltCost(GetSlotBoundId(ULT_INDEX, HOTBAR_CATEGORY_BACKUP))

  current, _, _ = GetUnitPower('player', POWERTYPE_ULTIMATE)
  FAB.UpdateUltimateValueLabels(true, current)
end
--------------------------------------------------------------------------------
-----------------------------[ 		Configuration    ]----------------------------
--------------------------------------------------------------------------------
function FAB.RefreshUpdateConfiguration()             -- set overlays refresh rate
  local update = {
    showDecimal       = false,
    showDecimalStart  = 0,
  }
  if (SV.showDecimal == 'Never') then
    update.showDecimal      = false
    update.showDecimalStart = 0
  elseif (SV.showDecimal == 'Always') then
    update.showDecimal      = true
    update.showDecimalStart = SV.durationMax
  elseif (SV.showDecimal == 'Expire') then
    update.showDecimal      = true
    update.showDecimalStart = SV.showDecimalStart
  end
  return update
end
--  ---------------------------------
--  Load Saved Ability Configuration
--  ---------------------------------
function FAB.BuildAbilityConfig()                     -- Parse FAB.abilityConfig for faster access.
  -- Init custom ability config with defaults
  for id, cfg in pairs(FAB.abilityConfig) do
    FAB.customAbilityConfig[id] = cfg
  end

  -- Apply changes to custom ability config
  for id, cfg in pairs(FAB.GetAbilityConfigChanges()) do
    FAB.customAbilityConfig[id] = cfg
  end

  if FAB.customAbilityConfig[31816] then -- configure stone giant
    FAB.customAbilityConfig[133027] = FAB.customAbilityConfig[31816]

    if FAB.customAbilityConfig[31816][1] == 31816 then
      FAB.stackMap[31816]   = FAB.customAbilityConfig[31816][1]
      FAB.stackMap[134336]  = nil
    elseif cI == 134336 then
      FAB.stackMap[31816]   = nil
      FAB.stackMap[134336]  = FAB.customAbilityConfig[31816][1]
    else
      FAB.stackMap[31816]   = nil
      FAB.stackMap[134336]  = nil
    end
  end

  for id, cfg in pairs(FAB.customAbilityConfig) do

    local toggled, hide = false, false

    -- if debuffs[id]
    -- then hide = debuffs[id]
    -- else hide = FAB.GetHideOnNoTargetGlobalSetting() end

    if FAB.toggled[id]  then  toggled = true; FAB.toggles[id] = false end

    local cI, rI = id, false

    if type(cfg) == 'table' then
      if cfg[1] then cI = cfg[1] end
    end

    if FAB.removeInstantly[cI] then rI = true end

    if type(cfg) == 'table' then  FAB.customAbilityConfig[id] = {cI, true, toggled, rI}
    elseif cfg then               FAB.customAbilityConfig[id] = {cI, true, toggled, rI}
    elseif cfg == false then      FAB.customAbilityConfig[id] = false
    else                          FAB.customAbilityConfig[id] = nil end
  end

  -- for id, isToggled in pairs(FAB.toggled) do
  --   if id then
  --     local i
  --     -- if FAB.abilityConfig[id] then i = FAB.abilityConfig[id]
  --     if config[id] then i = config[id]
  --       if type(i) == 'table'
  --       then i = i[1] or id
  --       else i = id end
  --     else i = id end
  --     abilityConfig[id] = {i, true, isToggled}
  --     FAB.toggles[id]   = false
  --   end
  -- end
end
--  ---------------------------------
--  Buffs gained by player from others
--  ---------------------------------
local BUFF_EFFECT_TYPE_DEBUFF	= BUFF_EFFECT_TYPE_DEBUFF
local function OnEffectGainedFromAlly(eventCode, change, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)

  if sourceType == COMBAT_UNIT_TYPE_PLAYER then return end
  if not AreUnitsEqual('player', unitTag) then return end

  local effect = FAB.effects[abilityId]
  if effect then

    local t = time()

    if SV.externalBlackList[abilityId] then return end

    if (change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED and buffType ~= BUFF_EFFECT_TYPE_DEBUFF) then

      if beginTime == endTime then UpdatePassiveEffect(abilityId, true) return end

      if (endTime > t + FAB.durationMin and endTime < t + FAB.durationMax and endTime > effect.endTime) then
        effect.endTime = endTime
        UpdateEffect(effect)
      end

    elseif (change == EFFECT_RESULT_FADED) then
      local hasEffect, duration, currentStacks = CheckForActiveEffect(abilityId)
      if hasEffect then
        effect.endTime = t + duration
        UpdateEffect(effect)
      else
        effect.endTime = t
        if beginTime == endTime then
          UpdatePassiveEffect(abilityId, false)
        end
      end
    end
  end
  -- local ts = tostring
  -- d('['..ts(abilityId)..'] '..effectName..' '..sourceType..': '..effectType..' --> '..unitName..endTime-beginTime..' ('..stackCount..')')
end

function FAB.SetExternalBuffTracking()                -- buffs gained from others
  EM:UnregisterForEvent(NAME .. 'External', EVENT_EFFECT_CHANGED)
  if SV.externalBuffs then
    EM:RegisterForEvent(NAME .. 'External', EVENT_EFFECT_CHANGED, OnEffectGainedFromAlly)
    EM:AddFilterForEvent(NAME .. 'External', EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG_PREFIX, 'player')
  end
end
--  ---------------------------------
--  UI Setup
--  ---------------------------------
local function AdjustControlsPositions()              -- resource bars and default action bar position
  FAB_ActionBarFakeQS:ClearAnchors()
  FAB_ActionBarFakeQS:SetAnchor(LEFT, ACTION_BAR, LEFT, 0, -5)

  local style  = FAB.GetContants()
  local anchor = ZO_Anchor:New()

  if FAB.initialSetup or uiModeChanged then
    -- Move action bar and attributes up a bit.
    uiModeChanged = false
    anchor:SetFromControlAnchor(ACTION_BAR)
    anchor:SetOffsets(nil, style.actionBarOffset)
    anchor:Set(ACTION_BAR)
  end

  anchor:SetFromControlAnchor(ZO_PlayerAttribute)
  anchor:SetOffsets(nil, style.attributesOffset)
  anchor:Set(ZO_PlayerAttribute)
end

function FAB.AdjustQuickSlotSpacing()                 -- quickslot placement and arrow visibility
  local style             = FAB.GetContants()
	local weaponSwapControl = ACTION_BAR:GetNamedChild('WeaponSwap')
  local QSB               = QuickslotButton

  QSB:ClearAnchors()

  if SV.showArrow == false then
		if SV.moveQS == true then
      if not FAB.style == 1 then
        QSB:SetAnchor(RIGHT, weaponSwapControl, RIGHT, - (2 + (SLOT_COUNT * (style.abilitySlotOffsetX*scale))), -2 * scale)
      else
        QSB:SetAnchor(RIGHT, weaponSwapControl, RIGHT, - (5 + (style.abilitySlotOffsetX*scale)), -2 * scale)
      end
    else
      QSB:SetAnchor(LEFT, FAB_ActionBarFakeQS, LEFT, 0, -2 * scale)
    end

  else
    QSB:SetAnchor(LEFT, FAB_ActionBarFakeQS, LEFT, 0, -2 * scale)
    FAB_ActionBarArrow:SetColor(unpack(SV.arrowColor))
  end

  -- ActionButton9:ClearAnchors()
  --
	-- if SV.showArrow == false then
	-- 	if SV.moveQS == true then
  --     if not FAB.style == 1 then
  --       ActionButton9:SetAnchor(RIGHT, weaponSwapControl, RIGHT, - (2 + (SLOT_COUNT * (style.abilitySlotOffsetX*scale))), -2 * scale)
  --     else
  --       ActionButton9:SetAnchor(RIGHT, weaponSwapControl, RIGHT, - (5 + (style.abilitySlotOffsetX*scale)), -2 * scale)
  --     end
  --   else
  --     ActionButton9:SetAnchor(LEFT, FAB_ActionBarFakeQS, LEFT, 0, -2 * scale)
  --   end
  --
  -- else
  --   ActionButton9:SetAnchor(LEFT, FAB_ActionBarFakeQS, LEFT, 0, -2 * scale)
  --   FAB_ActionBarArrow:SetColor(unpack(SV.arrowColor))
  -- end
  FAB_ActionBarArrow:SetHidden(not SV.showArrow)
end

function FAB.AdjustUltimateSpacing()                  -- place the ultimate button according to variables
  if FAB.style == 1 then return end
  local style  = FAB.GetContants()
  local weaponSwapControl = ACTION_BAR:GetNamedChild('WeaponSwap')

  ActionButton8:ClearAnchors()
  CompanionUltimateButton:ClearAnchors()

  local ultX = 10 + (10 * scale)
  local ultC = 20 + (10 * scale)
  local u    = 65 * scale
  local f1   = (style.abilitySlotWidth + style.abilitySlotOffsetX)
  local f2   = f1 * SLOT_COUNT

  if SV.showHotkeysUltGP then
    ActionButton8:SetAnchor(LEFT, weaponSwapControl, RIGHT, f2 + u, 0)
    CompanionUltimateButton:SetAnchor(LEFT, ActionButton8, RIGHT, u + ultC, 0)
    return
  end

  if SV.moveQS == true then
    ActionButton8:SetAnchor(LEFT, weaponSwapControl, RIGHT, f2 + ultX, 0)
    CompanionUltimateButton:SetAnchor(LEFT, ActionButton8, RIGHT, 20 + ultX, 0)
  else
    ActionButton8:SetAnchor(LEFT, weaponSwapControl, RIGHT, f2 + u, 0)
    -- ActionButton8:SetAnchor(RIGHT, ZO_ActionBar1, RIGHT, 40 * scale, 0)
    CompanionUltimateButton:SetAnchor(LEFT, ActionButton8, RIGHT, u + ultC, 0)
  end
end

function FAB.ApplySettings()                          -- apply all UI settings for current UI mode
  FAB.AdjustQuickSlotSpacing()

  FAB.ConfigureFrames()
  FAB.ApplyTimerFont()
  FAB.AdjustTimerY()

  FAB.ApplyStackFont()
  FAB.AdjustStackX()

  FAB.AdjustUltTimer(false)
  FAB.ApplyUltFont(false)

  FAB.AdjustUltValue()
  FAB.ApplyUltValueColor()
  FAB.AdjustCompanionUltValue()
  FAB.ApplyUltValueFont()
  FAB.UpdateUltimateCost()

  FAB.AdjustQuickSlotTimer()
  FAB.ApplyQuickSlotFont()
  FAB.ToggleQuickSlotDuration()

  FAB.ToggleGCD()

  if FAB.initialSetup then
    FAB.initialSetup = false
    FAB.ApplyPosition()
  end
end

function FAB.ToggleQuickSlotDuration()                -- enable / disable quickslot timer
  local enable = FAB.constants.qs.show
  EM:UnregisterForUpdate(NAME .. 'UpdateQuickSlot')
  if enable
  then EM:RegisterForUpdate(NAME .. 'UpdateQuickSlot', 500, UpdateQuickSlotOverlay)
  else FAB.qsOverlay:GetNamedChild('Duration'):SetText('') end
end

function FAB.ToggleUltimateValue()                    -- enable / disable ultimate value
  local e = FAB.constants.ult.value.show
  local current

  EM:UnregisterForUpdate(NAME .. 'UltValue', EVENT_POWER_UPDATE)
  EM:UnregisterForUpdate(NAME .. 'UltValueCompanion', EVENT_POWER_UPDATE)

  for i in pairs(FAB.ultOverlays) do
    local v = FAB.ultOverlays[i]:GetNamedChild('Value')
    if v then v:SetText('') end
  end

  -- FAB.ultOverlays[ULT_INDEX]:GetNamedChild('Value'):SetText('')
  -- FAB.ultOverlays[ULT_INDEX + SLOT_INDEX_OFFSET]:GetNamedChild('Value'):SetText('')
  -- FAB.ultOverlays[ULT_INDEX + COMPANION_INDEX_OFFSET]:GetNamedChild('Value'):SetText('')

  -- cost1 = GetSlotAbilityCost(ULT_INDEX, HOTBAR_CATEGORY_PRIMARY)
  -- cost2 = GetSlotAbilityCost(ULT_INDEX, HOTBAR_CATEGORY_BACKUP)
  cost3 = GetSlotAbilityCost(ULT_INDEX, COMPANION)

  if e then
    current, _, _ = GetUnitPower('player', POWERTYPE_ULTIMATE)
    FAB.UpdateUltimateValueLabels(true, current)
    EM:RegisterForEvent(NAME .. 'UltValue', EVENT_POWER_UPDATE, OnUltChanged)
    EM:AddFilterForEvent(NAME .. 'UltValue', EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_ULTIMATE, REGISTER_FILTER_UNIT_TAG, 'player')
  end

  if (not DoesUnitExist('companion') or not HasActiveCompanion() or cost3 == nil or cost3 == 0) then
    CompanionUltimateButton:SetHidden(true)
    return
  end

  local c = FAB.constants.ult.companion.show
  if c then
    current, _, _ = GetUnitPower('companion', POWERTYPE_ULTIMATE)
    FAB.UpdateUltimateValueLabels(false, current)
    EM:RegisterForEvent(NAME .. 'UltValueCompanion', EVENT_POWER_UPDATE, OnUltChangedCompanion)
    EM:AddFilterForEvent(NAME .. 'UltValueCompanion', EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_ULTIMATE, REGISTER_FILTER_UNIT_TAG, 'companion')
  end
end
--  ---------------------------------
--  UI Prep before initial
--  ---------------------------------
function FAB.OnActionBarInitialized(control)          -- backbar control initialized.
  ULTIMATE_BUTTON_STYLE.parentBar = control

  -- Set active bar as a parent to make inactive bar show/hide automatically.
  control:SetParent(ACTION_BAR)

  -- Need to adjust it here instead of in ApplyStyle(), otherwise it won't properly work with Azurah.
  AdjustControlsPositions()

  -- Create inactive bar buttons.
  for i = MIN_INDEX + SLOT_INDEX_OFFSET, MAX_INDEX + SLOT_INDEX_OFFSET do
    local button = ActionButton:New(i, ACTION_BUTTON_TYPE_VISIBLE, control, 'ZO_ActionButton')
    button:SetShowBindingText(false)
    button.icon:SetHidden(true)
    button:SetupBounceAnimation()
    FAB.buttons[i] = button
  end
end

function CreateOverlay(index)                         -- create normal skill button overlay.
  -- local template = ZO_GetPlatformTemplate('FAB_ActionButtonOverlay')
  local template  = FAB.constants.style.overlayTemplate
  local overlay   = FAB.overlays[index]
  if overlay then
    ApplyTemplateToControl(overlay, template)
    overlay:ClearAnchors()
    overlay.activeEffects = {}
  else
    overlay       = CreateControlFromVirtual('ActionButtonOverlay', ACTION_BAR, template, index)
    overlay.timer = overlay:GetNamedChild('Duration')
    overlay.bg    = overlay:GetNamedChild('BG')
    overlay.stack = overlay:GetNamedChild('Stacks')
    FAB.overlays[index] = overlay
  end
  return overlay
end

function CreateUltOverlay(index)                      -- create ultimate skill button overlay.
  -- local template = ZO_GetPlatformTemplate('FAB_UltimateButtonOverlay')
  local template = FAB.constants.style.ultOverlayTemplate
  local overlay  = FAB.ultOverlays[index]
  if overlay then
    ApplyTemplateToControl(overlay, template)
    overlay:ClearAnchors()
  else
    local parent
    if index == ULT_INDEX + COMPANION_INDEX_OFFSET
    then parent = ZO_ActionBar_GetButton(ULT_SLOT, COMPANION)
    else parent = ZO_ActionBar_GetButton(ULT_SLOT) end
    overlay = CreateControlFromVirtual('UltimateButtonOverlay', parent.slot, template, index)
    overlay.timer = overlay:GetNamedChild('Duration')
    overlay.value = overlay:GetNamedChild('Value')
    FAB.ultOverlays[index] = overlay
  end
  return overlay
end

function CreateQuickSlotOverlay()                     -- create quickslot button overlay.
  -- local template = ZO_GetPlatformTemplate('FAB_QuickSlotOverlay')
  local template = FAB.constants.style.qsOverlayTemplate
  local overlay  = FAB.qsOverlay
  if overlay then
    ApplyTemplateToControl(overlay, template)
    overlay:ClearAnchors()
  else
    overlay       = CreateControlFromVirtual('QuickSlotOverlay', ACTION_BAR, template, index)
    FAB.qsOverlay = overlay
  end
  return overlay
end

function ApplyQuickSlotAndUltimateStyle()             -- make sure UI is adjusted to settings
  local style  = FAB.GetContants()
  local weaponSwapControl = ACTION_BAR:GetNamedChild('WeaponSwap')
  local QSB = QuickslotButton

  ZO_ActionBar_GetButton(ULT_SLOT):ApplyStyle(style.ultButtonTemplate)
  ZO_ActionBar_GetButton(ULT_SLOT, COMPANION):ApplyStyle(style.ultButtonTemplate)
  -- ZO_ActionBar_GetButton(QUICK_SLOT):ApplyStyle(style.buttonTemplate)
  -- QSB:ApplyStyle(style.buttonTemplate)

  -- Reposition ultimate slot.
  if FAB.style == 2 then
    FAB.AdjustUltimateSpacing()
  else
    ActionButton8:ClearAnchors()
    CompanionUltimateButton:ClearAnchors()
    local u  = style.ultimateSlotOffsetX * scale
    local f1 = (style.abilitySlotWidth + style.abilitySlotOffsetX)
    local f2 = (f1 * SLOT_COUNT) - 2
    ActionButton8:SetAnchor(LEFT, weaponSwapControl, RIGHT, f2 + u, -2 * scale)
    -- ActionButton8:SetAnchor(LEFT, weaponSwapControl, RIGHT, SLOT_COUNT * ((style.abilitySlotWidth*scale) + 2 * (style.abilitySlotOffsetX*scale)), -2 * scale)
    CompanionUltimateButton:SetAnchor(LEFT, ActionButton8, RIGHT, u, 0)
  end

  local c8  = ActionButton8FlipCard
  local c9  = ActionButton9FlipCard
  local c38 = CompanionUltimateButtonFlipCard

  if c8  then c8:SetDimensions (style.ultFlipCardSize, style.ultFlipCardSize) end
  if c9  then c9:SetDimensions (style.flipCardSize,    style.flipCardSize)    end
  if c38 then c38:SetDimensions(style.ultFlipCardSize, style.ultFlipCardSize) end

  local hideUltNumber = FAB.constants.ult.value.show
  if hideUltNumber then SetSetting(SETTING_TYPE_UI, UI_SETTING_ULTIMATE_NUMBER, 0) end

  local leftFill   = ActionButton8FillAnimationLeft
  local rightFill  = ActionButton8FillAnimationRight
  local leftFillC  = CompanionUltimateButtonFillAnimationLeft
  local rightFillC = CompanionUltimateButtonFillAnimationRight
  local gpFrame    = ActionButton8Frame
  local gpFrameC   = CompanionUltimateButtonFrame

  if FAB.style == 2 then
    -- safety check for gamepad ultimate display
    if leftFill ~= nil then
      leftFill:ClearAnchors()
      leftFill:SetAnchor(TOPRIGHT,    ActionButton8Backdrop, TOP,          0, -24)
      leftFill:SetAnchor(BOTTOMLEFT,  ActionButton8Backdrop, BOTTOMLEFT, -24,  24)
      leftFill:SetHidden(false)
    end

    if rightFill ~= nil then
      rightFill:ClearAnchors()
      rightFill:SetAnchor(TOPLEFT,      ActionButton8Backdrop, TOP,            0, -24)
      rightFill:SetAnchor(BOTTOMRIGHT,  ActionButton8Backdrop, BOTTOMRIGHT,   24,  24)
      rightFill:SetHidden(false)
    end

    if leftFillC ~= nil then
      leftFillC:ClearAnchors()
      leftFillC:SetAnchor(TOPRIGHT,   CompanionUltimateButtonBackdrop, TOP,           0, -24)
      leftFillC:SetAnchor(BOTTOMLEFT, CompanionUltimateButtonBackdrop, BOTTOMLEFT,  -24,  24)
      leftFillC:SetHidden(false)
    end

    if rightFillC ~= nil then
      rightFillC:ClearAnchors()
      rightFillC:SetAnchor(TOPLEFT,     CompanionUltimateButtonBackdrop, TOP,           0, -24)
      rightFillC:SetAnchor(BOTTOMRIGHT, CompanionUltimateButtonBackdrop, BOTTOMRIGHT,  24,  24)
      rightFillC:SetHidden(false)
    end

    if gpFrame   ~= nil then gpFrame:SetHidden(false)     end
    if gpFrameC  ~= nil then gpFrameC:SetHidden(false)    end
  else
    if leftFill   ~= nil then leftFill:SetHidden(true)    end
    if rightFill  ~= nil then rightFill:SetHidden(true)   end
    if leftFillC  ~= nil then leftFillC:SetHidden(true)   end
    if rightFillC ~= nil then rightFillC:SetHidden(true)  end
    if gpFrame    ~= nil then gpFrame:SetHidden(true)     end
    if gpFrameC   ~= nil then gpFrameC:SetHidden(true)    end
  end

  -- front bar ult
  local u1 = CreateUltOverlay(ULT_INDEX)
  u1:SetAnchor(TOPLEFT,     ActionButton8,            TOPLEFT,      0,  0)
  u1:SetAnchor(BOTTOMRIGHT, ActionButton8,            BOTTOMRIGHT,  0,  0)
  u1.value = u1:GetNamedChild('Value')

  -- back bar ult
  local u2 = CreateUltOverlay(ULT_INDEX + SLOT_INDEX_OFFSET)
  u2:SetAnchor(TOPLEFT,     ActionButton8,            TOPLEFT,      0,  0)
  u2:SetAnchor(BOTTOMRIGHT, ActionButton8,            BOTTOMRIGHT,  0,  0)
  u2.value = u2:GetNamedChild('Value')

  -- companion ult
  local u3 = CreateUltOverlay(ULT_INDEX + COMPANION_INDEX_OFFSET)
  u3:SetAnchor(TOPLEFT,     CompanionUltimateButton,  TOPLEFT,     0,   0)
  u3:SetAnchor(BOTTOMRIGHT, CompanionUltimateButton,  BOTTOMRIGHT, 0,   0)
  u3.value = u3:GetNamedChild('Value')

  -- quickslot
  local QO = CreateQuickSlotOverlay()
  -- QO:SetAnchor(TOPLEFT,     ActionButton9,            TOPLEFT,      0,  0)
  -- QO:SetAnchor(BOTTOMRIGHT, ActionButton9,            BOTTOMRIGHT,  0,  0)
  QO:SetAnchor(TOPLEFT,     QSB,            TOPLEFT,      0,  0)
  QO:SetAnchor(BOTTOMRIGHT, QSB,            BOTTOMRIGHT,  0,  0)
  QO.timer = QO:GetNamedChild('Duration')
  QO.timer:SetColor(unpack(IsInGamepadPreferredMode() and SV.qsColorGP or SV.qsColorKB))

  local qsFrame = FAB.qsOverlay:GetNamedChild('Frame')
  if qsFrame then QO.frame = qsFrame end
end

local function ApplyStyle()                           -- apply style to action bars depending on keyboard/gamepad mode.
  FAB.UpdateStyle()
  currentHotbarCategory   = GetActiveHotbarCategory()
  local style             = FAB.GetContants()
  local weaponSwapControl = ACTION_BAR:GetNamedChild('WeaponSwap')	-- Most alignments are relative to weapon swap button.
  local lastButton	      -- Set positions for buttons and overlays.
  local buttonTemplate    = style.buttonTemplate   --ZO_GetPlatformTemplate('ZO_ActionButton')
  local overlayTemplate   = style.overlayTemplate  --ZO_GetPlatformTemplate('FAB_ActionButtonOverlay')

  ZO_ActionBar1:SetWidth(style.width)

  ACTION_BAR:GetNamedChild('KeybindBG'):SetHidden(true)	-- Hide default background.

  weaponSwapControl:ClearAnchors()	-- Achor weapon swap to fake quick slot. Hide and disable mouse click.
  weaponSwapControl:SetAnchor(LEFT, FAB_ActionBarFakeQS, RIGHT, 0, 0)
  weaponSwapControl:SetAlpha(0)
  weaponSwapControl:SetMouseEnabled(false)

  for i = MIN_INDEX, MAX_INDEX do

    local button = ZO_ActionBar_GetButton(i)
    button:ApplyStyle(buttonTemplate)

    local anchorTarget = lastButton and lastButton.slot
    if lastButton then button:ApplyAnchor(lastButton.slot, style.abilitySlotOffsetX)
    elseif i == MIN_INDEX then
      button.slot:ClearAnchors()
      button.slot:SetAnchor(BOTTOMLEFT, weaponSwapControl, RIGHT, 0, -4)
    end
    lastButton = button

    local overlayOffsetX = (i - MIN_INDEX) * ((style.abilitySlotWidth) + (style.abilitySlotOffsetX))
    -- Hotkey position.
    button.buttonText:ClearAnchors()
    button.buttonText:SetAnchor(TOP, weaponSwapControl, RIGHT, (overlayOffsetX + style.abilitySlotWidth / 2), style.buttonTextOffsetY)
    button.buttonText:SetHidden(not SV.showHotkeys)

    if SV.toggledHighlight or SV.showHighlight
    then button.status:SetTexture('/FancyActionBar+/texture/blank.dds')
    else button.status:SetTexture('EsoUI/Art/ActionBar/ActionSlot_toggledon.dds') end
  end

  for i = MIN_INDEX, MAX_INDEX do
    -- Main button overlay.
    local overlay = CreateOverlay(i)

    if i == MIN_INDEX
    then overlay:SetAnchor(BOTTOMLEFT, weaponSwapControl, RIGHT, 0, -4)
    else overlay:SetAnchor(LEFT, FAB.overlays[i - 1], RIGHT, style.abilitySlotOffsetX, 0) end

    -- Backbar button style and position.
    local button = FAB.buttons[i + SLOT_INDEX_OFFSET]
    button:ApplyStyle(buttonTemplate)

    button.icon:SetDesaturation(SV.desaturationInactive/100)
    button.icon:SetAlpha(SV.alphaInactive/100)

    if SV.toggledHighlight or SV.showHighlight
    then button.status:SetTexture('/FancyActionBar+/texture/blank.dds')
    else button.status:SetTexture('EsoUI/Art/ActionBar/ActionSlot_toggledon.dds') end

    if i == MIN_INDEX
    then button.slot:SetAnchor(TOPLEFT, weaponSwapControl, RIGHT, 0, 0)
    else button:ApplyAnchor(lastButton.slot, style.abilitySlotOffsetX) end
    lastButton = button

    overlay = CreateOverlay(i + SLOT_INDEX_OFFSET)	-- Back button overlay.

    if i == MIN_INDEX
    then overlay:SetAnchor(TOPLEFT, weaponSwapControl, RIGHT, 0, 0)
    else overlay:SetAnchor(LEFT, FAB.overlays[i + SLOT_INDEX_OFFSET - 1], RIGHT, style.abilitySlotOffsetX, 0) end
    -- overlay.button = button
  end

  ApplyQuickSlotAndUltimateStyle()

  FAB.ApplySettings()
end

local function SwapControls()                         -- refresh action bars positions.
  local style             = FAB.GetContants()
  local weaponSwapControl = ACTION_BAR:GetNamedChild('WeaponSwap')
  local hide
  local bar

  local function ApplyBarPosition(active, inactive, firstTop)
    if firstTop then
      active:SetAnchor(   BOTTOMLEFT, weaponSwapControl, RIGHT, 0, -4 )
      inactive:SetAnchor( TOPLEFT,    weaponSwapControl, RIGHT, 0,  0 )
    else
      active:SetAnchor(   TOPLEFT,    weaponSwapControl, RIGHT, 0,  0 )
      inactive:SetAnchor( BOTTOMLEFT, weaponSwapControl, RIGHT, 0, -4 )
    end
  end

  -- Set new anchors for the first buttons and ultimate buttons.
  ActionButton3:ClearAnchors()
  ActionButton23:ClearAnchors()
  ActionButtonOverlay3:ClearAnchors()
  ActionButtonOverlay23:ClearAnchors()
  if currentHotbarCategory == HOTBAR_CATEGORY_BACKUP then
    bar   = 0
    hide  = true
    if SV.staticBars then
      ApplyBarPosition(ActionButton23,        ActionButton3,          SV.frontBarTop      )
      ApplyBarPosition(ActionButtonOverlay23, ActionButtonOverlay3,   not SV.frontBarTop  )
    else
      ApplyBarPosition(ActionButton3,         ActionButton23,         SV.activeBarTop     )
      ApplyBarPosition(ActionButtonOverlay23, ActionButtonOverlay3,   SV.activeBarTop     )
    end
  else
    bar   = 1
    hide  = false
    if SV.staticBars then
      ApplyBarPosition(ActionButton3,         ActionButton23,         SV.frontBarTop      )
      ApplyBarPosition(ActionButtonOverlay23, ActionButtonOverlay3,   not SV.frontBarTop  )
    else
      ApplyBarPosition(ActionButton3,         ActionButton23,         SV.activeBarTop     )
      ApplyBarPosition(ActionButtonOverlay3,  ActionButtonOverlay23,  SV.activeBarTop     )
    end
  end

  FAB.ultOverlays[ULT_INDEX]:SetHidden(hide)
  FAB.ultOverlays[ULT_INDEX + SLOT_INDEX_OFFSET]:SetHidden(not hide)

  for i = MIN_INDEX, MAX_INDEX do
    -- Update icons for inactive bar.
    local index         = currentHotbarCategory == HOTBAR_CATEGORY_BACKUP and i or i + SLOT_INDEX_OFFSET
    -- local index         = (bar * SLOT_INDEX_OFFSET) + i
    -- local btnBackSlotId = slottedIds[index].ability
    local btnBack       = FAB.buttons[i + SLOT_INDEX_OFFSET]
    UpdateInactiveBarIcon(i, bar)

    local btnMain = ZO_ActionBar_GetButton(i)	-- Need to update main buttons manually, because by default it is done when animation ends.
    btnMain:HandleSlotChanged()
  end

  -- Unslot effects from the main bar if it's currently a special bar.
  if currentHotbarCategory ~= HOTBAR_CATEGORY_PRIMARY and currentHotbarCategory ~= HOTBAR_CATEGORY_BACKUP then
    for i = MIN_INDEX, MAX_INDEX do
      UnslotEffect(i)
    end
  end
end

function FAB.ApplyPosition()                          -- check if action bar should be moved.
  FAB.HideHotkeys(not SV.showHotkeys)

  FAB.MoveActionBar()
end

function FAB.UpdateBarSettings()                      -- run all UI visual updates when UI mode is changed.
  FAB.UpdateStyle()
  FAB.SetScale()
  -- FAB.SetMoved(false)
	ApplyStyle()
	SwapControls()
  AdjustControlsPositions()
  FAB.ApplyPosition()
end

function FAB.SetScale()                               -- resize and check for other addons with same function
  local enable = FAB.constants.abScale.enable
  local s

  if Azurah then
    if enable then
      local S = FAB.constants.abScale.scale
      s = S / 100
      if FAB.style == 2 then
        if not Azurah.db.uiData.gamepad['ZO_ActionBar1']
        then Azurah:RecordUserData('ZO_ActionBar1', TOPLEFT, ZO_ActionBar1:GetLeft(), ZO_ActionBar1:GetTop(), s)
        else Azurah.db.uiData.gamepad['ZO_ActionBar1'].scale = s end
      else
        if not Azurah.db.uiData.keyboard['ZO_ActionBar1']
        then Azurah:RecordUserData('ZO_ActionBar1', TOPLEFT, ZO_ActionBar1:GetLeft(), ZO_ActionBar1:GetTop(), s)
        else Azurah.db.uiData.keyboard['ZO_ActionBar1'].scale = s end
      end
    else
      if FAB.style == 2 then
        if Azurah.db.uiData.gamepad['ZO_ActionBar1'] and Azurah.db.uiData.gamepad['ZO_ActionBar1'].scale
        then s = Azurah.db.uiData.gamepad['ZO_ActionBar1'].scale
        else s = 1 end
      else
        if Azurah.db.uiData.keyboard['ZO_ActionBar1'] and Azurah.db.uiData.keyboard['ZO_ActionBar1'].scale
        then s = Azurah.db.uiData.keyboard['ZO_ActionBar1'].scale
        else s = 1 end
      end
    end
  else
    if enable then
      local S = FAB.constants.abScale.scale
      s = S / 100
    else s = 1 end
  end

  scale = s
  FAB.UpdateScale(s)
end
--------------------------------------------------------------------------------
-------------------------------[    Hooks   ]-----------------------------------
--------------------------------------------------------------------------------
local origApplySwapAnimationStyle = ActionButton['ApplySwapAnimationStyle']
local swapSize
local function ApplySwapAnimationStyle(button)
	local timeline = button.hotbarSwapAnimation

	if (timeline) then
    -- local size = FAB.style == 2 and 67 or 47
    -- local size = function() return GetUltimateFlipCardSize() end
    -- local size, _ = button.flipCard:GetDimensions()

		local firstAnimation = timeline:GetFirstAnimation()
		local lastAnimation  = timeline:GetLastAnimation()

		firstAnimation:SetStartAndEndWidth(swapSize, swapSize)
		firstAnimation:SetStartAndEndHeight(swapSize, 0)
		lastAnimation:SetStartAndEndWidth(swapSize, swapSize)
		lastAnimation:SetStartAndEndHeight(0, swapSize)
	end
end

local origSetUltimateMeter = ActionButton['SetUltimateMeter']
local function FancySetUltimateMeter(self, ultimateCount, setProgressNoAnim)
  local isSlotUsed                = IsSlotUsed(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, self.button.hotbarCategory)
  local barTexture                = GetControl(self.slot, "UltimateBar")
  local leadingEdge               = GetControl(self.slot, "LeadingEdge")
  local ultimateReadyBurstTexture = GetControl(self.slot, "ReadyBurst")
  local ultimateReadyLoopTexture  = GetControl(self.slot, "ReadyLoop")
  local ultimateFillLeftTexture   = GetControl(self.slot, "FillAnimationLeft")
  local ultimateFillRightTexture  = GetControl(self.slot, "FillAnimationRight")
  local ultimateFillFrame         = GetControl(self.slot, "Frame")

  local isGamepad = false
  if FAB.style == 2 then isGamepad = true end

  if isSlotUsed then
    -- Show fill bar if platform appropriate
    ultimateFillFrame:SetHidden(not isGamepad)
    ultimateFillLeftTexture:SetHidden(not isGamepad)
    ultimateFillRightTexture:SetHidden(not isGamepad)

    if ultimateCount >= self.currentUltimateMax then
      --hide progress bar
      barTexture:SetHidden(true)
      leadingEdge:SetHidden(true)

      -- Set fill bar to full
      self:PlayUltimateFillAnimation(ultimateFillLeftTexture, ultimateFillRightTexture, 1, setProgressNoAnim)
      self:PlayUltimateReadyAnimations(ultimateReadyBurstTexture, ultimateReadyLoopTexture, setProgressNoAnim)
    else
      --stop animation
      ultimateReadyBurstTexture:SetHidden(true)
      ultimateReadyLoopTexture:SetHidden(true)
      self:StopUltimateReadyAnimations()

      -- show platform appropriate progress bar
      barTexture:SetHidden(isGamepad)
      leadingEdge:SetHidden(isGamepad)

      -- update both platforms progress bars
      local slotHeight = FAB.constants.style.ultSize --self.slot:GetHeight()    the only change needed...
      local percentComplete = ultimateCount / self.currentUltimateMax
      local yOffset = zo_floor(slotHeight * (0.97 - percentComplete)) -- changed from 1 cause normally the bar shows below the button when at 0 and my OCD can't handle.
      barTexture:SetHeight(yOffset)

      leadingEdge:ClearAnchors()
      leadingEdge:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, yOffset - 5)
      leadingEdge:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, yOffset - 5)

      self:PlayUltimateFillAnimation(ultimateFillLeftTexture, ultimateFillRightTexture, percentComplete, setProgressNoAnim)
      self:AnchorKeysOut()
    end

    self:UpdateUltimateNumber()
  else
    --stop animation
    ultimateReadyBurstTexture:SetHidden(true)
    ultimateReadyLoopTexture:SetHidden(true)
    self:StopUltimateReadyAnimations()
    self:ResetUltimateFillAnimations()

    --hide progress bar for all platforms
    barTexture:SetHidden(true)
    leadingEdge:SetHidden(true)
    ultimateFillLeftTexture:SetHidden(true)
    ultimateFillRightTexture:SetHidden(true)
    ultimateFillFrame:SetHidden(true)
    self:AnchorKeysOut()
  end
  -- self:HideKeys(not isGamepad)
end

ActionButton['SetUltimateMeter'] = FancySetUltimateMeter

function FAB.UpdateStyle()
  local style = {}
  local mode

  if FAB.initialSetup then
    mode = IsInGamepadPreferredMode() and 2 or 1
  else
    if ADCUI then
      if ADCUI:originalIsInGamepadPreferredMode() then
        if ADCUI:shouldUseGamepadUI()
        then mode = 2
        else mode = ADCUI:shouldUseGamepadActionBar() and 2 or 1 end
      else mode = 1 end
    else mode = IsInGamepadPreferredMode() and 2 or 1 end
  end

  if mode == 1 then
    style     = KEYBOARD_CONSTANTS
    swapSize  = 47
  else
    style     = GAMEPAD_CONSTANTS
    swapSize  = 67
  end
  -- style = mode == 1 and KEYBOARD_CONSTANTS or GAMEPAD_CONSTANTS
  FAB.style = mode

  local offsetY = FAB.style == 2 and -75 or -22
  FAB_Default_Bar_Position:ClearAnchors()
  FAB_Default_Bar_Position:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 0, offsetY)

  FAB.constants = FAB:UpdateContants(mode, SV, style)
  ActionButton.ApplySwapAnimationStyle = ApplySwapAnimationStyle
  ZO_ActionBar_GetButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1):ApplySwapAnimationStyle()
end
-------------------------------------------------------------------------------
-----------------------------[  Helper & Debugging  ]--------------------------
-------------------------------------------------------------------------------
local function IdentifyIndex(number, bar)
  local index
  if bar == HOTBAR_CATEGORY_BACKUP then
    if number == 8
    then index = ULT_INDEX + SLOT_INDEX_OFFSET
    else index = number + SLOT_INDEX_OFFSET end
  else index = number end
  return index
end

local function IdCheck(index, id)
  if FAB.customAbilityConfig[id] and FAB.customAbilityConfig[id] == false then return false end
  if slottedIds[index] ~= nil and slottedIds[index].ability ~= slottedIds[index].effect then
    if FAB.toggled[id] then return true end
    if not FAB.traps[id] then return false end
  end
  return true
end

local function PostEffectUpdate(name, id, change, duration, stacks, when)
  if id == 61744 then return end
  if duration == 0 then if not FAB.toggled[id] then return end end
  local type
  if     change == EFFECT_RESULT_GAINED  then type = 'Gained'
  elseif change == EFFECT_RESULT_UPDATED then type = 'Updated'
  end
  local stack = '.'
  if (stacks ~= nil and stacks > 0) then stack = ' (x' .. stacks .. ').' end
  FAB:dbg('[<<2>> (<<3>>)] <<1>>: <<4>><<5>>', type, name, id, strformat('%0.1fs', duration), stack)
end

local function PostEffectFade(name, id, tag)
  if tag then if string.find(tag, 'companion') then return end end
  local uptime = strformat('%0.3fs', FAB.activeCasts[id].fade - FAB.activeCasts[id].begin)
  local delay  = '.'
  if FAB.activeCasts[id].cast > 0 then
    delay = strformat(' (%0.3fs).', FAB.activeCasts[id].fade - FAB.activeCasts[id].cast)
  end
  FAB:dbg('[<<1>> (<<2>>)] faded after <<3>><<4>>', name, id, uptime, delay)
  FAB.activeCasts[id] = nil
end

local function PostAllChanges(e, change, eSlot, eName, tag, gain, fade, stacks, icon, bType, eType, aType, seType, uName, unitId, aId, sType)
  if FAB.ignore[aId] then return end
  -- if GetAbilityBuffType(aId) and GetAbilityBuffType(aId) ~= BUFF_TYPE_NONE then return end
  -- if aType == 0 then return end -- passives (annoying when bar swapping)

  if FAB.IsGroupUnit(tag) then
    if AreUnitsEqual('player', tag) then return end -- filter doubles from 'player' and players 'group' tags.
  end

  local types = {
    [EFFECT_RESULT_GAINED]        = 'Gained',
    [EFFECT_RESULT_FADED]         = 'Faded',
    [EFFECT_RESULT_UPDATED]       = 'Updated',
    [EFFECT_RESULT_FULL_REFRESH]  = 'Refreshed',
    [EFFECT_RESULT_TRANSFER]      = 'Transfered'
  }
  local ts    = tostring
  local type  = types[change] or '?'
  local dur, s

  if (fade ~= nil and gain ~= nil)
  then dur = strformat(' %0.1f', fade - gain)..'s'
  else dur = 0 end

  if stacks and stacks > 0
  then s = ' x'..ts(stacks)..'.'
  else s = '.'end

  if not SV.debugVerbose then
    if change == EFFECT_RESULT_FADED
    then d('['..ts(aId)..'] '..eName..': '..type..' --> '..uName)
    else d('['..ts(aId)..'] '..eName..': '..type..' --> '..uName..dur..s) end
  else
    d(eName.." ("..ts(aId)..")".."\nchange: "..types[change].." || stacks: "..ts(stacks).." || duration: "..ts(dur).." || slot: "..ts(eSlot).." || tag: "..ts(tag).." || unit: "..ts(uName).." || unitId: "..ts(unitId).." || buffType: "..bType.." || effectType: "..ts(eType).." || abilityType: "..ts(aType).." || statusEffectType: "..ts(seType)..'\n===================')
  end
end

local function UnitCheck(unitTag, unitId)
  if unitId ~= nil then
    if (not AreUnitsEqual('player', unitTag)) then return true end
    if unitTag == '' then return true end
  end
  return false
end

local function ShouldTrackAsDebuff(id, tag)
  if not SV.advancedDebuff then return false end
  if id   == 38791  then return false end -- ZoS seem to think that Stampede is a debuff and not a ground effect :S
  if tag  ~= nil    then
    if AreUnitsEqual('player', tag) or FAB.IsGroupUnit(tag) then return false end
  end
  return true
end

local function ShouldHideIfNotOnTarget(Id) -- a setting I didn't finish making yet.
  local hide
  if FAB.constants.hideOnNoTargetList[id]
  then hide = FAB.constants.hideOnNoTargetList[id]
  else hide = FAB.constants.hideOnNoTargetGlobal end
  return hide
end

local fdNum     = 0
local fdStacks  = {}
local lastCW    = 0   -- track when last crystal weapon debuff was applied
local function HandleSpecial(id, change, updateTime, beginTime, endTime, unitTag, unitId)
  -- abilities that have multiple trigger ids.
  -- individual handling for each of them below.
  local effect        -- the ability we are updating
  local update = true -- update the stacks display for the ability. not sure why I called it this.

  if (change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED) then

    if (id == 40465) then -- scalding rune placed
      effect = FAB.effects[id]
      update = false

    elseif (id == 46331) then -- crystal weapon
      effect = FAB.effects[id]
      FAB.stacks[effect.id] = 2
      update = true

    elseif (id == FAB.tauntId) then
      update = false

      if FAB.activeTaunts[unitId] == nil then
        FAB.activeTaunts[unitId] = { overlay = 0, endTime = 0 }
      end

      FAB.activeTaunts[unitId].endTime  = endTime

      if FAB.lastTaunt ~= nil and FAB.overlays[FAB.lastTaunt] ~= nil then
        FAB.activeTaunts[unitId].overlay      = FAB.lastTaunt
        FAB.tauntSlots[FAB.lastTaunt].endTime = endTime
        FAB.tauntSlots[FAB.lastTaunt].unit    = unitId
        UpdateOverlay(FAB.lastTaunt)
      end
      -- d("Overlay " .. FAB.activeTaunts[unitId].overlay .. " on " .. unitId .. " for " .. strformat('%0.1fs', endTime - beginTime))

    elseif (FAB.traps[id] and endTime - beginTime > 2) then
      effect = FAB.effects[FAB.traps[id]]
      -- FAB.trapTimers[effect.id] = endTime
      -- UpdateEffect(effect)
      -- return

    elseif FAB.meteor[id] then
      effect = FAB.effects[FAB.meteor[id]]

    elseif FAB.frozen[id] then -- (id == 86179) then -- frozen device
      effect = FAB.effects[id]
      if not FAB.stacks[id] then FAB.stacks[id] = 0 end
      fdNum           = fdNum + 1
      fdStacks[fdNum] = beginTime
      FAB.stacks[id]  = fdNum

    elseif (id == 37475) then -- manifestation of terror cast
      effect                = FAB.effects[id]
      FAB.stacks[effect.id] = 2
      endTime               = endTime - 0

    elseif (id == 76634) then -- manifestation of terror trigger
      effect            = FAB.effects[37475]
      FAB.stacks[37475] = FAB.stacks[37475] - 1
      if FAB.stacks[37475] <= 0 then endTime = updateTime end

    elseif id == FAB.sCorch.id1 then
      effect = FAB.effects[id]
      if not FAB.stacks[id] then FAB.stacks[id] = 0 end
      FAB.stacks[id]  = 2
      endTime         = updateTime + 9

    elseif id == FAB.deepFissure.id1 then
      effect = FAB.effects[id]
      if not FAB.stacks[id] then FAB.stacks[id] = 0 end
      FAB.stacks[id]  = 2
      endTime         = updateTime + 9

    elseif id == FAB.subAssault.id1 then
      effect = FAB.effects[id]
      if not FAB.stacks[id] then FAB.stacks[id] = 0 end
      FAB.stacks[id]  = 2
      endTime         = updateTime + 6

    else
      if FAB.effects[id] then
        effect = FAB.effects[id]
      end
    end

    if effect then
      -- effect.faded    = false
      effect.endTime  = endTime
      if FAB.activeCasts[effect.id] then FAB.activeCasts[effect.id].begin = updateTime end
    end

  elseif (change == EFFECT_RESULT_FADED) then

    if FAB.meteor[id] then
      effect = FAB.effects[FAB.meteor[id]]
      effect.endTime = endTime

    elseif (id == 46331) then -- crystal weapon
      -- if unitTag == 'reticleover' then return end
      effect = FAB.effects[id]
      FAB.stacks[effect.id] = 0
      effect.endTime = endTime
      update = true

    elseif (id == FAB.tauntId) then
      update = false

      if FAB.activeTaunts[unitId] ~= nil then
        if (FAB.tauntSlots[FAB.activeTaunts[unitId].overlay] ~= nil and FAB.tauntSlots[FAB.activeTaunts[unitId].overlay].unit == unitId) then
          FAB.tauntSlots[FAB.activeTaunts[unitId].overlay].endTime = endTime
          UpdateOverlay(FAB.activeTaunts[unitId].overlay)
          -- d("Overlay " .. FAB.activeTaunts[unitId].overlay .. " on " .. unitId .. " faded")
        end
        FAB.activeTaunts[unitId] = nil
      end

    elseif id == FAB.sCorch.id1 then
      effect = FAB.effects[id]
      if FAB.stacks[id] == 2 then FAB.stacks[id] = 1 end

    elseif id == FAB.sCorch.id2 then
      effect = FAB.effects[FAB.sCorch.id1]

      if effect.endTime <= updateTime
      then FAB.stacks[FAB.sCorch.id1] = 0
      else update = false end

    elseif id == FAB.deepFissure.id1 then
      effect = FAB.effects[id]
      if FAB.stacks[id] == 2 then FAB.stacks[id] = 1 end

    elseif id == FAB.deepFissure.id2 then
      effect = FAB.effects[FAB.deepFissure.id1]

      if effect.endTime <= updateTime
      then FAB.stacks[FAB.deepFissure.id1] = 0
      else update = false end

    elseif id == FAB.subAssault.id1 then
      effect = FAB.effects[id]
      if FAB.stacks[id] == 2 then FAB.stacks[id] = 1 end

    elseif id == FAB.subAssault.id2 then
      effect = FAB.effects[FAB.subAssault.id1]

      if effect.endTime <= updateTime
      then FAB.stacks[FAB.subAssault.id1] = 0
      else update = false end

    elseif FAB.frozen[id] then -- (id == 86179) then -- frozen device
      if FAB.effects[id].endTime == 0 then return end
      if not FAB.stacks[id] then return end
      local faded    = 0
      local fadeTime = 0
      for i = 1, #fdStacks do
        if fdStacks[i] == beginTime then
          faded    = i
          fdStacks = nil
        else
          if (fdStacks[i] > fadeTime) then fadeTime = fdStacks[i] end
        end
        if (faded > 0 and i > faded) then fdStacks[i - 1] = fdStacks[i] end
      end

      effect = FAB.effects[id]
      fdNum  = fdNum - 1
      if fdNum >= 1 then
        if fadeTime + 15.5 > updateTime then
          effect.endTime = fadeTime + 15.5
          FAB.stacks[id] = fdNum
        else
          FAB.stacks[id] = 0
          effect.endTime = endTime
        end
      else
        FAB.stacks[id] = 0
        effect.endTime = endTime
      end

    elseif id == 37475 then -- manifestation of terror
      effect = FAB.effects[id]
      if      effect.endTime -  updateTime > 1 and  FAB.stacks[id] > 0 then return
      elseif  effect.endTime <= updateTime + 1 then FAB.stacks[id] = 0 end
    end
  end

  if effect then
    UpdateEffect(effect)
    if update then
      FAB.HandleStackUpdate(effect.id)
    end
  end
end

function FAB.RefreshEffects()

  FAB.activeCasts = {}

  for effect, data in pairs(FAB.effects) do data.endTime = 0 end

  for id in pairs(FAB.stacks) do
    FAB.stacks[id] = 0
    FAB.HandleStackUpdate(id)

    if (id == 61905 or id == 61919 or id == 61927) then
      if GFC then
        GFC.OnEffectChanged(_, 2, _, GetAbilityName(id), 'player', _, _, 1, _, _, _, _, _, _, _, id)
        GFC.UpdateStacks(0)
      end
    end
  end

  local t = time()

  for i = 1, GetNumBuffs('player') do
    local name, startTime, endTime, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo('player', i)

    if not castByPlayer then

      if SV.externalBuffs then
        local effect = FAB.effects[abilityId]
        if effect then
          if startTime == endTime then
            UpdatePassiveEffect(effect.id, true)
          else
            if (not FAB.activeCasts[effect.id] --[[and effect.id ~= 61744]]) then
              local slot = nil
              if effect.slot1 then slot = effect.slot1 elseif effect.slot2 then slot = effect.slot2 end
              FAB.activeCasts[effect.id] = {slot = slot, cast = 0, begin = 0, fade = 0 }
            end
            if endTime - t > 0 then
              FAB.activeCasts[effect.id].begin  = startTime
              effect.endTime                    = endTime
              UpdateEffect(effect)
            end
          end
        end
      end

    else

      if stackCount > 0 and FAB.stackMap[abilityId] then
        FAB.stacks[FAB.stackMap[abilityId]] = stackCount or 0
        FAB.HandleStackUpdate(FAB.stackMap[abilityId])

        if (id == 61905 or id == 61919 or id == 61927) then
          if GFC then -- Manually update GrimFocusCounter if enabled
            GFC.OnEffectChanged(_, 3, _, GetAbilityName(id), 'player', _, _, 0, _, _, _, _, _, _, _, id)
          end
        end
      end

      local effect = FAB.effects[abilityId]
      if effect then

        if FAB.toggles[abilityId] then
          UpdateToggledAbility(abilityId, true)
          return
        end

        if endTime - t > 0 then
          if not FAB.activeCasts[effect.id] then
            local slot = nil
            if effect.slot1 then slot = effect.slot1 elseif effect.slot2 then slot = effect.slot2 end
            FAB.activeCasts[effect.id] = {slot = slot, cast = 0, begin = 0, fade = 0 }
          end

          if FAB.activeCasts[effect.id] then
            FAB.activeCasts[effect.id].begin  = startTime
            effect.endTime                    = endTime
            UpdateEffect(effect)
          end
        end
      end
    end
  end
end

-- local groundString    = GetString(SI_ABILITY_TOOLTIP_TARGET_TYPE_GROUND)
-- local groundAbilities = {}
-- local LAST_ABILITY    = 0
-- local LAST_BUTTON     = 0
--
-- local function CheckGroundAbility(id)
-- 	local result = groundAbilities[id]
-- 	if result == nil then
-- 		result = GetAbilityTargetDescription(id) == groundString
-- 		groundAbilities[id] = result
-- 	end
-- 	return result
-- end

-------------------------------------------------------------------------------
-----------------------------[      Initialize      ]--------------------------
-------------------------------------------------------------------------------
local noget = false
local function Initialize()
  defaultSettings = FAB.defaultSettings
  SV = ZO_SavedVars:NewAccountWide('FancyActionBarSV', 1, nil, defaultSettings)
  CV = ZO_SavedVars:NewCharacterIdSettings('FancyActionBarSV', 1, nil, FAB.defaultCharacter)

  for i = MIN_INDEX, ULT_INDEX do
    FAB.SetSlottedEffect(i, 0, 0)
    FAB.SetSlottedEffect(i + SLOT_INDEX_OFFSET, 0, 0)
  end

  FAB.ValidateVariables()
  FAB.UpdateStyle()

  FAB.initialized = true

  FAB.UpdateTextures()

  if GetDisplayName() == '@nogetrandom' then
    FAB.SetPersonalSettings()
    noget = true
    if SV.debuffTable == nil then SV.debuffTable = {} end
  end

  SLASH_COMMANDS[slashCommand] = FAB.SlashCommand

  FAB.SetScale()
  FAB.RefreshUpdateConfiguration()
  FAB.UpdateDurationLimits()
  FAB:InitializeDebuffs(NAME, SV)
  FAB.BuildMenu(SV, CV, defaultSettings)
  FAB.BuildAbilityConfig()
  FAB.SetupGCD()
  FAB.ApplyDeathStateOption()
  debug = SV.debug

  FAB.player.name = zo_strformat("<<!aC:1>>", GetUnitName("player"))

  --ANTIQUITY_DIGGING_SCENE = 'antiquityDigging'
  --LOCK_PICK_SCENE = 'lockpickKeyboard'

  local function LockSkillsOnTrade()
    if TRADE_WINDOW.state == 3 then return false end
    if SM.currentScene:GetName() == 'antiquityDigging' then return false end
    return true
  end

  local useSlotsOverride = true
  if PerfectWeave and SV.perfectWeave then useSlotsOverride = false end

  if useSlotsOverride then
    -- Can use abilities while map is open, when cursor is active, etc.
    ZO_ActionBar_CanUseActionSlots = function()
      if SV.lockInTrade
      then return LockSkillsOnTrade()
        -- https://github.com/esoui/esoui/blob/pts7.0/esoui/ingame/actionbar/actionbar.lua
      else return (not (IsGameCameraActive() or IsInteractionCameraActive() or IsProgrammableCameraActive()) or SM:IsShowing("hud")) and not IsUnitDead("player") end
    end
  end

  -- Slot ability changed, e.g. summoned a pet, procced crystal, etc.
  local function OnSlotChanged(_, n)
    local btn = ZO_ActionBar_GetButton(n)
    if btn then
      btn:HandleSlotChanged()
      if (n == ULT_INDEX or n == ULT_INDEX + SLOT_INDEX_OFFSET) then
        FAB.UpdateUltimateCost()
      end
      FAB.UpdateSlottedSkillsDecriptions()
    end
    -- d('Slot ' .. tostring(n) .. ' changed')
  end

  -- Button (usable) state changed.
  local function OnSlotStateChanged(_, n)
    local btn = ZO_ActionBar_GetButton(n)
    if btn then btn:UpdateState() end
  end

  -- Any skill swapped. Setup buttons and slot effects.
	local function OnAllHotbarsUpdated()
		for i = MIN_INDEX, MAX_INDEX do	-- ULT_INDEX do
			local button = ZO_ActionBar_GetButton(i)
			if button then
				button.hotbarSwapAnimation = nil      -- delete default animation
				button.noUpdates = true               -- disable animation updates
				button.showTimer = false
				button.stackCountText:SetHidden(true)
				button.timerText:SetHidden(true)
				button.timerOverlay:SetHidden(true)
				button:HandleSlotChanged()            -- update slot manually
        button.buttonText:SetHidden(not SV.showHotkeys)
			end
			if (currentHotbarCategory == HOTBAR_CATEGORY_PRIMARY or currentHotbarCategory == HOTBAR_CATEGORY_BACKUP) then
				local button = ZO_ActionBar_GetButton(i, currentHotbarCategory == HOTBAR_CATEGORY_PRIMARY and HOTBAR_CATEGORY_BACKUP or HOTBAR_CATEGORY_PRIMARY)
				if button then
					button.noUpdates = true
					button.showTimer = false
					button.showBackRowSlot = false
				end
			end
		end
		SlotEffects()
    FAB.ToggleUltimateValue()
    FAB.UpdateSlottedSkillsDecriptions()
	end

  local function OnActiveWeaponPairChanged()
    currentHotbarCategory = GetActiveHotbarCategory()
    SwapControls()
  end

  -- IsAbilityUltimate(*integer* _abilityId_)
  local function OnAbilityUsed(_, n)
    if (n >= MIN_INDEX and n <= ULT_INDEX) then -- or n == (ULT_INDEX + SLOT_INDEX_OFFSET) then
      -- local duration = t + (GetActionSlotEffectTimeRemaining(n, currentHotbarCategory) / 1000)
      local id     = GetSlotBoundId(n, currentHotbarCategory)
      local index  = IdentifyIndex(n, currentHotbarCategory)
      local name   = GetAbilityName(id)
      local t      = time()
      local effect = SlotEffect(index, id)
      -- local effect = FAB.effects[id]
      local i      = FAB.GetSlottedEffect(index)

      -- lastButton = index

      if effect and effect.id == FAB.tauntId then  -- to track which taunt skill was used and which button it is assigned to
        FAB.lastTaunt = index
        -- d("Taunt cast from button " .. index)
      end

      if (i and FAB.activeCasts[i] == nil and not FAB.ignore[id]) then -- track when the skill was used and ignore other events for it that is lower than the GCD
        if (FAB.customAbilityConfig[id] and FAB.customAbilityConfig[id] ~= false) then
          FAB.activeCasts[i] = {slot = index, cast = t, begin = 0, fade = 0 }
        end
      end

      if IdCheck(index, id) == false then
        local E = FAB.effects[i]
        if E then
          if fakes[i] then activeFakes[i] = true end
          if FAB.activeCasts[E.id] then FAB.activeCasts[E.id].cast = t end
          local D = E.toggled == true and '0' or tostring((GetAbilityDuration(i) or 0) / 1000)
          dbg('4 [ActionButton%d]<%s> #%d: ' .. D, index, name, E.id)
          -- return
        end
      end

      if effect and FAB.toggled[effect.id] then
        local o = not FAB.toggles[effect.id]
        local O = o == true and 'On' or 'Off'
        dbg('3 [ActionButton%d]<%s> #%d: ' .. O .. '.', index, name, effect.id)
      end

      if effect then

        if effect.id ~= id then
          local e = FAB.effects[i]
          if e then
            if fakes[i] then activeFakes[i] = true end
            dbg('2 [ActionButton%d]<%s> #%d: %0.1fs', index, name, i, e.toggled == true and 0 or (GetAbilityDuration(e.id) or 0) / 1000)
          end
        else
          if not effect.custom and effect.duration then
            effect.endTime = effect.duration + t
            duration = effect.duration
            dbg('1 [ActionButton%d]<%s> #%d: %0.1fs', index, name, effect.id, (GetAbilityDuration(effect.id) or 0) / 1000)
            UpdateEffect(effect)
          else
            if fakes[id] then activeFakes[id] = true end
            dbg('0 [ActionButton%d]<%s> #%d: %0.1fs', index, name, effect.id, (GetAbilityDuration(effect.id) or 0) / 1000)
          end
        end
      elseif FAB.effects[i] then
        dbg('? [ActionButton%d]<%s> #%d: %0.1fs', index, name, FAB.effects[i].id, (GetAbilityDuration(FAB.effects[i].id) or 0) / 1000)
      else
        dbg('[ActionButton%d] #%d: %0.1fs', index, id, GetAbilityDuration(id))
      end
    end
    -- d('button ' .. n .. ' used.')
  end

  local ABILITY_TYPE_DAMAGE = ABILITY_TYPE_DAMAGE
  local function OnEffectChanged(eventCode, change, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)

    if SV.debugAll then
      PostAllChanges(eventCode, change, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
    end

    local t = time()

    if FAB.specialIds[abilityId] then -- abilities that need to be handled differently.
      HandleSpecial(abilityId, change, t, beginTime, endTime, unitTag, unitId)
      return
    end

    if (FAB.traps[abilityId]) then
      if change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED then
        FAB.trapTimers[abilityId] = 0
      end
      abilityId = FAB.traps[abilityId]
    end

    if (abilityId == 143808 and change == EFFECT_RESULT_GAINED) then -- crystal weapon. remove a stack when the debuff is applied.
      local pCW = t - lastCW
      if (FAB.effects[46331] and pCW > 0.5) then -- filter out double events
        lastCW = t
        if (FAB.stacks[46331] and FAB.stacks[46331] > 0) then
          FAB.stacks[46331] = FAB.stacks[46331] - 1
          FAB.HandleStackUpdate(46331)
        end
        return
      end
    end

    local effect = FAB.effects[abilityId]

    if effect then

      if effect.toggled then -- update the highlight of toggled abilities.
        if change == EFFECT_RESULT_FADED
        then UpdateToggledAbility(abilityId, false)
        else UpdateToggledAbility(abilityId, true) end
        return
      end

      if (effectType == DEBUFF) then -- if the ability is a debuff, check settings and handle accordingly.
        local tag = unitTag or ''

        if ShouldTrackAsDebuff(abilityId, tag) then
          effect.isDebuff = true

          if not FAB.debuffs[abilityId] then
            FAB.debuffs[abilityId]  = effect
          end

          FAB.OnDebuffChanged(effect, t, eventCode, change, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)

          if noget == true then
            if SV.debuffTable[abilityId] == nil then SV.debuffTable[abilityId] = true end
          end

          return
        end
      end

      if change == EFFECT_RESULT_GAINED or change == EFFECT_RESULT_UPDATED then

        if FAB.activeCasts[effect.id] then FAB.activeCasts[effect.id].begin = beginTime end

        if endTime ~= beginTime then -- lazy fix
          if effect.passive then UpdatePassiveEffect(effect.id, false) end
        end

        -- Ignore abilities which will end in less than min or longer than max (seconds).
        if (endTime > t + FAB.durationMin and endTime < t + FAB.durationMax) then
          if abilityId == 24330 then -- haunting curse (if advancedDebuff is disabled)
            effect.endTime = t + 12
          else

            if abilityType == GROUND_EFFECT then -- make sure to only track duration of the most recent cast of the ground ability.
              lastAreaTargets[abilityId] = unitId
              if abilityId == 117805 then -- unnerving boneyard sometimes updates to 25s duration, not sure why..
                effect.endTime = t + 10
                UpdateEffect(effect)
                return
              end
            end

            effect.endTime = endTime
          end

          if stackCount and stackCount > 0 then -- update stacks
            FAB.stacks[effect.id] = stackCount
            FAB.HandleStackUpdate(FAB.stackMap[effect.id])
          end
        else
          effect.endTime = 0 -- duration too long or too short. don't track.
        end
        UpdateEffect(effect)

      elseif (change == EFFECT_RESULT_FADED) then

        if FAB.IsGroupUnit(unitTag) then return end -- don't track anything on group members.

        if FAB.removeInstantly[abilityId] then -- abilities we want to reset the overlay instantly for when expired.
          effect.endTime = endTime
          UpdateEffect(effect)
          return
        end

        stackCount = 0

        if abilityId == 122658 and FAB.effects[122658] then
          FAB.effects[122658].endTime         = t
          FAB.stacks[FAB.stackMap[abilityId]] = stackCount
          FAB.HandleStackUpdate(FAB.stackMap[abilityId])
        end

        if (effectType == DEBUFF or abilityId == 38791) then return end -- (FAB.dontFade[abilityId]) then return end

        if FAB.activeCasts[effect.id] then

          if abilityType == GROUND_EFFECT then -- prevent effect from fading if event is from previous cast of the ability when reapplied before it had expired
            if lastAreaTargets[abilityId] then
              if lastAreaTargets[abilityId] ~= unitId then return end
              lastAreaTargets[abilityId] = nil
            end
          end

          -- crystal frags
          if (abilityId == 46327 and FAB.effects[46327]) or (FAB.activeCasts[effect.id].begin < (t - 0.7)) then
            FAB.activeCasts[effect.id].fade = t

            -- d('Fading ' .. effectName .. ': ' .. string.format(t - FAB.activeCasts[effect.id].begin) .. ' / ' .. tostring(effectType))

            effect.endTime = t
            if effect.passive then UpdateToggledAbility(abilityId, false) end
          end
        end
      end

      if FAB.stackMap[abilityId] then

        if (SV.advancedDebuff and effectType == DEBUFF) then return end -- is handled by debuff.lua

        FAB.stacks[FAB.stackMap[abilityId]] = stackCount
        FAB.HandleStackUpdate(FAB.stackMap[abilityId])
      end
    end
  end

  -- Update overlays.
  local function Update()
    UpdateUltOverlay(ULT_INDEX)
    UpdateUltOverlay(ULT_INDEX + SLOT_INDEX_OFFSET)
    UpdateUltOverlay(ULT_INDEX + COMPANION_INDEX_OFFSET)
    for i, overlay in pairs(FAB.overlays) do UpdateOverlay(i) end
  end

	-- Abilities stacks.
	function OnStackChanged(_, change, _, _, unitTag, _, _, stackCount, _, _, effectType, _, _, unitName, unitId, abilityId)

    if (SV.advancedDebuff and effectType == DEBUFF) then return end -- is handled by debuff.lua

    local c = ""
		if change == EFFECT_RESULT_FADED then
      c = "faded"
      stackCount = 0
    elseif change == EFFECT_RESULT_GAINED then
      c = "gained"
    elseif change == EFFECT_RESULT_UPDATED then
      c = "updated"
    end

		FAB.stacks[FAB.stackMap[abilityId]] = change == EFFECT_RESULT_FADED and 0 or stackCount
		if stackCount == 0 then
      -- Remove Seething Fury effect manually, otherwise it will keep counting down.
			if abilityId == 122658 and FAB.effects[122658] then FAB.effects[122658].endTime = time() end
		end
    -- d("[" .. abilityId .. "] " .. c .. " -> tag(" .. unitTag .. ") name(" .. unitName .. ") id(" .. unitId .. ") stacks(" .. stackCount .. ")")
    FAB.HandleStackUpdate(FAB.stackMap[abilityId])
	end

	for abilityId in pairs(FAB.stackMap) do
		EM:RegisterForEvent(NAME .. abilityId, EVENT_EFFECT_CHANGED, OnStackChanged)
		EM:AddFilterForEvent(NAME .. abilityId, EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, abilityId)
		EM:AddFilterForEvent(NAME .. abilityId, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
	end

  local function OnEquippedWeaponsChanged(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
    if bagId ~= BAG_WORN then return end
    if slotId == EQUIP_SLOT_MAIN_HAND or slotId == EQUIP_SLOT_BACKUP_MAIN then
      FAB.weaponFront = GetItemLinkWeaponType(GetItemLink(BAG_WORN, EQUIP_SLOT_MAIN_HAND, LINK_STYLE_DEFAULT))
      FAB.weaponBack  = GetItemLinkWeaponType(GetItemLink(BAG_WORN, EQUIP_SLOT_BACKUP_MAIN, LINK_STYLE_DEFAULT))
    end
  end

	local function OnDeath(eventCode, unitTag, isDead)
    if not isDead or not AreUnitsEqual('player', unitTag) then return end

    FAB.RefreshEffects()
    FAB:UpdateDebuffTracking()
  end

  local function OnCombatEvent( _, result, _, aName, _, _, _, _, tName, tType, hit, _, _, _, _, tId, aId)

    local effect

    if (FAB.needCombatEvent[aId] and result == FAB.needCombatEvent[aId].result) then
      effect = FAB.effects[aId]
      if effect then
        effect.endTime = time() + FAB.needCombatEvent[aId].duration
        -- effect.faded = false

        -- local ts = tostring
        -- d('===================')
        -- d(aName..' ('..ts(aId)..') || result: '..ts(result)..' || hit: '..ts(hit))
        -- d('===================')

        UpdateEffect(effect)
        return
      end
    end

    if (result == ACTION_RESULT_EFFECT_GAINED and activeFakes[aId]) then
      activeFakes[aId] = false
      effect = FAB.effects[aId]
      if effect then

        effect.endTime = time() + fakes[aId].duration

        -- FAB.trapTimers[effect.id] = time() + fakes[aId].duration

        UpdateEffect(effect)

        -- effect.faded = false

        -- local ts = tostring
        -- d('===================')
        -- d(aName..' ('..ts(aId)..') || result: '..ts(result)..' || hit: '..ts(hit))
        -- d('===================')

        UpdateEffect(effect)
      end
    end

    if aId == FAB.graveLordSacrifice.eventId then
      effect = FAB.effects[FAB.graveLordSacrifice.id]
      if effect then
        effect.endTime = time() + FAB.graveLordSacrifice.duration
        UpdateEffect(effect)
      end
    end

    if aId == FAB.expansiveFrostCloak.eventId then
      effect = FAB.effects[FAB.expansiveFrostCloak.id]
      if effect then
        effect.endTime = time() + (GetAbilityDuration(FAB.expansiveFrostCloak.id) / 1000)
        UpdateEffect(effect)
      end
    end
  end

  local function OnReflect( _, result, _, aName, _, _, _, _, tName, tType, hit, _, _, _, _, tId, aId)
    if (tType ~= COMBAT_UNIT_TYPE_PLAYER) then return end

    if SV.debugAll then
      local ts = tostring
      d('===================')
      d(aName .. ' (' .. ts(aId) .. ') || result: ' .. ts(result) .. ' || hit: ' .. ts(hit))
      d('===================')
    end

    if (FAB.reflects[aId]) then
      if (result == ACTION_RESULT_EFFECT_GAINED_DURATION) then
        if FAB.iceShield[aId] then
          FAB.stacks[FAB.reflects[aId]] = 3
        else
          FAB.stacks[FAB.reflects[aId]] = 1
        end
      elseif (result == ACTION_RESULT_DAMAGE_SHIELDED and FAB.iceShield[aId]) then
        FAB.stacks[FAB.reflects[aId]] = FAB.stacks[FAB.reflects[aId]] - 1
      elseif (result == ACTION_RESULT_EFFECT_FADED) then
        FAB.stacks[FAB.reflects[aId]] = 0
      end
      FAB.HandleStackUpdate(FAB.reflects[aId])

    elseif (FAB.effects[aId] and result == ACTION_RESULT_EFFECT_FADED) then
      FAB.stacks[aId] = 0
      FAB.HandleStackUpdate(aId)
    end
  end

  EM:UnregisterForEvent('ZO_ActionBar', EVENT_ACTIVE_COMPANION_STATE_CHANGED)

  EM:RegisterForEvent(NAME, EVENT_ACTIVE_COMPANION_STATE_CHANGED, HandleCompanionStateChanged)
  EM:RegisterForEvent(NAME, EVENT_ACTION_SLOT_UPDATED, OnSlotChanged)
  EM:RegisterForEvent(NAME, EVENT_ACTION_SLOT_STATE_UPDATED, OnSlotStateChanged)
  EM:RegisterForEvent(NAME, EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, OnAllHotbarsUpdated)
  EM:RegisterForEvent(NAME, EVENT_ACTION_SLOT_ABILITY_USED, OnAbilityUsed)
  EM:RegisterForEvent(NAME..'Death', EVENT_UNIT_DEATH_STATE_CHANGED, OnDeath)
  EM:AddFilterForEvent(NAME..'Death', EVENT_UNIT_DEATH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, 'player')
  EM:RegisterForEvent(NAME, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
    uiModeChanged = true
    FAB.UpdateBarSettings()
  end)

  EM:RegisterForEvent(NAME, EVENT_PLAYER_ACTIVATED, function()
    currentHotbarCategory = GetActiveHotbarCategory()
    EM:RegisterForEvent(NAME, EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
    ApplyStyle()
    OnAllHotbarsUpdated()
    SwapControls()
    EM:UnregisterForUpdate(NAME .. 'Update')
    EM:RegisterForUpdate(NAME .. 'Update', updateRate, Update)
    EM:UnregisterForEvent(NAME, EVENT_PLAYER_ACTIVATED)
  end)

  local function ActionBarActivated( eventCode, initial )
    if not initial then
      -- OnAllHotbarsUpdated()
      FAB.StackCheck()
    end
    FAB.OnPlayerActivated()
  end

  EM:RegisterForEvent(NAME .. '_Activated', EVENT_PLAYER_ACTIVATED, ActionBarActivated)
  EM:RegisterForEvent(NAME, EVENT_EFFECT_CHANGED, OnEffectChanged)
  EM:AddFilterForEvent(NAME, EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)

  FAB.SetExternalBuffTracking()

  EM:RegisterForEvent(NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnEquippedWeaponsChanged)
  EM:AddFilterForEvent(NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)

  ZO_PreHookHandler(ZO_ActionBar1, 'OnHide', function()
    -- if ZO_ActionBar1:IsHidden() and not wasStopped then
    if not FAB.wasStopped then
      EM:UnregisterForUpdate(NAME .. 'Update')
      FAB.wasStopped = true
    end
  end)

  ZO_PreHookHandler(ZO_ActionBar1, 'OnShow', function()
    if FAB.IsUnlocked() then return end

    FAB.ApplyPosition()

    if FAB.wasStopped then
      Update()
      EM:RegisterForUpdate(NAME .. 'Update', updateRate, Update)
    end
  end)

  ZO_PreHookHandler(CompanionUltimateButton, 'OnShow', function()
    if (not ZO_ActionBar_GetButton(ULT_SLOT, COMPANION).hasAction or not DoesUnitExist('companion') or not HasActiveCompanion()) then
      CompanionUltimateButton:SetHidden(true)
    end
  end)

  class = GetUnitClassId('player')
  if FAB.fakeClassEffects[class] then
    for i, x in pairs(FAB.fakeClassEffects[class]) do fakes[i] = x end
  end

  for i, x in pairs(FAB.fakeSharedEffects) do fakes[i] = x end

  for id in pairs(fakes) do
    EM:RegisterForEvent( NAME .. id, EVENT_COMBAT_EVENT, OnCombatEvent)
    EM:AddFilterForEvent(NAME .. id, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, id, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
  end

  for i in pairs(FAB.needCombatEvent) do
    EM:RegisterForEvent( NAME .. i, EVENT_COMBAT_EVENT, OnCombatEvent)
    EM:AddFilterForEvent(NAME .. i, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, i, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
  end

  if FAB.expansiveFrostCloak then
    EM:RegisterForEvent( NAME .. "ExpansiveFrostCloak", EVENT_COMBAT_EVENT, OnCombatEvent)
    EM:AddFilterForEvent(NAME .. "ExpansiveFrostCloak", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, FAB.expansiveFrostCloak.eventId, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
  end

  if FAB.graveLordSacrifice then
    EM:RegisterForEvent( NAME .. "GraveLordSacrifice", EVENT_COMBAT_EVENT, OnCombatEvent)
    EM:AddFilterForEvent(NAME .. "GraveLordSacrifice", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, FAB.graveLordSacrifice.eventId, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER_PET)
  end

  for i, x in pairs(FAB.reflects) do
    EM:RegisterForEvent( NAME .. 'Reflect' .. i, EVENT_COMBAT_EVENT, OnReflect)
    EM:AddFilterForEvent(NAME .. 'Reflect' .. i, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, i)

    EM:RegisterForEvent( NAME .. 'Reflect' .. x, EVENT_COMBAT_EVENT, OnReflect)
    EM:AddFilterForEvent(NAME .. 'Reflect' .. x, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, x, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_EFFECT_FADED)
  end

  -- ZO_PreHook('ZO_ActionBar_OnActionButtonDown', function(slotNum)
  --   d('ActionButton' .. slotNum .. ' pressed.')
  --   return false
  -- end)
end

local function OnAddOnLoaded(event, addonName)
	if addonName == NAME then
		EM:UnregisterForEvent(NAME, EVENT_ADD_ON_LOADED)
		Initialize()
	end
end

function FAB.ValidateVariables() -- all about safety checks these days..
  local d = defaultSettings

  if SV.externalBlackListRun == false then
    SV.externalBlackList = { -- just add all resto staff skills by default and player can take it from there.
    [61504] = "Vigor",
    [28385] = "Grand Healing",
    [40130] = "Ward Ally",
    [29224] = "Igneous Shield",
    [76518] = "Major Brutality",
    [61665] = "Major Brutality",
    [61704] = "Minor Endurance",
    [61694] = "Major Resolve",
    [83850] = "Life Giver",
    [31531] = "Force Siphon",
    [85132] = "Lights Champion",
    [40109] = "Siphon Spirit",
    [61693] = "Minor Resolve",
    [61706] = "Minor Intellect",
    [37232] = "Steadfast Ward",
    [61697] = "Minor Fortitude",
    [61506] = "Echoing Vigor",
    [92503] = "Major Sorcery",
    [40116] = "Quick Siphon",
    [28536] = "Regeneration",
    [88758] = "Major Resolve",
    [61687] = "Major Sorcery",
    [38552] = "Panacea",
    [61721] = "Minor Protection",
    [40058] = "Illustrious Healing",
    [40076] = "Rapid Regeneration",
    [40060] = "Healing Springs",
    [186493] = "Minor Protection",
    [40126] = "Healing Ward",
    [176991] = "Minor Resolve",
    }

    SV.externalBlackListRun = true
  end

  -- if SV.debuffConfigUpgraded == false then
  --   local debuffs = {}
  --   for skill, id in pairs(FAB.abilityConfig) do
  --     c[skill] = id
  --   end
  -- end

  if SV.variablesValidated == false then

    if SV.abScaling == nil then SV.abScaling = d.abScaling end
    if SV.scaleEnable ~= nil then
      SV.abScaling.kb.enable = SV.scaleEnable
      SV.abScaling.gp.enable = SV.scaleEnable
      SV.scaleEnable = nil
    end

    if SV.abScale ~= nil then
      SV.abScaling.kb.scale = SV.abScale
      SV.abScaling.gp.scale = SV.abScale
      SV.abScale = nil
    end

    if (SV.showDecimal == nil or type(SV.showDecimal) ~= 'string') then SV.showDecimal = d.showDecimal end

    if SV.alphaInactive	       == nil then SV.alphaInactive        = d.alphaInactive        end
    if SV.desaturationInactive == nil then SV.desaturationInactive = d.desaturationInactive end
    if SV.showDecimalStart	   == nil then SV.showDecimalStart     = d.showDecimalStart     end
    if SV.showExpire	         == nil then SV.showExpire           = d.showExpire           end
    if SV.showExpireStart	     == nil then SV.showExpireStart      = d.showExpireStart      end
    if SV.expireColor	         == nil then SV.expireColor          = d.expireColor          end

    if IsInGamepadPreferredMode() then
      if SV.fontName then SV.fontNameGP = SV.fontName SV.fontName = nil end
      if SV.fontSize then SV.fontSizeGP = SV.fontSize SV.fontSize = nil end
      if SV.fontType then SV.fontTypeGP = SV.fontType SV.fontType = nil end
      if SV.timerY   then SV.timerYGP   = SV.timerY   SV.timerY   = nil end
      if SV.timerYGP then
        local y
        if     SV.timerYGP == 0 then y = 0
        elseif SV.timerYGP  < 0 then y = SV.timerYGP + (SV.timerYGP * -2)
        elseif SV.timerYGP  > 0 then y = SV.timerYGP - (SV.timerYGP + SV.timerYGP) end
        SV.timeYGP  = y
        SV.timerYGP = nil
      end
      if SV.fontNameGP == nil then SV.fontNameGP = d.fontNameGP end
      if SV.fontSizeGP == nil then SV.fontSizeGP = d.fontSizeGP end
      if SV.fontTypeGP == nil then SV.fontTypeGP = d.fontTypeGP end
      if SV.timeYGP    == nil then SV.timeYGP    = d.timerYGP   end

      if SV.abMove.gp.x == nil or SV.abMove.gp.x == 0 then SV.abMove.gp.x = ZO_ActionBar1:GetLeft() end
      if SV.abMove.gp.y == nil or SV.abMove.gp.y == 0 then SV.abMove.gp.y = ZO_ActionBar1:GetTop() end
    else
      if SV.fontName then SV.fontNameKB = SV.fontName SV.fontName = nil end
      if SV.fontSize then SV.fontSizeKB = SV.fontSize SV.fontSize = nil end
      if SV.fontType then SV.fontTypeKB = SV.fontType SV.fontType = nil end
      if SV.timerY   then SV.timerYKB   = SV.timerY   SV.timerY   = nil end
      if SV.timerYKB then
        local y
        if     SV.timerYKB == 0 then y = 0
        elseif SV.timerYKB  < 0 then y = SV.timerYKB + (SV.timerYKB * -2)
        elseif SV.timerYKB  > 0 then y = SV.timerYKB - (SV.timerYKB + SV.timerYKB) end
        SV.timeYKB  = y
        SV.timerYKB = nil
      end
      if SV.fontNameKB == nil then SV.fontNameKB = d.fontNameKB end
      if SV.fontTypeKB == nil then SV.fontTypeKB = d.fontTypeKB end
      if SV.fontSizeKB == nil then SV.fontSizeKB = d.fontSizeKB end
      if SV.timeYKB    == nil then SV.timeYKB    = d.timeYKB    end

      if SV.abMove.kb.x == nil or SV.abMove.kb.x == 0 then SV.abMove.kb.x = ZO_ActionBar1:GetLeft() end
      if SV.abMove.kb.y == nil or SV.abMove.kb.y == 0 then SV.abMove.kb.y = ZO_ActionBar1:GetTop() end
    end

    if SV.fontNameStackKB == nil then SV.fontNameStackKB = d.fontNameStackKB end
    if SV.fontSizeStackKB	== nil then SV.fontSizeStackKB = d.fontSizeStackKB end
    if SV.fontTypeStackKB == nil then SV.fontTypeStackKB = d.fontTypeStackKB end
    if SV.stackXKB        == nil then SV.stackX          = d.stackXKB        end
    if SV.fontNameStackGP == nil then SV.fontNameStackGP = d.fontNameStackGP end
    if SV.fontSizeStackGP == nil then SV.fontSizeStackGP = d.fontSizeStackGP end
    if SV.fontTypeStackGP == nil then SV.fontTypeStackGP = d.fontTypeStackGP end
    if SV.stackGP         == nil then SV.stackXGP        = d.stackXGP        end
    if SV.showHotkeys	    == nil then SV.showHotkeys     = d.showHotkeys     end
    if SV.showHighlight	  == nil then SV.showHighlight   = d.showHighlight   end
    if SV.highlightColor  == nil then SV.highlightColor  = d.highlightColor  end
    if SV.showArrow	      == nil then SV.showArrow       = d.showArrow       end
    if SV.arrowColor      == nil then SV.arrowColor      = d.arrowColor      end
    if SV.moveQS          == nil then SV.moveQS          = d.moveQS          end
    if SV.showFrames      == nil then SV.showFrames      = d.showFrames      end
    if SV.frameColor      == nil then SV.frameColor      = d.frameColor      end
    if SV.showMarker      == nil then SV.showMarker      = d.showMarker      end
    if SV.markerSize      == nil then SV.markerSize      = d.markerSize      end
    if SV.abScaleEnable   == nil then	SV.abScaleEnable   = d.abScaleEnable   end
    if SV.abScale         == nil then SV.abScale         = d.abScale         end
    if SV.debug           == nil then	SV.debug           = d.debug           end
    if SV.showToggle      == nil then SV.showToggle      = d.showToggle      end
    if SV.toggleColor	    == nil then SV.toggleColor     = d.toggleColor     end

    SV.variablesValidated = true
  end
end

function FAB.SetPersonalSettings()  -- cause I like my UI fancy...
  local s	= ZO_SynergyTopLevel      -- add my button frame to the syngergy button pop-up and rearrange the layout.
  local c	= s:GetNamedChild('Container')
  local a	= c:GetNamedChild('Action')
  local k	= c:GetNamedChild('Key')
  local i	= c:GetNamedChild('Icon')
  local f	= i:GetNamedChild('Frame')

  i:SetDimensions(50, 50)
  f:SetHidden(true)
  local e = WINDOW_MANAGER:CreateControl('$(parent)Edge', i, CT_TEXTURE)
  e:SetDimensions(50, 50)
  e:ClearAnchors()
  e:SetAnchor(TOPLEFT, i, TOPLEFT, 0, 0)
  e:SetTexture('/FancyActionBar+/texture/abilityFrame64_up.dds')
  e:SetColor(unpack(SV.frameColor))
  e:SetDrawLayer(2)
  k:ClearAnchors()
  k:SetScale(0.85)
  k:SetAnchor(BOTTOMLEFT, i, BOTTOMRIGHT, 5, 0)
  a:ClearAnchors()
  a:SetFont('$(BOLD_FONT)|$(KB_18)|outline')
  a:SetAnchor(BOTTOMLEFT, k, TOPLEFT, 5, 5)

  local sub   = ZO_Subtitles
  local text  = sub:GetNamedChild('Text')
  text:ClearAnchors()
  text:SetAnchor(TOP, sub, TOP, 0, 0)
  text:SetVerticalAlignment(TOP)

  local function HookDestroyConfirm()       -- cause typing 'CONFIRM' is too exhausting...
    zo_callLater(function()
      if ZO_Dialog1 and ZO_Dialog1.textParams and ZO_Dialog1.textParams.mainTextParams then
        for k, v in pairs(ZO_Dialog1.textParams.mainTextParams) do
          if v == string.upper(v) then
            ZO_Dialog1EditBox:SetText(v)
            ZO_Dialog1EditBox:LoseFocus()
          end
        end
      end
    end, 10)
  end
  ZO_PreHook('ZO_Dialogs_ShowDialog', HookDestroyConfirm)

  --[[
  filterId    =  MOTIF_KNOWLEDGE_FILTER = 39,
  subFilterId = CONSUMABLE_MOTIF = 24,

  ]]
end

EM:RegisterForEvent(NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

--[[ Result Type
  resultType == ACTION_RESULT_BAD_TARGET
  or resultType == ACTION_RESULT_BUSY
  or resultType == ACTION_RESULT_FAILED
  or resultType == ACTION_RESULT_INVALID
  or resultType == ACTION_RESULT_CANT_SEE_TARGET
  or resultType == ACTION_RESULT_TARGET_DEAD
  or resultType == ACTION_RESULT_TARGET_OUT_OF_RANGE
  or resultType == ACTION_RESULT_TARGET_TOO_CLOSE
  or resultType == ACTION_RESULT_TARGET_NOT_IN_VIEW
]]

--[[ Slot info
  SKILL_TYPE_NONE       = 0
  SKILL_TYPE_CLASS      = 1
  SKILL_TYPE_WEAPON     = 2
  SKILL_TYPE_ARMOR      = 3
  SKILL_TYPE_WORLD      = 4
  SKILL_TYPE_GUILD      = 5
  SKILL_TYPE_AVA        = 6
  SKILL_TYPE_RACIAL     = 7
  SKILL_TYPE_TRADESKILL = 8
  SKILL_TYPE_CHAMPION   = 9

  IsBlockActive()

  GetAssignableAbilityBarStartAndEndSlots() - Returns: startActionSlotIndex, endActionSlotIndex

  IsAbilityPassive(abilityId)   - Returns: boolean
  IsAbilityPermanent(abilityId) - Returns: boolean
  IsActionBarRespeccable()      - Returns: boolean

  IsSkillAbilityPassive(  number skillType, number skillLineIndex, number skillIndex) - Returns: boolean
  IsSkillAbilityPurchased(number skillType, number skillLineIndex, number skillIndex) - Returns: boolean
  IsSkillAbilityUltimate( number skillType, number skillLineIndex, number skillIndex) - Returns: boolean

  IsSkillBuildAdvancedMode()            - Returns: boolean
  IsSlotItemConsumable(actionSlotIndex) - Returns: boolean
  IsSlotLocked(actionSlotIndex)         - Returns: boolean
  IsSlotSoulTrap(actionSlotIndex)       - Returns: boolean
  IsSlotToggled(actionSlotIndex)        - Returns: boolean
  IsSlotUsable(actionSlotIndex)         - Returns: boolean
  IsSlotUsed(actionSlotIndex)           - Returns: boolean

  GetActionSlotEffectDuration(actionSlotIndex, hotbarCategory)        - Returns: durationMilliseconds
  GetActionSlotEffectTimeRemaining(actionSlotIndex, hotbarCategory)   - Returns: timeRemainingMilliseconds
  GetActionSlotEffectStackCount(actionSlotIndex, hotbarCategory)      - Returns: stackCount
  GetEffectiveAbilityIdForAbilityOnHotbar(abilityId, hotbarCategory)  - Returns: effectiveAbilityId
  CanAbilityBeUsedFromHotbar(abilityId, hotbarCategory)               - Returns: canBeUsed
  GetAbilityAngleDistance(abilityId)                                  - Returns: number angleDistance
  GetAbilityEffectDescription(effectSlotId)                           - Returns: string description
  GetAbilityUpgradeLines(abilityId) - Uses variable returns...        - Returns: string label, string oldValue, string newValue

  GetCurrentCharacterId()  - Returns: string id
  GetCursorAbilityId()     - Returns: number:nilable abilityId
  GetCursorBagId()         - Returns: number:nilable originatingBag
  GetCursorCollectibleId() - Returns: number:nilable collectibleId
  GetCursorContentType()   - Returns: number cursorType
  GetCursorSlotIndex()     - Returns: number:nilable slotIndex
]]

--[[ Equipment info

  GetItemCooldownInfo(BAG_WORN, EQUIP_SLOT_MAIN_HAND)

  GetItemLinkWeaponType(GetItemLink(BAG_WORN, EQUIP_SLOT_MAIN_HAND, LINK_STYLE_DEFAULT))
  GetItemLinkWeaponType(GetItemLink(BAG_WORN, EQUIP_SLOT_BACKUP_MAIN, LINK_STYLE_DEFAULT))

  BAG_WORN

  GetItemLink(number Bag bagId, number slotIndex, number LinkStyle linkStyle)
  GetItemLinkWeaponType(string itemLink)

  0 = LINK_STYLE_DEFAULT
  1 = LINK_STYLE_BRACKETS

  0 = ACTION_BAR_FIRST_WEAPON_SLOT_INDEX
  1 = ACTION_BAR_LAST_WEAPON_SLOT_INDEX

  0 = ACTIVE_WEAPON_PAIR_NONE
  1 = ACTIVE_WEAPON_PAIR_MAIN
  2 = ACTIVE_WEAPON_PAIR_BACKUP

  2 = HOT_BAR_RESULT_ITEM_IN_WEAPON_SLOT

  -1 = EQUIP_SLOT_MIN_VALUE
  0  = EQUIP_SLOT_ITERATION_BEGIN

  -1 = EQUIP_SLOT_NONE
  0  = EQUIP_SLOT_HEAD
  1  = EQUIP_SLOT_NECK
  2  = EQUIP_SLOT_CHEST
  3  = EQUIP_SLOT_SHOULDERS
  4  = EQUIP_SLOT_MAIN_HAND
  5  = EQUIP_SLOT_OFF_HAND
  8  = EQUIP_SLOT_LEGS
  9  = EQUIP_SLOT_FEET
  10 = EQUIP_SLOT_COSTUME
  11 = EQUIP_SLOT_RING1
  12 = EQUIP_SLOT_RING2
  13 = EQUIP_SLOT_POISON
  14 = EQUIP_SLOT_BACKUP_POISON
  15 = EQUIP_SLOT_RANGED
  16 = EQUIP_SLOT_HAND
  17 = EQUIP_SLOT_CLASS1
  18 = EQUIP_SLOT_CLASS2
  19 = EQUIP_SLOT_CLASS3
  20 = EQUIP_SLOT_BACKUP_MAIN
  21 = EQUIP_SLOT_BACKUP_OFF

  21 = EQUIP_SLOT_ITERATION_END
  21 = EQUIP_SLOT_MAX_VALUE

====[  WEAPONTYPE  ]====
  0  = WEAPONTYPE_NONE
  1  = WEAPONTYPE_AXE
  2  = WEAPONTYPE_HAMMER
  3  = WEAPONTYPE_SWORD
  4  = WEAPONTYPE_TWO_HANDED_SWORD
  5  = WEAPONTYPE_TWO_HANDED_AXE
  6  = WEAPONTYPE_TWO_HANDED_HAMMER
  7  = WEAPONTYPE_PROP
  8  = WEAPONTYPE_BOW
  9  = WEAPONTYPE_HEALING_STAFF
  10 = WEAPONTYPE_RUNE
  11 = WEAPONTYPE_DAGGER
  12 = WEAPONTYPE_FIRE_STAFF
  13 = WEAPONTYPE_FROST_STAFF
  14 = WEAPONTYPE_SHIELD
  15 = WEAPONTYPE_LIGHTNING_STAFF

====[  WEAPON_CONFIG_TYPE  ]====
  0  = WEAPON_CONFIG_TYPE_ITERATION_BEGIN
  0  = WEAPON_CONFIG_TYPE_MIN_VALUE

  0  = WEAPON_CONFIG_TYPE_NONE
  1  = WEAPON_CONFIG_TYPE_ONE_HAND_AND_SHIELD
  2  = WEAPON_CONFIG_TYPE_DUAL_WIELD
  3  = WEAPON_CONFIG_TYPE_TWO_HANDED
  4  = WEAPON_CONFIG_TYPE_BOW
  5  = WEAPON_CONFIG_TYPE_DESTRO_STAFF
  6  = WEAPON_CONFIG_TYPE_RESTO_STAFF
  7  = WEAPON_CONFIG_TYPE_FIRE_STAFF
  8  = WEAPON_CONFIG_TYPE_FROST_STAFF
  9  = WEAPON_CONFIG_TYPE_LIGHTNING_STAFF
  10 = WEAPON_CONFIG_TYPE_ONE_HANDED
  11 = WEAPON_CONFIG_TYPE_UNARMED

  11 = WEAPON_CONFIG_TYPE_ITERATION_END
  11 = WEAPON_CONFIG_TYPE_MAX_VALUE

====[  WEAPON_MODEL_TYPE  ]====
  0  = WEAPON_MODEL_TYPE_MIN_VALUE
  1  = WEAPON_MODEL_TYPE_ITERATION_BEGIN

  0  = WEAPON_MODEL_TYPE_NONE
  1  = WEAPON_MODEL_TYPE_AXE
  2  = WEAPON_MODEL_TYPE_HAMMER
  3  = WEAPON_MODEL_TYPE_SWORD
  4  = WEAPON_MODEL_TYPE_DAGGER
  5  = WEAPON_MODEL_TYPE_BOW
  6  = WEAPON_MODEL_TYPE_STAFF
  7  = WEAPON_MODEL_TYPE_SHIELD
  8  = WEAPON_MODEL_TYPE_RUNE
  9  = WEAPON_MODEL_TYPE_PROP

  9  = WEAPON_MODEL_TYPE_MAX_VALUE
  9  = WEAPON_MODEL_TYPE_ITERATION_END

]]

--[[ Companion
  GetCrownCrateNPCCardThrowingBoneName() - Returns: string boneName

  GetCrownCrateNPCBoneWorldPosition(string boneName)
  Returns: boolean success, number positionX, number positionY, number positionZ

	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(COMPANION_PROGRESS_BAR_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(TITLE_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(COMPANION_MENU_PREVIEW_OPTIONS_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(ITEM_PREVIEW_KEYBOARD:GetFragment())
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(COMPANION_TITLE_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(COMPANION_KEYBOARD_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(COMPANION_CHARACTER_KEYBOARD_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(COMPANION_CHARACTER_WINDOW_FRAGMENT)
	COMPANION_CHARACTER_KEYBOARD_SCENE:AddFragment(THIN_LEFT_PANEL_BG_FRAGMENT)

	------------------------
	-- Companion Skills Scene
	------------------------
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(COMPANION_PROGRESS_BAR_FRAGMENT)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
	-- ESO-712835: Add a preview fragment to skills to solve the loss of focus upon the companion object when navigating between a screen with previewing and one without.
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(ITEM_PREVIEW_KEYBOARD:GetFragment())
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(TITLE_FRAGMENT)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(COMPANION_TITLE_FRAGMENT)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(COMPANION_KEYBOARD_FRAGMENT)
	COMPANION_SKILLS_KEYBOARD_SCENE:AddFragment(COMPANION_SKILLS_KEYBOARD_FRAGMENT)
]]

--[[ Retired
  EM:RegisterForEvent(NAME, EVENT_ACTION_SLOT_EFFECT_UPDATE, OnActionSlotEffectUpdated)
  -- Any effect duration gained.
	-- Effect must be slotted and not have custom duration specified in config.lua
	local function OnActionSlotEffectUpdated(hotbarCategory, actionSlotIndex)
    d('hey ' .. actionSlotIndex)
		local effect = FAB.effects[GetSlotBoundId(actionSlotIndex, hotbarCategory)]
		if effect and not effect.custom then
			local duration = GetActionSlotEffectDuration(actionSlotIndex, hotbarCategory)
			if duration > 2000 and duration < 100000 then
				effect.endTime = time() + (duration / 1000) --GetActionSlotEffectTimeRemaining(actionSlotIndex, hotbarCategory) / 1000
			else
				effect.endTime = 0
			end
			UpdateEffect(effect)
		end
    FAB:dbg('Effect Updated: [<<1>>]: <<2>> (<<3>>). <<4>> / <<5>>', actionSlotIndex, GetAbilityName(effect.id), effect.id or 'nil', effect.endTime or 'nil', duration or 'nil')
  end
]]

--[[==============[	API References	]==============
* MAX_ACTION_BAR_ABILITY_SLOTS
* HOT_BAR_RESULT_SLOT_LOCKED

Added _hotbarCategory_
* GetSlotAbilityCost(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* GetSlotTexture(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* IsSlotUsed(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* IsSlotToggled(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasCostFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasRequirementFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasWeaponSlotFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasTargetFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasRangeFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasLeapKeepTargetFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasSubzoneFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasStatusEffectFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasFallingFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasSwimmingFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasMountedFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasReincarnatingFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasActivationHighlight(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)
* HasNonCostStateFailure(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]:nilable* _hotbarCategory_)

Added _casterUnitTag_
* GetAbilityCastInfo(*integer* _abilityId_, *integer:nilable* _overrideRank_, *string* _casterUnitTag_)
* GetAbilityTargetDescription(*integer* _abilityId_, *integer:nilable* _overrideRank_, *string* _casterUnitTag_)
* GetAbilityRange(*integer* _abilityId_, *integer:nilable* _overrideRank_, *string* _casterUnitTag_)
* GetAbilityRadius(*integer* _abilityId_, *integer:nilable* _overrideRank_, *string* _casterUnitTag_)
* GetAbilityDuration(*integer* _abilityId_, *integer:nilable* _overrideRank_, *string* _casterUnitTag_)
* GetAbilityCooldown(*integer* _abilityId_, *string* _casterUnitTag_)
* GetAbilityDescriptionHeader(*integer* _abilityId_, *string* _casterUnitTag_)
* GetAbilityDescription(*integer* _abilityId_, *integer:nilable* _overrideRank_, *string* _casterUnitTag_)

* GetActionSlotEffectDuration(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]* _hotbarCategory_)
** _Returns:_ *integer* _durationMilliseconds_

* GetActionSlotEffectTimeRemaining(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]* _hotbarCategory_)
** _Returns:_ *integer* _timeRemainingMilliseconds_

  IsActionSlotLocked(actionSlotIndex, hotbarCategory)
  Returns: isLocked

* GetActionSlotUnlockText(*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]* _hotbarCategory_)
** _Returns:_ *string* _slotUnlockText_

h3. TooltipControl
Changed type to SkillType|#SkillType
* SetSkillLine(*[SkillType|#SkillType]* _skillType_, *luaindex* _skillLineIndex_)

* EVENT_ACTION_SLOT_EFFECTS_CLEARED
* EVENT_ACTION_SLOT_EFFECT_UPDATE (*[HotBarCategory|#HotBarCategory]* _hotbar_, *luaindex* _actionSlot_)
* EVENT_HOTBAR_SLOT_STATE_UPDATED (*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]* _hotbarCategory_)

Added _justUnlocked_
* EVENT_HOTBAR_SLOT_UPDATED (*luaindex* _actionSlotIndex_, *[HotBarCategory|#HotBarCategory]* _hotbarCategory_, *bool* _justUnlocked_)
]]

--[[ Interaction
  local interactionType = GetInteractionType()
  	if interactionType ~= INTERACTION_NONE then
  			EndInteraction(interactionType)
  	end

  	if IsInteractionPending() then
  			EndPendingInteraction()
  	end
  end

  SETTING_PANEL_DEBUG

  SETTING_TYPE_DEVELOPER_DEBUG

  TRADE_CONFIRM_ACCEPT
  TRADE_CONFIRM_EDIT
  TRADE_CONFIRM_ITERATION_BEGIN
  TRADE_CONFIRM_ITERATION_END
  TRADE_CONFIRM_MAX_VALUE
  TRADE_CONFIRM_MIN_VALUE
  TRADE_DELAY_TIME
  TRADE_ITERATION_BEGIN
  TRADE_ITERATION_END
  TRADE_MAX_VALUE
  TRADE_ME
  TRADE_MIN_VALUE
  TRADE_NUM_SLOTS
  TRADE_STATE_IDLE
  TRADE_STATE_INVITE_CONSIDERING
  TRADE_STATE_INVITE_WAITING
  TRADE_STATE_ITERATION_BEGIN
  TRADE_STATE_ITERATION_END
  TRADE_STATE_MAX_VALUE
  TRADE_STATE_MIN_VALUE
  TRADE_STATE_TRADING
  TRADE_THEM

  =============================================

  INTERACTION_ITERATION_BEGIN     =  0
  INTERACTION_MIN_VALUE           =  0

  INTERACTION_NONE                =  0
  INTERACTION_STORE               =  1
  INTERACTION_LOOT                =  2
  INTERACTION_QUEST               =  3
  INTERACTION_KEEP_INSPECT        =  4
  INTERACTION_KEEP_GUILD_CLAIM    =  5
  INTERACTION_BANK                =  6
  INTERACTION_MAIL                =  7
  INTERACTION_FAST_TRAVEL_KEEP    =  8

  INTERACTION_FAST_TRAVEL         = 11
  INTERACTION_BOOK                = 12
  INTERACTION_CONVERSATION        = 14
  INTERACTION_VENDOR              = 15
  INTERACTION_AVA_HOOK_POINT      = 16
  INTERACTION_STONE_MASON         = 17
  INTERACTION_GUILDKIOSK_BID      = 18
  INTERACTION_BUY_BAG_SPACE       = 19
  INTERACTION_LOCKPICK            = 20
  INTERACTION_KEEP_PIECE          = 21
  INTERACTION_SIEGE               = 22
  INTERACTION_CRAFT               = 23
  INTERACTION_FISH                = 24
  INTERACTION_GUILDBANK           = 25
  INTERACTION_TRADINGHOUSE        = 26
  INTERACTION_STABLE              = 27
  INTERACTION_HARVEST             = 28
  INTERACTION_KEEP_GUILD_RELEASE  = 29
  INTERACTION_PAY_BOUNTY          = 30
  INTERACTION_DYE_STATION         = 31
  INTERACTION_GUILDKIOSK_PURCHASE = 32
  INTERACTION_PICKPOCKET          = 33
  INTERACTION_HIDEYHOLE           = 34
  INTERACTION_FURNITURE           = 35
  INTERACTION_RETRAIT             = 36
  INTERACTION_SKILL_RESPEC        = 37
  INTERACTION_ATTRIBUTE_RESPEC    = 38
  INTERACTION_TREASURE_MAP        = 39
  INTERACTION_ANTIQUITY_DIG_SPOT  = 40
  INTERACTION_ANTIQUITY_SCRYING   = 41

  INTERACTION_MAX_VALUE           = 41
  INTERACTION_ITERATION_END       = 41

  =============================================

  INTERACT_CANCEL_CONTEXT_DEFAULT         =  0
  INTERACT_CANCEL_CONTEXT_COMBAT          =  1

  =============================================

  INTERACT_TARGET_TYPE_NONE               =  0
  INTERACT_TARGET_TYPE_OBJECT             =  1
  INTERACT_TARGET_TYPE_ITEM               =  2
  INTERACT_TARGET_TYPE_CLIENT_CHARACTER   =  3
  INTERACT_TARGET_TYPE_QUEST_ITEM         =  4
  INTERACT_TARGET_TYPE_FIXTURE            =  5
  INTERACT_TARGET_TYPE_AOE_LOOT           =  6
  INTERACT_TARGET_TYPE_COLLECTIBLE        =  7

  =============================================

--]]
