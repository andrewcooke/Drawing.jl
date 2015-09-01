
with(File("red_square.png"), Paper(100, 100), Pen("red", width=0.02)) do
    move(0.0, 0.0)
    line(1.0, 0.0)
    line(1.0, 1.0)
    with(Pen(width=0.05)) do
        line(0.0, 1.0)
        line(0.0, 0.0)
    end
end

compare("red_square.png")
