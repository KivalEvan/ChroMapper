using System;
using System.Collections.Generic;
using System.Linq;
using Beatmap.Base;
using Beatmap.V2;
using Beatmap.Containers;
using UnityEngine;

public class Track : MonoBehaviour
{
    public Transform ObjectParentTransform;

    public Vector3 RotationValue = Vector3.zero;

    public Action TimeChanged;
    private readonly Vector3 rotationPoint = LoadInitialMap.PlatformOffset;

    public BaseGrid Object;
    public ObjectContainer ObjectContainer;
    private (Transform, Vector3, Quaternion)[] nodesTarget;
    private float spawnPosition;
    private float despawnPosition;
    private float despawnTime;

    // this number pulled from my ass, but it looks fine
    // oh, it's actually correct
    const float JUMP_FAR = 500f;

    // this number also pulled from my ass, song bpm time
    public const float JUMP_TIME = 2f;

    public void AssignRotationValue(Vector3 rotation)
    {
        RotationValue = rotation;
        transform.RotateAround(rotationPoint, Vector3.right, RotationValue.x);
        transform.RotateAround(rotationPoint, Vector3.up, RotationValue.y);
        transform.RotateAround(rotationPoint, Vector3.forward, RotationValue.z);
    }

    public void UpdatePosition(float position)
    {
        ObjectParentTransform.localPosition = new Vector3(
            ObjectParentTransform.localPosition.x,
            ObjectParentTransform.localPosition.y,
            position);
        TimeChanged?.Invoke();
    }

    public void UpdateTime(float time)
    {
        var z = 0f;
        var v2 = Object is V2Object;
        var position = ObjectParentTransform.localPosition;

        // Jump in
        if (time < Object.SpawnSongBpmTime)
            z = ((Object.CustomSpawnEffect ?? !v2) ^ v2)
                ? Mathf.Lerp(spawnPosition, JUMP_FAR, (Object.SpawnSongBpmTime - time) / JUMP_TIME)
                : JUMP_FAR;
        else if (time < despawnTime)
            z = Mathf.Lerp(
                spawnPosition,
                despawnPosition,
                (time - Object.SpawnSongBpmTime) / (despawnTime - Object.SpawnSongBpmTime));
        // Jump out
        else
            z = Mathf.Lerp(despawnPosition, -JUMP_FAR, (time - despawnTime) / JUMP_TIME);

        position.z = z;

        // oh yeah you know its good when things start with a check like this
        if (Object is BaseNote note)
        {
            // Normalized [0-1] between despawn time and spawn time
            var normalizedLifetime = Mathf.Clamp01(
                Mathf.InverseLerp(Object.DespawnSongBpmTime, Object.SpawnSongBpmTime, time));

            // [0-1] between spawn time and note time
            // 0.3 magic number taken from ArcViewer (thanks polandball)
            var spawnLifetime = Mathf.Clamp01(1 - ((normalizedLifetime - 0.5f) * 2));
            var rotationLifetime = Mathf.Clamp01(spawnLifetime / 0.3f);

            // Beat Saber uses a parabolic arc so we use Quadratic Out easing because im lazy
            var jumpT = Easing.Quadratic.Out(spawnLifetime);
            var rotationT = Easing.Quadratic.Out(rotationLifetime);

            // Magic 1.1 number comes from ObjectContainer.offsetY which is currently protected
            // TODO: Pre-compute starting position so notes can stack and flip can be supported
            //   (Notes need to be aware of other notes)
            position.y = Mathf.Lerp(1.1f, note.GetPosition().y + 1.1f, jumpT);

            // Multiply euler rotation by spawn lifetime if we are in the first half (spawning) portion of our object lifetime
            if (normalizedLifetime >= 0.5f)
            {
                // OK this is hacky i sincerely apologize
                var noteContainer = ObjectContainer as NoteContainer;
                var quaternion = Quaternion.Euler(noteContainer.DirectionTargetEuler);
                noteContainer.DirectionTarget.localRotation = Quaternion.Lerp(
                    Quaternion.identity,
                    quaternion,
                    rotationT);
            }
        }

        ObjectParentTransform.localPosition = position;
    }

    public void UpdateAuxTime(float time)
    {
        // oh joy, slider has entered the chat
        switch (Object)
        {
            case BaseChain chain:
                {
                    for (var i = 0; i < nodesTarget.Length; i++)
                    {
                        var (nodeTransform, targetPosition, targetRotation) = nodesTarget[i];
                        var localPosition = nodeTransform.localPosition;
                        var offset = Mathf.Lerp(
                            0f,
                            chain.TailSongBpmTime - chain.SongBpmTime,
                            (i + 1f) / (chain.SliceCount - 1f));

                        // it's just copypasted above
                        var normalizedLifetime = Mathf.Clamp01(
                            Mathf.InverseLerp(
                                Object.DespawnSongBpmTime + offset,
                                Object.SpawnSongBpmTime + offset,
                                time));
                        var spawnLifetime = Mathf.Clamp01(1 - ((normalizedLifetime - 0.5f) * 2));
                        var rotationLifetime = Mathf.Clamp01(spawnLifetime / 0.3f);
                        var jumpT = Easing.Quadratic.Out(spawnLifetime);
                        var rotationT = Easing.Quadratic.Out(rotationLifetime);
                        localPosition.y = Mathf.Lerp(0, targetPosition.y, jumpT);
                        nodeTransform.localPosition = localPosition;
                        nodeTransform.localRotation = Quaternion.Lerp(Quaternion.identity, targetRotation, rotationT);
                    }

                    break;
                }
            case BaseArc arc:
                {
                    var arcContainer = ObjectContainer as ArcContainer;

                    var normalizedLifetime = Mathf.Clamp01(
                        Mathf.InverseLerp(
                            Object.DespawnSongBpmTime,
                            Object.SpawnSongBpmTime,
                            time));
                    var spawnLifetime = Mathf.Clamp01(1 - ((normalizedLifetime - 0.5f) * 2));
                    var jumpT = arcContainer.HasHeadNote ? Easing.Quadratic.Out(spawnLifetime) : 1f;
                    var headY = Mathf.Lerp(0, arc.GetPosition().y, jumpT) - arc.GetPosition().y;

                    var tailOffset = arc.TailSongBpmTime - arc.SongBpmTime;
                    var tailNormalizedLifetime = Mathf.Clamp01(
                        Mathf.InverseLerp(
                            Object.DespawnSongBpmTime + tailOffset,
                            Object.SpawnSongBpmTime + tailOffset,
                            time));
                    var tailSpawnLifetime = Mathf.Clamp01(1 - ((tailNormalizedLifetime - 0.5f) * 2));
                    var tailJumpT = arcContainer.HasTailNote ? Easing.Quadratic.Out(tailSpawnLifetime) : 1f;
                    var tailY = Mathf.Lerp(0, arc.GetTailPosition().y, tailJumpT) - arc.GetTailPosition().y;

                    // yoink from polandball
                    var basePositions = arcContainer.SplinePoints;
                    var newPositions = new Vector3[basePositions.Length];
                    var arcLength = basePositions.Last().z;
                    for (var i = 0; i < basePositions.Length; i++)
                    {
                        var point = basePositions[i];

                        //Get the preferred offset based on distance from the head
                        var headDist = point.z / arc.Jd;
                        var headT = 1 - Easing.Quadratic.Out(Mathf.Clamp01(headDist));
                        var headPreferredOffset = headY * headT;

                        //Get the preferred offset based on distance from the tail
                        var tailDist = (arcLength - point.z) / arc.Jd;
                        var tailT = 1 - Easing.Quadratic.Out(Mathf.Clamp01(tailDist));
                        var tailPreferredOffset = tailY * tailT;

                        //Weight the adjustment based on which end of the arc the point is closer to
                        var relativePosition = point.z / arcLength;
                        point.y += Mathf.Lerp(headPreferredOffset, tailPreferredOffset, relativePosition);

                        //Squish the arc if needed
                        // point.z *= njs; // vnjs not a thing here yet

                        newPositions[i] = point;
                    }

                    var splineRenderer = arcContainer.SplineRenderer;
                    splineRenderer.SetPositions(newPositions);
                    break;
                }
        }
    }

    public void AttachContainer(ObjectContainer obj)
    {
        UpdateMaterialRotation(obj);
        if (obj.transform.parent == ObjectParentTransform) return;
        obj.transform.SetParent(ObjectParentTransform, false);
        obj.AssignTrack(this);
        ObjectContainer = obj;
        if (obj.ObjectData is BaseGrid g)
        {
            Object = g;
            spawnPosition = Object.Jd;
            switch (Object)
            {
                case BaseObstacle obs:
                    despawnPosition = -(Object.Jd * 0.5f) - (obs.DurationSongBpm * obs.EditorScale);
                    despawnTime = obs.SongBpmTime + obs.DurationSongBpm + (obs.Hjd * 0.5f);
                    break;
                case BaseArc arc:
                    despawnPosition = -Object.Jd - ((arc.TailSongBpmTime - arc.SongBpmTime) * arc.EditorScale);
                    despawnTime = arc.TailSongBpmTime + arc.Hjd;
                    break;
                case BaseChain chain:
                    despawnPosition = -Object.Jd - ((chain.TailSongBpmTime - chain.SongBpmTime) * chain.EditorScale);
                    despawnTime = chain.TailSongBpmTime + chain.Hjd;
                    break;
                default:
                    despawnPosition = -Object.Jd;
                    despawnTime = Object.DespawnSongBpmTime;
                    break;
            }

            if (obj is ChainContainer chainContainer)
            {
                nodesTarget = chainContainer
                    .Nodes.Select(n => (n.transform, n.transform.localPosition, n.transform.localRotation))
                    .Append(
                        (chainContainer.MainObject.transform,
                            chainContainer.MainObject.transform.localPosition,
                            chainContainer.MainObject.transform.rotation))
                    .ToArray();
            }
        }
    }

    public void UpdateMaterialRotation(ObjectContainer obj)
    {
        if (obj is ObstacleContainer || obj is NoteContainer) obj.SetRotation(RotationValue.y);
    }
}
