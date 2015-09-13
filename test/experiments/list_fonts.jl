
using Drawing; const D = Drawing

fm = D.get_font_map_default()
ff = D.list_families(fm)
for f in ff
    println("$(D.get_name(f)) $(D.is_monospace(f))")
    fc = D.list_faces(f)
    for c in fc
        println("  $(D.get_name(c))")
    end
end
