class SynonymFinder::Spec

  INPUT = [
    {id : 001, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Gnamptogenys",    name : "Gnamptogenys porcata (Emery, 1896)"},
    {id : 003, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Gnamptogenys",    name : "Gnamptogenys triangularis (Mayr, 1887"),
    {id : 100, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Nylanderia",      name : "Nylanderia porcata"}, #match 001, no authorhsip
    {id : 200, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name : "Brachymyrmex obscurior Forel, 1893"},
    {id : 201, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name : "Brachymyrmex brevicornis Emery, 1906"},
    {id : 202, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name : "Brachymyrmex patagonicus Mayr, 1868"},
    {id : 203, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Brachymyrmex",    name : "Brachymyrmex minutus Forel, 1893"},
    {id : 300, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name : "Neobrachymyrmex obscurior"}, #match 200 no auth
    {id : 301, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name : "Neobrachymyrmex brevicornis"}, #match 201 no auth
    {id : 302, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name : "Neobrachymyrmex patagonicus Mayr, 1868"}, #match 203 auth
    {id : 303, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Neobrachymyrmex", name : "Neobrachymyrmex minutus Forel"}, #match 204 auth (part)
    {id : 400, path : "Animalia|Athropoda|Insecta|Hymenoptera|Formicidae|Crematogaster",   name : "Crematogaster obscurata  Emery, 1895"},
    {id : 500, path : "Animalia|Athropoda|Insecta|Hymenoptera|Tiphiidae|Diamma",           name : "Diamma obscurata  (Emery, 1895)"}, #match 2 degrees 400 auth
  ]

end
