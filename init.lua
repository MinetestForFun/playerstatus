

playerstatus = {}
dofile(minetest.get_modpath("playerstatus") .. "/conf.lua")
dofile(minetest.get_modpath("playerstatus") .. "/api.lua")

minetest.log("action", "playerstatus loaded.")
