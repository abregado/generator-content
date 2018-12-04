local noise = require("noise")
--remove autoplace from all tiles and entities

for name, category in pairs(data.raw) do
  print("MOD: Checking category "..name)
  for _, prototype in pairs(category) do
    if prototype.autoplace then
      prototype.autoplace = nil
      print("MOD: Removed autoplace from "..prototype.name)
    end
  end
end

--give sand a 0.2 probability
data.raw.tile['sand-1'].autoplace = {
 probability_expression = noise.to_noise_expression(0.2)
}

local seed1 = 123
local tne = noise.to_noise_expression
local litexp = noise.literal_expression


local onehalf = tne(1)/2
local onethird = tne(1)/3

local blobs = tne{
  type = "function-application",
  function_name = "factorio-basis-noise",
  arguments = {
    x = noise.var("x"),
    y = noise.var("y"),
    seed0 = noise.var("map_seed"),
    seed1 = tne(seed1),
    input_scale = tne(1),
    output_scale = tne(1),
  }
}
--} + tne{
--  type = "function-application",
--  function_name = "factorio-basis-noise",
--  arguments = {
--    x = noise.var("x"),
--    y = noise.var("y"),
--    seed0 = noise.var("map_seed"),
--    seed1 = tne(seed1),
--    input_scale = tne(1/24),
--    output_scale = tne(1),
--  }
--}

-- For biters, since there's no meaning for 'richness', we'll have
-- Probability max out at 1 at the center of biter bases.
-- In practice, since spawners are more than one tile large,
-- fewer will be placed than the probability function suggests.
local spot_height = tne(1)
-- Volume of cone = πr²h/3
-- 3v/πh = r²
-- r = √(3v/πh)
local function spot_radius_for_quantity(quantity)
  return ((tne(3)/math.pi) * quantity / spot_height) ^ onehalf
end
local function density_at_distance(dist)
  return 0.01 * dist / 1000
end
local function spots_per_km2_at_distance(dist)
  return 5
end
local function spot_quantity_at_distance(dist)
  return density_at_distance(dist) * 1000000 / spots_per_km2_at_distance(dist)
end
local distance_expression = noise.var("distance")
local density_expression = density_at_distance(distance_expression)
local spot_quantity_expression = spot_quantity_at_distance(distance_expression) * noise.random_between(0.25, 2.0)
local spot_radius_expression = spot_radius_for_quantity(spot_quantity_expression)
local basement_value = -1000

local spots = tne{
  type = "function-application",
  function_name = "spot-noise",
  arguments = {
    x = noise.var("x"),
    y = noise.var("y"),
    seed0 = noise.var("map_seed"),
    seed1 = tne(seed1),
    region_size = tne(512),
    candidate_point_count = tne(10),
    density_expression = litexp(density_expression), -- low-frequency noise evaluate for an entire region
    spot_quantity_expression = litexp(spot_quantity_expression), -- used to figure out where spots go
    hard_region_target_quantity = tne(false), -- it's fine for large spots to push region quantity past the target
    spot_radius_expression = litexp(spot_radius_expression),
    spot_favorability_expression = litexp(1),
    basement_value = tne(basement_value),
    maximum_spot_basement_radius = tne(128)
  }
}

local big_spots = tne{
  type = "function-application",
  function_name = "spot-noise",
  arguments = {
    x = noise.var("x"),
    y = noise.var("y"),
    seed0 = noise.var("map_seed"),
    seed1 = tne(seed1),
    region_size = tne(512),
    candidate_point_count = tne(10),
    density_expression = litexp(density_expression), -- low-frequency noise evaluate for an entire region
    spot_quantity_expression = litexp(spot_quantity_expression), -- used to figure out where spots go
    hard_region_target_quantity = tne(false), -- it's fine for large spots to push region quantity past the target
    spot_radius_expression = litexp(spot_radius_expression*1.1),
    spot_favorability_expression = litexp(1),
    basement_value = tne(basement_value),
    maximum_spot_basement_radius = tne(128)
  }
}

--give concrete a noise value between 0 and 1
data.raw.tile['concrete'].autoplace = {
 probability_expression = spots + 0.2
}

data.raw.tile['sand-2'].autoplace = {
 probability_expression = big_spots - spots + 0.2
}


--50% of land should be covered by concrete