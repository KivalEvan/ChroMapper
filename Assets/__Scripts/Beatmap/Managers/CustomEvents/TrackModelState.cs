using System;
using System.Collections.Generic;

public class TrackModelState
{
    public enum Kind : byte
    {
        DirectionalNote,
        AnyNote,
        Bomb,
        BurstSlider,
        BurstSliderElement,
    }

    public class ModelContainer
    {
        private readonly Stack<ModelContainer> histories = new();

        public struct PriorityModel
        {
            public VisualModelSO Model;
            public int Priority;
        }

        public bool HasSet;
        public PriorityModel Model;
        public List<PriorityModel> Models = new();

        public void Set(VisualModelSO model, int priority)
        {
            HasSet = true;
            histories.Push(new() { HasSet = HasSet, Model = Model, Models = new(Models) });
            Model = new PriorityModel { Model = model, Priority = priority };
            Models.Clear();
        }

        public void Add(VisualModelSO model, int priority) =>
            Models.Add(new PriorityModel { Model = model, Priority = priority });

        public void Remove(VisualModelSO model)
        {
            var index = Models.FindLastIndex(x => x.Model == model);
            if (index != -1) Models.RemoveAt(index);
        }

        public void Unset()
        {
            if (!histories.TryPop(out var history)) return;
            HasSet = history.HasSet;
            Model = history.Model;
            Models.Clear();
            Models.AddRange(history.Models);
        }
    }

    public ModelContainer DirectionalNote = new();
    public ModelContainer AnyNote = new();
    public ModelContainer Bomb = new();
    public ModelContainer BurstSlider = new();
    public ModelContainer BurstSliderElement = new();

    public void SetModel(Kind kind, VisualModelSO model, int priority)
    {
        switch (kind)
        {
            case Kind.DirectionalNote:
                DirectionalNote.Set(model, priority);
                break;
            case Kind.AnyNote:
                AnyNote.Set(model, priority);
                break;
            case Kind.Bomb:
                Bomb.Set(model, priority);
                break;
            case Kind.BurstSlider:
                BurstSlider.Set(model, priority);
                break;
            case Kind.BurstSliderElement:
                BurstSliderElement.Set(model, priority);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(kind), kind, null);
        }
    }

    public void AddModel(Kind kind, VisualModelSO model, int priority)
    {
        switch (kind)
        {
            case Kind.DirectionalNote:
                DirectionalNote.Add(model, priority);
                break;
            case Kind.AnyNote:
                AnyNote.Add(model, priority);
                break;
            case Kind.Bomb:
                Bomb.Add(model, priority);
                break;
            case Kind.BurstSlider:
                BurstSlider.Add(model, priority);
                break;
            case Kind.BurstSliderElement:
                BurstSliderElement.Add(model, priority);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(kind), kind, null);
        }
    }

    public ModelContainer GetModel(Kind kind)
    {
        return kind switch
        {
            Kind.DirectionalNote => DirectionalNote,
            Kind.AnyNote => AnyNote,
            Kind.Bomb => Bomb,
            Kind.BurstSlider => BurstSlider,
            Kind.BurstSliderElement => BurstSliderElement,
            _ => throw new ArgumentOutOfRangeException(nameof(kind), kind, null)
        };
    }

    public void RemoveModel(Kind kind, VisualModelSO model)
    {
        switch (kind)
        {
            case Kind.DirectionalNote:
                DirectionalNote.Remove(model);
                break;
            case Kind.AnyNote:
                AnyNote.Remove(model);
                break;
            case Kind.Bomb:
                Bomb.Remove(model);
                break;
            case Kind.BurstSlider:
                BurstSlider.Remove(model);
                break;
            case Kind.BurstSliderElement:
                BurstSliderElement.Remove(model);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(kind), kind, null);
        }
    }

    public void UnsetModel(Kind kind)
    {
        switch (kind)
        {
            case Kind.DirectionalNote:
                DirectionalNote.Unset();
                break;
            case Kind.AnyNote:
                AnyNote.Unset();
                break;
            case Kind.Bomb:
                Bomb.Unset();
                break;
            case Kind.BurstSlider:
                BurstSlider.Unset();
                break;
            case Kind.BurstSliderElement:
                BurstSliderElement.Unset();
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(kind), kind, null);
        }
    }
}
