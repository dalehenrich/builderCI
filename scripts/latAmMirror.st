"If latam mirror isn't available, take our chances with squeaksource"
(NetNameResolver addressForName: 'dsal.cl') ifNil: [ ^ self ].  
"if latam mirror is available, need to install from mirror, in case squeaksource is down"
Gofer new 
  url: 'http://dsal.cl/squeaksource/ObjectsAsMethodsWrap'; 
  package: 'ObjectAsMethodWrapper'; 
  load.
Gofer new 
  url: 'http://dsal.cl/squeaksource/MonticelloRedirect'; 
  package: 'MontiRedirect'; 
  load.
(Smalltalk at: #'MRManager') redirectFrom: 'http://www.squeaksource.com/' to: 'http://dsal.cl/squeaksource/'
