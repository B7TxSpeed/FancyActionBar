local MY_MODULE_NAME = "Floliroy"
local MY_MODULE_VERSION = 29.3

local HTT = HowToTitle
if not HTT then return end
if not HTT.version or HTT.version < 23.3 then return end

local isRegistered = false

if not isRegistered then
  if HowToTitleModules[MY_MODULE_NAME] then
    if not HowToTitleModules[MY_MODULE_NAME].version or HowToTitleModules[MY_MODULE_NAME].version <= MY_MODULE_VERSION then
      HowToTitleModules[MY_MODULE_NAME] = nil
    else
      return
    end
  end
end

local MY_MODULE = HTT:RegisterModule(MY_MODULE_NAME, MY_MODULE_VERSION)
if not MY_MODULE then
  return
else
  isRegistered = true
end

-- Flo originals
HTT:RegisterTitle("@Floliroy",            nil,  2075, {en = "Godplar"}, {color={"#F9E259", "#FE2008"}})
HTT:RegisterTitle("@Floliroy",            nil,    92, {en = "Send Nudes"}, {color={"#C71585", "#800080"}})
HTT:RegisterTitle("@Nixir",               nil,  2079, {en = "God's Mercenary", de = "Söldner der Götter", fr ="Mercenaire des Dieux"})
HTT:RegisterTitle("@Panaa",               nil,    92, {en = "|c0000CDTormen|cFFFFFFted By Ti|cFF0000ck Tock|r", fr = "|c4169E1 Le Handicap Est Ma Passion|r", de = "|cFFFF00Ich mag Schokoladen Kuchen|r"})
HTT:RegisterTitle("@Panaa",               nil,  2136, {en = "|c0000CDBag|cFFFFFFuet|cFF0000te!|r"})
HTT:RegisterTitle("@Renard7",             nil,    92, {en = "Legendary Renard"}, {color={"#CC6600", "#222222"}})
HTT:RegisterTitle("@Renard7",             nil,  1330, {en = "Guardian of the Galaxy"}, {color={"#73F9E7", "#D5003F"}})
HTT:RegisterTitle("@BigBadBlackBonsai",   nil,  1391, {en = "Squirts Like a Fire Hose"})
HTT:RegisterTitle("@Nameless-X",          nil,    92, {en = "Karma x Łułu's Łøvechild"}, {color={"#ff0066", "#800000"}})
HTT:RegisterTitle("@Nameless-X",          nil,  1838, {en = "Retard of the Guild"}, {color="#AFFF4F"})
HTT:RegisterTitle("@Nameless-X",          nil,  2467, {en = "Gødsłayer"}, {color={"#fef608", "#FFCC00"}})
HTT:RegisterTitle("@Nameless-X",          nil,  true, {en = "|c08FED5H|c07F4D9e W|c06EBDDhø |c05E1E1Sh|c04D8E5ał|c04CFEAł N|c03C5EEøt |c02BCF2Be |c01B2F6Na|c00A9FAme|c00A0FFd|r", hidden = true})
