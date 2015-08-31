
using Drawing

using Base.Test

with(File("foo.png"), Paper("a4"), Pen("red")) do
    move(0.0, 0.0)
    line(1.0, 0.0)
    line(1.0, 1.0)
    line(0.0, 1.0)
    line(0.0, 0.0)
end
