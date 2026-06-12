module GtkImageBridge

using Gtk
using Colors

export image_to_pixbuf

# Type du callback de destruction : void (*)(guchar *pixels, gpointer data)
const PixbufDestroyNotify = Ptr{Cvoid}

function image_to_pixbuf(img)
    h, w = size(img)

    rowstride = w * 3
    data = Vector{UInt8}(undef, h * rowstride)

    @inbounds for y in 1:h
        base = (y-1) * rowstride
        for x in 1:w
            px = img[y, x]
            i = base + (x-1)*3
            data[i+1] = UInt8(round(Int, clamp(Float64(red(px)),   0, 1) * 255))
            data[i+2] = UInt8(round(Int, clamp(Float64(green(px)), 0, 1) * 255))
            data[i+3] = UInt8(round(Int, clamp(Float64(blue(px)),  0, 1) * 255))
        end
    end

    # gdk_pixbuf_new_from_data(pixels, colorspace, has_alpha, bits_per_sample,
    #                          width, height, rowstride, destroy_fn, destroy_fn_data)
    pixptr = ccall((:gdk_pixbuf_new_from_data, Gtk.libgdkpixbuf),
        Ptr{Gtk.GObject},
        (Ptr{UInt8}, Cint, Cint, Cint, Cint, Cint, Cint, PixbufDestroyNotify, Ptr{Cvoid}),
        pointer(data),
        0,      # GDK_COLORSPACE_RGB
        0,      # has_alpha = false
        8,      # bits_per_sample
        w, h,
        rowstride,
        C_NULL, # destroy_fn (on garde "data" côté Julia)
        C_NULL  # destroy_fn_data
    )

    return Gtk.GdkPixbuf(pixptr), data
end

end