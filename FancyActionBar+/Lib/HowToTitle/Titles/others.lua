local MY_MODULE_NAME = "others"
local MY_MODULE_VERSION = 31.1

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

HTT:RegisterTitle("@YungDoggo",         nil,  2746, {en = "|cffffffA|cfff0ffl|cffe8ffm|cffe0ffi|cffd9ffg|cffc9ffh|cffc2fft|cffbaffy |cffa3ffW|cff9cffe|cff7dffe|cff66ffb|r"})
HTT:RegisterTitle("@Kater_MD",          nil,    92, {en = "Histidine"}, {color="#6600cc"})
HTT:RegisterTitle("@Fr0st_y",           nil,  2363, {en = "Gryphon Fart"}, {color={"#0000FF", "#660066"}})
HTT:RegisterTitle("@Reniy123",          nil,    92, {en = "The Deathbringer"}, {color="#6600ff"})
HTT:RegisterTitle("@ArCooA",            nil,  true, {en = "|c3399FFC|c3A8AE5o|c427BCBl|c4A6CB2d |c515D98B|c594F7Fl|c614065o|c68314Co|c702232d|r"}, {hidden = true})
HTT:RegisterTitle("@Enesx",             nil,  true, {en = "|c66CCFFA|c66C1F4l|c66B7EAr|c66ADE0ea|c66A3D6d|c6699CCy |c668EC1Br|c6684B7o|c667AADk|c6670A3en|r"}, {hidden = true})
HTT:RegisterTitle("@Kai_S",             nil,  true, {en = "|cB40404T|cBB1603h|cC32903e |cCA3C02A|cD24E02l|cD96102m|cE17401i|cE88601g|cF09900h|cF7AC00ty|r"}, {hidden = true})
HTT:RegisterTitle("@gncwolf",           nil,  true, {en = "Beşiktaş"}, {color={"#7A7A7A", "#E6E6E6"}})
HTT:RegisterTitle("@wulfy1987",         nil,  true, {en = "Beşiktaş"}, {color={"#7A7A7A", "#E6E6E6"}})
HTT:RegisterTitle("@Sleepyhead1100",    nil,    92, {en = "The Sandbag"}, {color={"#0000ff", "#ff00ff"}})
HTT:RegisterTitle("@Brulmorith",        nil,  1728, {en = "Lord of the Pog"}, {color={"#6600FF", "#00FFFF"}})
HTT:RegisterTitle("@NeosPride",         nil,  true, {en = "|c0000FFT|c2A23D4h|c5547AAe |c7F6B7FO|cAA8F55n|cD4B32Ae|r"}, {hidden = true})
HTT:RegisterTitle("@IsThatAWeed",       nil,  true, {en = "|cFF0066S|cFF0A5Bp|cFF1451e|cFF1E47c|cFF283Di|cFF3333a|cFF3D28l|cFF471Ei|cFF5114s|cFF5B0At|r"}, {hidden = true})
HTT:RegisterTitle("@Dldozer",           nil,  true, {en = "|c000000Pre|cff9900mium|r"})
HTT:RegisterTitle("@Zehwyn",            nil,    92, {en = "Jabbing Athlete"}, {color="#ffcc00"})
HTT:RegisterTitle("@Raclem",            nil,    92, {en = "Big_Ape"}, {color="#3366cc"})
HTT:RegisterTitle("@LinuxFan3E8",       nil,    93, {en = "Budgie Heart"}, {color={"#66FFFF", "#0066FF"}})
HTT:RegisterTitle("@ZoraxESO",          nil,  true, {en = "|cA30F00A|cA91900p|cB02300e|cB72D00s C|cBD3700o|cC44100n|cCB4B00qu|cD15500e|cD85F00r|cDF6900or|r"}, {hidden = true})
HTT:RegisterTitle("@ZoraxESO",          nil,  2139, {en = "Smash Them All"}, {color="#ADFF2F"})
HTT:RegisterTitle("@Slaayz",            nil,  2139, {en = "pls end me"}, {color={"#6600FF", "#FF66FF"}})
HTT:RegisterTitle("@Slaayz",            nil,  2467, {en = "Misanthrop"}, {color={"#ffffff", "#000000"}})
HTT:RegisterTitle("@DefinitelyNotHoid", nil,    92, {en = "Slacker"}, {color={"#6666FF", "#FF33CC"}})
HTT:RegisterTitle("@Cripty",            nil,  true, {en = "|cFF0000A|cFF1900s|cFF3300h|cFF4C00e|cFF6600n |cFF7F00O|cFF9900n|cFFB200e|r"}, {hidden = true})
HTT:RegisterTitle("@Juarezz",           nil,  true, {en = "where medusa"}, {color="#FF3300", hidden = true})
HTT:RegisterTitle("@VVombat",           nil,  true, {en = "|c938B8ET|cA8A0A3r|cBEB5B8a|cD3CBCDs|cE9E0E2h|r"}, {hidden = true})
HTT:RegisterTitle("@KGNOG",             nil,  true, {en = "|cFF3300So|cFF3D05me|cFF470Ath|cFF510Fin|cFF5B14g U|cFF6619rg|cFF701Een|cFF7A23t C|cFF8428am|cFF8E2De Up|r"}, {hidden = true})
HTT:RegisterTitle("@glebowsky",         nil,  true, {en = "|cFF7500F|cFE6919i|cFE5D33r|cFD514Ce|cFD4666b|cFC3A7Fe|cFC2E99n|cFB23B2d|cFB17CCe|cFA0BE5r|r"}, {hidden = true}) -- fr = "Maître du feu", ru="Маг огня"
HTT:RegisterTitle("@Schared",           nil,  true, {en = "|c6699FFm|c6B8DFFo|c7182FFL|c7777FFA|c7C6BFFG |c8260FFC|c8855FFe|c8D49FFn|c933EFFa|r"}, {hidden = true})
HTT:RegisterTitle("@atomkern",          nil,    92, {en = "tHe WeT n00dL3"},          {color={"#6600FF", "#FF00FF"}})
HTT:RegisterTitle("@Meshkeen",          nil,    92, {en = "PlAnEsBrEaKeR lMaO"},      {color={"#FFFF00", "#0000FF"}})
HTT:RegisterTitle("@MrsLizardFace",     nil,    93, {en = "The Afrikaaner"},          {color={"#ff4d94", "#ffcce0"}})
HTT:RegisterTitle("@Prideflare",        nil,    92, {en = "Prideflare"},              {color={"#ff0000", "#ffff00"}})
HTT:RegisterTitle("@atomkern",          nil,  2368, {en = "tHe WeT n00dL3"},          {color={"#6600FF", "#FF00FF"}})
HTT:RegisterTitle("@Monem.99",          nil,  2468, {en = "Wrath of Light"},          {color={"#FFFF99", "#FFCC00"}})
HTT:RegisterTitle("@PHAEL",             nil,    92, {en = "Moondancer"},              {color={"#FFFF00", "#6600FF"}})
HTT:RegisterTitle("@Chalybtor",         nil,  true, {en = "Immortal Memer"},          {color={"#752389", "#31206D"}})
HTT:RegisterTitle("@HarroHerro",        nil,  true, {en = "FULL-TIME CRINGE"},        {color={"#F0E775", "#AA9D00"}})
HTT:RegisterTitle("@lowscoman",         nil,    92, {en = "Lord of Cinder"},          {color={"#FFFF00", "#FF0000"}})
HTT:RegisterTitle("@lowscoman",         nil,    93, {en = "Planeswalker"},            {color={"#00FFFF", "#0000FF"}})

HTT:RegisterTitle("@lowscoman",         nil,    96, {en = "Potato Squad Ripperino"},  {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@Johny.Johnsson",    nil,    96, {en = "Potato Squad Masterino"},  {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@Motun99",           nil,    96, {en = "Potato Squad Guardian"},   {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@WalterLopes",       nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@onidalton",         nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@Y10K",              nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@wDrizz",            nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@Trxffy",            nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@Sakraello",         nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@Iman_V",            nil,    96, {en = "Potato Squad Mender"},     {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@isiiimode",         nil,    96, {en = "Bala-Bala Squad Mender"},  {color={"#FF0000", "#FFFF00"}})
HTT:RegisterTitle("@yaskudi",           nil,    96, {en = "Potato Squad Slayer"},     {color={"#FF0000", "#FFFF00"}})

HTT:RegisterTitle("@NipTunnus",         nil,  true, {en = "|c008d44Cum |cf7f7f7Mon|cc82a35ster|r"}, {hidden = true})
HTT:RegisterTitle("@HanYoIo",           nil,    92, {en = "Light of Meridia"},        {color={"#ffff00", "#ff9900"}})
HTT:RegisterTitle("@HanYoIo",           nil,    93, {en = "Grand Master Roleplayer"}, {color={"#ff0066", "#ff00ff"}})
HTT:RegisterTitle("@Ranegard",          nil,    92, {en = "Snake Eyes"},              {color={"#FF0000", "#ff9900"}})
HTT:RegisterTitle("@Ranegard",          nil,    93, {en = "Soul Harvester"},          {color={"#FF0000", "#ff9900"}})
HTT:RegisterTitle("@HanYoIo",           nil,    92, {en = "Light of Meridia"},        {color={"#ffff00", "#ff9900"}})
HTT:RegisterTitle("@HanYoIo",           nil,    93, {en = "Grand Master Roleplayer"}, {color={"#ff0066", "#ff00ff"}})
HTT:RegisterTitle("@Cabbage42",         nil,  2746, {en = "Gadse"},                   {color={"#6600CC", "#FF6600"}})
HTT:RegisterTitle("@C4_1397",           nil,    92, {en = "15 FPS"},                  {color="#99ccff"})
HTT:RegisterTitle("@C4_1397",           nil,    93, {en = "DIES FROM CRINGE"},        {color={"#6600CC", "#FF6600"}})
HTT:RegisterTitle("@xDevilz",           nil,    92, {en = "|c010e05D|c091f10U|c082e17M|c043f1bP|c004f1fS|c006121T|c007323E|c008522R|c00981fC|c11ab19R|c23be0aO|r"})
HTT:RegisterTitle("@IInsomniac",        nil,    92, {en = "|c160203D|c240a0bU|c320d11M|c420e14P|c510f17S|c610f19T|c720e1bE|c820d1bR|c930b1bB|ca30a1aL|cb40a18A|cc50c15D|cd51010E|r"})

HTT:RegisterTitle("@High.Quality",      nil,  3007, {en = "Pure Insanity"},           {color={"#cc0099", "#ffff00"}})


-- test
-- HTT:RegisterTitle("@nogetrandom", nil, 92, {en = "Snake Eyes"}, {color={"#FF0000", "#ff9900"}})
-- HTT:RegisterTitle("@nogetrandom",           nil,    92, {en = "|c010e05D|c091f10U|c082e17M|c043f1bP|c004f1fS|c006121T|c007323E|c008522R|c00981fC|c11ab19R|c23be0aO|r"})
-- HTT:RegisterTitle("@nogetrandom",        nil,    93, {en = "|c160203D|c240a0bU|c320d11M|c420e14P|c510f17S|c610f19T|c720e1bE|c820d1bR|c930b1bB|ca30a1aL|cb40a18A|cc50c15D|cd51010E|r"})
