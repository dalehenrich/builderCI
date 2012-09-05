"Sample travisCI.st file:

  Edit the Metacello api and test harness invocation
  using the correct configuration name and repository 
  location"

"Use Metacello to load your project and tests"
Metacello new
  configuration: 'MyProject';
  repository: 'filetree://', MetacelloBuilderTravisCI gitPath, '/MyProject/repository';
  load: 'Tests'.

"Run the tests"
TravisCIHarness
  value: #( 'ConfigurationOfMyProject' )
  value: 'TravisCISuccess.txt' 
  value: 'TravisCIFailure.txt'.

