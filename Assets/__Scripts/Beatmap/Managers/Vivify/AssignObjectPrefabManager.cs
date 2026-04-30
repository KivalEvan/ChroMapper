using System.Collections.Generic;
using SimpleJSON;
using ZLinq;

public class AssignObjectPrefabManager
{
    public VisualRepositorySO VisualRepository;
    public TracksManager TracksManager;

    public struct ActiveModelResult
    {
        public VisualModelSO OverrideModel;
        public readonly List<VisualModelSO> AdditiveModels;
        public bool HasOverride;

        public ActiveModelResult(List<VisualModelSO> list)
        {
            OverrideModel = null;
            AdditiveModels = list;
            HasOverride = false;
        }
    }

    private readonly Dictionary<string, TrackModelState> trackToTrackModelState = new();

    // TODO: actually cache them so we dont keep doing the search
    private TrackModelState.ModelContainer.PriorityModel cachedSet;
    private readonly List<TrackModelState.ModelContainer.PriorityModel> cachedAdditive = new();
    private ActiveModelResult cachedResult = new(new());

    public ref ActiveModelResult GetCurrentModels(TrackModelState.Kind kind, string track)
    {
        cachedResult.HasOverride = false;
        cachedResult.AdditiveModels.Clear();

        if (!trackToTrackModelState.TryGetValue(track, out var trackModel)) return ref cachedResult;
        var model = trackModel.GetModel(kind);
        if (model.HasSet)
        {
            cachedResult.OverrideModel = model.Model.Model;
            cachedResult.HasOverride = true;
        }

        model.Models.AsValueEnumerable().Select(x => x.Model).CopyTo(cachedResult.AdditiveModels);

        return ref cachedResult;
    }

    public ref ActiveModelResult GetCurrentModels(TrackModelState.Kind kind, string[] tracks)
    {
        cachedResult.HasOverride = false;
        cachedSet.Priority = -1;
        cachedAdditive.Clear();

        foreach (var track in tracks)
        {
            if (!trackToTrackModelState.TryGetValue(track, out var trackModel)) continue;
            var model = trackModel.GetModel(kind);
            if (model.HasSet && model.Model.Priority >= cachedSet.Priority)
            {
                cachedSet = model.Model;
                cachedResult.HasOverride = true;
            }

            cachedAdditive.AddRange(model.Models);
        }

        if (cachedResult.HasOverride)
        {
            cachedAdditive
                .AsValueEnumerable()
                .Where(x => x.Priority >= cachedSet.Priority)
                .Select(x => x.Model)
                .CopyTo(cachedResult.AdditiveModels);
        }
        else
            cachedAdditive.AsValueEnumerable().Select(x => x.Model).CopyTo(cachedResult.AdditiveModels);

        cachedResult.OverrideModel = cachedSet.Model;

        return ref cachedResult;
    }

    public void Assign(CustomEventStateData state, int index)
    {
        var data = state.Base.Data;
        var additive = data["loadMode"] != null && data["loadMode"] == "Additive";

        if (data["colorNotes"] != null)
        {
            var modelData = data["colorNotes"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
            {
                AssignModel(index, track, TrackModelState.Kind.DirectionalNote, modelData, "asset", additive);
                AssignModel(index, track, TrackModelState.Kind.AnyNote, modelData, "anyDirectionAsset", additive);
            }
        }

        if (data["bombNotes"] != null)
        {
            var modelData = data["bombNotes"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
                AssignModel(index, track, TrackModelState.Kind.Bomb, modelData, "asset", additive);
        }

        if (data["burstSliders"] != null)
        {
            var modelData = data["burstSliders"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
                AssignModel(index, track, TrackModelState.Kind.BurstSlider, modelData, "asset", additive);
        }

        if (data["burstSliderElements"] != null)
        {
            var modelData = data["burstSliderElements"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
            {
                AssignModel(index, track, TrackModelState.Kind.BurstSliderElement, modelData, "asset", additive);
            }
        }
    }

    private void AssignModel(
        int index,
        string track,
        TrackModelState.Kind kind,
        JSONNode json,
        string target,
        bool additive)
    {
        if (!json.HasKey(target)) return;
        var asset = json[target] != null ? VisualRepository.ModelsByName.GetValueOrDefault(json[target]) : null;
        trackToTrackModelState.TryAdd(track, new TrackModelState());
        var trackModel = trackToTrackModelState[track];
        if (additive)
            trackModel.AddModel(kind, asset, index);
        else
            trackModel.SetModel(kind, asset, index);
    }

    public void Remove(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var additive = data["loadMode"] != null && data["loadMode"] == "Additive";

        if (data["colorNotes"] != null)
        {
            var modelData = data["colorNotes"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
            {
                RemoveModel(track, TrackModelState.Kind.DirectionalNote, modelData, "asset", additive);
                RemoveModel(track, TrackModelState.Kind.AnyNote, modelData, "anyDirectionAsset", additive);
            }
        }

        if (data["bombNotes"] != null)
        {
            var modelData = data["bombNotes"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
                RemoveModel(track, TrackModelState.Kind.Bomb, modelData, "asset", additive);
        }

        if (data["burstSliders"] != null)
        {
            var modelData = data["burstSliders"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
                RemoveModel(track, TrackModelState.Kind.BurstSlider, modelData, "asset", additive);
        }

        if (data["burstSliderElements"] != null)
        {
            var modelData = data["burstSliderElements"];
            var track = modelData["track"];
            if (!string.IsNullOrEmpty(track))
                RemoveModel(track, TrackModelState.Kind.BurstSliderElement, modelData, "asset", additive);
        }
    }

    private void RemoveModel(string track, TrackModelState.Kind kind, JSONNode json, string target, bool additive)
    {
        if (!trackToTrackModelState.TryGetValue(track, out var trackModel)) return;
        var asset = json[target] != null ? VisualRepository.ModelsByName.GetValueOrDefault(json[target]) : null;
        if (additive)
            trackModel.RemoveModel(kind, asset);
        else
            trackModel.UnsetModel(kind);
    }
}
