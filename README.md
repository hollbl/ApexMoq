# ApexMoq
### Inspired by the Moq library for .NET, for use with Salesforce/Apex programming unit testing

```
public interface IMyInterface {
  String methodName(String arg);
}

public class MockOfIMyInterface extends ApexMoq implements IMyInterface {
  public String methodName(String arg){
    return (String)handleMethodInvocation('methodName', new List<Object>{arg});
  }
}

MockOfIMyInterface mock = new MockOfIMyInterface();

// instruct mock to return 'someValue' when methodName('expectedArguments') is called...
mock.setup('methodName', new List<Object>{'expectedArguments'}).returns('someValue');

//perform test...

// ask mock to confirm that methodName('expectedArguments') was called only 1 time...
mock.verify('methodName', new List<Object>{'expectedArguments'}).times(1);
```
