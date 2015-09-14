
using Drawing; const D = Drawing

fm = D.get_font_map_default()
ff = D.list_families(fm)
for f in ff
    m = D.is_monospace(f) ? "monospace" : ""
    println("$(D.get_name(f)) $m")
    fc = D.list_faces(f)
    for c in fc
        d1 = D.describe(c)
        println("  $(D.get_name(c)): $(d1)")
        println("  $(D.get_style(d1)), $(D.get_variant(d1)), $(D.get_weight(d1)), $(D.get_stretch(d1)), $(D.get_gravity(d1))")
        d2 = convert(D.FontDescription, "$(d1)")
        @assert d1 == d2
        @assert hash(d1) == hash(d2)
    end
    gc()  # call finalizer
end
