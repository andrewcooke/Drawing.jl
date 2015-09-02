
with(File(...), Paper(...), Ink(...), Pen(...)) do
    draw(Ink("red")) do
        move(...)
        line(...)
        line(...)
        arc(...)
    end
    paint(Ink("blue")) do
        line(...)
        line(...)
        start()
    end
end
