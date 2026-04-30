using Beatmap.Base.Customs;
using UnityEngine;

public class CustomEventStateManager : StateManager<CustomEventStateData, BaseCustomEvent>
{
    public VisualRepositorySO VisualRepository;
    public VivifyAssetBundleManager VivifyAssetBundleManager;
    public TracksManager TracksManager;

    private readonly InstantiateObjectPrefabManager instantiateObjectPrefabManager = new();
    public readonly AssignObjectPrefabManager AssignObjectPrefabManager = new();
    private readonly ObjectPropertyManager objectPropertyManager = new();
    private readonly StateChunksContainer<CustomEventStateData, BaseCustomEvent> container = new();
    private readonly TweenManager tweenManager = new();

    public override void Initialize()
    {
        if (BeatSaberSongContainer.Instance.Map.CustomData["pointDefinitions"] != null
            && BeatSaberSongContainer.Instance.Map.CustomData["pointDefinitions"].IsObject)
        {
            foreach (var (n, pd) in BeatSaberSongContainer.Instance.Map.CustomData["pointDefinitions"])
                PointDefinitionParser.Get(n, pd);
        }

        instantiateObjectPrefabManager.VivifyAssetBundleManager = VivifyAssetBundleManager;
        AssignObjectPrefabManager.VisualRepository = VisualRepository;
        AssignObjectPrefabManager.TracksManager = TracksManager;
        objectPropertyManager.InstantiateObjectPrefabManager = instantiateObjectPrefabManager;
        objectPropertyManager.VivifyAssetBundleManager = VivifyAssetBundleManager;
        objectPropertyManager.TweenManager = tweenManager;

        InitializeStates(
            container,
            CreateState(new() { songBpmTime = short.MinValue, JsonTime = short.MinValue }),
            CreateState(new() { songBpmTime = short.MaxValue, JsonTime = short.MaxValue }));
    }

    public override void Refresh()
    {
    }

    public override void UpdateTime(bool isPlaying, float time)
    {
        if (!container.CurrentState.IsWithinRange(time))
        {
            var isNext = container.IsNextDirection(time);

            // yea we have to fire this event outside of loop
            if (!isNext) RevertEvent(container.CurrentState);
            while (container.EnumerateTo(time, isNext))
            {
                if (isNext)
                    FireEvent(container.CurrentState);
                else
                    RevertEvent(container.CurrentState);
            }

            if (isNext) FireEvent(container.CurrentState);
        }

        if (isPlaying)
            tweenManager.UpdateForward(time);
        else
            tweenManager.UpdateJump(time);
    }

    private void FireEvent(CustomEventStateData state)
    {
        switch (state.Base.Type)
        {
            case "SetMaterialProperty":
                objectPropertyManager.AssignMaterial(state);
                break;
            case "SetGlobalProperty":
                objectPropertyManager.AssignGlobal(state);
                break;
            case "SetAnimatorProperty":
                objectPropertyManager.AssignAnimator(state);
                break;
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
            case "SetMaterialProperty":
            case "SetGlobalProperty":
            case "SetAnimatorProperty":
                objectPropertyManager.Revert(state);
                break;
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
        state.StartSecondTime = Atsc.GetSecondsFromBeat(data.SongBpmTime);
        HandleInsertState(container, state);
    }

    public override void RemoveData(BaseCustomEvent reference, BaseCustomEvent original) =>
        HandleRemoveState(container, reference, original);

    protected override CustomEventStateData CreateState(BaseCustomEvent data) => new(data);
}

public class CustomEventStateData : StateData<BaseCustomEvent>
{
    public float StartSecondTime;
    public CustomEventStateData(BaseCustomEvent data) : base(data) { }
}
