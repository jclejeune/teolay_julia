module ImageEngine

using FileIO
using Images
using ImageTransformations

export load_image, get_preview, image_to_cairo_surface

const PREVIEW_WIDTH = 800

mutable struct ImageData
    original::Array
    preview::Array
end

function load_image(path::String)
    img = load(path)
    img_rgb = convert(Array{RGB{Float64}}, img)
    preview = make_preview(img_rgb)
    return ImageData(img_rgb, preview)
end

function make_preview(img::Array)
    h, w = size(img)
    ratio = h / w
    pw = PREVIEW_WIDTH
    ph = floor(Int, pw * ratio)
    return imresize(img, (ph, pw))
end

function get_preview(data::ImageData)
    return data.preview
end

function image_to_cairo_surface(img::Array)
    h, w = size(img)
    buf[i, j] = (UInt32(0xFF) << 24) | (r << 16) | (g << 8) | b
        
    Threads.@threads for i in 1:h
        for j in 1:w
            px = img[i, j]
            r = round(UInt32, clamp(Float64(red(px)), 0.0, 1.0) * 255)
            g = round(UInt32, clamp(Float64(green(px)), 0.0, 1.0) * 255)
            b = round(UInt32, clamp(Float64(blue(px)), 0.0, 1.0) * 255)
            buf[i, j] = (r << 16) | (g << 8) | b
        end
    end
    
    return buf, w, h
end

end