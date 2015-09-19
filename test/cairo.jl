
with(PNG("red-square.png", 100, 100)) do
    ctx = current_context()
    move(0.5, 0.5)
    @test Drawing.has_current_point(ctx) == true
    x, y = Drawing.get_current_point(ctx)
    @test x == 0.5
    @test y == 0.5
end

println("cairo: ok")
