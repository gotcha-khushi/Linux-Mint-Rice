require 'cairo'

local dots = {}
math.randomseed(os.time())

local function create_dots(width, height)
    for i = 1, 40 do
        local radius = math.random(3, 7)
        table.insert(dots, {
            x = math.random(0 + radius, width - 0 - radius),
            y = math.random(0 + radius, height - 0 - radius),
            radius = radius,
            speed_x = math.random(3, 12) / 20,
            speed_y = math.random(3, 12) / 20,
            dir_x = math.random() > 0.5 and 1 or -1,
            dir_y = math.random() > 0.5 and 1 or -1,
        })
    end
end

function conky_draw_dots()
    if conky_window == nil then return end

    local width = conky_window.width
    local height = conky_window.height
    if width == nil or height == nil or width <= 0 or height <= 0 then return end

    local surface = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        width,
        height
    )
    local cs = cairo_create(surface)
    local margin = 0

    if #dots == 0 then
        create_dots(width, height)
    end

    cairo_set_operator(cs, CAIRO_OPERATOR_CLEAR)
    cairo_paint(cs)
    cairo_set_operator(cs, CAIRO_OPERATOR_OVER)

    for i, d in ipairs(dots) do
        d.x = d.x + (d.speed_x * d.dir_x)
        d.y = d.y + (d.speed_y * d.dir_y)
        local edge = margin + d.radius

        if d.x <= edge or d.x >= (width - edge) then
            d.dir_x = d.dir_x * -1
        end

        if d.y <= edge or d.y >= (height - edge) then
            d.dir_y = d.dir_y * -1
        end

        d.x = math.max(edge, math.min(width - edge, d.x))
        d.y = math.max(edge, math.min(height - edge, d.y))

        cairo_arc(cs, d.x, d.y, d.radius, 0, 2 * math.pi)
        cairo_set_source_rgba(cs, 1.0, 1.0, 1.0, 0.75)
        cairo_fill(cs)
    end

    cairo_destroy(cs)
    cairo_surface_destroy(surface)
end