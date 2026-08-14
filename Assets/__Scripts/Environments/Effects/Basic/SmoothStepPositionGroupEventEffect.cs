using System;
using System.Linq;
using Beatmap.Base;
using Beatmap.Enums;
using UnityEngine;

public class SmoothStepPositionGroupEventEffect : BasicEventEffect<SmoothStepPositionGroupStateData>
{
    public int GroupMinY;
    public int GroupMaxY;
    public float GroupStepSize;
    public Vector3 GroupStartPos;
    public string GroupEasing;

    private readonly BasicEventStateChunksContainer<SmoothStepPositionGroupStateData> container = new();
    private readonly Vector3Tween tween = new();
    private Transform[] elements = Array.Empty<Transform>();
    private Vector3 baseOffset;
    private Vector3 movementVector;

    public void SetElements(Transform group)
    {
        elements = group.Cast<Transform>().ToArray();
        movementVector = Vector3.forward;
        baseOffset = Vector3.forward;

        if (elements.Length > 1)
        {
            var authoredStep = elements[1].localPosition - elements[0].localPosition;
            if (authoredStep.sqrMagnitude > 0f)
            {
                movementVector = authoredStep.normalized;
                baseOffset = movementVector;
            }
        }

        if (Enum.TryParse(GroupEasing, out EaseType easing)) tween.Easing = Easing.FromID((int)easing);
    }

    private void Awake() => tween.Easing = Easing.Cubic.InOut;

    public override void Initialize() => InitializeStates(container);

    public override void Refresh() => UpdateObject();

    public override void UpdateTime(bool isPlaying, float currentTime)
    {
        if (!container.IsCurrentOrFindState(currentTime, isPlaying)) UpdateObject();
        if (tween.UpdateTime(currentTime)) SetPosition(tween.Current);
    }

    private void UpdateObject()
    {
        var state = container.CurrentState;
        tween.StartTime = state.StartTime;
        tween.StartValue = state.StartOffset;
        tween.EndTime = state.EndTime;
        tween.EndValue = state.EndOffset;
        SetPosition(tween.UpdateTime(Atsc.CurrentSongBpmTime) ? tween.Current : tween.StartValue);
    }

    private void SetPosition(Vector3 offset)
    {
        for (var i = 0; i < elements.Length; i++) elements[i].localPosition = i * offset;
    }

    private Vector3 GetPositionForValue(int value)
    {
        value = Mathf.Clamp(value, GroupMinY, GroupMaxY);
        return baseOffset + (movementVector * (GroupStepSize * value));
    }

    protected override SmoothStepPositionGroupStateData CreateState(BaseEvent data) => new(data);

    public override void InsertData(BaseEvent data)
    {
        var state = CreateState(data);
        state.StartTime = data.SongBpmTime;
        state.StartOffset = GetPositionForValue(data.Value);
        HandleInsertState(container, state);
    }

    protected override void OnInsertUpdateFromNextState(
        SmoothStepPositionGroupStateData newState,
        SmoothStepPositionGroupStateData nextState) => newState.EndOffset = nextState.StartOffset;

    protected override void OnInsertUpdateToPreviousState(
        SmoothStepPositionGroupStateData newState,
        SmoothStepPositionGroupStateData prevState) => prevState.EndOffset = newState.StartOffset;

    public override void RemoveData(BaseEvent reference, BaseEvent original)
    {
        var state = HandleRemoveState(container, reference, original);
        if (container.CurrentState == state) container.SetStateAt(reference.SongBpmTime);
    }

    protected override void OnRemoveUpdatePreviousAndNextState(
        SmoothStepPositionGroupStateData currState,
        SmoothStepPositionGroupStateData prevState,
        SmoothStepPositionGroupStateData nextState) => prevState.EndOffset = nextState.StartOffset;
}

public class SmoothStepPositionGroupStateData : BasicEventStateData
{
    public Vector3 StartOffset;
    public Vector3 EndOffset;

    public SmoothStepPositionGroupStateData(BaseEvent data) : base(data)
    {
    }
}
