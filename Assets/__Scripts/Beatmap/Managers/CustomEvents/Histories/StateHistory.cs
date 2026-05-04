public abstract class CustomEventStateHistory
{
    public abstract void Revert();
}

public abstract class ObjectPropertyStateHistory : CustomEventStateHistory
{
    protected readonly string Property;
    protected ObjectPropertyStateHistory() { }
    protected ObjectPropertyStateHistory(string property) => Property = property;
}
