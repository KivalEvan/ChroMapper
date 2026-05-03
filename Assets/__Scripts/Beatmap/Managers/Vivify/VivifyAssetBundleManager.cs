using System.Collections.Generic;
using System.IO;
using Beatmap.Animations;
using HarmonyLib;
using TMPro;
using UnityEngine;
using UnityEngine.Video;

public class VivifyAssetBundleManager : MonoBehaviour
{
    public VisualRepositorySO VisualRepository;

    [SerializeField] private AudioTimeSyncController atsc;
    [SerializeField] private TracksManager tracksManager;
    [SerializeField] private BeatmapRuntimeContext beatmapRuntimeContext;

    public AssetBundle Bundle;
    public readonly Dictionary<string, VivifyObject> AssetPathToPrefab = new();
    public readonly Dictionary<string, Material> AssetPathToMaterial = new();
    public readonly Dictionary<string, Texture> AssetPathToTexture = new();
    public readonly Dictionary<string, Object> AssetPathToObject = new();

    public void Start()
    {
        LoadInitialMap.OnLevelLoaded += LoadAssetBundle;
    }

    public void OnDestroy()
    {
        LoadInitialMap.OnLevelLoaded -= LoadAssetBundle;
        UnloadAssetBundle();
    }

    private void LoadAssetBundle()
    {
        if (!BeatSaberSongContainer.Instance.MapDifficultyInfo.CustomRequirements.Contains("Vivify")) return;

        var vivifyBundlePath = Path.Combine(BeatSaberSongContainer.Instance.Info.Directory, "bundleWindows2021.vivify");
        if (!File.Exists(vivifyBundlePath))
            vivifyBundlePath = Path.Combine(BeatSaberSongContainer.Instance.Info.Directory, "bundleWindows2019.vivify");
        if (!File.Exists(vivifyBundlePath)) return;

        Bundle = AssetBundle.LoadFromFile(vivifyBundlePath);
        if (Bundle == null) return;

        foreach (var assetPath in Bundle.GetAllAssetNames())
        {
            var asset = Bundle.LoadAsset(assetPath);
            if (asset == null) continue;

            AssetPathToObject.Add(assetPath, asset);

            switch (asset)
            {
                case Material material:
                    AssetPathToMaterial.Add(assetPath, material);
                    continue;
                case Texture texture:
                    AssetPathToTexture.Add(assetPath, texture);
                    continue;
            }

            if (asset is not GameObject prefab) continue;

            prefab.SetActive(false);
            var go = Instantiate(prefab);
            go.name = asset.name;

            go
                .GetComponentsInChildren<Component>()
                .Do(c =>
                {
                    switch (c)
                    {
                        case Animator:
                            var asc = c.gameObject.AddComponent<AnimatorSyncController>();
                            asc.Atsc = atsc;
                            asc.SetStartTime(0f);
                            break;
                        case ParticleSystem:
                            var pssc = c.gameObject.AddComponent<ParticleSystemSyncController>();
                            pssc.Atsc = atsc;
                            pssc.SetStartTime(0f);
                            break;
                        case VideoPlayer vp:
                            if (!vp.playOnAwake) return;
                            var vpsc = c.gameObject.AddComponent<VideoPlayerSyncController>();
                            vpsc.Atsc = atsc;
                            vpsc.SetStartTime(0f);
                            break;
                    }
                });
            // this is more of a patch, but is it needed?
            // go
            //     .GetComponentsInChildren<TextMeshPro>(true)
            //     .Do(t => Destroy(t.GetComponent<CanvasRenderer>()));

            var vivifyObject = go.AddComponent<VivifyObject>();
            vivifyObject.AssetPath = assetPath;
            vivifyObject.Atsc = atsc;
            vivifyObject.Animators = go.GetComponentsInChildren<Animator>();
            vivifyObject.SetDefault();
            vivifyObject.SongSynchronize(0);

            // TODO: ok genuinely i have no idea how this work
            var objectAnimator = go.AddComponent<ObjectAnimator>();
            vivifyObject.Animator = objectAnimator;
            objectAnimator.AnimationThis = go;
            objectAnimator.LocalTarget = go.transform;
            objectAnimator.WorldTarget = go.transform;
            objectAnimator.TracksManager = tracksManager;
            objectAnimator.Context = beatmapRuntimeContext;
            vivifyObject.SetAnimatorDefault();

            AssetPathToPrefab.Add(assetPath, vivifyObject);
            VisualRepository.AddWithFallback(go, assetPath);
        }
    }

    private void UnloadAssetBundle()
    {
        foreach (var (key, prefab) in AssetPathToPrefab)
        {
            VisualRepository.ModelsByName.Remove(key);
            Destroy(prefab);
        }

        AssetPathToPrefab.Clear();
        AssetPathToMaterial.Clear();
        AssetPathToTexture.Clear();
        AssetPathToObject.Clear();
        if (Bundle != null) Bundle.Unload(true);
    }
}
