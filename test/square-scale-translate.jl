
draw(PNG("square-scale-translate.png", 140, 100), 
     Paper("lightgrey"),
     Scale(0.5), Translate(1, 1)) do
    move(0, 0)
    line(1, 0)
    line(1, 1)
    line(0, 1)
    line(0, 0)
end
