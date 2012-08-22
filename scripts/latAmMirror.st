"Use Latin American Mirror"
Gofer new 
  url: 'http://www.squeaksource.com/ObjectsAsMethodsWrap';
  package: 'ObjectAsMethodWrapper'; 
  load.

Gofer new 
  url: 'http://www.squeaksource.com/MonticelloRedirect';
  package: 'MontiRedirect'; 
  load.

"If the LatAm mirror is available, use that. Otherwise, try use SqueakSource."
(NetNameResolver addressForName: 'dsal.cl')
    ifNotNil: [(Smalltalk at: #MRManager)
      redirectFrom: 'http://www.squeaksource.com/'
    to: 'http://dsal.cl/squeaksource/'].

