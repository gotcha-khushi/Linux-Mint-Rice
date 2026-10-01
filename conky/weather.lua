require 'cairo'

local weather = {
    last_updated = 0,
    temperature = '--°C',
    condition = 'Weather unavailable',
    humidity = '--%',
    precipitation = '--',
    aqi = '--',
}

local location = {
    last_updated = 0,
    latitude = nil,
    longitude = nil,
}

local function run_command(command)
    local handle = io.popen(command)
    if handle == nil then return nil end
    local result = handle:read('*a')
    handle:close()
    return result
end

local function update_weather()
    if os.time() - weather.last_updated < 900 then return end
    weather.last_updated = os.time()

    -- Fetch IP coordinates via ip-api (prevents 403 blocks)
    if location.latitude == nil or os.time() - location.last_updated > 86400 then
        local geo = run_command("curl -fsSL --max-time 8 'http://ip-api.com/json/' 2>/dev/null")
        if geo then
            location.latitude = geo:match('"lat"%s*:%s*([%-%d%.]+)')
            location.longitude = geo:match('"lon"%s*:%s*([%-%d%.]+)')
            location.last_updated = os.time()
        end
    end

    if location.latitude == nil or location.longitude == nil then return end

    local weather_api = string.format(
        "curl -fsSL --max-time 8 'https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,relative_humidity_2m,precipitation,weather_code' 2>/dev/null",
        location.latitude,
        location.longitude
    )
    local result = run_command(weather_api)
    if result then
        local temperature = tonumber(result:match('"temperature_2m"%s*:%s*([%-%d%.]+)'))
        local humidity = tonumber(result:match('"relative_humidity_2m"%s*:%s*([%-%d%.]+)'))
        local precipitation = tonumber(result:match('"precipitation"%s*:%s*([%-%d%.]+)'))
        local weather_code = tonumber(result:match('"weather_code"%s*:%s*(%d+)'))

        if temperature then weather.temperature = string.format('%.0f°C', temperature) end
        if humidity then weather.humidity = string.format('%.0f%%', humidity) end
        if precipitation then weather.precipitation = string.format('%.1f mm', precipitation) end

        local conditions = {
            [0] = 'Clear', [1] = 'Mainly clear', [2] = 'Partly cloudy', [3] = 'Overcast',
            [45] = 'Fog', [48] = 'Rime fog', [51] = 'Light drizzle', [53] = 'Drizzle',
            [55] = 'Heavy drizzle', [61] = 'Light rain', [63] = 'Rain', [65] = 'Heavy rain',
            [71] = 'Light snow', [73] = 'Snow', [75] = 'Heavy snow', [80] = 'Rain showers',
            [81] = 'Rain showers', [82] = 'Heavy showers', [95] = 'Thunderstorm',
        }
        if weather_code and conditions[weather_code] then
            weather.condition = conditions[weather_code]
        end
    end

    local air_api = string.format(
        "curl -fsSL --max-time 8 'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=%s&longitude=%s&current=us_aqi' 2>/dev/null",
        location.latitude,
        location.longitude
    )
    local air_quality = run_command(air_api)
    if air_quality then
        local aqi = tonumber(air_quality:match('"us_aqi"%s*:%s*([%d%.]+)'))
        if aqi then weather.aqi = string.format('%.0f', aqi) end
    end
end

local function draw_single_line_fit(cs, text, y, padding)
    local extents = {}
    cairo_text_extents(cs, text, extents)
    local advance = extents.x_advance or 1
    if advance <= 0 then advance = 1 end

    local available_width = conky_window.width - (padding * 2)
    local scale_x = math.min(1, available_width / advance)

    cairo_save(cs)
    -- Align text to the left margin inside padding, then scale horizontally
    cairo_translate(cs, padding, 0)
    cairo_scale(cs, scale_x, 1)
    cairo_move_to(cs, 0, y)
    cairo_show_text(cs, text)
    cairo_restore(cs)
end

-- Intentionally left as a compatibility stub. The active weather widget now uses
-- a direct ${execpi ...} text output in weather.conf for reliable visibility.
function draw_weather()
end

function conky_draw_weather()
end