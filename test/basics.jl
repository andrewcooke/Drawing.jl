
function axes()
    move(0,0)
    line(1,0)
    move(0,0)
    line(0,1)
end

draw(axes, File("portrait.png"), Paper(70, 100; background="lightgrey"))
compare("portrait.png")
draw(axes, File("landscape.png"), Paper(100, 70; background="lightgrey"))
compare("landscape.png")

draw(axes, File("scale.png"), Paper(70, 100; background="lightgrey"), Scale(0.5))
compare("scale.png")
draw(axes, File("scale2.png"), Paper(70, 100; background="lightgrey"), Scale(0.5, 1.0))
compare("scale2.png")
draw(axes, File("translate.png"), Paper(70, 100; background="lightgrey"), Translate(0.1, 0.1))
compare("translate.png")
draw(axes, File("rotate.png"), Paper(70, 100; background="lightgrey"), Rotate(pi/4))
compare("rotate.png")

draw(axes, File("centred_portrait.png"), Paper(70, 100; background="lightgrey", centred=true))
compare("centred_portrait.png")
draw(axes, File("centred_landscape.png"), Paper(100, 70; background="lightgrey", centred=true))
compare("centred_landscape.png")

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
