| repository version |
Transcript cr; show: 'travis---->bootstrapGofer.st'.

Smalltalk at: #Gofer ifPresent: [ ^self ].

repoUrl := 'http://seaside.gemstone.com/ss/metacello'.
filename := 'Gofer-Core-lr.115'.
repository := (MCCacheRepository default includesVersionNamed: filename )
	ifTrue: [MCCacheRepository default]
	ifFalse: [MCHttpRepository
		location: repoUrl
		user: ''
		password: ''].
MetacelloBuilderTravisCI
  retry: [
    repository
	    versionReaderForFileNamed:  filename, '.mcz'
	    do: [:reader | 
		    version := reader version.
		    version load.
		    version workingCopy repositoryGroup addRepository: repository ]]
