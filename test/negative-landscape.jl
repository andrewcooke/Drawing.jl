
draw(PNG("negative-landscape.png", 140, 100),
     Axes(negative=true),
     Paper("lightgrey"),
     # default Pen is 0.02.  use 0.04 here so consistent with bottom
     # left image which is twice as dark because the user coordinates
     # are half as large.
     Pen(0.04)) do
    move(0, 0)
    line(1, 0)
    move(0, 0)
    line(0, 1)
end
