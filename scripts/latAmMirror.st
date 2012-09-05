Gofer new 
  url: 'http://dsal.cl/squeaksource/ObjectsAsMethodsWrap'; 
  package: 'ObjectAsMethodWrapper'; 
  load.
Gofer new 
  url: 'http://ss3.gemstone.com/ss/Scratchpad-fbs';
  package: 'MetacelloBuildOverrides';
  load.

"MetacelloRepositoryOverrider adds well-known repository sources: SqueakSource, its LatAm mirror, and SqueakSource3."
(Smalltalk at: #MetacelloRepositoryOverrider)
  installOn: MetacelloLoaderPolicy
  selector: #overrideRepositories.
