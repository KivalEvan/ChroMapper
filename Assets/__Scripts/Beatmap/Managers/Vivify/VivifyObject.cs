using System;
using Beatmap.Animations;
using UnityEngine;

public class VivifyObject : MonoBehaviour
{
    public string AssetPath;
    public AudioTimeSyncController Atsc;
    public ObjectAnimator Animator;
    public Animator[] Animators;

    private ISync[] syncs = Array.Empty<ISync>();

    public Vector3 InitialPosition;
    public Quaternion InitialRotation;
    public Vector3 InitialScale;

    public void Awake() => syncs = gameObject.GetComponentsInChildren<ISync>();

    public void SongSynchronize(float startTime)
    {
        foreach (var sync in syncs) sync.SetStartTime(startTime);
    }

    public void Initialize()
    {
        transform.localScale = InitialScale;
        transform.SetPositionAndRotation(InitialPosition, InitialRotation);
    }

    public void SetDefault()
    {
        InitialPosition = transform.position;
        InitialRotation = transform.rotation;
        InitialScale = transform.localScale;
    }

    public void SetAnimatorDefault()
    {
        Animator.OffsetPosition.Default = InitialPosition;
        Animator.WorldPosition.Default = InitialPosition;
        Animator.LocalRotation.Default = transform.localRotation;
        Animator.WorldRotation.Default = transform.rotation;
        Animator.Scale.Default = InitialScale;
    }

    public void Activate() => gameObject.SetActive(true);
    public void Deactivate() => gameObject.SetActive(false);
}
