module HaldCLUT

using Images
using Colors

export apply_haldclut, load_hald

function load_hald(path::String)
    return convert(Array{RGB{Float64}}, load(path))
end

function apply_haldclut(img::Array, lut_path::String)
    hald_size = size(hald, 1)
    level = round(Int, hald_size ^ (1/3))
    lut_n = level * level  # 64 pour level 8

    result = copy(img)
    h, w = size(result)

    Threads.@threads for i in 1:h
        for j in 1:w
            px = result[i, j]
            r = Float64(red(px))
            g = Float64(green(px))
            b = Float64(blue(px))

            result[i, j] = lookup_hald(hald, r, g, b, lut_n)
        end
    end

    return result
end

function lookup_hald(hald::Array, r::Float64, g::Float64, b::Float64, lut_n::Int)
    # Coordonnées dans la table
    r_scaled = r * (lut_n - 1)
    g_scaled = g * (lut_n - 1)
    b_scaled = b * (lut_n - 1)

    r0 = clamp(floor(Int, r_scaled), 0, lut_n - 2)
    g0 = clamp(floor(Int, g_scaled), 0, lut_n - 2)
    b0 = clamp(floor(Int, b_scaled), 0, lut_n - 2)

    # Fractions pour interpolation trilinéaire
    rf = r_scaled - r0
    gf = g_scaled - g0
    bf = b_scaled - b0

    # 8 coins du cube
    c000 = hald_lookup(hald, r0,   g0,   b0,   lut_n)
    c100 = hald_lookup(hald, r0+1, g0,   b0,   lut_n)
    c010 = hald_lookup(hald, r0,   g0+1, b0,   lut_n)
    c110 = hald_lookup(hald, r0+1, g0+1, b0,   lut_n)
    c001 = hald_lookup(hald, r0,   g0,   b0+1, lut_n)
    c101 = hald_lookup(hald, r0+1, g0,   b0+1, lut_n)
    c011 = hald_lookup(hald, r0,   g0+1, b0+1, lut_n)
    c111 = hald_lookup(hald, r0+1, g0+1, b0+1, lut_n)

    # Interpolation trilinéaire
    c = (1-rf)*(1-gf)*(1-bf)*c000 +
           rf *(1-gf)*(1-bf)*c100 +
        (1-rf)*   gf *(1-bf)*c010 +
           rf *   gf *(1-bf)*c110 +
        (1-rf)*(1-gf)*   bf *c001 +
           rf *(1-gf)*   bf *c101 +
        (1-rf)*   gf *   bf *c011 +
           rf *   gf *   bf *c111

    return c
end

function hald_lookup(hald::Array, ri::Int, gi::Int, bi::Int, lut_n::Int)
    # Convertir indices 3D → position 2D dans l'image HaldCLUT
    idx = ri + gi * lut_n + bi * lut_n * lut_n
    row = idx ÷ size(hald, 2) + 1
    col = idx % size(hald, 2) + 1
    return hald[row, col]
end

end