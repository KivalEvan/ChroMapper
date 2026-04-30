using System.Runtime.CompilerServices;

public abstract class PointOperation
{
    public IPointDefinitionValue Rhs;
    public abstract float EvaluateX(float lhs);
    public abstract float EvaluateY(float lhs);
    public abstract float EvaluateZ(float lhs);
    public abstract float EvaluateW(float lhs);

    protected PointOperation(IPointDefinitionValue rhs) => Rhs = rhs;
}

public class PointOperationNone : PointOperation
{
    public override float EvaluateX(float lhs) => lhs;
    public override float EvaluateY(float lhs) => lhs;
    public override float EvaluateZ(float lhs) => lhs;
    public override float EvaluateW(float lhs) => lhs;

    public PointOperationNone(IPointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationAdd : PointOperation
{
    public override float EvaluateX(float lhs) => lhs + Rhs.X;
    public override float EvaluateY(float lhs) => lhs + Rhs.Y;
    public override float EvaluateZ(float lhs) => lhs + Rhs.Z;
    public override float EvaluateW(float lhs) => lhs + Rhs.W;

    public PointOperationAdd(IPointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationSub : PointOperation
{
    public override float EvaluateX(float lhs) => lhs - Rhs.X;
    public override float EvaluateY(float lhs) => lhs - Rhs.Y;
    public override float EvaluateZ(float lhs) => lhs - Rhs.Z;
    public override float EvaluateW(float lhs) => lhs - Rhs.W;

    public PointOperationSub(IPointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationMul : PointOperation
{
    public override float EvaluateX(float lhs) => lhs * Rhs.X;
    public override float EvaluateY(float lhs) => lhs * Rhs.Y;
    public override float EvaluateZ(float lhs) => lhs * Rhs.Z;
    public override float EvaluateW(float lhs) => lhs * Rhs.W;

    public PointOperationMul(IPointDefinitionValue rhs) : base(rhs) { }
}

public class PointOperationDiv : PointOperation
{
    public override float EvaluateX(float lhs) => SafeDivide(lhs, Rhs.X);
    public override float EvaluateY(float lhs) => SafeDivide(lhs, Rhs.Y);
    public override float EvaluateZ(float lhs) => SafeDivide(lhs, Rhs.Z);
    public override float EvaluateW(float lhs) => SafeDivide(lhs, Rhs.W);

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    private static float SafeDivide(float lhs, float rhs) => rhs == 0f ? 0f : lhs / rhs;

    public PointOperationDiv(IPointDefinitionValue rhs) : base(rhs) { }
}
