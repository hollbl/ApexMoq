public virtual class ApexMoq{    

    public enum Arguments {HAVE_ANY_VALUE}

    public interface ISetupInvocation{
       ISetupInvocation returns(Object setReturnValue);
    }

    public interface IVerifyInvocation{
        void times(Integer expected);
        void atLeastOnce();
        void never();
        void once();
        Integer timesCalled();
    }

    private class Invocation implements ISetupInvocation, IVerifyInvocation{
        public String methodName;
        public String arguments;
        public List<Object> returnValues = new List<Object>();
        public Object returnValue;
        public Integer timesCalled = 0;
        public Boolean isSequence = false;
        
        public ISetupInvocation returns(Object setReturnValue){
            returnValues.add(setReturnValue);
            returnValue = setReturnValue;
            System.debug('Setup Invocation: ' + this);
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
    }
    
    private Object DEFAULT_RETURN_VALUE = null;
    private Map<String,List<Invocation>> setups = new Map<String,List<Invocation>>();
    private Map<String,List<Invocation>> defaultSetups = new Map<String,List<Invocation>>();
    private Map<String,List<Invocation>> invocations = new Map<String,List<Invocation>>();
    
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
        return verify(methodName,null);
    }
    
    public IVerifyInvocation verify(String methodName, List<Object> arguments){
        Invocation testCall = new Invocation();
        testCall.methodName = methodName;
        testCall.arguments = String.valueOf(arguments);

        System.debug('Verifying: ' + testCall);
        
        if(invocations.containsKey(invocationKey(testCall))){
            for(Invocation call : invocations.get(invocationKey(testCall))){
                if(allArgumentsMatch(call, testCall)){
                    return call;
                }
            }
        }

        return testCall;
    }
    
    protected Object handleMethodInvocation(String methodName){
        return handleMethodInvocation(methodName, null);
    }
    
    protected Object handleMethodInvocation(String methodName, List<Object> arguments){
        Invocation thisCall = recordInvocation(methodName,arguments);
        thisCall.returnValue = getReturnValue(thisCall);
        System.debug('Method Invoked: ' + thisCall);
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
        
        return call;
    }
    
    private Object getReturnValue(Invocation actualCall){
        if(setups.get(invocationKey(actualCall)) != null){
            for(Invocation setupCall : setups.get(invocationKey(actualCall))){
                if(allArgumentsMatch(actualCall,setupCall)){
                    if(setupCall.isSequence){
                        if(setupCall.returnValues.size() >= actualCall.timesCalled){
                            return setupCall.returnValues[actualCall.timesCalled - 1];
                        } 
                    }else{
                        return setupCall.returnValue;
                    }

                }
            }
        }

        if(defaultSetups.get(invocationKey(actualCall)) != null){
            for(Invocation setupCall : defaultSetups.get(invocationKey(actualCall))){
                return setupCall.returnValue;
            }
        }

        return DEFAULT_RETURN_VALUE;
    }
    
    private Boolean allArgumentsMatch(Invocation call1, Invocation call2){
        return (call1.arguments == call2.arguments);
    }

    private String invocationKey(Invocation call){
        return call.methodName;
    }
}