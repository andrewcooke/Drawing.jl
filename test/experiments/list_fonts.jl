
using Drawing; const D = Drawing

fm = D.get_font_map_default()
ff = D.list_font_map_families(fm)
for f in ff
    println("$(D.get_font_family_name(f)) $(D.is_font_family_monospace(f))")
    fc = D.list_font_family_faces(f)
    for c in fc
        println("  $(D.get_font_face_name(c))")
    end
end
