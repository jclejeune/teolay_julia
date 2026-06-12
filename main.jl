ENV["GTK_THEME"] = "Adwaita:dark"

using Logging

mkpath("logs")

logio = open("logs/teolay.log", "a")

global_logger(SimpleLogger(logio, Logging.Info))

@info "Démarrage Teolay"

include("src/teolay.jl")
using .teolay

try
    teolay.main()
catch e
    @error "Crash application" exception=(e, catch_backtrace())
    rethrow()
finally
    flush(logio)
    close(logio)
end