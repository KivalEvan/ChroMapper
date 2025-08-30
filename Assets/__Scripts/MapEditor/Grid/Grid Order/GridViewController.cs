using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[Flags]
public enum EditingMode
{
    None = 0,
    Gameplay = 1 << 0,
    GLS = 1 << 2,
    BasicEvent = 1 << 3,
}

public class GridViewController : MonoBehaviour
{
    private static Dictionary<int, List<GridChild>> allChildren = new();

    [SerializeField] private GridRotationController gridRotationController;
    [SerializeField] private EditingMode initialMode = EditingMode.Gameplay;

    private static EditingMode editingMode = EditingMode.Gameplay;

    public static EditingMode EditingMode
    {
        get => editingMode;
        set
        {
            editingMode = value;
            NotifyChanged();
        }
    }

    public static event Action onOrderChangedEvent;
    public static event Action onOrderUpdatedEvent;

    private void Awake()
    {
        editingMode = initialMode;
        gridRotationController.ObjectRotationChangedEvent += NotifyChanged;
    }

    private void OnDestroy() => gridRotationController.ObjectRotationChangedEvent -= NotifyChanged;

    private static void UpdateGrid()
    {
        var activeChildren = new Dictionary<int, List<GridChild>>();

        foreach (var (order, children) in from child in allChildren from childViewable in child.Value select child)
        {
            foreach (var child in children)
            {
                if (child.ViewableMode.HasFlag(EditingMode)
                    && child.Transforms.TrueForAll(x => x.Transform.gameObject.activeSelf))
                {
                    child.transform.localPosition = Vector3.zero;
                    if (activeChildren.ContainsKey(order))
                        activeChildren[order].Add(child);
                    else
                        activeChildren.Add(order, new List<GridChild> { child });
                }
                else
                    child.transform.localPosition = new Vector3(0, 69420, 69420);
            }
        }

        float childX = 0;
        if (activeChildren.Any(x => x.Key < 0))
        {
            if (activeChildren.TryGetValue(0, out var centerGridChildren))
                childX -= centerGridChildren.Max(x => x.Size) / 2f;
            foreach (var (_, child) in activeChildren.Where(x => x.Key < 0))
                childX -= Mathf.Ceil(child.Max(x => x.Size)) + 1;
        }

        foreach (var (order, children) in activeChildren)
        {
            children.RemoveAll(x => x == null);
            foreach (var transformData in children.SelectMany(child => child.Transforms))
            {
                transformData.Transform.eulerAngles = new Vector3(
                    transformData.Transform.eulerAngles.x,
                    transformData.Transform.parent.eulerAngles.y,
                    transformData.Transform.eulerAngles.z);
                var x = childX + transformData.LocalOffset.x;
                var side = transformData.Transform.parent.right.normalized * x;
                var up = transformData.Transform.parent.up.normalized * transformData.LocalOffset.y;
                var forward = transformData.Transform.parent.forward.normalized * transformData.LocalOffset.z;
                var total = side + up + forward;
                transformData.Transform.position = transformData.Transform.parent.position + total;
            }

            childX += Mathf.Ceil(children.Any() ? children.Max(x => x.Size) + 1 : 0);
        }
    }

    public static int GetSizeForOrder(int order)
    {
        return allChildren.TryGetValue(order, out var children)
            ? Mathf.CeilToInt(
                children.Any() ? children.Where(x => x.ViewableMode.HasFlag(EditingMode)).Max(x => x.Size) : 0)
            : 0;
    }

    public static void RegisterChild(GridChild child)
    {
        if (allChildren.TryGetValue(child.Order, out var grids))
        {
            grids.Add(child);
        }
        else
        {
            allChildren[child.Order] = new List<GridChild> { child };
            RefreshChildDictionary();
        }
    }

    public static void DeregisterChild(GridChild child)
    {
        if (!allChildren.TryGetValue(child.Order, out var grids)) return;
        grids.Remove(child);
        if (grids.Count != 0) return;
        allChildren.Remove(child.Order);
        RefreshChildDictionary();
    }

    public static void NotifyChanged()
    {
        onOrderChangedEvent?.Invoke();
        UpdateGrid();
    }

    public static void RefreshChildDictionary()
    {
        allChildren = allChildren.OrderBy(x => x.Key).ToDictionary(x => x.Key, y => y.Value);
        NotifyChanged();
    }
}
