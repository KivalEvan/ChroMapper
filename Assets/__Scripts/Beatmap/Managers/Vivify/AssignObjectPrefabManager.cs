using System;
using System.Collections.Generic;
using SimpleJSON;
using UnityEngine;
using ZLinq;

public class AssignObjectPrefabManager
{
    public VisualRepositorySO VisualRepository;
    public TracksManager TracksManager;
    private readonly Dictionary<string, TrackModelState> trackToTrackModelState = new();

    public struct ActiveModelResult
    {
        public VisualModelSO OverrideModel;
        public List<VisualModelSO> AdditiveModels;

        public ActiveModelResult(List<VisualModelSO> list)
        {
            OverrideModel = null;
            AdditiveModels = list;
        }
    }

    // TODO: actually cache them so we dont keep doing the search
    private List<TrackModelState.ModelContainer.PriorityModel> cachedSet = new();
    private List<TrackModelState.ModelContainer.PriorityModel> cachedAdditive = new();
    private ActiveModelResult cachedResult = new(new());

    public ActiveModelResult GetCurrentModels(TrackModelState.Kind kind, string track)
    {
        cachedResult.OverrideModel = null;

        if (!trackToTrackModelState.TryGetValue(track, out var trackModel)) return cachedResult;
        var model = trackModel.GetModel(kind);
        if (model.HasSet) cachedResult.OverrideModel = model.Model.Model;
        model.Models.AsValueEnumerable().Select(x => x.Model).CopyTo(cachedResult.AdditiveModels);

        return cachedResult;
    }

    public ActiveModelResult GetCurrentModels(TrackModelState.Kind kind, string[] tracks)
    {
        cachedResult.OverrideModel = null;
        
        cachedSet.Clear();
        cachedAdditive.Clear();

        foreach (var track in tracks)
        {
            if (!trackToTrackModelState.TryGetValue(track, out var trackModel)) continue;
            var model = trackModel.GetModel(kind);
            if (model.HasSet) cachedSet.Add(model.Model);
            cachedAdditive.AddRange(model.Models);
        }

        var lastSet = cachedSet.AsValueEnumerable().FirstOrDefault();
        if (lastSet.Model != null)
        {
            cachedAdditive
                .AsValueEnumerable()
                .Where(x => x.Priority >= lastSet.Priority)
                .Select(x => x.Model)
                .CopyTo(cachedResult.AdditiveModels);
        }
        else
            cachedAdditive.AsValueEnumerable().Select(x => x.Model).CopyTo(cachedResult.AdditiveModels);

        cachedResult.OverrideModel = lastSet.Model;

        return cachedResult;
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

        if (!TracksManager.AnimationTracks.TryGetValue(track, out var animationTrack)) return;
        foreach (var child in animationTrack.Children) child.AnimationTrack.NotifyModelChanged();
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

        if (!TracksManager.AnimationTracks.TryGetValue(track, out var animationTrack)) return;
        foreach (var child in animationTrack.Children) child.AnimationTrack.NotifyModelChanged();
    }
}
