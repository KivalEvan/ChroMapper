using System.Linq;
using UnityEngine;

public class AnimatorHistoryBool : ObjectPropertyStateHistory
{
    private readonly (Animator animator, bool value)[] animatorValue;

    public AnimatorHistoryBool(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetBool(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue) animator.SetBool(Property, value);
    }
}

public class AnimatorHistoryFloat : ObjectPropertyStateHistory
{
    private readonly (Animator animator, float value)[] animatorValue;

    public AnimatorHistoryFloat(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetFloat(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue) animator.SetFloat(Property, value);
    }
}

public class AnimatorHistoryInt : ObjectPropertyStateHistory
{
    private readonly (Animator animator, int value)[] animatorValue;

    public AnimatorHistoryInt(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetInteger(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue) animator.SetInteger(Property, value);
    }
}

public class AnimatorHistoryTrigger : ObjectPropertyStateHistory
{
    private readonly (Animator animator, bool value)[] animatorValue;

    public AnimatorHistoryTrigger(Animator[] animators, string property) : base(property) =>
        animatorValue = animators.Select(x => (x, x.GetBool(property))).ToArray();

    public override void Revert()
    {
        foreach (var (animator, value) in animatorValue)
        {
            if (value)
                animator.SetTrigger(Property);
            else
                animator.ResetTrigger(Property);
        }
    }
}
