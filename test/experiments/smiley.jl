
using Drawing

with(Axes(centred=true), Pen(0.2)) do
    paint(Ink("yellow")) do
        circle(1)           # face background, painted yellow
    end
    draw() do
        circle(1)           # face outline, drawn black (default)
        circle(0.5; from=200deg, to=340deg)    # smile
    end
    paint() do
        move(0.3, 0.25)     # right eye position
        circle(0.2)         # paint eye
        move(-0.3, 0.25)    # left eye position
        circle(0.2)         # paint eye
    end
end
