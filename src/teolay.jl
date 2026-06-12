module teolay

include("theme.jl")
include("ui.jl")
using .UI

function main()
    println("Teolay démarre")
    UI.run_ui()
end

end