
# at some point these should be a pull request for Cairo.jl
# WARNING: verbs have been moved to the front of function names

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

function get_font_map_default()
    ccall((:pango_cairo_font_map_get_default, X._jl_libpangocairo), Ptr{Void}, ())
end

# this assumes the underlying structs that are pointed to are
# persistent which seems to be implied by the api.  so we copy the
# array of pointers (maybe that could be avoied by calling
# pointer_to_array with true)
function list_font_map_families(fm)
    pff = Ptr{Ptr{Void}}[0]
    pn = Cint[0]
    ccall((:pango_font_map_list_families, X._jl_libpango), Void, (Ptr{Void}, Ptr{Ptr{Ptr{Void}}}, Ptr{Cint}), fm, pff, pn)
    a = pointer_to_array(pff[1], (pn[1],), false)
    ff = copy(a)
    Libc.free(pff[1])
    ff
end

function get_font_family_name(ff)
    bytestring(ccall((:pango_font_family_get_name, X._jl_libpango), Cstring, (Ptr{Void},), ff))
end

function is_font_family_monospace(ff)
    convert(Bool, ccall((:pango_font_family_is_monospace, X._jl_libpango), Cint, (Ptr{Void},), ff))
end

# this assumes the underlying structs that are pointed to are
# persistent which seems to be implied by the api.  so we copy the
# array of pointers (maybe that could be avoied by calling
# pointer_to_array with true)
function list_font_family_faces(ff)
    pfc = Ptr{Ptr{Void}}[0]
    pn = Cint[0]
    ccall((:pango_font_family_list_faces, X._jl_libpango), Void, (Ptr{Void}, Ptr{Ptr{Ptr{Void}}}, Ptr{Cint}), ff, pfc, pn)
    a = pointer_to_array(pfc[1], (pn[1],), false)
    fc = copy(a)
    Libc.free(pfc[1])
    fc
end

function get_font_face_name(fc)
    bytestring(ccall((:pango_font_face_get_face_name, X._jl_libpango), Cstring, (Ptr{Void},), fc))
end
