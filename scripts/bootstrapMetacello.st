Transcript cr; show: 'travis---->bootstrapMetacello.st'.

"Bootstrap Metacello-Base to simulate conditions when it's included in base images"
(Smalltalk
  at: #'MetacelloProject'
  ifAbsent: []) 
    ifNil: [
      "Metacello not pre-installed install Metacello-Base"
      MetacelloBuilderTravisCI fileIn: 'Metacello-Base.st'.

      "ensure that Gofer is available on Squeak"
      MetacelloBuilderTravisCI retry: [
        (Smalltalk at: #ConfigurationOf) 
          ensureGoferVersion: 'Gofer-Core-lr.115' 
          repositoryUrl: 'http://seaside.gemstone.com/ss/metacello'. ]]
    ifNotNil: [
      "Metacello already installed, install Preview".
      MetacelloBuilderTravisCI retry: [
        (Smalltalk at: #Gofer) new
          gemsource: 'metacello';
          package: 'ConfigurationOfMetacello';
          load ].
      ((Smalltalk at: #ConfigurationOfMetacello) project 
        version: '1.0-beta.32') load.
      (Smalltalk at: #Metacello) new
        configuration: 'MetacelloPreview';
        version: #stable;
        repository: 'github://dalehenrich/metacello-work:configuration';
        load ].


