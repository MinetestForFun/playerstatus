
local player_status = {}
player_status["players"] = {}

--APPLY PHYSICS START
function playerstatus.set_physics(playerName)
	local player = minetest.get_player_by_name(playerName)
	if not player then return end
	local physic = {
		speed = player_status["players"][playerName]["physics"]["speed"],
		jump = player_status["players"][playerName]["physics"]["jump"],
		gravity = player_status["players"][playerName]["physics"]["gravity"],
	}
	player:set_physics_override(physic)
end

function playerstatus.update_physics(playerName)
	local player = minetest.get_player_by_name(playerName)
	if not player then return end
	
	local bonus = playerstatus.get_bonus(playerName)
	local speed = SPEED + bonus["speed"]
	local jump = JUMP + bonus["agility"]
	local gravity = GRAVITY + bonus["gravity"]
	local sprint_speed = SPRINT_SPEED + bonus["speed"]
	local sprint_jump = SPRINT_JUMP + bonus["agility"]
	local stamina_max = playerstatus.get_stamina_max(playerName) + bonus["stamina_max"]
	playerstatus.set_stamina_max(playerName, stamina_max)
	player_status["players"][playerName]["physics"]["speed"] = speed
	player_status["players"][playerName]["physics"]["jump"] = jump
	player_status["players"][playerName]["physics"]["gravity"] = gravity
	player_status["players"][playerName]["physics"]["sprint_speed"] = sprint_speed
	player_status["players"][playerName]["physics"]["sprint_jump"] = sprint_jump
	playerstatus.set_physics(playerName)
	--print(dump(player_status["players"][playerName]))
end


function playerstatus.get_bonus(playerName)
	local bonus = {
		["speed"] = 0,
		["agility"] = 0,
		["gravity"] = 0,
		["stamina_max"] = 0,
	}
	for def, n in pairs(player_status["players"][playerName]["bonus"]) do
		for _,i in pairs(n) do
			bonus[def] = bonus[def] + i
		end
	end
	return bonus
end


function playerstatus.set_bonus(playerName, modname, bonus)
	player_status["players"][playerName]["bonus"]["speed"][modname] = bonus["speed"] or nil
	player_status["players"][playerName]["bonus"]["agility"][modname] = bonus["agility"] or nil
	player_status["players"][playerName]["bonus"]["gravity"][modname] = bonus["gravity"] or nil
	player_status["players"][playerName]["bonus"]["stamina_max"][modname] = bonus["stamina_max"] or nil
	playerstatus.update_physics(playerName)
end
--APPLY PHYSICS END


--SPRINT START
function playerstatus.set_sprinting(playerName, is_sprint)
	local player = minetest.get_player_by_name(playerName)
	if not player then return end
	if is_sprint and playerstatus.get_stamina(playerName) > 0 then
		player:set_physics_override({
			speed = player_status["players"][playerName]["physics"]["sprint_speed"],
			jump = player_status["players"][playerName]["physics"]["sprint_jump"],
		})
	else
		player:set_physics_override({
			speed = player_status["players"][playerName]["physics"]["speed"],
			jump = player_status["players"][playerName]["physics"]["jump"],
		})
	end

end


function playerstatus.get_stamina(playerName)
	return player_status["players"][playerName]["physics"]["stamina"] or 0
end


function playerstatus.set_stamina(playerName, stamina)
	local max = playerstatus.get_stamina_max(playerName)
	if stamina < 0 then
		stamina = 0
	elseif stamina > max then
		stamina = max
	end
	player_status["players"][playerName]["physics"]["stamina"] = stamina
end


function playerstatus.get_stamina_max(playerName)
	return player_status["players"][playerName]["physics"]["stamina_max"] or STAMINA_MAX
end


function playerstatus.set_stamina_max(playerName, stamina_max)
	if stamina_max >= 0 then
		player_status["players"][playerName]["physics"]["stamina_max"] = stamina_max
	end
end
--SPRINT END



minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	player_status["players"][playerName] = {}
	player_status["players"][playerName]["physics"] = {
		["speed"] = SPEED,
		["jump"] = JUMP,
		["gravity"] = GRAVITY,
		["sprint_speed"] = SPRINT_SPEED,
		["sprint_jump"] = SPRINT_JUMP,
		["walking"] = true,
		["stamina"] = 0,
		["stamina_max"] = STAMINA_MAX,
		--["sneak"] = false,
		--["sneak_glitch"] = false,
	}
	player_status["players"][playerName]["bonus"] = {
		["speed"] = {},
		["agility"] = {},
		["gravity"] = {},
		["stamina_max"] = {},
	}
	playerstatus.update_physics(playerName)
end)


minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	player_status["players"][playerName] = nil
end)

