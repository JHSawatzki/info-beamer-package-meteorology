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

local json = require "json"

local font = resource.load_font("slkscr.ttf")
local node_config = {}
local node_i18n = {}
local node_sensors = {}

local temparature_identifier = "Temperature"
local humidity_identifier = "Humidity"
local dew_point_identifier = "Dew point"
local time_identifier = "Time"
local type_identifier = "Type"
local sensor_identifier = "Sensor"
local name_identifier = "Name"

local temperature_unit = "°C"

local sensors_horizontally = 1
local sensors_vertically = 1

--while WIDTH / (sensors_horizontally + 1) >= 200:
--    sensors_horizontally += 1

--while HEIGHT / (sensors_vertically + 1) >= 200:
--    sensors_vertically += 1

--sensors_per_view = w * h

local function isBitSet(number, checkbit)
    if bit.band(number, bit.lshift(1, (checkbit - 1))) ~= 0 then
        return true
    else
        return false
    end
end

local function i18n(config)
    if next(config) ~= nil then
        if node_config.language == "en" then
            temparature_identifier = node_i18n.temparature_identifier.en
            humidity_identifier = node_i18n.humidity_identifier.en
            dew_point_identifier = node_i18n.dew_point_identifier.en
            time_identifier = node_i18n.time_identifier.en
            type_identifier = node_i18n.type_identifier.en
            sensor_identifier = node_i18n.sensor_identifier.en
            name_identifier = node_i18n.name_identifier.en
        elseif node_config.language == "de" then
            temparature_identifier = node_i18n.temparature_identifier.de
            humidity_identifier = node_i18n.humidity_identifier.de
            dew_point_identifier = node_i18n.dew_point_identifier.de
            time_identifier = node_i18n.time_identifier.de
            type_identifier = node_i18n.type_identifier.de
            sensor_identifier = node_i18n.sensor_identifier.de
            name_identifier = node_i18n.name_identifier.de
        else
            -- Fallback
            temparature_identifier = node_i18n.temparature_identifier.en
            humidity_identifier = node_i18n.humidity_identifier.en
            dew_point_identifier = node_i18n.dew_point_identifier.en
            time_identifier = node_i18n.time_identifier.en
            type_identifier = node_i18n.type_identifier.en
            sensor_identifier = node_i18n.sensor_identifier.en
            name_identifier = node_i18n.name_identifier.en
        end
    else
        -- Fallback
        temparature_identifier = "Temperature"
        humidity_identifier = "Humidity"
        dew_point_identifier = "Dew point"
        time_identifier = "Time"
        type_identifier = "Type"
        sensor_identifier = "Sensor"
        name_identifier = "Name"
    end
end

util.json_watch("config.json", function(config)
    node_config = config
    font = resource.load_font(node_config.font.asset_name)
    if node_config.temperature_unit == "celsius" then
        temperature_unit = "°C"
    elseif node_config.temperature_unit == "fahrenheit" then
        temperature_unit = "°F"
    else
        temperature_unit = "K"
    end
    i18n(node_i18n)
end)

util.json_watch("i18n.json", function(i18n_config)
    node_i18n = i18n_config
    i18n(node_config)
end)

util.json_watch("sensors.json", function(sensors)
    node_sensors = sensors
    pp(node_sensors[1].sensor_display_units)
    pp(isBitSet(node_sensors[1].sensor_display_units, 1))
    pp(isBitSet(node_sensors[1].sensor_display_units, 2))
    pp(isBitSet(node_sensors[1].sensor_display_units, 3))
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

function node.render()
    gl.clear(node_config.bg_color.r, node_config.bg_color.g, node_config.bg_color.b, node_config.bg_color.a)
--Different 

    local system_time_string = "System Time: " ..  clock.formatted()
--    local time_width = font:width(time_string, 100)
--    local time_x = (NATIVE_WIDTH/2)-(time_width/2)
    local y_gap = 10
    local font_size = 40
    local y_pos = y_gap
    font:write(20, y_pos, system_time_string, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
    y_pos = y_pos + font_size + y_gap
    if next(node_sensors) ~= nil then
        font:write(20, y_pos, "Sensor " .. name_identifier .. ": " .. node_sensors[1].sensor_title, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
        y_pos = y_pos + font_size + y_gap
        if node_config.show_sensor_types then
            font:write(20, y_pos, "Sensor " .. type_identifier .. ": " .. node_sensors[1].sensor_type, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
            y_pos = y_pos + font_size + y_gap
        end
        if node_config.show_sensor_times then
            font:write(20, y_pos, "Sensor " .. time_identifier .. ": " .. node_sensors[1].sensor_time, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
            y_pos = y_pos + font_size + y_gap
        end
        if isBitSet(node_sensors[1].sensor_display_units, 1) then
            font:write(20, y_pos, "Sensor " .. temparature_identifier .. ": " .. node_sensors[1].values.temperature .. " " .. temperature_unit, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
            y_pos = y_pos + font_size + y_gap
        end
        if isBitSet(node_sensors[1].sensor_display_units, 2) then
            font:write(20, y_pos, "Sensor " .. humidity_identifier .. ": " .. node_sensors[1].values.humidity .. " %", font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
            y_pos = y_pos + font_size + y_gap
        end
        if isBitSet(node_sensors[1].sensor_display_units, 3) then
            font:write(20, y_pos, "Sensor " .. dew_point_identifier .. ": " .. node_sensors[1].values.dew_point .. " " .. temperature_unit, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
            y_pos = y_pos + font_size + y_gap
        end
    end
end