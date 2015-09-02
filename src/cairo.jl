
function has_current_point(ctx::X.CairoContext)
    ccall((:cairo_has_current_point, X._jl_libcairo), Int, (Ptr{Void},), ctx.ptr) != 0
end

# can be called if has_current_point is false (will return 0.0, 0.0)
function get_current_point(ctx::X.CairoContext)
    x = Cdouble[0]
    y = Cdouble[0]
    ccall((:cairo_get_current_point, X._jl_libcairo), Void, (Ptr{Void}, Ptr{Cdouble}, Ptr{Cdouble}), ctx.ptr, x, y)
    (x[1], y[1])
end
