using UnityEngine;

public class MaterialHistoryTexture : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly Texture value;

    public MaterialHistoryTexture(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetTexture(propertyId);
    }

    public override void Revert() => material.SetTexture(propertyId, value);
}

public class MaterialHistoryKeyword : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly string keyword;
    private readonly bool value;

    public MaterialHistoryKeyword(Material material, string property, string keyword) : base(property)
    {
        this.material = material;
        value = material.IsKeywordEnabled(keyword);
    }

    public override void Revert()
    {
        if (value)
            material.EnableKeyword(keyword);
        else
            material.DisableKeyword(keyword);
    }
}

public class MaterialHistoryFloat : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly float value;

    public MaterialHistoryFloat(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetFloat(propertyId);
    }

    public override void Revert() => material.SetFloat(propertyId, value);
}

public class MaterialHistoryVector : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly Vector4 value;

    public MaterialHistoryVector(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetVector(propertyId);
    }

    public override void Revert() => material.SetVector(propertyId, value);
}

public class MaterialHistoryColor : ObjectPropertyStateHistory
{
    private readonly Material material;
    private readonly int propertyId;
    private readonly Color value;

    public MaterialHistoryColor(Material material, string property) : base(property)
    {
        this.material = material;
        propertyId = Shader.PropertyToID(property);
        value = material.GetColor(propertyId);
    }

    public override void Revert() => material.SetColor(propertyId, value);
}
