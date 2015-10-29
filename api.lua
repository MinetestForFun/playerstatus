local stats = {}
local effects = {}

local players = {}
local eiidCounter = 0

local function nvl(v, d) if v == nil then return d end return v end
-- No, I swear I didn't do any Oracle SQL ;)
local function pnm(p) if type(p) == "string" then return p elseif type(p) == "userdata" return p:get_player_name() end return nil end

--
-- STATS
--

function playerstatus.register_stat(name, spec)
	if type(name) ~= "string" or type(spec) ~= "table" or stats[name] ~= nil then
		return
	end
	stats[name] = {
		basemax   = spec.basemax,
		baseregen = spec.baseregen or 0,
		integer   = nvl(spec.integer, true),
		maxchangescale = nvl(spec.maxchangescale, true),
		valchangecbs = {}
	}
	if spec.hudbar then
		stats[name].hudbar = {
			text_color = spec.hudbar.text_color,
			label = spec.hudbar.label,
			textures = spec.hudbar.textures,
			default_start_hidden = nvl(spec.hudbar.default_start_hidden, false),
			format_string = spec.hudbar.format_string
		}
		stats[name].hudbar.visible = default_start_hidden
	end
end

local function stat_invalid(name)
	return type(name) ~= "string" or stats[name] == nil
end

local function plr_stat_invalid(player, name)
	return player == nil or players[player] == nil or players[player].stats == nil or
	       stat_invalid(name) or players[player].stats[name] == nil
end


function playerstatus.get_stat_basemax(name)
	if stat_invalid(name) then
		return nil
	end
	return stats[name].basemax
end

function playerstatus.get_stat_baseregen(name)
	if stat_invalid(name) then
		return nil
	end
	return stats[name].baseregen
end


function playerstatus.get_stat_effectivemax(player, name)
	player = pnm(player)
	if plr_stat_invalid(player, name) then
		return nil
	end
	return players[player].stats[name].max
end

function playerstatus.get_stat_effectiveregen(player, name)
	player = pnm(player)
	if plr_stat_invalid(player, name) then
		return nil
	end
	return players[player].stats[name].regen
end

function playerstatus.get_stat_value(player, name)
	player = pnm(player)
	if plr_stat_invalid(player, name) then
		return nil
	end
	if stats[name].integer then
		return floor(players[player].stats[name].value)
	end
	return players[player].stats[name].value
end

function playerstatus.set_stat_value(player, name, value)
	player = pnm(player)
	if plr_stat_invalid(player, name) then
		return
	end
	players[player].stats[name].value = value
end

function playerstatus.add_stat_value(player, name, add)
	player = pnm(player)
	if plr_stat_invalid(player, name) then
		return
	end
	players[player].stats[name].value = players[player].stats[name].value + add
end


function playerstatus.add_onstatvalchange_callback(name, callback)
	if stat_invalid(name) or type(callback) ~= "function" then
		return nil
	end
	table.insert(stats[name].valchangecbs, callback)
	return true
end

-- function playerstatus.set_stat_hudbar_visibility(name, visible)
-- Or something like that.

--
-- EFFECTS
--

function playerstatus.register_effect(name, spec)
	if type(name) ~= "string" or type(spec) ~= "table" or effects[name] ~= nil then
		return nil
	end
	effects[name] = {
		maxapplies = nvl(spec.maxapplies, 0),
		statchanges = {}
	}
	for k, v in pairs(spec.statchanges) do
		effects[name].statchanges[k] = {
			baseadd = nvl(spec.statchanges.baseadd, 0),
			pct = nvl(spec.statchanges.pct, 0),
			add = nvl(spec.statchanges.add, 0),
			regenbaseadd = nvl(spec.statchanges.regenbaseadd, 0),
			regenpct = nvl(spec.statchanges.regenpct, 0),
			regenadd = nvl(spec.statchanges.regenadd, 0),
			disableregen = nvl(spec.statchanges.disableregen, false)
		}
	end
	return true
end

local function effect_invalid(name)
	return type(name) ~= "string" or effects[name] == nil
end

function playerstatus.apply_effect(player, effectname)
	player = pnm(player)
	if player == nil or effect_invalid(effectname) then
		return nil
	end
	local applied = 0
	for k, v in ipairs(players[player].effects) do
		if v == effectname then
			applied = applied + 1
		end
	end
	if applied >= effects[effectname].maxapplies then
		return false
	end
	players[player].effects[eiidCounter] = effectname
	eiidCounter = eiidCounter + 1
	return eiidCounter - 1
end

function playerstatus.remove_effect(eeid)
	if type(eeid) ~= "number" then
		return nil
	end
	for player, ptable in pairs(players) do
		for peeid, peffectname in pairs(ptable.effects) do
			if peeid == eeid then
				ptable.effects[eeid] = nil
				return true
			end
		end
	end
	return nil
end

function playerstatus.remove_effect_all(effectname)
	if effect_invalid(effectname) then
		return nil
	end
	local rmCount = 0
	for player, ptable in pairs(players) do
		for peeid, peffectname in pairs(ptable.effects) do
			if peffectname == effectname then
				ptable.effects[peeid] = nil
				rmCount = rmCount + 1
			end
		end
	end
	return rmCount
end

--
-- INTERNALS
--

local function update_core_values(playerName)
	local player = minetest.get_player_by_name(playerName)
	if not player then return end
	player:set_physics_override({
		speed = players[playerName].stats.speed.value,
		jump = players[playerName].stats.jump.value,
		gravity = players[playerName].stats.gravity.value,
	})
end


minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = {
		stats = {},
		effects = {}
	}
	playerstatus.update_physics(playerName)
end)


minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

