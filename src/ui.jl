module UI

using Gtk

include("theme.jl")
using .Theme

include("processor.jl")
using .Processor
include("image_engine.jl")
using .ImageEngine

include("gtk_image_bridge.jl")
using .GtkImageBridge
export run_ui

const preview_pix = Ref{Union{Nothing,Tuple{Gtk.GdkPixbuf,Vector{UInt8}}}}(nothing)

const image_data = Ref{Union{ImageEngine.ImageData,Nothing}}(nothing)
const params = Ref{ProcessParams}(ProcessParams())
const preview_buf = Ref{Union{Array,Nothing}}(nothing)

const last_draw_time = Ref{Float64}(0.0)
const THROTTLE_MS = 50.0

function create_window()
    Theme.apply_theme!()

    win = GtkWindow("Teolay", 900, 700)

    hbox = GtkBox(:h)
    set_gtk_property!(hbox, :spacing, 5)
    push!(win, hbox)

    img_widget = GtkImage()
    set_gtk_property!(img_widget, :hexpand, true)
    set_gtk_property!(img_widget, :vexpand, true)
    push!(hbox, img_widget)

    panel = GtkBox(:v)
    set_gtk_property!(panel, :spacing, 8)
    set_gtk_property!(panel, :margin, 10)
    set_gtk_property!(panel, :width_request, 220)
    push!(hbox, panel)

    push!(panel, GtkLabel("Settings"))

    sliders = Dict{String,GtkScale}()

    function add_slider(label::String, min::Float64, max::Float64, val::Float64)
        lbl = GtkLabel(label)
        Theme.add_css_class!(lbl, "title-display")
        push!(panel, lbl)
        sl = GtkScale(false, min, max, 1.0)
        set_gtk_property!(GtkAdjustment(sl), :value, val)
        push!(panel, sl)
        sliders[label] = sl
        return sl
    end

    add_slider("Red",      -255.0, 255.0,   0.0)
    add_slider("Green",    -255.0, 255.0,   0.0)
    add_slider("Blue",     -255.0, 255.0,   0.0)
    add_slider("Hue",      -180.0, 180.0,   0.0)
    add_slider("Sat",         0.0, 400.0, 100.0)
    add_slider("Lum",         0.0, 200.0, 100.0)
    add_slider("Contrast",    0.0, 200.0, 100.0)
    add_slider("Invert",      0.0,   1.0,   0.0)

    btn_box = GtkBox(:h)
    set_gtk_property!(btn_box, :spacing, 5)
    push!(panel, btn_box)

    btn_open  = GtkButton("Open")
    btn_reset = GtkButton("Reset")
    push!(btn_box, btn_open)
    push!(btn_box, btn_reset)

    function trigger_draw()
        now = time() * 1000.0
        if now - last_draw_time[] < THROTTLE_MS
            return
        end
        last_draw_time[] = now

        if image_data[] === nothing
            return
        end

        p = params[]
        processed = Processor.process_image(ImageEngine.get_preview(image_data[]), p)
        pix, data = GtkImageBridge.image_to_pixbuf(processed)
        preview_pix[] = (pix, data)  # garde data vivant

        Gtk.g_idle_add() do
            try
                set_gtk_property!(img_widget, :pixbuf, pix)
            catch e
                @warn "Erreur set pixbuf" exception=(e, catch_backtrace())
            end
            return false
        end
        return nothing
    end

    get_value(sl::GtkScale) = get_gtk_property(GtkAdjustment(sl), :value, Float64)

    function update_params()
        p = params[]
        p.red      = get_value(sliders["Red"])
        p.green    = get_value(sliders["Green"])
        p.blue     = get_value(sliders["Blue"])
        p.hue      = get_value(sliders["Hue"])
        p.sat      = get_value(sliders["Sat"])
        p.lum      = get_value(sliders["Lum"])
        p.contrast = get_value(sliders["Contrast"])
        p.invert   = get_value(sliders["Invert"]) >= 0.5
        trigger_draw()
        return nothing
    end

    for (_, sl) in sliders
        signal_connect(sl, "value-changed") do _
            update_params()
        end
    end

    signal_connect(btn_open, "clicked") do _
        dialog = GtkFileChooserDialog(
            "Ouvrir une image", win,
            Gtk.GConstants.GtkFileChooserAction.OPEN,
            (("Annuler", 0), ("Ouvrir", 1))
        )
        filter = GtkFileFilter()
        ccall((:gtk_file_filter_set_name, Gtk.libgtk), Nothing,
            (Ptr{Gtk.GObject}, Cstring), filter, "Images")
        ccall((:gtk_file_filter_add_mime_type, Gtk.libgtk), Nothing,
            (Ptr{Gtk.GObject}, Cstring), filter, "image/*")
        ccall((:gtk_file_chooser_add_filter, Gtk.libgtk), Nothing,
            (Ptr{Gtk.GObject}, Ptr{Gtk.GObject}), dialog, filter)

        if run(dialog) == 1
            path = unsafe_string(Gtk.GAccessor.filename(Gtk.GtkFileChooser(dialog)))
            try
                image_data[] = ImageEngine.load_image(path)
                params[] = ProcessParams()
                trigger_draw()
                println("Image chargée : $path")
            catch e
                println("Erreur chargement : $e")
            end
        end
        destroy(dialog)
        return nothing
    end

    signal_connect(btn_reset, "clicked") do _
        Gtk.g_idle_add() do
            params[] = ProcessParams()
            defaults = Dict(
                "Red" => 0.0, "Green" => 0.0, "Blue" => 0.0,
                "Hue" => 0.0, "Sat" => 100.0, "Lum" => 100.0,
                "Contrast" => 100.0, "Invert" => 0.0
            )
            for (name, sl) in sliders
                set_gtk_property!(GtkAdjustment(sl), :value, defaults[name])
            end
            trigger_draw()
            return false
        end
        return nothing
    end

    signal_connect(win, "delete-event") do widget, event
        try AudioEngine.stop_playback() catch end
        return false
    end

    signal_connect(win, :destroy) do _
        return nothing
    end

    return win
end

function run_ui()
    win = create_window()
    showall(win)

    if !isinteractive()
        c = Condition()
        signal_connect(win, :destroy) do _
            notify(c)
        end
        wait(c)
    end
end

end