--[[
    MIT License

    Copyright (c) 2020-2025, Jan Henrik Sawatzki

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

local temperature_unit_identifier = "°C"

local margin = 10
local font_size = 40
local header_height = 2 * margin + font_size
local line_spacing = 10
local sensor_tile_width_init = 500
local sensor_tile_height_init = 300
local sensor_tile_width = sensor_tile_width_init
local sensor_tile_height = sensor_tile_height_init

local calc_width = WIDTH - (2 * margin)
local calc_height = HEIGHT - (2 * margin) - header_height

local sensors_horizontally = 1
local sensors_vertically = 1
local sensors_per_page_hw = sensors_horizontally * sensors_vertically
local sensors_horizontally_loop = 1
local sensors_vertically_loop = 1
local current_page = 1
local sensor_pages = 1
local sensors_per_page = sensors_horizontally * sensors_vertically
local view = 1

local logo = resource.load_image{
    file = "package.png";
    mipmap = true;
    nearest = true;
}

local function isBitSet(number, checkbit)
    if bit.band(number, bit.lshift(1, (checkbit - 1))) ~= 0 then
        return true
    else
        return false
    end
end

local function length(t)
   local count = 0
   for _ in pairs(t) do
      count = count + 1
   end
   return count
end

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

local last_page_change = clock.unix()

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
            page_identifier = node_i18n.page_identifier.en
        elseif node_config.language == "de" then
            temparature_identifier = node_i18n.temparature_identifier.de
            humidity_identifier = node_i18n.humidity_identifier.de
            dew_point_identifier = node_i18n.dew_point_identifier.de
            time_identifier = node_i18n.time_identifier.de
            type_identifier = node_i18n.type_identifier.de
            sensor_identifier = node_i18n.sensor_identifier.de
            name_identifier = node_i18n.name_identifier.de
            page_identifier = node_i18n.page_identifier.de
        else
            -- Fallback
            temparature_identifier = node_i18n.temparature_identifier.en
            humidity_identifier = node_i18n.humidity_identifier.en
            dew_point_identifier = node_i18n.dew_point_identifier.en
            time_identifier = node_i18n.time_identifier.en
            type_identifier = node_i18n.type_identifier.en
            sensor_identifier = node_i18n.sensor_identifier.en
            name_identifier = node_i18n.name_identifier.en
            page_identifier = node_i18n.page_identifier.en
        end
    else
        -- Fallback
        temparature_identifier = "Temperature"
        humidity_identifier = "Humidity"
        dew_point_identifier = "Dew point"
        time_identifier = "Date / Time"
        type_identifier = "Type"
        sensor_identifier = "Sensor"
        name_identifier = "Name"
        page_identifier = "Page"
    end
end

util.json_watch("config.json", function(config)
    -- Configuration changed
    node_config = config
    font = resource.load_font(node_config.font.asset_name)
    if node_config.temperature_unit == "celsius" then
        temperature_unit_identifier = "°C"
    elseif node_config.temperature_unit == "fahrenheit" then
        temperature_unit_identifier = "°F"
    else
        temperature_unit_identifier = "K"
    end

    sensors_horizontally = 1
    calc_width = WIDTH - (2 * margin)
    while calc_width / (sensors_horizontally + 1) >= sensor_tile_width_init do
        sensors_horizontally = sensors_horizontally + 1
    end

    sensors_vertically = 1
    calc_height = HEIGHT - (2 * margin) - header_height
    while HEIGHT / (sensors_vertically + 1) >= sensor_tile_height_init do
        sensors_vertically = sensors_vertically + 1
    end

    sensors_per_page_hw = sensors_horizontally * sensors_vertically
    sensors_per_page = math.min(sensors_per_page_hw, node_config.sensors_per_page)
    if node_config.sensors_per_page < sensors_per_page_hw then
        squared_sensors_per_slot = math.ceil(math.sqrt(node_config.sensors_per_page))
        while sensors_horizontally > squared_sensors_per_slot do
            if (sensors_horizontally - 1) * sensors_vertically >= node_config.sensors_per_page then
                sensors_horizontally = sensors_horizontally - 1
            else
                break
            end
        end
        while sensors_vertically > squared_sensors_per_slot do
            if (sensors_vertically - 1) * sensors_horizontally >= node_config.sensors_per_page then
                sensors_vertically = sensors_vertically - 1
            else
                break
            end
        end
    end
    sensor_tile_width = sensor_tile_width_init + ((calc_width - (sensors_horizontally * sensor_tile_width_init)) / sensors_horizontally)
    sensor_tile_height = sensor_tile_height_init + ((calc_height - (sensors_vertically * sensor_tile_height_init)) / sensors_vertically)
    i18n(node_i18n)
end)

util.json_watch("i18n.json", function(i18n_config)
    node_i18n = i18n_config
    i18n(node_config)
end)

util.json_watch("sensors.json", function(sensors)
    node_sensors = sensors

    -- Check if pages to be displayed changed (depends on sensor count and how many sensors should/can be displayed on screen)
    local sensor_pages_new = math.ceil(length(node_sensors) / sensors_per_page)
    if sensor_pages_new ~= sensor_pages then
        sensor_pages = sensor_pages_new
        current_page = 1
        last_page_change = clock.unix()
    end

    -- Change page
    if clock.unix() - last_page_change > node_config.page_rate then
        if current_page < sensor_pages then
            current_page = current_page + 1
        else
            current_page = 1
        end
        if view < 4 then
            view = view + 1
        else
            view = 1
        end
        last_page_change = clock.unix()
    end
    -- TODO: Calculate optimal space for each sensor
end)

function node.render()
    gl.clear(node_config.bg_color.r, node_config.bg_color.g, node_config.bg_color.b, node_config.bg_color.a)

    local x_pos = margin
    local y_pos = margin

    util.draw_correct(logo, x_pos, y_pos, 50, 50)

    local header_text = time_identifier .. ": " ..  clock.formatted() .. "  --  " .. page_identifier .. " " .. current_page .. "/" .. sensor_pages
    local text_width = font:width(header_text, font_size)
    local x_pos = x_pos + (calc_width / 2) - (text_width / 2)
    if x_pos < margin then
        x_pos = margin
    end
    font:write(x_pos, y_pos, header_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
    x_pos = margin
    y_pos = margin + header_height

    local starting_sensor_index = (current_page - 1) * sensors_per_page + 1
    local i, node_sensor = next(node_sensors, nil) -- Get first sensor

    while i do
        if i < starting_sensor_index then
            -- Get next sensor
            i, node_sensor = next(node_sensors, i)
        else
            break
        end
    end

    sensors_vertically_loop = sensors_vertically
    while sensors_vertically_loop >= 1 do
        sensors_horizontally_loop = sensors_horizontally
        while sensors_horizontally_loop >= 1 do
            if i then
                -- Sensor available, display
                x_pos = margin + (sensors_horizontally - sensors_horizontally_loop) * sensor_tile_width
                y_pos = margin + header_height + (sensors_vertically - sensors_vertically_loop) * sensor_tile_height
                -- center vertically and horizontally
                -- local sensor_header_text = sensor_identifier .. ": " .. node_sensor.sensor_title
                local sensor_header_text = node_sensor.sensor_title
                local sensor_type_text = ""
                local sensor_time_text = ""
                local sensor_temperature_text = ""
                local sensor_humidity_text = ""
                local sensor_dew_point_text = ""

                text_width = font:width(sensor_header_text, font_size)
                local max_width = text_width
                local actual_height = font_size + line_spacing
                if view == 1 then
                    if node_config.show_sensor_types then
                        sensor_type_text = type_identifier .. ": " .. node_sensor.sensor_type
                        text_width = font:width(sensor_type_text, font_size)
                        if text_width > max_width then
                            max_width = text_width
                        end
                        actual_height = actual_height + font_size + line_spacing
                    end
                    if node_config.show_sensor_times then
                        sensor_time_text = time_identifier .. ": " .. node_sensor.sensor_time
                        text_width = font:width(sensor_time_text, font_size)
                        if text_width > max_width then
                            max_width = text_width
                        end
                        actual_height = actual_height + font_size + line_spacing
                    end
                    if isBitSet(node_sensor.sensor_display_units, 1) then
                        sensor_temperature_text = temparature_identifier .. ": " .. node_sensor.values.temperature .. " " .. temperature_unit_identifier
                        text_width = font:width(sensor_temperature_text, font_size)
                        if text_width > max_width then
                            max_width = text_width
                        end
                        actual_height = actual_height + font_size + line_spacing
                    end
                    if isBitSet(node_sensor.sensor_display_units, 2) then
                        sensor_humidity_text = humidity_identifier .. ": " .. node_sensor.values.humidity .. " %"
                        text_width = font:width(sensor_humidity_text, font_size)
                        if text_width > max_width then
                            max_width = text_width
                        end
                        actual_height = actual_height + font_size + line_spacing
                    end
                    if isBitSet(node_sensor.sensor_display_units, 3) then
                        sensor_dew_point_text = dew_point_identifier .. ": " .. node_sensor.values.dew_point .. " " .. temperature_unit_identifier
                        text_width = font:width(sensor_dew_point_text, font_size)
                        if text_width > max_width then
                            max_width = text_width
                        end
                        actual_height = actual_height + font_size + line_spacing
                    end
                end
                -- TODO: If sensor count is uneven for this page, then use the whole screen to display
                x_pos = x_pos + (sensor_tile_width / 2) - (max_width / 2)
                y_pos = y_pos + (sensor_tile_height / 2) - (actual_height / 2)
                if x_pos < margin + (sensors_horizontally - sensors_horizontally_loop) * sensor_tile_width then
                    x_pos = margin + (sensors_horizontally - sensors_horizontally_loop) * sensor_tile_width
                end
                if y_pos < margin + header_height + (sensors_vertically - sensors_vertically_loop) * sensor_tile_height then
                    y_pos = margin + header_height + (sensors_vertically - sensors_vertically_loop) * sensor_tile_height
                end

                font:write(x_pos, y_pos, sensor_header_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
                y_pos = y_pos + font_size + line_spacing
                if view == 1 then
                    if node_config.show_sensor_types then
                        font:write(x_pos, y_pos, sensor_type_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
                        y_pos = y_pos + font_size + line_spacing
                    end
                    if node_config.show_sensor_times then
                        font:write(x_pos, y_pos, sensor_time_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
                        y_pos = y_pos + font_size + line_spacing
                    end
                    if isBitSet(node_sensor.sensor_display_units, 1) then
                        font:write(x_pos, y_pos, sensor_temperature_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
                        y_pos = y_pos + font_size + line_spacing
                    end
                    if isBitSet(node_sensor.sensor_display_units, 2) then
                        font:write(x_pos, y_pos, sensor_humidity_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
                        y_pos = y_pos + font_size + line_spacing
                    end
                    if isBitSet(node_sensor.sensor_display_units, 3) then
                        font:write(x_pos, y_pos, sensor_dew_point_text, font_size, node_config.font_color.r, node_config.font_color.g, node_config.font_color.b, node_config.font_color.a)
                        y_pos = y_pos + font_size + line_spacing
                    end
                elseif view == 2 then 
                    local sensor_history = resource.load_image{
                        file = os.getenv("SCRATCH") .. "/sensor-data-" .. node_sensor.sensor_hash .. "-daily.png";
                    }
                    if sensor_history ~= nil then
                        util.draw_correct(sensor_history, x_pos, y_pos, 470, 240)
                    end
                elseif view == 3 then
                    local sensor_history = resource.load_image{
                        file = os.getenv("SCRATCH") .. "/sensor-data-" .. node_sensor.sensor_hash .. "-monthly.png"
                    }
                    if sensor_history ~= nil then
                        util.draw_correct(sensor_history, x_pos, y_pos, 470, 240)
                    end
                elseif view == 4 then
                    local sensor_history = resource.load_image{
                        file = os.getenv("SCRATCH") .. "/sensor-data-" .. node_sensor.sensor_hash .. "-yearly.png"
                    }
                    if sensor_history ~= nil then
                        util.draw_correct(sensor_history, x_pos, y_pos, 470, 240)
                    end
                end
                -- Get next sensor
                i, node_sensor = next(node_sensors, i)
            else
                -- No further sensor available
                break
            end
            -- No further sensor available
            if not i then break end
            sensors_horizontally_loop = sensors_horizontally_loop - 1
        end
        -- No further sensor available
        if not i then break end
        sensors_vertically_loop = sensors_vertically_loop - 1
    end
end