module Processor

using Colors
using ImageTransformations

export ProcessParams, process_image

mutable struct ProcessParams
    red::Float64
    green::Float64
    blue::Float64
    hue::Float64
    sat::Float64
    lum::Float64
    contrast::Float64
    invert::Bool
end

ProcessParams() = ProcessParams(0.0, 0.0, 0.0, 0.0, 100.0, 100.0, 100.0, false)

function process_image(img::Array, params::ProcessParams)
    result = copy(img)
    
    h, w = size(result)
    
    Threads.@threads for i in 1:h
        for j in 1:w
            px = result[i, j]
            
            r = Float64(red(px))
            g = Float64(green(px))
            b = Float64(blue(px))
            
            # RGB offset
            r = clamp(r + params.red / 255.0, 0.0, 1.0)
            g = clamp(g + params.green / 255.0, 0.0, 1.0)
            b = clamp(b + params.blue / 255.0, 0.0, 1.0)
            
            # Invert
            if params.invert
                r = 1.0 - r
                g = 1.0 - g
                b = 1.0 - b
            end
            
            # HSL
            hsl = convert(HSL, RGB(r, g, b))
            h_val = clamp(hsl.h + params.hue, 0.0, 360.0)
            s_val = clamp(hsl.s * (params.sat / 100.0), 0.0, 1.0)
            l_val = clamp(hsl.l * (params.lum / 100.0), 0.0, 1.0)
            rgb = convert(RGB, HSL(h_val, s_val, l_val))
            
            # Contrast
            r2 = clamp((Float64(rgb.r) - 0.5) * (params.contrast / 100.0) + 0.5, 0.0, 1.0)
            g2 = clamp((Float64(rgb.g) - 0.5) * (params.contrast / 100.0) + 0.5, 0.0, 1.0)
            b2 = clamp((Float64(rgb.b) - 0.5) * (params.contrast / 100.0) + 0.5, 0.0, 1.0)
            
            result[i, j] = RGB(r2, g2, b2)
        end
    end
    
    return result
end

end