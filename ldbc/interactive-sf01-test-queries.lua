local iq01 = ldbc_snb_iq01("1129", "Chen")
local iq02 = ldbc_snb_iq02("1129", date("2022-05-20T18:55:55.595+0000Z"))
local iq13a = ldbc_snb_iq13("1129", "1242") -- 1
local iq13b = ldbc_snb_iq13("1129", "555") -- 2
local iq13c = ldbc_snb_iq13("1129", "3412") -- 3
local iq13d = ldbc_snb_iq13("1129", "1885") -- 4
iq01, iq02, iq13a, iq13b, iq13c, iq13d
