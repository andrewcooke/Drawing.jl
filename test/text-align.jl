
using Drawing

d = 0.05
k = 2

with(
     PNG("text-align.png", 300, 150), 
#     TK(300, 150), 
     Axes(centred=true, scale=0.5)) do
    for align in 1:9
        x = k * ((align + 2) % 3 - 1) / 2
        y = (1 - round((align - 2) / 3)) / 2
        draw(Pen(0.03), Ink("orange")) do
            move(x-d, y)
            line(x+d, y)
            move(x, y-d)
            line(x, y+d)
            move(x, y)
        end
        paint(Font(size=0.2)) do
            text("align=$(align)"; align=align)
        end
    end
end
