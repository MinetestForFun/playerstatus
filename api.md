
# Stats
A stat is a value borne by a player. It may represent things such as health, mana, breath, glucose levels (a.k.a. hunger), or even caffeine or alcohol levels.

It is basically defined by a maximum value.
You probably want to make that stat affect gameplay, so you can bind it to a callback that is called when its value changes.

Most stats have some kind of auto-regeneration over time, which has a base level.

# Special stat names

* `health` is the core Minetest health bar.
* `breath` is the core Minetest underwater breath bar.
  Applicable regen is **disabled** when underwater and [the standard consume rate of 1-per-2-seconds](https://github.com/minetest/minetest/blob/ca8e56c15a26bc5f3d1dffe5fd39e1ca4b82d6f8/src/environment.cpp#L2245) cannot be changed. It is integer-only with a maximum effective value is 65536 due to engine limitations (breath is stored [as an unsigned 16-bit integer](https://github.com/minetest/minetest/blob/54f1267c2c87daea769966c694777a2e5977f870/src/script/lua_api/l_object.cpp#L1030)).
* `speed`, `jump` and `gravity` are the core Minetest player speed, jump height and gravity properties, respectively (set using `player:set_physics_override`).
  Regen **can** be applied to them, as usual.

# API
## Stats
* `playerstatus.register_stat(name, spec)`
  * **Parameters**:
     * `name`: name of the stat
     * `spec`: table describing the stat (see below)
  * **Returns**: `nil`
```lua
{
  -- Base maximum value for the stat.
  basemax = 1,
  -- Base regen speed (in units per second).
  -- Defaults to 0.
  baseregen = 0,
  -- Whether the stat is an integer or not.
  -- Defaults to true.
  integer = true,
  -- If true, changes to the effective maximum will
  -- also scale the actual value (e.g. a full stat
  -- that changes max will stay full).
  -- Defaults to false;
  maxchangescale = false,
  -- Parameters passed to hudbars mod. If nil
  -- or hudbars mod isn't available, no hudbar
  -- is created.
  hudbar = {
    text_color = 0xFFFFFF,
    label = "Stat",
    textures = {
      bar = "bar.png",
      icon = "icon.png"
    },
    -- Optional, defaults to false
    default_start_hidden = false,
    -- Optional, default up to hudbars
    format_string = "%s: %d/%d"
  }
}
```
* `playerstatus.get_stat_basemax(name) -> number`
* `playerstatus.get_stat_baseregen(name) -> number`
* `playerstatus.get_stat_effectivemax(player, name) -> number`
* `playerstatus.get_stat_effectiveregen(player, name) -> number`
* `playerstatus.get_stat_value(player, name) -> number`
* `playerstatus.set_stat_value(player, name, value)`
* `playerstatus.add_stat_value(player, name, add)`
* `playerstatus.add_onstatvalchange_callback(name, callback)`
  * **Parameters**:
     * `name`: name of the stat
     * `callback`: `function` to be called when stat value changes
  * **Returns**:
     * `true` on success 
     * `nil` if stat name or callback is invalid

If `hudbars` is available:

* `playerstatus.set_stat_hudbar_visibility(name, visible)`

## Effects
EEID stands for Effect Instance ID.

* `playerstatus.register_effect(name, spec)`
  * **Parameters**:
     * `name`: name of the effect
     * `spec`: table describing the effect (see below)
  * **Returns**:
     * `true` on success
     * `nil` otherwise
```lua
{
  -- Maximum  times the effect can be applied on
  -- the same player. 0/nil means infinite and is default.
  maxapplies = 1,

  -- Table of the stats the effect affects
  statchanges = {
    -- Name of the affected stat
    ["statusname"] = {
      -- How much is added to the base stat.
      -- May be negative. nil means 0.
      baseadd = 0,
      -- Added percentage to the base stat coefficient.
      -- May be negative. nil means 0.
      pct = 0,
      -- How much is added to the multiplied stat.
      -- May be negative. nil means 0.
      add = 0,

      -- Same properties as above, but for regen
      regenbaseadd = 0,
      regenpct = 0,
      regenadd = 0,
      -- If true, disables all other regen provided
      -- to the stat, except this effect's one.
      disableregen = false
    }
  }
}
```
* `playerstatus.apply_effect(player, effectname) -> EIID/false/nil`
  * **Parameters**:
     * `player`: nickname or ObjectRef of targeted player
     * `effectname`: name of the effect to apply
  * **Returns**:
     * An EEID if all succeeds
     * `false` if the effect is already applied `maxapplies` times
     * `nil` if the player or effect isn't found (bad parameters)
* `playerstatus.remove_effect(eeid) -> true/nil`
  * **Parameters**:
     * `eeid`: EEID of effect to remove
  * **Returns**:
     * `true` if all succeeds
     * `nil` if the supplied EEID is invalid
* `playerstatus.remove_effect_all(effectname) -> number/nil`
  * **Parameters**:
     * `effectname`: name of effect to remove to all players
  * **Returns**:
     * `number` of effects removed
     * `nil` if effect name is invalid
