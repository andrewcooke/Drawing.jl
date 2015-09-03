
function square()
    move(0,0)
    line(0,1)
    line(1,1)
    line(1,0)
    line(0,0)
end

draw(square, File("portrait.png"), Paper(70, 100))
compare("portrait.png")
draw(square, File("landscape.png"), Paper(100, 70))
compare("landscape.png")

draw(square, File("scale.png"), Paper(70, 100), Scale(0.75))
compare("scale.png")
draw(square, File("scale2.png"), Paper(70, 100), Scale(0.75, 1.25))
compare("scale2.png")
draw(square, File("translate.png"), Paper(70, 100), Translate(0.1, 0.1))
compare("translate.png")
draw(square, File("rotate.png"), Paper(70, 100), Rotate(pi/4))
compare("rotate.png")

function centred_square()
    move(-1,-1)
    line(-1,1)
    line(1,1)
    line(1,-1)
    line(-1,-1)
end

draw(centred_square, File("centred_portrait.png"), Paper(70, 100; centred=true))
compare("centred_portrait.png")
draw(centred_square, File("centred_landscape.png"), Paper(100, 70; centred=true))
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
