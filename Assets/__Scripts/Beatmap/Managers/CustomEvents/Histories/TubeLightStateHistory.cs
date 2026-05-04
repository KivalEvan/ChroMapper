using System.Collections.Generic;
using ZLinq;

public class TubeLightColorAlphaMultiplierHistory : CustomEventStateHistory
{
    private readonly (ParametricBloomFogLightController, float)[] controllers;

    public TubeLightColorAlphaMultiplierHistory(List<ParametricBloomFogLightController> controllers) =>
        this.controllers = controllers.AsValueEnumerable().Select(x => (x, x.ColorAlphaMultiplier)).ToArray();

    public override void Revert()
    {
        foreach (var (controller, value) in controllers) controller.ColorAlphaMultiplier = value;
    }
}

public class TubeLightColorBloomFogIntensityHistory : CustomEventStateHistory
{
    private readonly (ParametricBloomFogLightController, float)[] controllers;

    public TubeLightColorBloomFogIntensityHistory(List<ParametricBloomFogLightController> controllers) =>
        this.controllers = controllers.AsValueEnumerable().Select(x => (x, x.BloomFogIntensityMultiplier)).ToArray();

    public override void Revert()
    {
        foreach (var (controller, value) in controllers) controller.BloomFogIntensityMultiplier = value;
    }
}
