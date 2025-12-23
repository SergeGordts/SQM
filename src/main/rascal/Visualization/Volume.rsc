module Visual::Tree

public Content visualizeA(loc cl, M3 model) {
   rel[str, num] regels = { <l.file, a> | <l,a> <- toRel(regelsPerBestand(model)) };
   return barChart(sort(regels, aflopend), title="Regels per Javabestand");
}

public Content visualizeB() {
   return graph(gebruikt,title="Componenten", \layout=defaultGridLayout(rows=2,cols=3));
}