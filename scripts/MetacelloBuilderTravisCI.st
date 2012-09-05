'From Pharo1.4 of 18 April 2012 [Latest update: #14457] on 4 September 2012 at 6:40:36 pm'!
Object subclass: #MetacelloBuilderTravisCI
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'XXX'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MetacelloBuilderTravisCI class
	instanceVariableNames: ''!

!MetacelloBuilderTravisCI class methodsFor: 'git' stamp: 'dkh 9/4/2012 18:36'!
gitPath
    ^ self gitPathFor: 'git_cache'! !

!MetacelloBuilderTravisCI class methodsFor: 'git' stamp: 'dkh 9/4/2012 18:33'!
gitPathFor: gitCacheName
    ^ (Smalltalk at: #'FileDirectory' ifAbsent: [  ])
        ifNil: [ 
            "Pharo-2.x"
            ((Smalltalk at: #'FileSystem') workingDirectory / gitCacheName) pathString ]
        ifNotNil: [ :fileDirectoryClass | 
            "Pharo-1.x"
            (fileDirectoryClass default directoryNamed: gitCacheName) fullName ]! !


!MetacelloBuilderTravisCI class methodsFor: 'retry' stamp: 'dkh 9/4/2012 18:28'!
retry: aBlock
    self retry: aBlock retryCount: 3! !

!MetacelloBuilderTravisCI class methodsFor: 'retry' stamp: 'dkh 9/4/2012 18:28'!
retry: aBlock retryCount: retryCount
    | count |
    count := 1.
    [ true ]
        whileTrue: [ 
            [ 
            aBlock value.
            ^ self ]
                on: Error
                do: [ :ex | 
                    count < retryCount
                        ifTrue: [ 
                            Transcript
                                cr;
                                show: 'RETRYING AFTER:';
                                cr;
                                show: ex description printString.
                            (Delay forSeconds: 10) wait.]
                        ifFalse: [ 
                            Transcript
                                cr;
                                show: 'FAILED RETRYING:';
                                cr;
                                show: ex description printString.
                            ex pass ] ].
            count := count + 1 ]! !


!MetacelloBuilderTravisCI class methodsFor: 'test harness' stamp: 'dkh 9/4/2012 18:31'!
runHarnessFor: configurationClassNameList successFilename: successFilename failFilename: failFilename
    [ 
    | suite result resultsFileName |
    suite := TestCase suiteClass named: configurationClassNameList printString , ' Test Suite'.
    configurationClassNameList
        do: [ :className | 
            (((Smalltalk at: #'MetacelloProjectRegistration')
                registrationForClassNamed: className
                ifAbsent: [ self error: className printString , ' not registered (loaded)' ])
                currentlyLoadedClassesInProject select: [ :cl | cl inheritsFrom: TestCase ])
                do: [ :cl | 
                    cl isAbstract
                        ifFalse: [ suite addTest: cl buildSuiteFromSelectors ] ] ].
    result := suite run.
    resultsFileName := result defects isEmpty
        ifTrue: [ successFilename ]
        ifFalse: [ failFilename ].
    (Smalltalk at: #'TravisResultFileBlock')
        value: resultsFileName
        value: [ :fileStream | 
            fileStream lineEndConvention: #'lf'.
            fileStream
                nextPutAll: '***********************************************';
                cr.
            fileStream
                tab;
                nextPutAll: 'Results for ' , suite name;
                cr;
                nextPutAll: result printString;
                cr.
            fileStream
                nextPutAll: '***********************************************';
                cr.
            result failures notEmpty
                ifTrue: [ 
                    fileStream
                        nextPutAll: '*** FAILURES ***';
                        nextPutAll: '****************';
                        cr ].
            result failures
                do: [ :each | 
                    fileStream tab
                        nextPutAll: each class name asString , ' debug: ' , each selector printString , '.';
                        cr ].
            result errors notEmpty
                ifTrue: [ 
                    fileStream
                        nextPutAll: '*** ERRORS ***';
                        nextPutAll: '****************';
                        cr ].
            result errors
                do: [ :each | 
                    fileStream tab
                        nextPutAll: each class name asString , ' debug: ' , each selector printString , '.';
                        cr ].
            fileStream
                nextPutAll: '***********************************************';
                cr ] ]
        ensure: [ 
            | stream |
            stream := Transcript.
            (Smalltalk globals associationAt: #'Transcript') value: (Smalltalk at: #'OLDTranscript').
            stream close ]! !


!MetacelloBuilderTravisCI class methodsFor: 'filein' stamp: 'dkh 9/4/2012 18:33'!
fileIn: fileName
    (Smalltalk at: #'FileDirectory' ifAbsent: [  ])
        ifNil: [ (Smalltalk at: #'FileSystem') workingDirectory / fileName readStreamDo: [ :fileStream | fileStream fileIn ] ]
        ifNotNil: [ :fileDirectoryClass | fileDirectoryClass default fileNamed: fileName do: [ :fileStream | fileStream fileIn ] ]! !

