# ApexMoq
### Inspired by the Moq library for .NET, for use with Salesforce/Apex programming unit testing

useage:
```
MockOfSomeInterface mock = new MockOfSomeInterface();

// instruct mock to return 'someValue' when methodName('expectedArguments') is called...
mock.setup('methodName',new List<Object>{'expectedArguments'}).returns('someValue');

//perform test...

// ask mock to confirm that methodName('expectedArguments') was called only 1 time...
mock.verify('methodName',new List<Object>{'expectedArguments'}).times(1);
```
