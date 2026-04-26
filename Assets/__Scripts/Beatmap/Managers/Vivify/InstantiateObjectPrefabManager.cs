using System.Collections.Generic;
using UnityEngine;

public class InstantiateObjectPrefabManager
{
    public VivifyAssetBundleManager VivifyAssetBundleManager;

    private readonly Dictionary<string, Stack<VivifyObject>> prefabPool = new();
    private readonly Dictionary<CustomEventStateData, Object> ownerToObject = new();
    private readonly Dictionary<string, List<CustomEventStateData>> idToOwner = new();
    private readonly Dictionary<CustomEventStateData, List<CustomEventStateData>> deletedObjectToRevert = new();

    private VivifyObject GetOrCreateObject(string prefabName)
    {
        if (string.IsNullOrEmpty(prefabName)) return null;
        if (prefabPool.ContainsKey(prefabName) && prefabPool[prefabName].Count > 0) return prefabPool[prefabName].Pop();
        var prefab = VivifyAssetBundleManager.AssetPathToPrefab.GetValueOrDefault(prefabName);
        return prefab == null ? null : Object.Instantiate(prefab);
    }

    private void RemoveObject(Object obj)
    {
        if (obj is not VivifyObject vivifyObject)
        {
            Object.Destroy(obj);
            return;
        }

        prefabPool.TryAdd(vivifyObject.AssetPath, new Stack<VivifyObject>());
        vivifyObject.Deactivate();
        prefabPool[vivifyObject.AssetPath].Push(vivifyObject);
    }

    public void InstantiateVivifyObject(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var prefabName = data["asset"];
        var vivifyObject = GetOrCreateObject(prefabName);
        if (vivifyObject == null) return;

        vivifyObject.Initialize();

        if (data["scale"] != null) vivifyObject.transform.localScale = data["scale"].ReadVector3(Vector3.one);

        if (data["localPosition"] != null)
            vivifyObject.transform.localPosition = data["scale"].ReadVector3(Vector3.zero);
        else if (data["position"] != null) vivifyObject.transform.position = data["scale"].ReadVector3(Vector3.zero);

        if (data["localRotation"] != null)
            vivifyObject.transform.localEulerAngles = data["localRotation"].ReadVector3(Vector3.zero);
        else if (data["rotation"] != null)
            vivifyObject.transform.eulerAngles = data["rotation"].ReadVector3(Vector3.zero);

        vivifyObject.Activate();
        vivifyObject.SongSynchronize(state.StartSecondTime);
        ownerToObject.Add(state, vivifyObject);

        if (!data.HasKey("id")) return;
        var id = data["id"];
        idToOwner.TryAdd(id, new());
        idToOwner[id].Add(state);
    }

    public void ReinstantiateVivifyObject(CustomEventStateData state)
    {
        if (!deletedObjectToRevert.TryGetValue(state, out var p)) return;
        foreach (var s in p) InstantiateVivifyObject(s);
        deletedObjectToRevert.Remove(state);
    }

    public void RemoveVivifyObjectByState(CustomEventStateData state)
    {
        if (!ownerToObject.TryGetValue(state, out var val)) return;

        RemoveObject(val);
        ownerToObject.Remove(state);

        if (!state.Base.Data.HasKey("id")) return;
        var id = state.Base.Data["id"];
        if (!idToOwner.TryGetValue(id, out var v)) return;
        v.Remove(state);
        if (v.Count == 0) idToOwner.Remove(id);
    }

    public void RemoveVivifyObjectById(CustomEventStateData state)
    {
        if (!state.Base.Data.HasKey("id")) return;
        deletedObjectToRevert.Add(state, new());

        if (state.Base.Data["id"].IsString && idToOwner.TryGetValue(state.Base.Data["id"], out var l1))
        {
            foreach (var s in l1) RemoveVivifyObject(s, state);
            idToOwner.Remove(state.Base.Data["id"]);
        }
        else if (state.Base.Data["id"].IsArray)
        {
            foreach (var (_, id) in state.Base.Data["id"].AsArray)
            {
                if (!id.IsString || !idToOwner.TryGetValue(id, out var l2)) continue;
                foreach (var s in l2) RemoveVivifyObject(s, state);
                idToOwner.Remove(id);
            }
        }
    }

    private void RemoveVivifyObject(CustomEventStateData state, CustomEventStateData removeState)
    {
        if (!ownerToObject.TryGetValue(state, out var o)) return;
        RemoveObject(o);
        ownerToObject.Remove(state);
        deletedObjectToRevert[removeState].Add(state);
    }
}
