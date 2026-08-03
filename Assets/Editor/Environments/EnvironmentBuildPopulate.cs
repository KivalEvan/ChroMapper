using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

public class EnvironmentBuildPopulate
{
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
        
        library.MarkForChange();

        // Validate every source before mutating generated assets so one unreadable file cannot leave a partial refresh.
        var environmentData = new List<EnvData>(envDataPaths.Count);
        foreach (var data in CreateUtils.GetEnvironmentData())
        {
            Debug.Log($"Populating data from {data.Data.ID}");

            foreach (var m in data.Data.UniqueMeshes) library.Meshes.AddEntry(m, data.Data.ID);
            foreach (var m in data.Data.UniqueMaterials)
            {
                if (m.Shader == "Hidden/InternalErrorShader") continue;
                library.Materials.AddEntry(m, data.Data.ID);
                if (library.Shaders.All(s => s.name != m.Shader))
                    library.Shaders.Add(new ShaderEntry { name = m.Shader });
                var keywords = library.Shaders.Find(x => x.name == m.Shader).keywords;
                keywords.AddRange(m.Keywords.Where(x => !keywords.Contains(x)));
            }

            foreach (var m in data.Data.UniqueTextures) library.Textures.AddEntry(m.Hash, m.Name, data.Data.ID);

            foreach (var layerName in data.Objects.Select(x => x.Layer))
                library.LayerMaskLookup.TryAdd(layerName, LayerMask.GetMask("Default"));
        }

        library.RemoveUnused();
        library.Sort();
        
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

        foreach (var entry in library.Shaders)
        {
            if (entry.shader != null) continue;
            entry.shader = Shader.Find(entry.name);
            if (entry.shader == null)
                Debug.LogWarning($"[EnvironmentTools] Shader.Find('{entry.name}') returned null. This shader is not compiled into the project. Materials using it will show as purple until a Shader is assigned manually in EnvironmentLibrarySO.");
            else
                Debug.Log($"[EnvironmentTools] Auto-assigned shader '{entry.name}'.");
        }

        library.Initialize();

        var usedMaterialName = new Dictionary<string, int>();
        foreach (var matInfo in library.Materials.list)
        {
            if (matInfo.Material == null)
            {
                var shader = Shader.Find("ChroMapper/Missing");
                if (TryGetShader(library.Shaders, matInfo.Shader, out var existingShader))
                    shader = existingShader;
                else
                    Debug.LogWarning($"[EnvironmentTools] No Shader mapped for '{matInfo.Shader}' in EnvironmentLibrarySO.Shaders — material '{matInfo.Name}' will use ChroMapper/Missing (purple). Assign a Shader to this entry in the Inspector.");

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

        foreach (var unusedMaterial in AssetDatabase
            .GetAllAssetPaths()
            .Where(x => x.StartsWith(Constants.MaterialsPath) && !x.Contains("Custom/"))
            .Select(AssetDatabase.LoadAssetAtPath<Material>)
            .Where(x => x != null)
            .Where(x => !library.Materials.list.Exists(y => y.Material == x)))
            AssetDatabase.RemoveObjectFromAsset(unusedMaterial);

        foreach (var obj in library
            .Materials.list.Select(x => x.Material)
            .Where(x => x != null)
            .Cast<Object>()
            .Concat(library.Textures.list.Select(x => x.Texture))
            .Where(x => x != null)
            .Append(library)
            .Append(library.Materials)
            .Append(library.Meshes)
            .Append(library.Textures)
            .Append(library.Sprites))
            EditorUtility.SetDirty(obj);
        AssetDatabase.SaveAssets();
    }

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
