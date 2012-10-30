Object subclass: #ConfigurationOf
	instanceVariableNames: 'project'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Metacello-Base'!
!ConfigurationOf commentStamp: 'dkh 5/30/2012 16:31' prior: 0!
**ConfigurationOf** is the common superclass for all Metacello configurations.

A short description of why you would want to use a **ConfigurationOf**.

To create a new Metacello configuration:

1. Create a subclass of the class ConfigurationOf appending the name of
   your project (don't forget to change the **category:** to match the
   name of the configuration class):

    ```Smalltalk
    ConfigurationOf subclass: #ConfigurationOfExample
      instanceVariableNames: ''
      classVariableNames: ''
      poolDictionaries: ''
      category: 'ConfigurationOfExample'
    ```

2. Create a **baselineXXXX:** method where you specify the structure of your project:

    ```Smalltalk
    baseline0100: spec
      <baseline: '1.0-baseline'>

      spec for: #common do: [
        spec repository: 'http://ss3.gemstone.com/ss/Example'.
        spec
          package: 'Example-Core';
          package: 'Example-Tests' with: [
            spec requires: 'Example-Core' ]].
    ```

3. Create a **versionXXXX:** method where you specify the specific
   versions of the packages to be loaded for this version:

    ```Smalltalk
    version01000: spec
      <version: '1.0' imports: #('1.0-baseline')>

      spec for: #common do: [
        spec blessing: #release.
        spec
          package: 'Example-Core' with: 'Example-Core';
          package: 'Example-Tests' with: 'Example-Tests' ].
    ```

4. Create a Monticello package for your **ConfigurationOf** class and save it in the repository where your packages are stored. !


!ConfigurationOf methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
customProjectAttributes
    "Edit to return a collection of any custom attributes e.g. for conditional loading: Array with: #'Condition1' with: #'Condition2.
	For more information see: http://code.google.com/p/metacello/wiki/CustomProjectAttrributes "

    ^ #()! !

!ConfigurationOf methodsFor: 'accessing' stamp: 'dkh 6/22/2012 14:31'!
project
    ^ project
        ifNil: [ 
            "Bootstrap Metacello if it is not already loaded"
            self class ensureMetacello.
            project := self projectClass new projectAttributes: self customProjectAttributes.	"Create the Metacello project"
            project versionNumberClass: self versionNumberClass.
            project class versionConstructorClass on: self project: project.	"Construct the project"
            project loadType: #'linear'.	"change to #atomic if desired"
            project ]! !

!ConfigurationOf methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
project: aProject

	project ifNil: [ self class ensureMetacello ].
	project := aProject! !

!ConfigurationOf methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
projectClass
    ^ MetacelloMCProject! !

!ConfigurationOf methodsFor: 'accessing' stamp: 'dkh 6/22/2012 12:09'!
versionNumberClass
    ^ MetacelloSemanticVersionNumber! !


!ConfigurationOf methodsFor: 'defaults' stamp: 'dkh 5/31/2012 17:57:13'!
bleedingEdge 
	"override if different behavior desired.
	 Use:
		self versionDoesNotExistError: #bleedingEdge
	 if #bleedingEdge version is disallowed."

	<defaultSymbolicVersion: #bleedingEdge>
	
	^self defaultBleedingEdgeVersion! !

!ConfigurationOf methodsFor: 'defaults' stamp: 'dkh 5/31/2012 17:57:13'!
defaultBleedingEdgeVersion
	| bleedingEdgeVersion |
	bleedingEdgeVersion := (self project map values select: [ :version | version blessing == #baseline ])
		detectMax: [ :version | version ].
	bleedingEdgeVersion ifNil: [ ^#'notDefined' ].
	^ bleedingEdgeVersion versionString! !


!ConfigurationOf methodsFor: 'private' stamp: 'dkh 5/31/2012 17:57:13'!
versionDoesNotExistError: versionStringOrSymbol

	((Smalltalk at: #MetacelloSymbolicVersionDoesNotExistError) project: self project versionString: versionStringOrSymbol) signal! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ConfigurationOf class
	instanceVariableNames: ''!

!ConfigurationOf class methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
project

	^self new project! !

!ConfigurationOf class methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
validate
	"Check the configuration for Errors, Critical Warnings, and Warnings (see class comment for MetacelloMCVersionValidator for more information). 
	Errors identify specification issues that will result in unexpected behaviour when you load the configuration. 
	Critical Warnings identify specification issues that may result in unexpected behavior when you load the configuration.
	Warnings identify specification issues that are technically correct, but are worth take a look at."

	"self validate"

	<apiDocumentation>
	self ensureMetacello.
	^ ((Smalltalk at: #MetacelloToolBox) validateConfiguration: self debug: #() recurse: false) explore! !



!ConfigurationOf class methodsFor: 'unloading Metacello' stamp: 'dkh 5/31/2012 17:57:13'!
unloadMetacello
	"Unload the classes that implement Metacello. Metacello is not needed once a project has been loaded, so it can safely be unloaded."

	"self unloadMetacello"

	<apiDocumentation>
	| gofer |
	gofer := (Smalltalk at: #Gofer) new.
	MCWorkingCopy allManagers do: [:wc |
		((wc packageName beginsWith: 'Metacello') or: [ wc packageName beginsWith: 'OB-Metacello' ])
			ifTrue: [ gofer package: wc packageName ]].
	gofer unload.! !


!ConfigurationOf class methodsFor: 'private' stamp: 'dkh 7/27/2012 01:36'!
bootstrapMetacelloFrom: repositoryUrl
    "Corresponds to version 1.0-beta.32.2"

    "KEEP MetacelloConfigTemplate class>>ensureMetacelloBaseConfiguration in synch!!"

    | platformPkg |
    self ensureGoferVersion: 'Gofer-Core-lr.115' repositoryUrl: repositoryUrl.
    #('Metacello-Base-dkh.103' 'Metacello-Core-dkh.667' 'Metacello-MC-dkh.665')
        do: [ :pkg | self bootstrapPackage: pkg from: repositoryUrl ].
    platformPkg := Smalltalk
        at: #'SystemVersion'
        ifPresent: [ :cl | 
            | versionString |
            versionString := cl current version.
            (versionString beginsWith: 'Squeak')
                ifTrue: [ 
                    (versionString beginsWith: 'Squeak3')
                        ifTrue: [ 'Metacello-Platform.squeak-dkh.5' ]
                        ifFalse: [ 'Metacello-Platform.squeak-dkh.13' ] ]
                ifFalse: [ 
                    (versionString beginsWith: 'Pharo')
                        ifTrue: [ 'Metacello-Platform.pharo-dkh.27' ] ] ].
    self bootstrapPackage: platformPkg from: repositoryUrl! !

!ConfigurationOf class methodsFor: 'private' stamp: 'dkh 5/31/2012 17:57:13'!
bootstrapPackage: aString from: aPath 
	| repository version |
	repository := (MCCacheRepository default includesVersionNamed: aString)
		ifTrue: [MCCacheRepository default]
		ifFalse: [MCHttpRepository
				location: aPath
				user: ''
				password: ''].
	MetacelloBuilderTravisCI retry: [
    repository
		  versionReaderForFileNamed: aString , '.mcz'
		  do: [:reader | 
			  version := reader version.
			  version load.
			  version workingCopy repositoryGroup addRepository: repository ]]! !

!ConfigurationOf class methodsFor: 'private' stamp: 'dkh 6/10/2012 22:01'!
ensureGoferVersion: goferVersion repositoryUrl: repositoryUrl
    "load the p=file goferVersion if Gofer isn't loaded or an earlier version of Gofer is currently loaded"

    | goferVersionNumber wc pName |
    (Smalltalk at: #'Gofer' ifAbsent: [  ]) == nil
        ifTrue: [ ^ self bootstrapPackage: goferVersion from: repositoryUrl ].
    goferVersionNumber := (goferVersion copyAfterLast: $.) asNumber.
    wc := [ ((Smalltalk at: #'GoferPackageReference') name: 'Gofer') workingCopy ]
        on: Error
        do: [ :ex | ex return: ((Smalltalk at: #'GoferPackageReference') name: 'Gofer-Core') workingCopy ].
    pName := wc ancestry ancestors first name.
    (pName copyAfterLast: $.) asNumber <= goferVersionNumber
        ifTrue: [ self bootstrapPackage: goferVersion from: repositoryUrl ]! !

!ConfigurationOf class methodsFor: 'private' stamp: 'dkh 6/11/2012 11:05'!
ensureMetacello
    "Bootstrap Metacello and load the 'botstrap' group"

    self ensureMetacello: #('batch')! !

!ConfigurationOf class methodsFor: 'private' stamp: 'dkh 6/25/2012 10:32'!
ensureMetacello: loadList
    "Bootstrap Metacello, retry using alternate repository, if primary repository is not accessible"

    Smalltalk
        at: #'MetacelloProject'
        ifAbsent: [ 
            | version error gofer |
            (Array with: 'http://seaside.gemstone.com/ss/metacello' with: 'http://www.squeaksource.com/metacello')
                do: [ :repositoryUrl | 
                    "bootstrap Metacello"
                    self bootstrapMetacelloFrom: repositoryUrl.
                    MetacelloBuilderTravisCI retry: [
                      Smalltalk
                        at: #'ConfigurationOfMetacello'
                        ifAbsent: [ 
                              gofer := (Smalltalk at: #'Gofer') new.
                              gofer
                                perform: #'url:' with: repositoryUrl;
                                perform: #'package:' with: 'ConfigurationOfMetacello';
                                perform: #'load' ] ].
                    version := (Smalltalk at: #'ConfigurationOfMetacello') project version: '1.0-beta.32'.	"bootstrap with 1.0-beta.32"
                    version load: loadList.
                    MetacelloBuilderTravisCI retry: [
                      gofer := (Smalltalk at: #'Gofer') new.
                      Smalltalk
                        at: #'ConfigurationOfMetacelloPreview'
                        ifAbsent: [ 
                            gofer
                                perform: #'url:' with: repositoryUrl;
                                perform: #'package:' with: 'ConfigurationOfMetacelloPreview';
                                perform: #'load' ] ].
                    version := (Smalltalk at:
#'ConfigurationOfMetacelloPreview') project version: #'stable'.
                    version load: loadList.
                    ^ self ].	
            "shouldn't get here unless the load failed ... throw an error"
            self error: 'retry with alternate repository failed: ']! !


Object subclass: #Metacello
	instanceVariableNames: 'executorSpec statements'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Metacello-Base'!
!Metacello commentStamp: 'dkh 6/25/2012 14:56' prior: 0!
# Metacello Scripting API Documentation

The **Metacello Scripting API** provides a platform independent way for
loading Metacello configurations into your image.

Currently [Pharo1.3][1] and [Squeak4.3][2] are supported.

* [Installation](#installation)
* [Using the Metacello Scripting API](#using-the-metacello-scripting-api)
* [Best Practice](#best-practice)
* [Specifying Configurations](#specifying-configurations)
* [Metacello Version Numbers](*metacello-version-numbers)
* [Help](#help)

## Installation

To get started we need to load the `ConfigurationOfMetacello`. In a Pharo1.3 image:

```Smalltalk
"Get the Metacello configuration"
Gofer new
  gemsource: 'metacello';
  package: 'ConfigurationOfMetacello';
  load.
```

or a Squeak4.3 image:

```Smalltalk
Installer gemsource
    project: 'metacello';
    install: 'ConfigurationOfMetacello'. 
```

then bootstrap `Metacello 1.0-beta.32` and install the `Metacello Preview` code (both images):

```Smalltalk
((Smalltalk at: #ConfigurationOfMetacello) project 
  version: '1.0-beta.32') load.

(Smalltalk at: #Metacello) new
  configuration: 'MetacelloPreview';
  version: #stable;
  repository: 'github://dalehenrich/metacello-work:configuration';
  load.
```

*Once the Metacello Scripting API is released, the Metacello class
will be installed in the base images for GemStone, Pharo and Squeak and
bootstrapping will no longer be necessary.*

## Using the Metacello Scripting API

* [Loading](#loading)
* [Upgrading](#upgrading)
* [Downgrading](#downgrading)
* [Locking](#locking)
* [Unlocking](#unlocking)
* [Getting](#getting)
* [Fetching](#fetching)
* [Recording](#recording)
* [Finding](#finding)
* [Listing](#listing)

### Loading

Metacello loads the packages and dependencies (*required projects*) for a project
based on the specifications in the [configuration of a
project](#configurationof).

The statement: 

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  squeaksource: 'MetacelloRepository';
  version: '3.0.7';
  load.
```

will download the `ConfigurationOfSeaside30` package from
`http:www.squeaksource.com/MetacelloRepository` and 
proceed to load the `default` group of `Seaside 3.0.7` into your image.

The above expression is equivalent to the following old-style `Gofer-based`
expression:

```Smalltalk
Gofer new
  squeaksource: 'MetacelloRepository';
  package: 'ConfigurationOfSeaside30';
  load.
((Smalltalk at: #ConfigurationOfSeaside30) project version: '3.0.7') load.
``` 

Besides being a bit more compact, the Metacello scripting API uses a few
handy default values for the **version** and **repository** attributes.
The default **version** attribute is `#stable` and the default
**repository** attribute is [platform-dependent](#load-notes)

Applying the default values, the following expression:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  load.
```

is equivalent to (assuming the platform-specific default repository is `http:www.squeaksource.com/MetacelloRepository`):

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  squeaksource: 'MetacelloRepository';
  version: #stable;
  load.
```

Arguments to the **load** command may be used to specify which groups,
packages or dependent projects should be loaded instead of the
`default` group.

This command loads the `Base` group for the `#stable` version of `Seaside30`:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  load: 'Base'.
```

This command loads the `Base` group, the `Seaside-HTML5` package, 
and the `Zinc-Seaside` package for the `#stable` version of `Seaside30`:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  load: #('Base' 'Seaside-HTML5' 'Zinc-Seaside').
```

#### `load` Notes

* If a configuration is already present in the image when the load command
is executed, the existing configuration is used. Use the [get](#getting)
command to refresh the configuration.

* The default repository is platform-dependent. See the documentation
  for your platform to determine which repository is used. 
  Currently `http:www.squeaksource.com/MetacelloRepository` is used as the default.

* `github://` projects are implicitly [locked](#locking) when loaded.

* `filetree://` projects are implicitly [locked](#locking) when loaded
unless loaded as a project dependency.

* see the [Options](#options) section for additional information.

### Upgrading

When you come back to an image that you've left dormant for awhile, it
can be a real pain to upgrade all of the loaded projects to the latest
version. With Metacello you can upgrade all of the projects with one
command:

```Smalltalk
Metacello upgrade.
```

The `upgrade` command iterates over all loaded projects; refreshes
the project configuration and loads the `#stable` version of each project.

You can also selectively upgrade an individual project:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  upgrade.
```

Or upgrade a project to a specific version:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  version: '3.0.8';
  upgrade.
```

In this case the project configuration is refreshed and the specified
version is loaded. If the project was previously [locked](*locking), the
lock is changed to reflect the new version of the project.

If you want to ensure that all dependent projects are upgraded along
with the target project, you can write an [onUpgrade:](*onupgrade)
clause:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  version: '3.0.8';
  onUpgrade: [:ex | ex allow];
  upgrade.
```

Otherwise, project locks for dependent projects are honored by the
upgrade command. 

#### `upgrade` Notes

* [project locking](#locking) is respected for dependent projects.

* see the [Options](#options) section for additional information.

#### Downgrading

The upgrade command can be used to `downgrade` the version of a
project:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  version: '3.0.0';
  upgrade.
```

If you want to ensure that all dependent projects are downgraded along
with the target project, you can write an [onDowngrade:](*ondowngrade)
clause:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  version: '3.0.0';
  onDowngrade: [:ex | ex allow];
  upgrade.
```

Otherwise, dependent projects are not normally downgraded.

### Locking

Automatically upgrading projects is not always desirable. Of course, 
in the normal course of loading and upgrading, you will want the correct
version of dependent projects loaded. However under the following
conditions:

* Your application may depend upon a specific version (or 
  range of versions) for a project.
* You may be actively developing a particular version of a 
  project and you don't want the
  project upgraded (or downgraded) out from under you.
* You may be working with a git checkout of a project and you want to
  continue using the git checkout.

you many not want to have particular projects upgraded automatically.
The `lock` command gives you control.

You can lock a project to a particular version:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  version: '3.0.7';
  lock.
```

Or you can specify a block to be evaluated against the `proposedVersion`
and answer `true` to allow limited upgrades:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  version: [:proposedVersion | 
    (propsedVersion versionNumberFrom: '3.0.7') <= proposedVersion 
      and: [ proposedVersion < (proposedVersion versionNumberFrom: '3.1.0') ]];
  lock.
```

If you don't specify an explicit version, then the currently loaded
version of the project is locked:

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  lock.
```

If you are locking a [baseline configuration](#baselineof) it is not
necessary to specify a version:

```Smalltalk
Metacello new
  baseline: 'Seaside30';
  lock.
```

#### `lock` Notes

* To lock a git checkout for a project, you should lock the `baseline`:

    ```Smalltalk
    Metacello new
      baseline: 'Seaside30';
      lock.
    ```

### Unlocking

```Smalltalk
Metacello new
  baseline: 'Seaside30';
  unlock.
```

### Getting

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  get.
```

### Fetching

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  fetch.
```

### Recording

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  record.
```

### Finding

```Smalltalk
Metacello new
  configuration: 'Seaside30';
  find.
```

### Listing

```Smalltalk
Metacello list.
```

### Project Specs
####configuration:
####baseline:
####project:
####className:
####version:
####repository:
##### Repository descriptions
##### Repository Shortcuts

* blueplane:
* croquet:
* gemsource:
* impara:
* renggli:
* saltypickle:
* squeakfoundation:
* squeaksource:
* wiresong:

### Options
####ignoreImage
####onUpgrade:
####onDowngrade:
####onConflict:
####silently
## Best Practice
### Use #development and #release blessings
#### Semantic Versioning
### Validate configuration before commit
### GitHub project structure
## Specifying Configurations

### ConfigurationOf
### BaselineOf

## Metacello Version Numbers
## Help

[1]: http://www.pharo-project.org/pharo-download/release-1-3
[2]: http://www.squeak.org/Download/!


!Metacello methodsFor: 'private' stamp: 'dkh 5/31/2012 17:57:13'!
addStatement: selector args: args
    self statements add: selector -> args! !

!Metacello methodsFor: 'private' stamp: 'dkh 7/12/2012 14:29'!
execute
    | script |
    script := self statements.
    self statements: nil.
    ^ self scriptExecutor execute: script! !


!Metacello methodsFor: 'accessing' stamp: 'dkh 7/13/2012 09:12'!
executorSpec
    executorSpec ifNil: [ executorSpec := #'MetacelloScriptApiExecutor' -> 'batch' ].
    ^ executorSpec! !

!Metacello methodsFor: 'accessing' stamp: 'dkh 7/13/2012 09:13'!
executorSpec: anAssoc
    executorSpec := anAssoc! !

!Metacello methodsFor: 'accessing' stamp: 'dkh 7/13/2012 09:16'!
scriptExecutor
    ^ (self class scriptExecutorClass: self executorSpec) new! !

!Metacello methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
statements
    statements ifNil: [ statements := OrderedCollection new ].
    ^ statements! !

!Metacello methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
statements: anObject
	statements := anObject! !


!Metacello methodsFor: 'api projectSpec' stamp: 'dkh 7/12/2012 13:45'!
baseline: projectName
    self addStatement: #'baselineArg:' args: {projectName}! !

!Metacello methodsFor: 'api projectSpec' stamp: 'dkh 7/12/2012 13:45'!
className: className
    self addStatement: #'classNameArg:' args: {className}! !

!Metacello methodsFor: 'api projectSpec' stamp: 'dkh 7/12/2012 13:46'!
configuration: projectName
    self addStatement: #'configurationArg:' args: {projectName}! !

!Metacello methodsFor: 'api projectSpec' stamp: 'dkh 7/12/2012 13:46'!
project: projectName
    self addStatement: #'projectArg:' args: {projectName}! !

!Metacello methodsFor: 'api projectSpec' stamp: 'dkh 7/12/2012 13:46'!
repository: repositoryDescription
    self addStatement: #'repositoryArg:' args: {repositoryDescription}! !

!Metacello methodsFor: 'api projectSpec' stamp: 'dkh 7/12/2012 13:46'!
version: versionString
    self addStatement: #'versionArg:' args: {versionString}! !


!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:46'!
blueplane: projectName
    self repository: 'http://squeaksource.blueplane.jp/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:48'!
croquet: projectName
    self repository: 'http://hedgehog.software.umn.edu:8888/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:48'!
gemsource: projectName
    self repository: 'http://seaside.gemstone.com/ss/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:48'!
impara: projectName
    self repository: 'http://source.impara.de/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:48'!
renggli: projectName
    self repository: 'http://source.lukas-renggli.ch/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:49'!
saltypickle: projectName
    self repository: 'http://squeak.saltypickle.com/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:49'!
squeakfoundation: projectName
    self repository: 'http://source.squeakfoundation.org/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:50'!
squeaksource3: projectName
    self repository: 'http://ss3.gemstone.com/ss/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:50'!
squeaksource: projectName
    self repository: 'http://www.squeaksource.com/' , projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:46'!
ss3: projectName
    self squeaksource3: projectName! !

!Metacello methodsFor: 'api repository shortcuts' stamp: 'dkh 7/17/2012 16:50'!
wiresong: projectName
    self repository: 'http://source.wiresong.ca/' , projectName! !


!Metacello methodsFor: 'api actions' stamp: 'dkh 7/23/2012 15:55'!
fetch
    self addStatement: #'fetch:' args: #(#()).
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/23/2012 15:49'!
fetch: required
    self addStatement: #'fetch:' args: {required}.
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 5/31/2012 17:57:13'!
get
    "resolve project name in given repository and return an instance of MetacelloProject resolved from a ConfigurationOf or BaselineOf"

    self addStatement: #'get' args: #().
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/13/2012 16:35'!
list
    "list projects in registry"

    self addStatement: #'list' args: #().
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/23/2012 15:56'!
load
    self addStatement: #'load:' args: #(#()).
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 5/31/2012 17:57:13'!
load: required
    self addStatement: #'load:' args: {required}.
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/17/2012 10:53'!
lock
    "lock projects in registry"

    self addStatement: #'lock' args: #().
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/23/2012 15:56'!
record
    self addStatement: #'record:' args: #(#()).
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/19/2012 07:40'!
record: required
    self addStatement: #'record:' args: {required}.
    ^ self execute! !

!Metacello methodsFor: 'api actions' stamp: 'dkh 7/17/2012 12:31'!
unlock
    "unlock projects in registry"

    self addStatement: #'unlock' args: #().
    ^ self execute! !


!Metacello methodsFor: 'api options' stamp: 'dkh 7/23/2012 16:17'!
cacheRepository: aRepositoryDescription
    self addStatement: #'cacheRepository:' args: {aRepositoryDescription}! !

!Metacello methodsFor: 'api options' stamp: 'dkh 6/13/2012 16:05'!
ignoreImage
    "ignore image state"

    self addStatement: #'ignoreImage:' args: {true}! !

!Metacello methodsFor: 'api options' stamp: 'dkh 6/7/2012 15:34'!
onConflict: aBlock
    self addStatement: #'onConflict:' args: {aBlock}! !

!Metacello methodsFor: 'api options' stamp: 'dkh 6/8/2012 14:03:46'!
onDowngrade: aBlock
    self addStatement: #'onDowngrade:' args: {aBlock}! !

!Metacello methodsFor: 'api options' stamp: 'dkh 6/7/2012 15:33'!
onUpgrade: aBlock
    self addStatement: #'onUpgrade:' args: {aBlock}! !

!Metacello methodsFor: 'api options' stamp: 'dkh 7/23/2012 19:27'!
repositoryOverrides: aRepositoryDescriptionCollection
    self addStatement: #'repositoryOverrides:' args: {aRepositoryDescriptionCollection}! !

!Metacello methodsFor: 'api options' stamp: 'dkh 5/31/2012 17:57:13'!
silently
    "no progress bars"

    self addStatement: #'silently:' args: {true}! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Metacello class
	instanceVariableNames: ''!

!Metacello class methodsFor: 'instance creation' stamp: 'dkh 6/13/2012 16:09'!
classic
    "set the options such that the load performed will be identical to the classic ConfigurationOf load:
	(ConfigurationOfExample project version: '1.0') load
	
	#classic forces Metacello to look at image state to determine which version of a project is loaded instead of using
		the registry to tell us explicitly which version of a project is loaded .. image state is not PRECISE"

    "useCurrentVersion is a 'private' option for enforcing classic rules, so it's not part of scripting api"

    ^ self new
        onUpgrade: [ :ex | ex allow ];
        onConflict: [ :ex | ex allow ];
        addStatement: #'useCurrentVersion:' args: {true};
        yourself! !

!Metacello class methodsFor: 'instance creation' stamp: 'dkh 7/16/2012 10:12'!
image
    ^ self new
        executorSpec: #'MetacelloScriptImageExecutor' -> 'batch';
        yourself! !

!Metacello class methodsFor: 'instance creation' stamp: 'dkh 7/13/2012 09:13'!
registry
    ^ self new
        executorSpec: #'MetacelloScriptRegistryExecutor' -> 'batch';
        yourself! !


!Metacello class methodsFor: 'private' stamp: 'dkh 7/13/2012 09:08'!
scriptExecutorClass
    ^ self scriptExecutorClass: {(#'MetacelloScriptApiExecutor' -> 'batch')}! !

!Metacello class methodsFor: 'private' stamp: 'dkh 7/13/2012 09:15'!
scriptExecutorClass: anExecutorSpec
    Smalltalk at: anExecutorSpec key ifAbsent: [ ConfigurationOf ensureMetacello: anExecutorSpec value ].
    ^ Smalltalk at: anExecutorSpec key! !


ConfigurationOf subclass: #BaselineOf
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Metacello-Base'!
!BaselineOf commentStamp: 'dkh 5/30/2012 16:30' prior: 0!
**BaselineOf** is the common superclass for all Metacello baselines.

A short description of why you would want to use a **BaselineOf**.

To create a new Metacello baseline

1. Create a subclass of the class BaselineOf appending the name of
   your project (don't forget to change the **category:** to match the
   name of the configuration class):

    ```Smalltalk
    BaselineOf subclass: #BaselineOfExample
      instanceVariableNames: ''
      classVariableNames: ''
      poolDictionaries: ''
      category: 'BaselineOfExample'
    ```

2. Create a **baseline:** method where you specify the structure of your project:

    ```Smalltalk
    baseline: spec
      <baseline>

      spec for: #common do: [
        spec
          package: 'Example-Core';
          package: 'Example-Tests' with: [
            spec requires: 'Example-Core' ]].
    ```

3. Create a Monticello package for your **BaselineOf** class and save it in the repository where your packages are stored.!


!BaselineOf methodsFor: 'accessing' stamp: 'dkh 5/31/2012 17:57:13'!
projectClass
    ^ MetacelloMCBaselineProject! !

!BaselineOf methodsFor: 'accessing' stamp: 'dkh 6/22/2012 12:09'!
versionNumberClass
    ^ MetacelloVersionNumber! !

