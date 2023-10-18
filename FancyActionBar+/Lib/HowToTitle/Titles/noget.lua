local MY_MODULE_NAME = "noget"
local MY_MODULE_VERSION = 29.5

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

-- Symbolic
HTT:RegisterTitle("@Vatrokion",         nil,    92, {en = "SweetHeart"}, {color={"#C71585", "#800080"}})
HTT:RegisterTitle("@Deekri",            nil,  true, {en = "Trap"}, {color="#ff3333", hidden = true})
HTT:RegisterTitle("@nogetrandom",       nil,  2746, {en = ":PeepoPing:"}, {color="#FE2008"})
HTT:RegisterTitle("@nogetrandom",       nil,  true, {en = "|c999999lower case|r n ツ"}, {hidden = true})
HTT:RegisterTitle("@alperr",            nil,  true, {en = "GAMING WARLORD"}, {color="#FF9933", hidden = true})
HTT:RegisterTitle("@a_lx",              nil,  true, {en = "Krankenschwester"}, {color="#ffcce6", hidden = true})
HTT:RegisterTitle("@Schäffo",           nil,  true, {en = "On Coffee Break"}, {color="#996600", hidden = true})

-- Stress Tested
HTT:RegisterTitle("@Valencer",          nil,  true, {en = "|cFF99CCC|cF989B7u|cF47AA3t|cEF6B8Ei|cEA5B7Ae|cE54C66p|cE03D51i|cDB2D3De |cD61E28<|cD10F143|r"}, {hidden = true})
HTT:RegisterTitle("@oLulu",             nil,    92, {en = "Emperor"}, {color="#D4AF37"})
HTT:RegisterTitle("@oLulu",             nil,  true, {en = "Akatsuki"}, {color="#D10000", hidden = true})
HTT:RegisterTitle("@imidazole",         nil,  true, {en = "|c66FF99D|c60F4A3e|c5BEAADli|c56E0B7v|c51D6C1er|c4CCCCCy |c47C1D6Se|c42B7E0r|c3DADEAvi|c38A3F4c|c3399FFe|r"}, {hidden = true})
HTT:RegisterTitle("@elfoblin",          nil,  true, {en = "|cff66ffCan I Watch? |cffffff:3|r"}, {hidden = true})
HTT:RegisterTitle("@SShortRound",       nil,  true, {en = "Still using Thrassians"}, {color = "#6666ff", hidden = true})
HTT:RegisterTitle("@Tyreh",             nil,  2467, {en = "Breadly"}, {color="#ffb366", hidden = true})
HTT:RegisterTitle("@Tyreh",             nil,  true, {en = "Brad"}, {color="#ffb366", hidden = true})
HTT:RegisterTitle("@Pebbs",             nil,  true, {en = "Proper Northern Necro"}, {color="#cc66ff", hidden = true})
HTT:RegisterTitle("@Porkkanalaatikko",  nil,  true, {en = "|c40C833H|c53C32Dea|c66BE28lt|c79B923hy |c8CB51ESl|c9FB019ee|cB2AB14p S|cC5A70Fch|cD8A20Aed|cEB9D05ul|cFF9900e|r"}, {hidden = true})
HTT:RegisterTitle("@Saphorius",         nil,  true, {en = "Throwing for UA"}, {color = "#df4242", hidden = true})

-- Unchained Animals
HTT:RegisterTitle("@SloppyChef",        nil,  true, {en = "|cFF9BC3S|cF995C9l|cF490CFi|cEF8BD5p|cEA85DBp|cE580E1y |cE07BE7C|cDB75EDh|cD670F3e|cD16BF9nf|r"}, {hidden = true})
HTT:RegisterTitle("@Baumlaus",          nil,  true, {en = "|c99CCFFS|c9ECCFFa|cA3CCFFl|cA8CCFFt A|cADCCFFt|cB2CCFFr|cB7CCFFon|cBCCCFFa|cC1CCFFr|cC6CCFFch|r"}, {hidden = true})

-- Homies
HTT:RegisterTitle("@EstarossaOfLove",   nil,    92, {en = "Tri Focus"}, {color={"#FF3300", "#3366FF"}})
HTT:RegisterTitle("@EstarossaOfLove",   nil,  true, {en = "|cFFAE00A|cFFBE33n|cFFCE66g|cFFDC8Fe|cFFDF99l |cFFDF99O|cFFDF99f |cFFCE66D|cFFC23De|cFFBB29a|cFFB414t|cFFAE00h|r"}, {hidden = true})
HTT:RegisterTitle("@frozzzen101",       nil,  true, {en = "Schap"}, {color= "#ffcc00", hidden = true})
HTT:RegisterTitle("@kubafc",            nil,  true, {en = "|cFF66FFT|cFF70EFO|cFF7AE0O |cFF84D1R|cFF8EC1E|cFF99B2L|cFFA3A3A|cFFAD93X|cFFB784E|cFFC175D|r"}, {hidden = true})
HTT:RegisterTitle("@Robert-K",          nil,    92, {en = "ﾟ Where Is My Guard Zero? ﾟ"}, {color={"#FFCC66", "#CC66FF"}})
HTT:RegisterTitle("@thecreed00",        nil,  true, {en = "Pepega Warlord"}, {color={"#00ccff", "#00ff00"}, hidden = true})
HTT:RegisterTitle("@AbhorashNL",        nil,    92, {en = "NecroJail"}, {color="#0000ff"})
HTT:RegisterTitle("@Matherios",         nil,  true, {en ="Why Do I Hear Boss Music"}, {color={"#FF00FF", "#0033CC"}, hidden = true})

--Divinity
-- HTT:RegisterTitle("@LadyYousha", nil, true, {en = "Mama Mia"}, {color="#da5ee5", hidden = true})
HTT:RegisterTitle("@LadyYousha",        nil,  true, {en = "Ambition"}, {color="#da5ee5", hidden = true})
HTT:RegisterTitle("@SimplyArmin",       nil,  true, {en = "Ｓェ爪やし∈ |cf2f20dД尺爪ェＮ|r"}, {hidden = true})
HTT:RegisterTitle("@Chaos'Knight",      nil,  true, {en = "Iceheart"}, {color = {"#00a9ffi", "#0052ff"}, hidden = true})
-- HTT:RegisterTitle("@Youse-1", nil, true, {en = "|cff471aKil Tibin|r *spits*"}, {hidden = true})
HTT:RegisterTitle("@Youse-1",           nil,  true, {en = "|cff471aLookLookLook|r"}, {hidden = true})
-- HTT:RegisterTitle("@Batu.Khan", nil, true, {en = "Mosque Squatter"}, {color="ffb3ff", hidden = true})
HTT:RegisterTitle("@Batu.Khan",         nil,  true, {en = "Hello there."}, {color="ffb3ff", hidden = true})
HTT:RegisterTitle("@xModest",           nil,  true, {en = "Daddy"}, {color="#FF33CC", hidden = true})

-- u["@Chaos'Knight"] = {"Iceheart", "|c00a9ffi|r|c009cffc|r|c0090ffe|r|c0084ffh|r|c0077ffe|r|c006bffa|r|c005effr|r|c0052fft|r", "HodorReflexes/esologo.dds"}

--Det Frie Folk
HTT:RegisterTitle("@Donlup",            nil,  true, {en = "|ccc0000P|ccc4400T|cff7733S|cffcc00Donlup|r"}, {hidden = true})
HTT:RegisterTitle("@Daarbak",           nil,  true, {en = "16 Seconds Taunt Cooldown"}, {color="#99cc00", hidden = true})
HTT:RegisterTitle("@Sami98",            nil,  true, {en = "SamiLicious"}, {color="#66ff33", hidden = true})
HTT:RegisterTitle("@HappyLicious",      nil,  true, {en = "Quick vAS"}, {color="#9933ff", hidden = true})
HTT:RegisterTitle("@anle",              nil,  true, {en = "zzzZZzzZZ"}, {color={"#FFE3A6", "#FFAE00", hidden = true}})
HTT:RegisterTitle("@Shadedrifter",      nil,  true, {en = "Healer"}, {color="#808080", hidden = true})
HTT:RegisterTitle("@Mille_W",           nil,  2755, {en = "#1 T-Bagger"}, {color="#ffc61a"})
HTT:RegisterTitle("@Mille_W",           nil,  true, {en = "|cffe6ff(∩|cb3e6ff*|cffe6ff-|cb3e6ff*|cffe6ff)>|cffeee6--+|cb3e6ff. o ･ ｡ﾟ|r"},{hidden = true})
HTT:RegisterTitle("@Berthelsen21",      nil,  true, {en = "|c1a6600  En |cffffff  |c002db3To  |cffffff |ccca300Ørkensten|r"}, {hidden = true})
HTT:RegisterTitle("@Skinfaxe_DK",       nil,  true, {en = "|cCC6699K|cCC60A3a|cCC5BADd|cCC56B7a|cCC51C1v|cCC4CCCe|cCC47D6r|cCC42E0k|cCC3DEAl|cCC38F4at|r"}, {hidden = true})

-- test
-- HTT:RegisterTitle("@nogetrandom",      nil,  92, {en = "Iceheart"}, {color = {"#00a9ffi", "#0052ff"}})
