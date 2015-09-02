
with(File("orange_blue_square.png"), Paper(100, 100), Pen("red", width=0.05)) do
    draw(Pen("orange", width=0.05)) do
        move(0.0, 0.0)
        line(1.0, 0.0)
        line(1.0, 1.0)
    end
    draw(Pen("blue", width=0.05)) do
        line(0.0, 1.0)
        line(0.0, 0.0)
    end
end

compare("orange_blue_square.png")
