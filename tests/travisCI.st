"Load and run tests to be performed by TravisCI"
Transcript cr; show: 'travis---->travisCI.st'.

"Use the Sample project to verify that Metacello and FileTree are 
 booting correctly"

[Metacello new
  configuration: 'Sample';
  version: '0.9.0';
  repository: 'github://dalehenrich/sample:configuration';
  load: 'Tests' ]
        on: Warning
        do: [:ex |
                Transcript cr; show: 'Warning: ', ex description.
                ex resume: true].
Transcript cr; show: '  Finished load.'.

"Run the tests"
TravisCIHarness
  value: #( 'ConfigurationOfSample' )
  value: 'TravisCISuccess.txt' 
  value: 'TravisCIFailure.txt'.
