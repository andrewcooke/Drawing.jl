
@test_throws DrawingError draw() do 
    with() do
    end
end
@test Drawing.thread_context.context == nothing

@test_throws DrawingError draw(Paper("foo")) do
end
@test Drawing.thread_context.context == nothing

# todo - test output but no paper
# todo - test paper but no output
# todo - test state no output or paper
# todo - test multiple paper
# todo - test multiple output

println("errors: ok")
