class SynonymFinder::Spec

  INPUT = [
    {id: 001, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Gnamptogenys",    name: "Gnamptogenys porcata (Emery, 1896)"},
    {id: 003, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Gnamptogenys",    name: "Gnamptogenys triangularis (Mayr, 1887)"},
    {id: 004, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Gnamptogenys",    name: "Gnamptogenys triangularis var. alba Brown 1992"},
    {id: 005, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Gnamptogenys",    name: "Gnamptogenys triangularis var. borealis Brown 1992"},
    {id: 100, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Nylanderia",      name: "Nylanderia porcata"}, #match 001, no authorhsip
    {id: 101, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Nylanderia",      name: "Nylanderia porcatum Emery, 1896"}, #match 001 by stem
    {id: 102, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Nylanderia",      name: "Nylanderia porcatum"}, #match 001 by stem
    {id: 200, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name: "Brachymyrmex obscurior Forel, 1893"},
    {id: 201, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name: "Brachymyrmex brevicornis Emery, 1906"},
    {id: 202, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name: "Brachymyrmex patagonicus Mayr, 1868"},
    {id: 203, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name: "Brachymyrmex minutus Forel, 1893"},
    {id: 204, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name: "Brachymyrmex minutus Brown, 2010"}, #chresonym match with 203
    {id: 205, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name: "Brachymyrmex micropeda Forel, 1893"},
    {id: 300, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name: "Neobrachymyrmex obscurior"}, #match 200 no auth
    {id: 301, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name: "Neobrachymyrmex brevicornis"}, #match 201 no auth
    {id: 302, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name: "Neobrachymyrmex patagonicus Mayr, 1868"}, #match 203 auth
    {id: 303, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name: "Neobrachymyrmex minutus Forel"}, #match 204 no auth (part)
    {id: 304, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name: "Neobrachymyrmex micropeda Brown 1995"}, #match 205 no auth 
    {id: 400, path: "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Crematogaster",   name: "Crematogaster obscurata  Emery, 1895"},
    {id: 500, path: "Animalia|Athropoda|Insecta|Hymenoptera|Tiphiidae|Diamma",           name: "Diamma obscurata  (Emery, 1895)"}, #match 2 degrees 400 auth
    {id: 600, path: "Animalia|Athropoda|Insecta|Hymenoptera|Tiphiidae|Crematogaster",    name: "Crematogaster obscurata  Em. 1895"}, #full name match
    {id: 700, path: "Animalia|Something1|Something2|Something3|Something4|Somename",     name: "Somename obscurata Emery"}, #distance over threshold
    {id: 800, path: "Animalia|Athropoda|Insecta|Hymenoptera|Tiphiidae|Neobrachymyrmex",  name: "Neobrachymyrmex obscurata  (Emery, 1895)"}, #match 2 degrees 400 auth
  ]

end
