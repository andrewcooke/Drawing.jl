
ignore = false  # when re-generating

draw(axes, PNG("defaults.png", 140, 100))
ignore || compare("defaults.png")

#draw(axes, PNG("portrait.png", 100, 140), Paper("lightgrey"))
include("portrait.jl")
ignore || compare("portrait.png")
draw(axes, PNG("landscape.png", 140, 100), Paper("lightgrey"))
ignore || compare("landscape.png")


draw(axes, PNG("scale.png", 100, 140), Paper("lightgrey"), Scale(0.5))
ignore || compare("scale.png")
#draw(axes, PNG("scale2.png", 100, 140), Paper("lightgrey"), Scale(0.5, 1.0))
#ignore || compare("scale2.png")
draw(axes, PNG("translate.png", 100, 140), Paper("lightgrey"), Translate(0.1, 0.1))
ignore || compare("translate.png")
draw(axes, PNG("rotate.png", 100, 140), Paper("lightgrey"), Rotate(45))
ignore || compare("rotate.png")

draw(axes, PNG("centred-portrait.png", 100, 140), Paper("lightgrey"), Axes(centred=true))
ignore || compare("centred-portrait.png")
#draw(axes, PNG("centred-landscape.png", 140, 100), Paper("lightgrey"), Axes(centred=true))
include("centred-landscape.jl")
ignore || compare("centred-landscape.png")

#function wiggle()
#    move(0,0)
#    line(0.005, 0)
#    line(0.005, 0.005)
#    line(0.01, 0.01)
#end

#draw(wiggle, PNG("round-round.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.2, "lightgrey"), Scale(100), Pen(0.003, cap="round", join="round"))
include("round-round.jl")
ignore || compare("round-round.png")

#draw(wiggle, PNG("butt-mitre.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.2, "lightgrey"), Scale(100), Pen(0.003, cap="butt", join="mitre"))
include("butt-mitre.jl")
ignore || compare("butt-mitre.png")

#draw(wiggle, PNG("square-bevel.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.2, "lightgrey"), Scale(100), Pen(0.003, cap="square", join="bevel"))
include("square-bevel.jl")
ignore || compare("square-bevel.png")

#function square()
#    move(0, 0)
#    line(1, 0)
#    line(1, 1)
#    line(0, 1)
#    line(0, 0)
#end

#draw(square, PNG("square.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, "lightgrey"))
include("square.jl")
ignore || compare("square.png")

#draw(square, PNG("square-scale.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, "lightgrey"), Scale(0.5))
include("square-scale.jl")
ignore || compare("square-scale.png")

#draw(square, PNG("square-scale-translate.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, "lightgrey"), Scale(0.5), Translate(1, 1))
include("square-scale-translate.jl")
ignore || compare("square-scale-translate.png")

#draw(square, PNG("square-rotate.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, "lightgrey"), Rotate(45))
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
