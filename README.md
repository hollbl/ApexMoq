# ApexMoq
### Inspired by the Moq library for .NET, for use with Salesforce/Apex unit testing

So there's an interface defined that you'd like to be able to mock:
```
public interface IMyInterface {
  String methodName(String arg);
}
```

Define an implementation of the interface that extends the ApexMoq class:
```
public class MockOfIMyInterface extends ApexMoq implements IMyInterface {
  public String methodName(String arg){
    return (String)handleMethodInvocation('methodName', new List<Object>{arg});
  }
}
```

Now create an instance of this implementation and use in your unit tests:
```
MockOfIMyInterface mock = new MockOfIMyInterface();

// instruct mock to return 'someValue' when methodName('expectedArguments') is called...
mock.setup('methodName', new List<Object>{'expectedArguments'}).returns('someValue');

//perform test...

// ask mock to confirm that methodName('expectedArguments') was called only 1 time...
mock.verify('methodName', new List<Object>{'expectedArguments'}).times(1);
```
