using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

public class EnvironmentBuildPopulate
{
    private const string editorPath = "Assets/Editor/Environments";
    private const string graphicsPath = "Assets/_Graphics";
    private const string environmentPath = "Assets/__Scenes/Environments";

    [MenuItem("Environment/Populate Build Data", false, 800)]
    private static void PopulateBuildData()
    {
        // AssetDatabase always reports forward-slash paths, including on Windows.
        var envDataPaths = AssetDatabase
            .GetAllAssetPaths()
            .Where(x => x.StartsWith(PathUtils.Combine(environmentPath, "Data")) && x.EndsWith(".json"))
            .ToList();

        // Abort before marking entries unused so a path regression cannot silently empty the generated libraries.
        if (envDataPaths.Count == 0)
        {
            const string message = "Populate Build Data found no environment JSON assets; generated libraries were not changed.";
            Debug.LogError(message);
            throw new InvalidOperationException(message);
        }

        // Unity asset loading requires normalized project-relative paths on every host platform.
        var library =
            AssetDatabase.LoadAssetAtPath<EnvironmentLibrarySO>(PathUtils.Combine(editorPath, "EnvironmentLibrarySO.asset"));

        // Fail explicitly instead of producing a partial refresh when the library asset cannot be resolved.
        if (library == null)
        {
            const string message = "Populate Build Data could not load EnvironmentLibrarySO.asset.";
            Debug.LogError(message);
            throw new InvalidOperationException(message);
        }

        // Validate every source before mutating generated assets so one unreadable file cannot leave a partial refresh.
        var environmentData = new List<EnvironmentData>(envDataPaths.Count);
        foreach (var dataPath in envDataPaths)
        {
            var dataAsset = AssetDatabase.LoadAssetAtPath<TextAsset>(dataPath);
            if (dataAsset == null)
            {
                var message = $"Populate Build Data could not load '{dataPath}'.";
                Debug.LogError(message);
                throw new InvalidOperationException(message);
            }

            var data = CreateUtils.JsonToEnvironmentData(dataAsset);
            if (data?.Data == null)
            {
                var message = $"Populate Build Data could not deserialize '{dataPath}'.";
                Debug.LogError(message);
                throw new InvalidOperationException(message);
            }

            environmentData.Add(data);
        }

        library.Meshes.MarkForChange();
        library.Materials.MarkForChange();
        library.Sprites.MarkForChange();
        foreach (var s in library.Shaders)
            s.keywords.Clear();

        foreach (var data in environmentData)
        {
            Debug.Log($"Populating data from {data.Data.ID}");

            foreach (var m in data.Data.UniqueMeshes) library.Meshes.AddEntry(m, data.Data.ID);
            foreach (var m in data.Data.UniqueMaterials)
            {
                if (IsInternalErrorMaterial(m.Name, m.Shader)) continue;

                library.Materials.AddEntry(m, data.Data.ID);
                if (library.Shaders.All(s => s.name != m.Shader))
                    library.Shaders.Add(new ShaderEntry { name = m.Shader });
                var keywords = library.Shaders.Find(x => x.name == m.Shader).keywords;
                keywords.AddRange(m.Keywords.Where(x => !keywords.Contains(x)));
            }

            foreach (var o in data.Objects.Where(x => x.Components.SpriteRenderer != null))
            {
                var t = o.Components.SpriteRenderer;
                foreach (var r in t)
                {
                    if (string.IsNullOrEmpty(r.Texture))
                    {
                        Debug.LogWarning($"Could not get sprite in {o.ChromaID}");
                        continue;
                    }

                    library.Sprites.AddEntry(r.Texture, data.Data.ID);
                }
            }

            foreach (var layerName in data.Objects.Select(x => x.Layer))
                library.LayerMaskLookup.TryAdd(layerName, LayerMask.GetMask("Default"));
        }

        library.Meshes.RemoveUnused();
        library.Materials.RemoveUnused();
        library.Sprites.RemoveUnused();

        library.Meshes.Sort();
        library.Materials.Sort();
        library.Sprites.Sort();
        // Rebuild runtime lookups now so Create All from Data can run correctly in the same Unity session.
        library.Meshes.RebuildLookup();
        library.Materials.RebuildLookup();
        library.Sprites.RebuildLookup();
        // Report unresolved references explicitly; null entries are metadata-only and cannot render.
        var resolvedMeshCount = library.Meshes.Lookup.Values.Count(x => x != null);
        var resolvedMaterialCount = library.Materials.Lookup.Values.Count(x => x != null);
        Debug.Log(
            $"Populated environment libraries: {resolvedMeshCount}/{library.Meshes.list.Count} meshes and " +
            $"{resolvedMaterialCount}/{library.Materials.list.Count} materials resolved.");
        if (resolvedMeshCount == 0 || resolvedMaterialCount == 0)
        {
            const string message = "Populate Build Data produced no usable mesh or material references.";
            Debug.LogError(message);
            throw new InvalidOperationException(message);
        }

        foreach (var s in library.Shaders)
            s.keywords.Sort((a, b) => string.Compare(a.Replace("_", ""), b.Replace("_", ""), StringComparison.Ordinal));
        library.Shaders.Sort((a, b) => string.Compare(a.name, b.name, StringComparison.Ordinal));

        library.layerMaskRemap =
            library
                .LayerMaskLookup
                .Select(x => new LayerMaskEntry { name = x.Key, layerMask = x.Value })
                .OrderBy(x => x.name)
                .ToList();

        var usedMaterialName = new Dictionary<string, int>();
        foreach (var matInfo in library.Materials.list)
        {
            if (matInfo.Material == null)
            {
                var shader = Shader.Find("ChroMapper/Missing");
                if (TryGetShader(library.Shaders, matInfo.Shader, out var existingShader)) shader = existingShader;

                // Create new material with gpu instancing enabled
                // Shaders that dont support instancing should ignore the flag, but otherwise this should be free performance
                var mat = new Material(shader) { enableInstancing = true };

                var name = usedMaterialName.TryGetValue(matInfo.Name, out var n) && n > 0
                    ? matInfo.Name + n
                    : matInfo.Name;
                if (matInfo.Environments.Count > 1)
                {
                    // Asset creation and lookup paths must use Unity's forward-slash convention.
                    var targetPath = PathUtils.Combine(graphicsPath, "Materials", "Environment", $"{name}.mat");
                    if (!AssetDatabase.AssetPathExists(targetPath))
                        AssetDatabase.CreateAsset(mat, targetPath);
                    else
                        mat = AssetDatabase.LoadAssetAtPath<Material>(targetPath);
                }
                else
                {
                    // Keep every folder and material path compatible with AssetDatabase on Windows.
                    var parentPath = PathUtils.Combine(graphicsPath, "Materials", "Environment");
                    var env = matInfo.Environments[0].Replace("Environment", "");
                    var folderPath = PathUtils.Combine(parentPath, env);
                    if (!AssetDatabase.AssetPathExists(folderPath)) AssetDatabase.CreateFolder(parentPath, env);

                    var targetPath = PathUtils.Combine(folderPath, $"{name}.mat");
                    if (!AssetDatabase.AssetPathExists(targetPath))
                        AssetDatabase.CreateAsset(mat, targetPath);
                    else
                        mat = AssetDatabase.LoadAssetAtPath<Material>(targetPath);
                }

                usedMaterialName.TryAdd(name, 0);
                usedMaterialName[name]++;

                matInfo.Material = mat;
            }
            else if (matInfo.Material.shader.name == "ChroMapper/Missing")
            {
                if (TryGetShader(library.Shaders, matInfo.Shader, out var shader)) matInfo.Material.shader = shader;
            }

            MaterialProcessor.HandleProp(library, matInfo);
        }

        foreach (var obj in library
            .Materials.list.Select(x => x.Material)
            .Cast<Object>()
            .Append(library)
            .Append(library.Materials)
            .Append(library.Meshes)
            .Append(library.Sprites))
            EditorUtility.SetDirty(obj);
        AssetDatabase.SaveAssets();
    }

    private static bool IsInternalErrorMaterial(string materialName, string shaderName) =>
        string.Equals(shaderName, "Hidden/InternalErrorShader", StringComparison.Ordinal) ||
        materialName?.StartsWith("Hidden/InternalErrorShader", StringComparison.Ordinal) == true;

    private static bool TryGetShader(List<ShaderEntry> list, string shaderName, out Shader shader)
    {
        var entry = list.FirstOrDefault(x => x.name == shaderName);
        if (entry.shader == null)
        {
            shader = null;
            return false;
        }

        shader = entry.shader;
        return true;
    }
}
