module Theme
using Gtk

const CSS_THEME = """
window {
    background-color: #3C3F41;
}

label {
    color: #BBBBBB;
    font-family: monospace;
}

label.radio-display {
    color: #FA8B01;
    background-color: #282828;
    font-size: 28px;
    font-weight: bold;
    padding: 20px;
}

button {
    background-color: #4D4D4D;
    color: #DCDCDC;
    border: 1px solid #646464;
    border-radius: 3px;
    padding: 5px 15px;
    font-family: monospace;
    font-weight: bold;
}

button:hover {
    background-color: #5A5A5A;
    border-color: #FA8B01;
}

treeview {
    background-color: #282828;
    color: #BBBBBB;
    font-family: monospace;
}

treeview:selected {
    background-color: #FA8B01;
    color: #000000;
}

label.title-display {
    color: #BBBBBB;
    font-family: monospace;
    font-size: 14px;
    font-style: italic;
    background-color: transparent;
}
    
"""

function apply_theme!()
    provider = GtkCssProvider()
    
    ccall((:gtk_css_provider_load_from_data, Gtk.libgtk),
          Bool, 
          (Ptr{GObject}, Ptr{UInt8}, Cint, Ptr{Nothing}),
          provider, CSS_THEME, -1, C_NULL)
    
    screen = ccall((:gdk_display_get_default_screen, Gtk.libgdk), 
                   Ptr{Nothing}, 
                   (Ptr{Nothing},), 
                   ccall((:gdk_display_get_default, Gtk.libgdk), Ptr{Nothing}, ()))
    
    ccall((:gtk_style_context_add_provider_for_screen, Gtk.libgtk),
          Nothing,
          (Ptr{Nothing}, Ptr{GObject}, Cuint),
          screen, provider, 800)
end

function add_css_class!(widget, class_name::String)
    ctx = ccall((:gtk_widget_get_style_context, Gtk.libgtk), Ptr{Nothing}, (Ptr{GObject},), widget)
    ccall((:gtk_style_context_add_class, Gtk.libgtk), Nothing, (Ptr{Nothing}, Cstring), ctx, class_name)
end

end # module