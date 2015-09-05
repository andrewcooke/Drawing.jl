
@test_throws DrawingError draw() do 
    with() do
    end
end

@test isnull(Drawing.thread_context.context)

@test_throws DrawingError draw(Paper("foo")) do
end

@test isnull(Drawing.thread_context.context)

println("errors: ok")
