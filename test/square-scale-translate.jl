
draw(PNG("square-scale-translate.png", 140, 100), 
     Paper("lightgrey"),
     Scale(0.5), Translate(1, 1)) do
    move(0, 0)
    square(1, align=7)
end
