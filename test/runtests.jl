
using Draw

using Base.Test

with(Paper("a4")) do
    with(Pen("red")) do
        move(0.0, 0.0)
        line(1.0, 0.0)
        line(1.0, 1.0)
        line(0.0, 1.0)
        line(0.0, 0.0)
    end
    # TODO - move into "with"
    save("foo.png")
end
