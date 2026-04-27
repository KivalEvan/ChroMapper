using System.Collections.Generic;
using Beatmap.Containers;
using UnityEngine;

public class ModelUpdateQueueManager : MonoBehaviour
{
    private readonly HashSet<ObjectContainer> containerQueue = new();

    private void LateUpdate()
    {
        if (containerQueue.Count == 0) return;

        foreach (var obj in containerQueue) obj.HandleModelChanged();
        containerQueue.Clear();
    }

    public void Add(ObjectContainer container) => containerQueue.Add(container);
}
