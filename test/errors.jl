
@test_throws AssertionError draw() do 
    with() do
    end
end

@test isnull(Drawing.thread_context.context)

println("errors: ok")
