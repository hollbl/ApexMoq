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
        public List<Object> arguments = new List<Object>();
        public List<Object> returnValues = new List<Object>();
        public Object returnValue;
        public Integer timesCalled = 0;
        public Boolean isSequence = false;
        
        public ISetupInvocation returns(Object setReturnValue){
            returnValues.add(setReturnValue);
            returnValue = setReturnValue;
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
        Invocation scenario = addSetup(methodName,arguments, false);
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
        Invocation scenario = addSetup(methodName,arguments,true);
        return scenario;
    }
    
    public IVerifyInvocation verify(String methodName){
        return verify(methodName,null);
    }
    
    public IVerifyInvocation verify(String methodName, List<Object> arguments){
        Invocation testCall = new Invocation();
        testCall.methodName = methodName;
        testCall.arguments = arguments;
        
        if(invocations.containsKey(methodName)){
            for(Invocation call : invocations.get(methodName)){
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
        return setupReturnValue(thisCall);
    }
    
    private Invocation addSetup(String methodName, List<Object> arguments, Boolean isSequence){
        Invocation setup = new Invocation();
        setup.methodName = methodName;
        setup.arguments = arguments;
        setup.isSequence = isSequence;
        
        if(!setups.containsKey(methodName)){
            setups.put(methodName,new List<Invocation>());
        }
        setups.get(methodName).add(setup);
        return setup;
    }
    
    private Invocation addSetupAsDefault(String methodName){
    	Invocation setup = addSetup(methodName, null, false);
        
        if(!defaultSetups.containsKey(methodName)){
            defaultSetups.put(methodName,new List<Invocation>());
        }
        defaultSetups.get(methodName).add(setup);
        return setup;
    }
        
    private Invocation recordInvocation(String methodName, List<Object> arguments){
        Invocation call = new Invocation();
        call.methodName = methodName;
        call.arguments = arguments;
        call.timesCalled = 1;
        
        if(!invocations.containsKey(methodName)){
            invocations.put(methodName,new List<Invocation>());
        }
        
        Boolean registeredToPreviousCall = false;
        for(Invocation previousCall : invocations.get(methodName)){
            if(allArgumentsMatch(call, previousCall)){
                registeredToPreviousCall = true;
                previousCall.timesCalled += 1;
                call.timesCalled = previousCall.timesCalled;
            }
        }
        
        if(registeredToPreviousCall == false){
            invocations.get(methodName).add(call);
        }
        
        return call;
    }
    
    private Object setupReturnValue(Invocation actualCall){
        if(setups.get(actualCall.methodName) != null){
            for(Invocation setupCall : setups.get(actualCall.methodName)){
                if(allArgumentsMatch(actualCall,setupCall)){
                    if(setupCall.isSequence){
                        if(setupCall.returnValues.size() >= actualCall.timesCalled){
                            actualCall.returnValue = setupCall.returnValues[actualCall.timesCalled - 1];
                            return actualCall.returnValue;
                        } 
                    }else{
                        actualCall.returnValue = setupCall.returnValue;
                        return actualCall.returnValue;
                    }

                }
            }
        }

        if(defaultSetups.get(actualCall.methodName) != null){
            for(Invocation setupCall : defaultSetups.get(actualCall.methodName)){
                actualCall.returnValue = setupCall.returnValue;
                return actualCall.returnValue;
            }
        }

        actualCall.returnValue = DEFAULT_RETURN_VALUE;
        return actualCall.returnValue;
    }
    
    private Boolean allArgumentsMatch(Invocation call1, Invocation call2){
        Integer argumentCount1 = (call1.arguments != null) ? call1.arguments.size() : 0;
        Integer argumentCount2 = (call2.arguments != null) ? call2.arguments.size() : 0;
        
        if(argumentCount1 != argumentCount2){return false;}

        Integer matchingArgumentCount = 0;
        for(Integer i=0; i<argumentCount1; i++){
            if(String.valueOf(call1.arguments[0]) == String.valueOf(call2.arguments[0])){
                matchingArgumentCount++;
            }
    	}
        return (matchingArgumentCount == argumentCount1);
    }
}