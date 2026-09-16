require 'cairo'

-- Generate a sparse field of dots across the canvas.
local dots = {}
math.randomseed(os.time())

local function create_dots(width, height)
    for i = 1, 40 do
        table.insert(dots, {
            x = math.random(40, width - 40),
            y = math.random(40, height - 40),
            radius = math.random(3, 7),
            speed_x = math.random(3, 12) / 20,
            speed_y = math.random(3, 12) / 20,
            dir_x = math.random() > 0.5 and 1 or -1,
            dir_y = math.random() > 0.5 and 1 or -1,
        })
    end
end

function conky_draw_dots()
    if conky_window == nil then return end

    local surface = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cs = cairo_create(surface)
    local padding = 25

    -- Initialise from the real window dimensions so the whole enlarged area is used.
    if #dots == 0 then
        create_dots(conky_window.width, conky_window.height)
    end

    -- Clear window canvas with full transparency
    cairo_set_operator(cs, CAIRO_OPERATOR_CLEAR)
    cairo_paint(cs)
    cairo_set_operator(cs, CAIRO_OPERATOR_OVER)

    for i, d in ipairs(dots) do
        -- Update position along X and Y axes
        d.x = d.x + (d.speed_x * d.dir_x)
        d.y = d.y + (d.speed_y * d.dir_y)

        -- Bounce off horizontal boundaries
        if d.x <= padding or d.x >= conky_window.width - padding then
            d.dir_x = d.dir_x * -1
        end

        -- Bounce off vertical boundaries
        if d.y <= padding or d.y >= conky_window.height - padding then
            d.dir_y = d.dir_y * -1
        end

        -- Render semi-transparent glowing white dot
        cairo_arc(cs, d.x, d.y, d.radius, 0, 2 * math.pi)
        cairo_set_source_rgba(cs, 1.0, 1.0, 1.0, 0.75)
        cairo_fill(cs)
    end

    cairo_destroy(cs)
    cairo_surface_destroy(surface)
end
