using System.Collections.Generic;

// ok i gotta think of making sure the ordering works or otherwise overlapping just undefined behaviour
public class TweenManager
{
    private readonly List<TweenFloat> tweens = new();
    private readonly List<TweenFloat> removedTweens = new();

    public void UpdateForward(float beatTime)
    {
        for (var index = 0; index < tweens.Count; index++)
        {
            tweens[index].UpdateWithCallback(beatTime);
            if (!(tweens[index].EndTime < beatTime)) continue;
            removedTweens.Add(tweens[index]);
            tweens.RemoveAtSwapBack(index);
        }
    }

    public void UpdateJump(float beatTime)
    {
        for (var index = 0; index < removedTweens.Count; index++)
        {
            if (!(removedTweens[index].EndTime > beatTime)) continue;
            tweens.Add(removedTweens[index]);
            removedTweens.RemoveAtSwapBack(index);
        }

        for (var index = 0; index < tweens.Count; index++) tweens[index].UpdateWithCallback(beatTime);
    }

    public void AddTween(TweenFloat tween)
    {
        tweens.Add(tween);
    }

    public void RemoveTween(TweenFloat tween)
    {
        tweens.RemoveSwapBack(tween);
        removedTweens.RemoveSwapBack(tween);
    }
}
