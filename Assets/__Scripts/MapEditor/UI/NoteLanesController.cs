using System.Linq;
using UnityEngine;
using UnityEngine.Serialization;

public class NoteLanesController : MonoBehaviour
{
    [FormerlySerializedAs("noteGrid")] public Transform NoteGrid;
    [SerializeField] private GridChild notePlacementGridChild;

    private void Start()
    {
        Settings.NotifyBySettingName("NoteLanes", UpdateNoteLanes);
        UpdateNoteLanes(4);
        if (Settings.NonPersistentSettings.ContainsKey("NoteLanes")) Settings.NonPersistentSettings["NoteLanes"] = 4;
    }

    private void OnDestroy() => Settings.ClearSettingNotifications("NoteLanes");

    public void UpdateNoteLanes(object value)
    {
        var noteLanesText = value.ToString();
        if (!int.TryParse(noteLanesText, out var noteLanes)) return;
        if (noteLanes < 1) return;
        var index = notePlacementGridChild.Transforms.FindIndex(x => x.Transform == NoteGrid);
        var gridTransformData = notePlacementGridChild.Transforms[index];
        gridTransformData.LocalOffset = new Vector3(noteLanes / 2f, 0.05f, 0); // srsly who tf is offsettin the note grid
        notePlacementGridChild.Transforms[index] = gridTransformData;
        notePlacementGridChild.Size = noteLanes;
        NoteGrid.localScale = new Vector3((float)noteLanes / 10, 1, NoteGrid.localScale.z);
    }
}
