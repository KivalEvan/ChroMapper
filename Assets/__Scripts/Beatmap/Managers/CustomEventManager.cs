using System.Collections.Generic;
using Beatmap.Base.Customs;
using UnityEngine;

public class CustomEventManager : BeatmapObjectManager<BaseCustomEvent>
{
    [SerializeField] private CustomEventStateManager manager;

    protected override void Awake()
    {
        base.Awake();
        LoadInitialMap.OnLevelLoaded += Refresh;
        LoadedDifficultySelectController.OnLoadedDifficultyChanged += Refresh;
    }

    protected override void OnDestroy()
    {
        base.OnDestroy();
        LoadInitialMap.OnLevelLoaded -= Refresh;
        LoadedDifficultySelectController.OnLoadedDifficultyChanged -= Refresh;
        Context.Atsc.OnTimeChangedEarly -= UpdateTime;
    }

    public override void Refresh()
    {
        manager.Initialize();
        BeatSaberSongContainer.Instance.Map.CustomEvents.ForEach(manager.InsertData);

        Context.Atsc.OnTimeChangedEarly += UpdateTime;
    }

    public override void UpdateTime() => UpdateTime(Context.Atsc.IsPlaying, Context.Atsc.CurrentSongBpmTime);
    public override void UpdateTime(bool isPlaying, float beatTime) => manager.UpdateTime(isPlaying, beatTime);

    protected override bool AddData(IEnumerable<BaseCustomEvent> data)
    {
        var mark = false;
        foreach (var d in data)
        {
            manager.InsertData(d);
            mark = true;
        }

        return mark;
    }

    protected override bool RemoveData(IEnumerable<(BaseCustomEvent reference, BaseCustomEvent original)> data)
    {
        var mark = false;
        foreach (var (reference, original) in data)
        {
            manager.RemoveData(reference, original);
            mark = true;
        }

        return mark;
    }

    protected override bool RemoveData(IEnumerable<BaseCustomEvent> data)
    {
        var mark = false;
        foreach (var d in data)
        {
            manager.RemoveData(d, d);
            mark = true;
        }

        return mark;
    }
}
