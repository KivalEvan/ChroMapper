using UnityEngine;

public class SpectrogramSideSwapper : MonoBehaviour
{
    [SerializeField] private GridChild spectrogramGridChild;
    [SerializeField] private GridChild bpmGridChild;
    public bool IsNoteSide { get; set; } = true;

    public void SwapSides()
    {
        IsNoteSide = !IsNoteSide;

        var order = IsNoteSide ? -1 : 2;
        var offset = IsNoteSide ? 3.5f : 2.5f;

        GridViewController.DeregisterChild(spectrogramGridChild);
        GridViewController.DeregisterChild(bpmGridChild);

        spectrogramGridChild.Order = order;
        bpmGridChild.Order = IsNoteSide ? order - 1 : order + 1;
        // spectrogramGridChild.LocalOffset = new Vector3(offset, 0, 0);
        // spectrogramChunksChild.LocalOffset = new Vector3(offset - 2, 0, 0);

        GridViewController.RegisterChild(spectrogramGridChild);
        GridViewController.RegisterChild(bpmGridChild);

        GridViewController.NotifyChanged();
    }
}
