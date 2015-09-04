
ignore = false  # when re-generating

draw(File("defaults.png")) do
    axes()
end
ignore || compare("defaults.png")

draw(axes, File("portrait.png"), Paper(70, 100; background="lightgrey"))
ignore || compare("portrait.png")
draw(axes, File("landscape.png"), Paper(100, 70; background="lightgrey"))
ignore || compare("landscape.png")

draw(axes, File("scale.png"), Paper(70, 100; background="lightgrey"), Scale(0.5))
ignore || compare("scale.png")
draw(axes, File("scale2.png"), Paper(70, 100; background="lightgrey"), Scale(0.5, 1.0))
ignore || compare("scale2.png")
draw(axes, File("translate.png"), Paper(70, 100; background="lightgrey"), Translate(0.1, 0.1))
ignore || compare("translate.png")
draw(axes, File("rotate.png"), Paper(70, 100; background="lightgrey"), Rotate(pi/4))
ignore || compare("rotate.png")

draw(axes, File("centred_portrait.png"), Paper(70, 100; background="lightgrey", centred=true))
ignore || compare("centred_portrait.png")
draw(axes, File("centred_landscape.png"), Paper(100, 70; background="lightgrey", centred=true))
ignore || compare("centred_landscape.png")

with(File("orange_blue_square.png"), Paper(100, 100), Pen(0.05)) do
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
compare("orange_blue_square.png")

with(File("red_blue_square.png"), Paper(100, 100), Ink("red"), Pen(0.1)) do
    draw(Ink("blue")) do
        move(0.0, 0.0)
        line(1.0, 0.0)
        line(1.0, 1.0)
    end
    draw() do
        line(0.0, 1.0)
        line(0.0, 0.0)
    end
end
compare("red_blue_square.png")
