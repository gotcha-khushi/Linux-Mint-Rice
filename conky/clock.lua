require 'cairo'

local function draw_right(cs, text, y, padding)
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cs, text, extents)
    local x = math.max(padding, conky_window.width - extents.x_advance - padding)
    cairo_move_to(cs, x, y)
    cairo_show_text(cs, text)
end

function conky_draw_clock()
    if conky_window == nil then return end

    local surface = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cs = cairo_create(surface)

    -- Clear background
    cairo_set_operator(cs, CAIRO_OPERATOR_CLEAR)
    cairo_paint(cs)
    cairo_set_operator(cs, CAIRO_OPERATOR_OVER)

    -- Fetch the current time string
    local hours_mins = os.date("%I:%M %p")

    -- Bitcount Grid Single display font
    cairo_select_font_face(cs, "Bitcount Grid Single Roman", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Draw Large Time (HH:MM)
    cairo_set_font_size(cs, 190)
    cairo_set_source_rgba(cs, 1.0, 1.0, 1.0, 0.40) -- Soft translucent white
    -- Position the text 15 px from the window's right edge.
    draw_right(cs, hours_mins, 215, 15)

    cairo_destroy(cs)
    cairo_surface_destroy(surface)
end
