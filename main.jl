ENV["GTK_THEME"] = "Adwaita:dark"

include("src/teolay.jl")
using .teolay

teolay.main()