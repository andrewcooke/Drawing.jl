
with(PNG("red-square.png", 100, 100)) do
    ctx = current_context()
    @test has_current_point(ctx) == false
    move(0.5, 0.5)
    @test has_current_point(ctx) == true
    x, y = get_current_point(ctx)
    @test x == 0.5
    @test y == 0.5
end

println("cairo: ok")
