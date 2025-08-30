using System;
using UnityEngine;

public class SwitchEditMode : MonoBehaviour
{
    public void SwitchMode()
    {
        switch (GridViewController.EditingMode)
        {
            case EditingMode.None:
                break;
            case EditingMode.Gameplay:
                GridViewController.EditingMode = EditingMode.BasicEvent;
                break;
            case EditingMode.GLS:
                break;
            case EditingMode.BasicEvent:
                GridViewController.EditingMode = EditingMode.Gameplay;
                break;
            default:
                throw new ArgumentOutOfRangeException();
        }
    }
}
