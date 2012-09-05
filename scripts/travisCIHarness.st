"builderCI test harness ... invoked by the following expression:

    TravisCIHarness
      value: #( 'BaselineOfFileTreeTests' 'ConfigurationOfMetacello')
      value: 'TravisCISuccess.txt' 
      value: 'TravisCIFailure.txt'.

"

    Smalltalk
        at: #'TravisCIHarness'
        put: [ :configurationClassNameList :successFilename :failFilename |
          MetacelloBuilderTravisCI 
            runHarnessFor: configurationClassNameList 
            successFilename: successFilename 
            failFilename: failFilename]
