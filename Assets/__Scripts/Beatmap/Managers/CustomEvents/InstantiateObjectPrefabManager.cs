using System;
using System.Collections.Generic;
using UnityEngine;

public class InstantiateObjectPrefabManager
{
    public VivifyAssetBundleManager VivifyAssetBundleManager;
    public TracksManager TracksManager;
    public Action<UnityEngine.Object> BeforeTargetReleased;

    private readonly Dictionary<string, Stack<VivifyObject>> prefabPool = new();
    private readonly Dictionary<CustomEventStateData, VivifyObject> ownerToObject = new();
    private readonly Dictionary<string, List<CustomEventStateData>> idToOwner = new();
    private readonly Dictionary<string, List<VivifyObject>> idToObjects = new();
    private readonly Dictionary<CustomEventStateData, List<CustomEventStateData>> deletedObjectToRevert = new();
    private readonly List<VivifyObject> emptyObjects = new();

    public List<VivifyObject> GetObjectById(string id) => idToObjects.GetValueOrDefault(id, emptyObjects);

    private VivifyObject GetOrCreateObject(string prefabName)
    {
        if (string.IsNullOrEmpty(prefabName)) return null;
        if (prefabPool.ContainsKey(prefabName) && prefabPool[prefabName].Count > 0) return prefabPool[prefabName].Pop();
        var prefab = VivifyAssetBundleManager.AssetPathToPrefab.GetValueOrDefault(prefabName);
        return prefab == null ? null : UnityEngine.Object.Instantiate(prefab);
    }

    private void RemoveObject(VivifyObject vivifyObject)
    {
        ReleaseTargets(vivifyObject);
        prefabPool.TryAdd(vivifyObject.AssetPath, new Stack<VivifyObject>());
        vivifyObject.Deactivate();
        prefabPool[vivifyObject.AssetPath].Push(vivifyObject);
    }

    private void ReleaseTargets(VivifyObject vivifyObject)
    {
        foreach (var animator in vivifyObject.Animators)
            BeforeTargetReleased?.Invoke(animator);
    }

    public void Reset()
    {
        var ownedObjects = new HashSet<VivifyObject>();

        foreach (var vivifyObject in ownerToObject.Values)
            DestroyOwnedObject(vivifyObject, ownedObjects);

        foreach (var pool in prefabPool.Values)
        {
            foreach (var vivifyObject in pool)
                DestroyOwnedObject(vivifyObject, ownedObjects);
        }

        ClearState();
    }

    private void DestroyOwnedObject(VivifyObject vivifyObject, HashSet<VivifyObject> ownedObjects)
    {
        if (vivifyObject == null || !ownedObjects.Add(vivifyObject)) return;

        ReleaseTargets(vivifyObject);
        vivifyObject.Deactivate();
        UnityEngine.Object.Destroy(vivifyObject.gameObject);
    }

    private void ClearState()
    {
        ownerToObject.Clear();
        idToOwner.Clear();
        idToObjects.Clear();
        deletedObjectToRevert.Clear();
        prefabPool.Clear();
    }

    public void InstantiateVivifyObject(CustomEventStateData state)
    {
        var data = state.Base.Data;
        var prefabName = data["asset"];
        var vivifyObject = GetOrCreateObject(prefabName);
        if (vivifyObject == null) return;

        vivifyObject.transform.SetParent(null, false);
        vivifyObject.Initialize();

        if (data["scale"] != null) vivifyObject.transform.localScale = data["scale"].ReadVector3(Vector3.one);

        if (data["localPosition"] != null)
            vivifyObject.transform.localPosition = data["localPosition"].ReadVector3(Vector3.zero);
        else if (data["position"] != null) vivifyObject.transform.position = data["position"].ReadVector3(Vector3.zero);

        if (data["localRotation"] != null)
            vivifyObject.transform.localEulerAngles = data["localRotation"].ReadVector3(Vector3.zero);
        else if (data["rotation"] != null)
            vivifyObject.transform.eulerAngles = data["rotation"].ReadVector3(Vector3.zero);

        vivifyObject.Activate();
        vivifyObject.SongSynchronize(state.StartSecondTime);
        
        if (data["track"] != null)
            vivifyObject.Animator.AttachToVivify(vivifyObject, data["track"]);

        ownerToObject.Add(state, vivifyObject);

        if (!data.HasKey("id")) return;
        var id = data["id"];
        idToOwner.TryAdd(id, new());
        idToOwner[id].Add(state);

        idToObjects.TryAdd(id, new());
        idToObjects[id].Add(vivifyObject);
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
        if (idToOwner.TryGetValue(id, out var v))
        {
            v.Remove(state);
            if (v.Count == 0) idToOwner.Remove(id);
        }

        if (idToObjects.TryGetValue(id, out var l))
        {
            l.Remove(val);
            if (l.Count == 0) idToObjects.Remove(id);
        }
    }

    public void RemoveVivifyObjectById(CustomEventStateData state, Func<string, bool> destroyRenderResource = null)
    {
        if (!state.Base.Data.HasKey("id")) return;
        deletedObjectToRevert.Add(state, new());

        if (state.Base.Data["id"].IsString && destroyRenderResource?.Invoke(state.Base.Data["id"]) != true
            && idToOwner.TryGetValue(state.Base.Data["id"], out var l1))
        {
            foreach (var s in l1) RemoveVivifyObject(s, state);
            idToOwner.Remove(state.Base.Data["id"]);
            idToObjects.Remove(state.Base.Data["id"]);
        }
        else if (state.Base.Data["id"].IsArray)
        {
            foreach (var (_, id) in state.Base.Data["id"].AsArray)
            {
                if (!id.IsString || destroyRenderResource?.Invoke(id) == true || !idToOwner.TryGetValue(id, out var l2)) continue;
                foreach (var s in l2) RemoveVivifyObject(s, state);
                idToOwner.Remove(id);
                idToObjects.Remove(id);
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
