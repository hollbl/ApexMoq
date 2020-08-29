public class Times{
    private final Boolean m_atLeast;
    private final Integer m_count;
    private Times(Integer count){
        m_atLeast = false;
        m_count = count;
    }
    private Times(Boolean atLeast, Integer count){
        m_atLeast = atLeast;
        m_count = count;
    }
    public static Times Exactly(Integer count){
        return new Times(count);
    }
    public static Times Never {get{
        return Times.Exactly(0);
    }}
    public static Times Once {get{
        return Times.Exactly(1);
    }}
    public static Times Twice {get{
        return Times.Exactly(2);
    }}
    public static Times Thrice {get{
        return Times.Exactly(3);
    }}
    public static Times AtLeastOnce {get{
        return Times.AtLeast(1);
    }}
    public static Times AtLeast(Integer count){
        return new Times(true, count);
    }
    public Integer Count {get{return m_count;}}
    public Boolean IsAtLeast {get{return m_atLeast;}}
}