
with(Paper("a4", "landscape")) do
    move(0.5, 0.5)
    draw(0.25, 0.25)
end

with(Paper("letter"), Pen("red", 0.05), Scale(100, 100)) do
    forwards(100)
    right(45)
    up()
    forwards(10)
    down()
end

with(File("drawing.ps"), Paper("a4", "landscape")) do
    move(0.5, 0.5)
    with(Pen("red")) do
        draw(0.1, 0.1)
    end
end

with(Paper("a4", orientation="landscape")) do
    move(0.5, 0.5)
    with(Pen("red")) do
        draw(0.1, 0.1)
    end
    write_to("drawing.ps")
end
