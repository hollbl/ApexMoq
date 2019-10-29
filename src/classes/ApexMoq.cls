public virtual class ApexMoq{

    public static Arguments ARGUMENTS_HAVE_ANY_VALUE = Arguments.HAVE_ANY_VALUE;
    public enum Arguments {HAVE_ANY_VALUE}

    public interface ISetupInvocation{
       ISetupInvocation returns(Object setReturnValue);
       ISetupInvocation throws(Exception setThrowValue);
    }

    public interface IVerifyInvocation{
        void times(Integer expected);
        void atLeastOnce();
        void never();
        void once();
        void twice();
        void thrice();
        Integer timesCalled();
    }

    private class Invocation implements ISetupInvocation, IVerifyInvocation{
        public String methodName;
        public String arguments;
        public List<Object> returnValues = new List<Object>();
        public Object returnValue;
        public Exception throwValue;
        public Integer timesCalled = 0;
        public Boolean isSequence = false;
        public List<Object> argumentObjects;
        
        public ISetupInvocation returns(Object setReturnValue){
            returnValues.add(setReturnValue);
            returnValue = setReturnValue;
            ApexMoq.log('Setup Invocation Return: ' + this);
            return this;
        }

        public ISetupInvocation throws(Exception setThrowValue){
            throwValue = setThrowValue;
            log('Setup Invocation Throw: ' + this);
            return this;
        }

        public Integer timesCalled(){
            return timesCalled;
        }
        
        public void times(Integer expected){
            if(timesCalled <> expected){
                String msg = 'Expected invocation of method ' + methodName + '(' + String.valueOf(arguments) + ') on Mock ' + String.valueOf(expected) + ' times, but invocation was made ' + String.valueOf(timesCalled) + ' times.';
                System.assert(false, msg);
            }
        }
        
        public void atLeastOnce(){
            if(timesCalled == 0){
                String msg = 'Expected invocation of method ' + methodName + '(' + String.valueOf(arguments) + ') on Mock at least once, but invocation was never made.';
                System.assert(false, msg);
            }
        }
        
        public void never(){
            times(0);
        }
        
        public void once(){
            times(1);
        }

        public void twice(){
            times(2);
        }

        public void thrice(){
            times(3);
        }
    }
    
    private final Integer hashCode = System.hashCode(this);
    private Object DEFAULT_RETURN_VALUE = null;
    private Map<String,List<Invocation>> setups = new Map<String,List<Invocation>>();
    private Map<String,List<Invocation>> defaultSetups = new Map<String,List<Invocation>>();
    private Map<String,List<Invocation>> invocations = new Map<String,List<Invocation>>();
    private Map<String,List<List<Object>>> argumentsByMethodName = new Map<String,List<List<Object>>>();
    
    public ISetupInvocation setup(String methodName){
        return setup(methodName, (List<Object>)null);
    }
    
    public ISetupInvocation setup(String methodName, List<Object> arguments){
        Invocation scenario = addSetup(methodName,arguments);
        return scenario;
    }
    
    public ISetupInvocation setup(String methodName, Arguments anyArgs){
        Invocation scenario = addSetupAsDefault(methodName);
        return scenario;
    }

    public ISetupInvocation setupSequence(String methodName){
        return setupSequence(methodName, (List<Object>)null);
    }

    public ISetupInvocation setupSequence(String methodName, List<Object> arguments){
        Invocation scenario = addSetup(methodName,arguments);
        scenario.isSequence = true;
        return scenario;
    }

    public ISetupInvocation setupSequence(String methodName, Arguments anyArgs){
        Invocation scenario = addSetupAsDefault(methodName);
        scenario.isSequence = true;
        return scenario;
    }
    
    public IVerifyInvocation verify(String methodName){
        return verify(methodName,new List<Object>());
    }
    
    public IVerifyInvocation verify(String methodName, List<Object> arguments){
        if(arguments.size() == 0) arguments = null;

        Invocation testCall = new Invocation();
        testCall.methodName = methodName;
        testCall.arguments = String.valueOf(arguments);

        log('Verifying: ' + testCall);
        
        if(invocations.containsKey(invocationKey(testCall))){
            for(Invocation call : invocations.get(invocationKey(testCall))){
                if(allArgumentsMatch(call, testCall)){
                    return call;
                }
            }
        }

        return testCall;
    }

    public IVerifyInvocation verify(String methodName, Arguments anyArgs){
        Invocation testCall = new Invocation();
        testCall.methodName = methodName;
        testCall.arguments = '{{Arguments.HAVE_ANY_VALUE}}';

        log('Verifying: ' + testCall);
        
        if(invocations.containsKey(invocationKey(testCall))){
            for(Invocation call : invocations.get(invocationKey(testCall))){
                testCall.timesCalled += call.timesCalled;
            }
        }

        return testCall;
    }

    public List<Object> getArgumentsFromCall(String methodName){
        return argumentsByMethodName.get(methodName).get(0);
    }

    public List<Object> getArgumentsFromCall(String methodName, Integer invocationNumber){
        return argumentsByMethodName.get(methodName).get(invocationNumber-1);
    }
    
    protected Object handleMethodInvocation(String methodName){
        return handleMethodInvocation(methodName, null);
    }
    
    protected Object handleMethodInvocation(String methodName, List<Object> arguments){
        Invocation thisCall = recordInvocation(methodName,arguments);
        thisCall.returnValue = getReturnValue(thisCall);
        thisCall.throwValue = getThrowValue(thisCall);
        log('Method Invoked: ' + thisCall);
        if(thisCall.throwValue != null) throw thisCall.throwValue;
        return thisCall.returnValue;
    }
    
    private Invocation addSetup(String methodName, List<Object> arguments){
        Invocation setup = new Invocation();
        setup.methodName = methodName;
        setup.arguments = String.valueOf(arguments);
        
        if(!setups.containsKey(invocationKey(setup))){
            setups.put(invocationKey(setup),new List<Invocation>());
        }
        setups.get(invocationKey(setup)).add(setup);

        return setup;
    }
    
    private Invocation addSetupAsDefault(String methodName){
        Invocation setup = addSetup(methodName, null);
        
        if(!defaultSetups.containsKey(invocationKey(setup))){
            defaultSetups.put(invocationKey(setup),new List<Invocation>());
        }
        defaultSetups.get(invocationKey(setup)).add(setup);
        log('Setup Invocation As Default: ' + setup);
        return setup;
    }
        
    private Invocation recordInvocation(String methodName, List<Object> arguments){
        Invocation call = new Invocation();
        call.methodName = methodName;
        call.arguments = String.valueOf(arguments);
        call.timesCalled = 1;
        
        if(!invocations.containsKey(invocationKey(call))){
            invocations.put(invocationKey(call),new List<Invocation>());
        }
        
        Boolean registeredToPreviousCall = false;
        for(Invocation previousCall : invocations.get(invocationKey(call))){
            if(allArgumentsMatch(call, previousCall)){
                registeredToPreviousCall = true;
                previousCall.timesCalled += 1;
                call.timesCalled = previousCall.timesCalled;
            }
        }
        
        if(registeredToPreviousCall == false){
            invocations.get(invocationKey(call)).add(call);
        }

        recordInvocationByMethodName(methodName,arguments);
        
        return call;
    }

    private void recordInvocationByMethodName(String methodName, List<Object> arguments){
        if(!argumentsByMethodName.containsKey(methodName)){
            argumentsByMethodName.put(methodName,new List<List<Object>>());
        }
        argumentsByMethodName.get(methodName).add(arguments);
    }
    
    private Object getReturnValue(Invocation actualCall){
        if(setups.get(invocationKey(actualCall)) != null){
            for(Invocation setupCall : setups.get(invocationKey(actualCall))){
                if(allArgumentsMatch(actualCall,setupCall)){
                    if(setupCall.isSequence){
                        if(setupCall.returnValues.size() >= actualCall.timesCalled){
                            log('getReturnValue--Returning Sequence Call ' + actualCall.timesCalled);
                            return setupCall.returnValues[actualCall.timesCalled - 1];
                        } 
                    }else{
                        log('getReturnValue--Returning Specified Value for ' + actualCall);
                        return setupCall.returnValue;
                    }
                }else{
                    log('getReturnValue--Arguments do not match, actual: ' + actualCall + ', setup: ' + setupCall);
                }
            }
        }

        if(defaultSetups.get(invocationKey(actualCall)) != null){
            log('getReturnValue--Returning Default Value for ' + actualCall);
            for(Invocation setupCall : defaultSetups.get(invocationKey(actualCall))){
                return setupCall.returnValue;
            }
        }

        log('getReturnValue--No setup found for ' + actualCall);
        return DEFAULT_RETURN_VALUE;
    }

    private Exception getThrowValue(Invocation actualCall){
        if(setups.get(invocationKey(actualCall)) != null){
            for(Invocation setupCall : setups.get(invocationKey(actualCall))){
                if(allArgumentsMatch(actualCall,setupCall)){
                    return setupCall.throwValue;
                }
            }
        }
        if(defaultSetups.get(invocationKey(actualCall)) != null){
            for(Invocation setupCall : defaultSetups.get(invocationKey(actualCall))){
                return setupCall.throwValue;
            }
        }
        return null;
    }
    
    private Boolean allArgumentsMatch(Invocation call1, Invocation call2){
        return (call1.arguments == call2.arguments);
    }

    private String invocationKey(Invocation call){
        return call.methodName.toUpperCase();
    }

    private static void log(Object content){
        String prefix = '###apexmoq###';
        System.debug(prefix + String.valueOf(content));
    }
}
