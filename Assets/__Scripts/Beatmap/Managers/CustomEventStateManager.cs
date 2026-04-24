using Beatmap.Base.Customs;

public class CustomEventStateManager : StateManager<CustomEventStateData, BaseCustomEvent>
{
    public VivifyAssetBundleManager VivifyAssetBundleManager;
    public TracksManager TracksManager;

    private readonly ObjectPrefabManager objectPrefabManager = new();
    private readonly StateChunksContainer<CustomEventStateData, BaseCustomEvent> container = new();

    public override void Initialize()
    {
        objectPrefabManager.VivifyAssetBundleManager = VivifyAssetBundleManager;
        InitializeStates(
            container,
            CreateState(new() { songBpmTime = short.MinValue, JsonTime = short.MinValue }),
            CreateState(new() { songBpmTime = short.MaxValue, JsonTime = short.MaxValue }));
    }

    public override void Refresh()
    {
    }

    public override void UpdateTime(bool _, float time)
    {
        var isNext = container.IsNextDirection(time);
        var enumerator = container.EnumerateTo(time);
        while (enumerator.MoveNext())
        {
            var state = enumerator.Current;
            if (isNext)
                FireEvent(state);
            else
                RevertEvent(state);
        }
    }

    private void FireEvent(CustomEventStateData state)
    {
        var data = state.Base.Data;
        switch (state.Base.Type)
        {
            case "InstantiatePrefab":
                objectPrefabManager.InstantiateVivifyObject(state);
                break;
            case "DestroyObject":
                objectPrefabManager.RemoveVivifyObjectById(state);
                break;
        }
    }

    private void RevertEvent(CustomEventStateData state)
    {
        switch (state.Base.Type)
        {
            case "InstantiatePrefab":
                objectPrefabManager.RemoveVivifyObjectByState(state);
                break;
            case "DestroyObject":
                objectPrefabManager.ReinstantiateVivifyObject(state);
                break;
        }
    }

    public override void InsertData(BaseCustomEvent data)
    {
        var state = CreateState(data);
        state.StartTime = data.SongBpmTime;
        HandleInsertState(container, state);
    }

    public override void RemoveData(BaseCustomEvent reference, BaseCustomEvent original) =>
        HandleRemoveState(container, reference, original);

    protected override CustomEventStateData CreateState(BaseCustomEvent data) =>
        new(data, Atsc.GetSecondsFromBeat(data.SongBpmTime));
}

public class CustomEventStateData : StateData<BaseCustomEvent>
{
    public float StartSecondTime;
    public CustomEventStateData(BaseCustomEvent data, float secondTime) : base(data) => StartSecondTime = secondTime;
}
