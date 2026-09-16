require 'cairo'

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

    -- Fetch current time strings
    local hours_mins = os.date("%H:%M")
    local day_date = os.date("%A, %B %d")

    -- Select a modern clean font
    cairo_select_font_face(cs, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)

    -- Draw Large Time (HH:MM)
    cairo_set_font_size(cs, 72)
    cairo_set_source_rgba(cs, 1.0, 1.0, 1.0, 0.9) -- Semi-transparent white
    cairo_move_to(cs, 40, 90)
    cairo_show_text(cs, hours_mins)

    -- Draw Date (Day, Month Date) below the clock
    cairo_select_font_face(cs, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cs, 20)
    cairo_set_source_rgba(cs, 0.8, 0.85, 1.0, 0.75) -- Soft blue-tinted white
    cairo_move_to(cs, 45, 130)
    cairo_show_text(cs, day_date)

    cairo_destroy(cs)
    cairo_surface_destroy(surface)
end