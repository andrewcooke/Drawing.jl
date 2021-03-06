
# isometric projection
to_2d(x, y, z) = (y-x)*sqrt(3)/2, z-(x+y)/2

# number of blocks along one side of square base
const N = 20

# (x,y) of uppermost corner of each tower's base "diamond", from the 
# back to the front (and left to right).
function roots()
    Task() do
        for sum in 0:2N-1
            x0 = min(sum, N-1)
            y0 = max(0, sum-N+1)
            for col in 0:(x0-y0)
                x = x0-col
                y = y0+col
                produce(x, y)
            end
        end
    end
end

# the "outline" of a tower (for filling)
function column_outline(x, y, z)
    move(to_2d(x+1, y, 0)...)
    line(to_2d(x+1, y+1, 0)...)
    line(to_2d(x, y+1, 0)...)
    line(to_2d(x, y+1, z)...)
    line(to_2d(x, y, z)...)
    line(to_2d(x+1, y, z)...)
    line(to_2d(x+1, y, 0)...)
end
     
# the outline extended with a "Y" (for stroking)
function column(x, y, z)
    column_outline(x, y, z)
    move(to_2d(x+1, y, z)...)
    line(to_2d(x+1, y+1, z)...)
    line(to_2d(x, y+1, z)...)
    move(to_2d(x+1, y+1, z)...)
    line(to_2d(x+1, y+1, 0)...)
end

# put it all together
with(PNG("towers.png", 300, 150), Axes(centred=true), 
Ink("black"), Pen(0.03), Translate(0, 1), Scale(2.4/N)) do
    for (x, y) in roots()
        d = sqrt((x/N-1/2)^2 + (y/N-1/2)^2)
        z = max(0, cos(d * pi * 0.9) * N * 0.5 * rand())
        if z > 1
            paint(Ink("white")) do
                column_outline(x,y,z)
            end
            draw() do
                column(x,y,z)
            end
        end
    end
end

println("towers: ok")
