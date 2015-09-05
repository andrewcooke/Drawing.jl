
ignore = false  # when re-generating

draw(File("defaults.png")) do
    axes()
end
ignore || compare("defaults.png")

#draw(axes, File("portrait.png"), Paper(100, 140; background="lightgrey"))
include("portrait.jl")
ignore || compare("portrait.png")
draw(axes, File("landscape.png"), Paper(140, 100; background="lightgrey"))
ignore || compare("landscape.png")


draw(axes, File("scale.png"), Paper(100, 140; background="lightgrey"), Scale(0.5))
ignore || compare("scale.png")
draw(axes, File("scale2.png"), Paper(100, 140; background="lightgrey"), Scale(0.5, 1.0))
ignore || compare("scale2.png")
draw(axes, File("translate.png"), Paper(100, 140; background="lightgrey"), Translate(0.1, 0.1))
ignore || compare("translate.png")
draw(axes, File("rotate.png"), Paper(100, 140; background="lightgrey"), Rotate(pi/4))
ignore || compare("rotate.png")

draw(axes, File("centred-portrait.png"), Paper(100, 140; background="lightgrey", centred=true))
ignore || compare("centred-portrait.png")
#draw(axes, File("centred-landscape.png"), Paper(140, 100; background="lightgrey", centred=true))
include("centred-landscape.jl")
ignore || compare("centred-landscape.png")

#function wiggle()
#    move(0,0)
#    line(0.005, 0)
#    line(0.005, 0.005)
#    line(0.01, 0.01)
#end

#draw(wiggle, File("a10-round-round.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.2, background="lightgrey"), Scale(100), Pen(0.003, cap="round", join="round"))
include("a10-round-round.jl")
ignore || compare("a10-round-round.png")

#draw(wiggle, File("a10-butt-mitre.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.2, background="lightgrey"), Scale(100), Pen(0.003, cap="butt", join="mitre"))
include("a10-butt-mitre.jl")
ignore || compare("a10-butt-mitre.png")

#draw(wiggle, File("a10-square-bevel.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.2, background="lightgrey"), Scale(100), Pen(0.003, cap="square", join="bevel"))
include("a10-square-bevel.jl")
ignore || compare("a10-square-bevel.png")

#function square()
#    move(0, 0)
#    line(1, 0)
#    line(1, 1)
#    line(0, 1)
#    line(0, 0)
#end

#draw(square, File("a10-square.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, background="lightgrey"))
include("a10-square.jl")
ignore || compare("a10-square.png")

#draw(square, File("a10-square-scale.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, background="lightgrey"), Scale(0.5))
include("a10-square-scale.jl")
ignore || compare("a10-square-scale.png")

#draw(square, File("a10-square-scale-translate.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, background="lightgrey"), Scale(0.5), Translate(1, 1))
include("a10-square-scale-translate.jl")
ignore || compare("a10-square-scale-translate.png")

#draw(square, File("a10-square-rotate.png"), Paper("a10"; dpi=100, orientation="landscape", border=0.1, background="lightgrey"), Rotate(pi/4))
include("a10-square-rotate.jl")
ignore || compare("a10-square-rotate.png")

with(File("orange-blue-square.png"), Paper(100, 100), Pen(0.05)) do
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
