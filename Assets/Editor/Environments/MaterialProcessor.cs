using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public static class MaterialProcessor
{
    private static readonly Dictionary<string, string> propRemap = new()
    {
        { "_BlendSrcFactor", "_BlendModeSrc" },
        { "_BlendDstFactor", "_BlendModeDst" },
        { "_BlendSrcFactorA", "_BlendModeSrcA" },
        { "_BlendDstFactorA", "_BlendModeDstA" },
        { "_WhiteBoostMultiplier", "_BloomWhiteMultiplier" },
        { "_ThresholdAngle", "_EmissionThresholdAngle" },
        { "_WhiteboostRemapStart", "_WhiteBoostRemapStart" },
        { "_Rotate_UV", "_RotateUV" },
        { "_RimCameraDistanceOffset", "_RimDistanceOffset" },
        { "_RimCameraDistanceScale", "_RimDistanceScale" }
    };

    private static readonly Dictionary<string, string> keywordRemap = new()
    {
        { "_VERTEXMODE_COLOR", "_VERTEX_COLOR" },
        { "_VERTEXMODE_EMISSION", "_VERTEX_EMISSION" },
        { "_VERTEXMODE_METALSMOOTHNESS", "_VERTEX_METALSMOOTHNESS" },
        { "_VERTEXMODE_SPECIAL", "_VERTEX_SPECIAL" },
        { "_VERTEXMODE_DISPLACEMENT", "_VERTEX_DISPLACEMENT" },
        { "_VERTEXMODE_EMISSIVE_MULT_ADD", "_VERTEX_EMISSIVE_MULT_ADD" },
        { "_VERTEX_WHITEBOOSTTYPE_MAINEFFECT", "_VERTEX_BLOOMTYPE_PP" },
        { "_VERTEX_WHITEBOOSTTYPE_ALWAYS", "_VERTEX_BLOOMTYPE_FRAG" },
        { "ENABLE_WORLD_NOISE", "WORLD_NOISE" },
        { "ENABLE_WORLD_SPACE_FADE", "WORLD_SPACE_FADE" },
        { "ENABLE_ANGLE_DISAPPEAR", "ANGLE_DISAPPEAR" },
        { "ENABLE_NOISE_DITHERING", "NOISE_DITHERING" },
        { "ENABLE_Y_AXIS_BILLBOARD", "Y_AXIS_BILLBOARD" },
        { "ENABLE_CUTOUT", "CUTOUT" },
        { "ENABLE_CLIPPING", "CLIPPING" },
        { "ENABLE_DIRT", "DIRT" },
        { "ENABLE_TARGET_POINT", "TARGET_POINT" },
        { "ENABLE_TIME_OFFSET", "TIME_OFFSET" },
        { "ENABLE_EMISSION_ANGLE_DISAPPEAR", "ANGLE_DISAPPEAR" },
        { "ENABLE_RIM_DIM", "RIM_DIM" },
        { "DISTORTION_SIMPLE", "_DISTORTION_SIMPLE" },
        { "_EMISSIONCOLORTYPE_FLAT", "_EMISSIONBLOOMTYPE_FLAT" },
        { "_EMISSIONCOLORTYPE_WHITEBOOST", "_EMISSIONBLOOMTYPE_FRAG" },
        { "_EMISSIONCOLORTYPE_GRADIENT", "_EMISSIONBLOOMTYPE_GRADIENT" },
        { "_EMISSIONCOLORTYPE_MAINEFFECT", "_EMISSIONBLOOMTYPE_PP" },
        { "_WHITEBOOSTTYPE_MAINEFFECT", "_BLOOMTYPE_PP" },
        { "_ENABLE_MAIN_EFFECT_WHITE_BOOST", "_BLOOMTYPE_PP" },
        { "_WHITEBOOSTTYPE_ALWAYS", "_BLOOMTYPE_FRAG" },
        { "ENABLE_FOG", "FOG" },
        { "ENABLE_HEIGHT_FOG", "HEIGHT_FOG" },
    };

    public static void HandleProp(EnvironmentLibrarySO library, MaterialInfo matInfo)
    {
        var mat = matInfo.Material;

        foreach (var floatProp in matInfo.FloatProps)
        {
            var renamedKey = propRemap.GetValueOrDefault(floatProp.Key, floatProp.Key);
            mat.SetFloat(renamedKey, floatProp.Value);
        }

        foreach (var vectorProp in matInfo.VectorProps)
        {
            var renamedKey = propRemap.GetValueOrDefault(vectorProp.Key, vectorProp.Key);
            mat.SetVector(renamedKey, vectorProp.Value);
        }

        foreach (var textureProp in matInfo.TextureProps)
        {
            if (textureProp.Value == "null") continue;
            var renamedKey = propRemap.GetValueOrDefault(textureProp.Key, textureProp.Key);
            mat.SetTexture(renamedKey, library.Textures.Lookup[textureProp.Value.ToLower()]);
        }

        // reset keywords
        var count = mat.shader.GetPropertyCount();
        for (var i = 0; i < count; i++)
        {
            var attributes = mat.shader.GetPropertyAttributes(i);
            var propId = mat.shader.GetPropertyNameId(i);
            foreach (var attribute in attributes)
            {
                var p = attribute.IndexOf("(", StringComparison.Ordinal);
                if (p == -1) continue;
                var n = attribute[..p];
                switch (n)
                {
                    case "KeywordEnum":
                    case "Toggle":
                    case "EnumShowIfAny":
                    case "ToggleShowIfAny":
                        mat.SetFloat(propId, 0f);
                        break;
                }
            }
        }

        foreach (var keyword in matInfo.Keywords.Select(x => keywordRemap.GetValueOrDefault(x, x)))
        {
            var found = false;
            for (var i = 0; i < count; i++)
            {
                var attributes = mat.shader.GetPropertyAttributes(i);
                var propId = mat.shader.GetPropertyNameId(i);
                foreach (var attribute in attributes)
                {
                    var p = attribute.IndexOf("(", StringComparison.Ordinal);
                    if (p == -1) continue;
                    var attributeName = attribute[..p];
                    var parameters = attribute[(p + 1)..^1].Split(',').Select(x => x.Trim().ToUpper()).ToArray();
                    var propName = mat.shader.GetPropertyName(i).ToUpper();
                    switch (attributeName)
                    {
                        case "KeywordEnum":
                            {
                                var keywords = parameters.Select(x => $"{propName}_{x}").ToArray();
                                if (keywords.Contains(keyword))
                                {
                                    mat.SetFloat(propId, Array.IndexOf(keywords, keyword));
                                    found = true;
                                }

                                break;
                            }
                        case "Toggle":
                            {
                                if (parameters[0] == keyword)
                                {
                                    mat.SetFloat(propId, 1f);
                                    found = true;
                                }

                                break;
                            }
                        case "EnumShowIfAny":
                            {
                                var c = int.Parse(parameters.First());
                                var keywords = parameters.Skip(1).Take(c).Select(x => $"{propName}_{x}").ToArray();
                                if (keywords.Contains(keyword))
                                {
                                    mat.SetFloat(propId, Array.IndexOf(keywords, keyword));
                                    found = true;
                                }

                                break;
                            }
                        case "ToggleShowIfAny":
                            {
                                if (parameters[0] == keyword)
                                {
                                    mat.SetFloat(propId, 1f);
                                    found = true;
                                }

                                break;
                            }
                    }

                    if (found) break;
                }

                if (found) break;
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
                            if (!normalizedKeywordMatch(parameters[0], targetKeyword)) break;

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
        var normalized = keyword.ToUpper();
        return keywordRemap.GetValueOrDefault(normalized, normalized);
    }

    private static bool normalizedKeywordMatch(string value, string target)
    {
        return string.Equals(value.Trim().ToUpper(), target, StringComparison.Ordinal);
    }

}
