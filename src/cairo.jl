
import Base.==

# at some point these should be a pull request for Cairo.jl?

# this is a #define - no idea how to extract it dynamically
# https://developer.gnome.org/pango/stable/pango-Glyph-Storage.html#PANGO-SCALE:CAPS
const PANGO_SCALE = 1024

# these are enums - again, no idea how to read
# https://people.redhat.com/otaylor/pango-mirror/api/pango-fonts.html#PANGOSTYLE
const PANGO_STYLE_NORMAL = 0
const PANGO_STYLE_ITALIC = 1
const PANGO_STYLE_OBLIQUE = 2
# https://people.redhat.com/otaylor/pango-mirror/api/pango-fonts.html#PANGOVARIANT
const PANGO_VARIANT_NORMAL = 0
const PANGO_VARIANT_SMALL_CAPS = 1
# https://developer.gnome.org/pygtk/stable/class-pangofontdescription.html#method-pangofontdescription--set-weight
# any value from 100-900
const PANGO_WEIGHT_ULTRALIGHT = 200
const PANGO_WEIGHT_LIGHT = 300
const PANGO_WEIGHT_NORMAL = 400
const PANGO_WEIGHT_BOLD = 700
const PANGO_WEIGHT_ULTRABOLD = 800
const PANGO_WEIGHT_HEAVY = 900
# https://people.redhat.com/otaylor/pango-mirror/api/pango-fonts.html#PANGOSTRETCH
const PANGO_STRETCH_ULTRA_CONDENSED = 0
const PANGO_STRETCH_EXTRA_CONDENSED = 1
const PANGO_STRETCH_CONDENSED = 2
const PANGO_STRETCH_SEMI_CONDENSED = 3
const PANGO_STRETCH_NORMAL = 4
const PANGO_STRETCH_SEMI_EXPANDED = 5
const PANGO_STRETCH_EXPANDED = 6
const PANGO_STRETCH_EXTRA_EXPANDED = 7
const PANGO_STRETCH_ULTRA_EXPANDED = 8
# http://sourcecodebrowser.com/pango1.0/1.22.1/pango-gravity_8h.html#ab9f9c35c3778c1ca07195d6687a83e9c
const PANGO_GRAVITY_SOUTH = 0
const PANGO_GRAVITY_EAST = 1
const PANGO_GRAVITY_NORTH = 2
const PANGO_GRAVITY_WEST = 3
const PANGO_GRAVITY_AUTO = 4

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

immutable FontMap
    ptr::Ptr{Void}
end

function get_font_map_default()
    FontMap(ccall((:pango_cairo_font_map_get_default, X._jl_libpangocairo), Ptr{Void}, ()))
end

immutable FontFamily
    ptr::Ptr{Void}
end

# this assumes the underlying structs that are pointed to are
# persistent which seems to be implied by the api.  so we copy the
# array of pointers (maybe that could be avoied by calling
# pointer_to_array with true)
function list_families(fm::FontMap)
    pff = Ptr{Ptr{Void}}[0]
    pn = Cint[0]
    ccall((:pango_font_map_list_families, X._jl_libpango), Void, (Ptr{Void}, Ptr{Ptr{Ptr{Void}}}, Ptr{Cint}), fm.ptr, pff, pn)
    a = pointer_to_array(pff[1], (pn[1],), false)
    ff = [FontFamily(p) for p in a]
    Libc.free(pff[1])
    ff
end

function get_name(ff::FontFamily)
    bytestring(ccall((:pango_font_family_get_name, X._jl_libpango), Cstring, (Ptr{Void},), ff.ptr))
end

function is_monospace(ff::FontFamily)
    convert(Bool, ccall((:pango_font_family_is_monospace, X._jl_libpango), Cint, (Ptr{Void},), ff.ptr))
end

immutable FontFace
    ptr::Ptr{Void}
end

# this assumes the underlying structs that are pointed to are
# persistent which seems to be implied by the api.  so we copy the
# array of pointers (maybe that could be avoied by calling
# pointer_to_array with true)
function list_faces(ff::FontFamily)
    pfc = Ptr{Ptr{Void}}[0]
    pn = Cint[0]
    ccall((:pango_font_family_list_faces, X._jl_libpango), Void, (Ptr{Void}, Ptr{Ptr{Ptr{Void}}}, Ptr{Cint}), ff.ptr, pfc, pn)
    a = pointer_to_array(pfc[1], (pn[1],), false)
    fc = [FontFace(p) for p in a]
    Libc.free(pfc[1])
    fc
end

function get_name(fc::FontFace)
    bytestring(ccall((:pango_font_face_get_face_name, X._jl_libpango), Cstring, (Ptr{Void},), fc.ptr))
end

# cannot use immutable here as finalizer() complains
type FontDescription
    ptr::Ptr{Void}
    function FontDescription(ptr)
        this = new(ptr)
        finalizer(this, fd -> ccall((:pango_font_description_free, X._jl_libpango), Void, (Ptr{Void},), fd.ptr))
        this
    end
end

function describe(fc::FontFace)
    FontDescription(ccall((:pango_font_face_describe, X._jl_libpango), Ptr{Void}, (Ptr{Void},), fc.ptr))
end

# non-standard function names here to support round-tripping to strings

function Base.show(io::IO, fd::FontDescription)
    s = bytestring(ccall((:pango_font_description_to_string, X._jl_libpango), Cstring, (Ptr{Void},), fd.ptr))
    print(io, s)
end

function Base.convert(::Type{FontDescription}, s::AbstractString)
    FontDescription(ccall((:pango_font_description_from_string, X._jl_libpango), Ptr{Void}, (Ptr{Cchar},), s))
end

function ==(fd1::FontDescription, fd2::FontDescription)
    convert(Bool, ccall((:pango_font_description_equal, X._jl_libpango), Cint, (Ptr{Void}, Ptr{Void}), fd1.ptr, fd2.ptr))
end

function Base.hash(fd::FontDescription)
    ccall((:pango_font_description_hash, X._jl_libpango), Culong, (Ptr{Void},), fd.ptr)
end

function Base.copy(fd::FontDescription)
    FontDescription(ccall((:pango_font_description_copy, X._jl_libpango), Ptr{Void}, (Ptr{Void},), fd.ptr))
end

for name in [:style, :variant, :weight, :stretch, :gravity, :size]
    g1 = symbol(:get_, name)
    g2 = symbol(:pango_font_description_, g1)
    s1 = symbol(:set_, name)
    s2 = symbol(:pango_font_description_, g1)
    @eval begin
        $g1(fd::FontDescription) = ccall(($(Expr(:quote, g2)), X._jl_libpango), Culong, (Ptr{Void},), fd.ptr)
        $s1(fd::FontDescription, x) = ccall(($(Expr(:quote, s2)), X._jl_libpango), Void, (Ptr{Void}, Culong), fd.ptr, x)
    end
end

function set_absolute_size(fd::FontDescription, size)
    ccall((:pango_font_description_set_absolute_size, X._jl_libpango), Void, (Ptr{Void}, Cdouble), fd.ptr, size * PANGO_SCALE)
end

function get_absolute_size(fd::FontDescription, size)
    ccall((:pango_font_description_get_absolute_size, X._jl_libpango), Cdouble, (Ptr{Void},), fd.ptr) / PANGO_SCALE
end

immutable Layout
    ptr::Ptr{Void}
end

function set_text(l::Layout, text)
    ccall((:pango_layout_set_text, X._jl_libpango), Void, (Ptr{Void}, Ptr{Cchar}), l.ptr, text)
end

function set_description(l::Layout, fd::FontDescription)
    ccall((:pango_layout_set_font_description, X._jl_libpango), Void, (Ptr{Void}, Ptr{Void}), l.ptr, fd.ptr)
end

function update_layout(c::X.CairoContext, l::Layout)
    ccall((:pango_cairo_update_layout, X._jl_libpangocairo), Void, (Ptr{Void}, Ptr{Void}), c.ptr, l.ptr)
end

function show_path(c::X.CairoContext, l::Layout)
    ccall((:pango_cairo_layout_path, X._jl_libpangocairo), Void, (Ptr{Void}, Ptr{Void}), c.ptr, l.ptr)
end

immutable Rectangle
    x::Cint
    y::Cint
    width::Cint
    height::Cint
end

function get_pixel_extents(l::Layout)
    ink = Rectangle[Rectangle(0, 0, 0, 0)]
    logical = Rectangle[Rectangle(0, 0, 0, 0)]
    ccall((:pango_layout_get_pixel_extents, X._jl_libpango), Void, (Ptr{Void}, Ptr{Void}, Ptr{Void}), l.ptr, ink, logical)
    ink[1], logical[1]
end
