
with(PNG("red-blue-square.png", 100, 100), Ink("red"), Pen(0.1)) do
    draw(Ink("blue")) do
        move(0, 0)
        line(1, 0)
        line(1, 1)
    end
    draw() do
        line(0, 1)
        line(0, 0)
    end
end
