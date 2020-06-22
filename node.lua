--[[
MIT License

Copyright (c) 2020, Jan Henrik Sawatzki

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

util.noglobals()

local json = require("json")

local font = resource.load_font("slkscr.ttf")
local node_config = {}
local node_i18n = {}
local node_sensors = {}

local temparature_identifier = "Temperature: "
local humidity_identifier = "Humididty: "
local dew_point_identifier = "Dew point: "

local sensors_horizontally = 1
local sensors_vertically = 1

--while WIDTH / (sensors_horizontally + 1) >= 200:
--	sensors_horizontally += 1

--while HEIGHT / (sensors_vertically + 1) >= 200:
--	sensors_vertically += 1

--sensors_per_view = w * h

util.json_watch("config.json", function(config)
	node_config = config
	font = resource.load_font(node_config.font)
	if node_i18n ~= nil then
		if node_config.language == "en" then
			temparature_identifier = node_i18n.temparature_identifier.en
			humidity_identifier = node_i18n.humidity_identifier.en
			dew_point_identifier = node_i18n.dew_point_identifier.en
		elseif node_config.language == "de" then
			temparature_identifier = node_i18n.temparature_identifier.de
			humidity_identifier = node_i18n.humidity_identifier.de
			dew_point_identifier = node_i18n.dew_point_identifier.de
		else
			-- Fallback
			temparature_identifier = node_i18n.temparature_identifier.en
			humidity_identifier = node_i18n.humidity_identifier.en
			dew_point_identifier = node_i18n.dew_point_identifier.en
		end
	else
		-- Fallback
		temparature_identifier = "Temperature: "
		humidity_identifier = "Humidity: "
		dew_point_identifier = "Dew point: "
	end
end)

util.json_watch("i18n.json", function(i18n)
	node_i18n = i18n
	if node_config ~= nil then
		if node_config.language == "en" then
			temparature_identifier = node_i18n.temparature_identifier.en
			humidity_identifier = node_i18n.humidity_identifier.en
			dew_point_identifier = node_i18n.dew_point_identifier.en
		elseif node_config.language == "de" then
			temparature_identifier = node_i18n.temparature_identifier.de
			humidity_identifier = node_i18n.humidity_identifier.de
			dew_point_identifier = node_i18n.dew_point_identifier.de
		else
			-- Fallback
			temparature_identifier = node_i18n.temparature_identifier.en
			humidity_identifier = node_i18n.humidity_identifier.en
			dew_point_identifier = node_i18n.dew_point_identifier.en
		end
	else
		-- Fallback
		temparature_identifier = "Temperature: "
		humidity_identifier = "Humidity: "
		dew_point_identifier = "Dew point: "
	end
end)

util.json_watch("sensors.json", function(sensors)
	node_sensors = sensors
end)

local function Clock()
	local formatted_time = ""
	local unix_diff = 0

	util.data_mapper{
		["clock/formatted"] = function(time)
			formatted_time = time
		end;
	}

	local function formatted()
		return formatted_time
	end

	local function unix()
		local now = sys.now()
		if now == 0 then
			return os.time()
		end
		if unix_diff == 0 then
			local ts = os.time()
			if ts > 1000000 then
				unix_diff = ts - sys.now()
			end
		end
		return now + unix_diff
	end

	return {
		formatted = formatted;
		unix = unix;
	}
end

local clock = Clock()

local function 

function node.render()
	gl.clear(node_config.bg_color.r, node_config.bg_color.g, node_config.bg_color.b, node_config.bg_color.a)
--Different Sensors

	local time_string = clock.human()
	local time_width = font:width(time_string, 100)
	local time_x = (NATIVE_WIDTH/2)-(time_width/2)
	font:write(time_x, 10, time_string, 100, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
end