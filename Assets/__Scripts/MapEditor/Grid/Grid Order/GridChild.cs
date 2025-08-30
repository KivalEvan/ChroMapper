using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class GridChild : MonoBehaviour
{
    private void Awake() => GridViewController.RegisterChild(this);
    private void OnDestroy() => GridViewController.DeregisterChild(this);

    #region GridChild Properties

    public List<GridTransformData> Transforms
    {
        get => transforms;
        set
        {
            transforms = value;
            GridViewController.NotifyChanged();
        }
    }

    [SerializeField] private List<GridTransformData> transforms;

    /// <summary>
    ///     Flag which editing mode is allowed to view.
    /// </summary>
    public EditingMode ViewableMode
    {
        get => viewableMode;
        set
        {
            viewableMode = value;
            GridViewController.NotifyChanged();
        }
    }

    [SerializeField] private EditingMode viewableMode = (EditingMode)short.MaxValue;

    /// <summary>
    ///     Order that determines its original position. Each child with the same Order will be at the same position
    /// </summary>
    public int Order
    {
        get => order;
        set
        {
            order = value;
            GridViewController.NotifyChanged();
        }
    }

    [SerializeField] private int order;

    /// <summary>
    ///     How large this object is, to the largest integer.
    /// </summary>
    public int Size
    {
        get => size;
        set
        {
            size = value;
            GridViewController.NotifyChanged();
        }
    }

    [SerializeField] private int size;

    #endregion
}

[Serializable]
public struct GridTransformData
{
    [SerializeField] public Transform Transform;
    [SerializeField] public Vector3 LocalOffset;
}
