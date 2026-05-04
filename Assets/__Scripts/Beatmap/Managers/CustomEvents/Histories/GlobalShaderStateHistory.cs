using UnityEngine;

public class GlobalHistoryTexture : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly Texture value;

    public GlobalHistoryTexture(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalTexture(propertyId);
    }

    public override void Revert() => Shader.SetGlobalTexture(propertyId, value);
}

public class GlobalHistoryKeyword : ObjectPropertyStateHistory
{
    private readonly string keyword;
    private readonly bool value;

    public GlobalHistoryKeyword(string property, string keyword) : base(property) =>
        value = Shader.IsKeywordEnabled(keyword);

    public override void Revert()
    {
        if (value)
            Shader.EnableKeyword(keyword);
        else
            Shader.DisableKeyword(keyword);
    }
}

public class GlobalHistoryFloat : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly float value;

    public GlobalHistoryFloat(int propertyId)
    {
        this.propertyId = propertyId;
        value = Shader.GetGlobalFloat(propertyId);
    }

    public GlobalHistoryFloat(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalFloat(propertyId);
    }

    public override void Revert() => Shader.SetGlobalFloat(propertyId, value);
}

public class GlobalHistoryVector : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly Vector4 value;

    public GlobalHistoryVector(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalVector(propertyId);
    }

    public override void Revert() => Shader.SetGlobalVector(propertyId, value);
}

public class GlobalHistoryColor : ObjectPropertyStateHistory
{
    private readonly int propertyId;
    private readonly Color value;

    public GlobalHistoryColor(string property) : base(property)
    {
        propertyId = Shader.PropertyToID(property);
        value = Shader.GetGlobalColor(propertyId);
    }

    public override void Revert() => Shader.SetGlobalColor(propertyId, value);
}
