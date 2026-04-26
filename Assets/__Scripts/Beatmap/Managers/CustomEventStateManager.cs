using Beatmap.Base.Customs;

public class CustomEventStateManager : StateManager<CustomEventStateData, BaseCustomEvent>
{
    public VisualRepositorySO VisualRepository;
    public VivifyAssetBundleManager VivifyAssetBundleManager;
    public TracksManager TracksManager;

    private readonly InstantiateObjectPrefabManager instantiateObjectPrefabManager = new();
    public readonly AssignObjectPrefabManager AssignObjectPrefabManager = new();
    private readonly StateChunksContainer<CustomEventStateData, BaseCustomEvent> container = new();

    public override void Initialize()
    {
        instantiateObjectPrefabManager.VivifyAssetBundleManager = VivifyAssetBundleManager;
        AssignObjectPrefabManager.VisualRepository = VisualRepository;
        AssignObjectPrefabManager.TracksManager = TracksManager;
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
        switch (state.Base.Type)
        {
            case "InstantiatePrefab":
                instantiateObjectPrefabManager.InstantiateVivifyObject(state);
                break;
            case "DestroyObject":
                instantiateObjectPrefabManager.RemoveVivifyObjectById(state);
                break;
            case "AssignObjectPrefab":
                AssignObjectPrefabManager.Assign(state, container.Collection.IndexOf(state));
                break;
        }
    }

    private void RevertEvent(CustomEventStateData state)
    {
        switch (state.Base.Type)
        {
            case "InstantiatePrefab":
                instantiateObjectPrefabManager.RemoveVivifyObjectByState(state);
                break;
            case "DestroyObject":
                instantiateObjectPrefabManager.ReinstantiateVivifyObject(state);
                break;
            case "AssignObjectPrefab":
                AssignObjectPrefabManager.Remove(state);
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
