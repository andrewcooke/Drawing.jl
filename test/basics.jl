
ignore = false  # when re-generating

draw(axes, PNG("defaults.png", 140, 100))
ignore || compare("defaults.png")

include("portrait.jl")
ignore || compare("portrait.png")

draw(axes, PNG("landscape.png", 140, 100), Paper("lightgrey"))
ignore || compare("landscape.png")

draw(axes, PNG("scale.png", 100, 140), Paper("lightgrey"), Scale(0.5))
ignore || compare("scale.png")

draw(axes, PNG("translate.png", 100, 140), Paper("lightgrey"), Translate(0.1, 0.1))
ignore || compare("translate.png")

draw(axes, PNG("negative-portrait.png", 100, 140), Paper("lightgrey"), 
     Axes(negative=true))
ignore || compare("negative-portrait.png")

include("negative-landscape.jl")
ignore || compare("negative-landscape.png")

include("round-round.jl")
ignore || compare("round-round.png")

include("butt-mitre.jl")
ignore || compare("butt-mitre.png")

include("square-bevel.jl")
ignore || compare("square-bevel.png")

include("square.jl")
ignore || compare("square.png")

include("square-scale.jl")
ignore || compare("square-scale.png")

include("square-scale-translate.jl")
ignore || compare("square-scale-translate.png")

include("square-rotate.jl")
ignore || compare("square-rotate.png")

with(PNG("orange-blue-square.png", 100, 100), Pen(0.05)) do
    draw(Ink("orange")) do
        move(0.0, 0.0)
        line(1.0, 0.0)
        line(1.0, 1.0)
    end
    draw(Ink("blue")) do
        line(0.0, 1.0)
        line(0.0, 0.0)
    end
end
ignore || compare("orange-blue-square.png")

include("red-blue-square.jl")
ignore || compare("red-blue-square.png")
