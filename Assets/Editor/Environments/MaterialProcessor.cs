using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

public static class MaterialProcessor
{
    private static readonly Dictionary<string, string> propRemap = new()
    {
        { "_DiffuseTexture", "_DiffuseTex" },
        { "_DiffuseTexture_ST", "_DiffuseTex_ST" },
        { "_NormalTexture", "_NormalTex" },
        { "_NormalTexture_ST", "_NormalTex_ST" },
        { "_BlendSrcFactor", "_BlendModeSrc" },
        { "_BlendDstFactor", "_BlendModeDst" },
        { "_BlendSrcFactorA", "_BlendModeSrcA" },
        { "_BlendDstFactorA", "_BlendModeDstA" },
        { "_WhiteBoostMultiplier", "_BloomWhiteMultiplier" },
        { "_AngleDisappear", "_EnableEmissionAngleDisappear" },
        { "_ThresholdAngle", "_EmissionThresholdAngle" },
        { "_Cull", "_CullMode" },
        { "_EmissionTexWhiteboostMultiplier", "_EmissionTexWhiteBoostMultiplier" },
        { "_WhiteboostRemapStart", "_WhiteBoostRemapStart" },
        { "_Rotate_UV", "_RotateUV" },
        { "_RimCameraDistanceOffset", "_RimDistanceOffset" },
        { "_RimCameraDistanceScale", "_RimDistanceScale" },
        { "_DissolveGradientWidth", "_DissolveScale" },
        { "_InvertDissolve", "_DissolveReverse" },
        { "_FinalAlphaOverride", "_OverrideFinalAlpha" },
        { "_CustomZWrite", "_ZWrite" },
        { "_CloseToCameraOffset", "_CloseCameraDisappearDistance" },
        { "_CloseToCameraFactor", "_CloseCameraDisappearWidth" },
        { "_UseMipmapBias", "_EnableMipmapBias" },
        { "_FakeMirrorTransparencyEnabled", "_EnableFakeMirrorTransparency" },
        { "_FakeMirrorTransparencyMultiplier", "_FakeMirrorTransparency" },
        { "_EnableCloseToCameraDisappear", "_EnableViewAlignedDisappearDistance" },
        { "_UseColor_Gradient", "_UseColorGradient" },
        { "_WorldspacePanning", "_EnableWorldspacePanningMain" },
        { "_MainTexWorldspacePanning", "_EnableWorldspacePanningMain" }
    };

    public static void HandleProp(EnvironmentLibrarySO library, MaterialInfo matInfo)
    {
        var material = matInfo.Material;

        foreach (var prop in matInfo.FloatProps)
        {
            if (TryGetPropertyName(material, prop.Key, out var name))
                material.SetFloat(name, prop.Value);
        }

        RecoverKeywordProperties(material, matInfo);

        foreach (var prop in matInfo.VectorProps)
            if (TryGetPropertyName(material, prop.Key, out var name))
                material.SetVector(name, prop.Value);

        foreach (var prop in matInfo.TextureProps)
            if (prop.Value != "null" && TryGetPropertyName(material, prop.Key, out var name))
                material.SetTexture(name, library.Textures.Lookup[prop.Value.ToLowerInvariant()]);
    }

    private static void RecoverKeywordProperties(Material material, MaterialInfo matInfo)
    {
        if (material == null || material.shader == null || matInfo == null) return;

        var serializedKeywords = new HashSet<string>(
            (matInfo.Keywords ?? new List<string>())
                .Where(keyword => !string.IsNullOrWhiteSpace(keyword))
                .Select(keyword => keyword.ToUpperInvariant()),
            StringComparer.Ordinal);
        var floatPropertyNames = new HashSet<string>(StringComparer.Ordinal);
        foreach (var prop in matInfo.FloatProps ?? new List<MaterialInfo.ShaderProps<float>>())
        {
            if (TryGetPropertyName(material, prop.Key, out var name))
                floatPropertyNames.Add(name);
        }

        var shader = material.shader;
        for (var propertyIndex = 0; propertyIndex < shader.GetPropertyCount(); propertyIndex++)
        {
            if (shader.GetPropertyType(propertyIndex) is not (ShaderPropertyType.Float or ShaderPropertyType.Range))
                continue;

            var propertyName = shader.GetPropertyName(propertyIndex);
            var uppercaseName = propertyName.ToUpperInvariant();
            foreach (var attribute in shader.GetPropertyAttributes(propertyIndex))
            {
                if (!TryGetKeywordOptions(uppercaseName, attribute, out var keywords, out var isToggle)) continue;

                ApplyKeywordValue(material, propertyName, material.GetFloat(propertyName));
                if (floatPropertyNames.Contains(propertyName)) break;

                var selectedIndex = FindSelectedKeywordIndex(shader, keywords, serializedKeywords);
                if (selectedIndex >= 0)
                {
                    var value = isToggle ? 1f : selectedIndex;
                    material.SetFloat(propertyName, value);
                    ApplyKeywordValue(material, propertyName, value);
                }

                break;
            }
        }
    }

    public static int SynchronizeCanonicalKeywords(MaterialInfo matInfo, IEnumerable<string> canonicalKeywords)
    {
        if (matInfo?.Material == null || canonicalKeywords == null)
            return 0;

        var keywordSet = canonicalKeywords
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(NormalizeKeyword)
            .ToHashSet(StringComparer.Ordinal);

        return ApplyKeywordSet(material: matInfo.Material, keywords: keywordSet, reset: true);
    }

    public static bool SynchronizeLocalKeyword(MaterialInfo matInfo, string keywordName)
    {
        if (matInfo?.Material == null || string.IsNullOrWhiteSpace(keywordName))
            return false;

        var keywordSet = matInfo.Keywords == null
            ? new HashSet<string>(StringComparer.Ordinal)
            : matInfo.Keywords.Where(x => !string.IsNullOrWhiteSpace(x)).Select(NormalizeKeyword).ToHashSet(StringComparer.Ordinal);

        var targetKeyword = NormalizeKeyword(keywordName);
        return ApplyKeywordSet(material: matInfo.Material, keywords: keywordSet, reset: false, targetKeyword: targetKeyword) > 0;
    }

    private static int ApplyKeywordSet(Material material, HashSet<string> keywords, bool reset, string targetKeyword = null)
    {
        var changed = 0;
        var count = material.shader.GetPropertyCount();

        for (var i = 0; i < count; i++)
        {
            var attributes = material.shader.GetPropertyAttributes(i);
            var propId = material.shader.GetPropertyNameId(i);
            var propName = material.shader.GetPropertyName(i).ToUpper();

            var found = false;
            var value = 0f;

            foreach (var attribute in attributes)
            {
                var p = attribute.IndexOf("(", StringComparison.Ordinal);
                if (p == -1) continue;

                var attributeName = attribute[..p];
                var parameters = attribute[(p + 1)..^1]
                    .Split(',')
                    .Select(x => x.Trim().ToUpper())
                    .ToArray();

                string[] normalizedKeywords;

                switch (attributeName)
                {
                    case "KeywordEnum":
                        if (parameters.Length == 0) break;

                        normalizedKeywords = parameters.Select(x => $"{propName}_{x}").ToArray();

                        if (targetKeyword != null)
                        {
                            var targetIndex = Array.IndexOf(normalizedKeywords, targetKeyword);
                            if (targetIndex == -1) break;

                            var currentValue = material.GetFloat(propId);
                            value = 0f;
                            if (keywords.Contains(targetKeyword)) value = targetIndex;
                            else if (reset) value = 0f;
                            else if (Mathf.Approximately(currentValue, targetIndex)) value = 0f;
                            else break;
                        }
                        else
                        {
                            value = 0f;
                            for (var k = 0; k < normalizedKeywords.Length; k++)
                            {
                                if (keywords.Contains(normalizedKeywords[k]))
                                {
                                    value = k;
                                    break;
                                }
                            }
                        }

                        found = true;
                        break;

                    case "Toggle":
                    case "ToggleShowIfAny":
                        if (parameters.Length == 0) break;

                        if (targetKeyword != null)
                        {
                            if (!NormalizedKeywordMatch(parameters[0], targetKeyword)) break;

                            var currentValue = material.GetFloat(propId);
                            value = keywords.Contains(targetKeyword) ? 1f : 0f;
                            if (value != currentValue || reset)
                                found = true;
                        }
                        else
                        {
                            value = 0f;
                            for (var k = 0; k < parameters.Length; k++)
                            {
                                if (keywords.Contains(parameters[k]))
                                {
                                    value = 1f;
                                    break;
                                }
                            }

                            found = true;
                        }

                        break;

                    case "EnumShowIfAny":
                        if (parameters.Length < 2) break;

                        if (!int.TryParse(parameters[0], out var optionsCount)) break;
                        normalizedKeywords = parameters.Skip(1).Take(optionsCount).Select(x => $"{propName}_{x}").ToArray();

                        if (targetKeyword != null)
                        {
                            var targetIndex = Array.IndexOf(normalizedKeywords, targetKeyword);
                            if (targetIndex == -1) break;

                            var currentValue = material.GetFloat(propId);
                            value = 0f;
                            if (keywords.Contains(targetKeyword)) value = targetIndex;
                            else if (reset) value = 0f;
                            else if (Mathf.Approximately(currentValue, targetIndex)) value = 0f;
                            else break;
                        }
                        else
                        {
                            value = 0f;
                            for (var k = 0; k < normalizedKeywords.Length; k++)
                            {
                                if (keywords.Contains(normalizedKeywords[k]))
                                {
                                    value = k;
                                    break;
                                }
                            }
                        }

                        found = true;
                        break;
                }

                if (found) break;
            }

            if (!found) continue;

            var oldValue = material.GetFloat(propId);
            if (Mathf.Approximately(oldValue, value)) continue;

            material.SetFloat(propId, value);
            changed++;
        }

        return changed;
    }

    private static string NormalizeKeyword(string keyword)
    {
        return keyword.ToUpperInvariant();
    }

    private static bool NormalizedKeywordMatch(string value, string target)
    {
        return string.Equals(value.Trim().ToUpper(), target, StringComparison.Ordinal);
    }

    private static int FindSelectedKeywordIndex(
        Shader shader,
        string[] keywords,
        ISet<string> serializedKeywords)
    {
        for (var index = 0; index < keywords.Length; index++)
        {
            var keyword = keywords[index];
            if (keyword == null || !serializedKeywords.Contains(keyword)) continue;
            if (shader.keywordSpace.FindKeyword(keyword).isValid) return index;
        }

        return -1;
    }

    private static void ApplyKeywordValue(Material material, string propertyName, float value)
    {
        var propertyIndex = material.shader.FindPropertyIndex(propertyName);
        if (propertyIndex < 0) return;

        var uppercaseName = propertyName.ToUpperInvariant();
        foreach (var attribute in material.shader.GetPropertyAttributes(propertyIndex))
        {
            if (!TryGetKeywordOptions(uppercaseName, attribute, out var keywords, out var isToggle)) continue;

            var selectedIndex = isToggle ? (value == 0f ? -1 : 0) : (int)value;
            for (var i = 0; i < keywords.Length; i++)
            {
                if (keywords[i] != null) SetLocalKeyword(material, keywords[i], i == selectedIndex);
            }

            break;
        }
    }

    private static void SetLocalKeyword(Material material, string keyword, bool enabled)
    {
        var localKeyword = material.shader.keywordSpace.FindKeyword(keyword);
        if (!localKeyword.isValid) return;

        if (enabled)
            material.EnableKeyword(localKeyword);
        else
            material.DisableKeyword(localKeyword);
    }

    private static bool TryGetKeywordOptions(
        string propertyName,
        string attribute,
        out string[] keywords,
        out bool isToggle)
    {
        keywords = Array.Empty<string>();
        isToggle = false;

        if (attribute is "Toggle" or "ToggleHeader")
        {
            keywords = new[] { $"{propertyName}_ON" };
            isToggle = true;
            return true;
        }

        var parenthesis = attribute.IndexOf('(');
        if (parenthesis < 0 || !attribute.EndsWith(")", StringComparison.Ordinal)) return false;

        var attributeName = attribute[..parenthesis];
        var parameters = attribute[(parenthesis + 1)..^1]
            .Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(value => value.Trim().ToUpperInvariant())
            .ToArray();

        switch (attributeName)
        {
            case "KeywordEnum":
                keywords = parameters.Select(value => EnumKeyword(propertyName, value)).ToArray();
                return true;
            case "Toggle":
            case "ToggleHeader":
            case "ToggleShowIfAny":
                keywords = new[] { parameters.FirstOrDefault() ?? $"{propertyName}_ON" };
                isToggle = true;
                return true;
            case "EnumShowIfAny" when parameters.Length > 0 && int.TryParse(parameters[0], out var count):
                keywords = parameters
                    .Skip(1)
                    .Take(count)
                    .Select(value => EnumKeyword(propertyName, value))
                    .ToArray();
                return true;
            default:
                return false;
        }
    }

    private static string EnumKeyword(string prefix, string option)
    {
        var normalized = option.Replace(' ', '_').ToUpperInvariant();
        if (normalized == "NONE" || normalized == "OFF") return null;
        return $"{prefix}_{normalized}";
    }

    private static bool TryGetPropertyName(
        Material material,
        string sourceName,
        out string propertyName)
    {
        var remappedName = propRemap.GetValueOrDefault(sourceName, sourceName);
        if (HasProperty(material, remappedName))
        {
            propertyName = remappedName;
            return true;
        }

        if (HasProperty(material, sourceName))
        {
            propertyName = sourceName;
            return true;
        }

        propertyName = null;
        return false;
    }

    private static bool HasProperty(Material material, string propertyName)
    {
        if (material.HasProperty(propertyName)) return true;
        return propertyName.EndsWith("_ST", StringComparison.Ordinal) && material.HasProperty(propertyName[..^3]);
    }
}
