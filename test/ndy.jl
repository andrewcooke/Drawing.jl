
using Drawing

p = 1.02
q = 0.9375

with(
     PNG("ndy.png", 300, 300), 
#     TK(300, 300), 
     Axes(negative=true)) do
         paint(Ink("darkgreen")) do
             square(100, align=5)
         end
         paint(Ink("red")) do
             square(2, align=5)
         end
         paint(Ink("black"), Font("Arial Black, Bold"; size=0.58)) do
             move(-q, p)
             text("NOT", align=1)
             move(0.0, 0.0)
             text("DEAD", align=5)
             move(q, -p)
             text("YET", align=9)
         end
     end

