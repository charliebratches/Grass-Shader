using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WindManager : MonoBehaviour
{
    // Wind direction in range radians
    public float windDirection = 0;

    private bool isRotating = false;
    private float previousWindDirection;

    private float currentRotationAmount = 0;

    public AnimationCurve windRotationCurve;

    private float previousRotationTime = 0f;
    private float currentRotationSpeed = 0f;

    private readonly float windVectorBaseCoefficient = 0.05f;

    private bool waiting;

    public int windTransitionTime;
    public int transitionTime;

    void Start()
    {
        waiting = false;
    }

    // Update is called once per frame
    void Update()
    {
        if (!waiting)
        {
            StartCoroutine(Wait());
        }

        isRotating = previousWindDirection != windDirection;
        currentRotationSpeed = windDirection - previousWindDirection;
        previousWindDirection = windDirection;
    }

    IEnumerator Wait()
    {
        waiting = true;

        StartCoroutine(ChangeWindDirection(windTransitionTime));
        yield return new WaitForSeconds(transitionTime);

        waiting = false;
    }

    public IEnumerator ChangeWindDirection(float timeInSeconds = 1f)
    {
        var startingValue = windDirection;
        var newIncrement = Random.Range(-45, 45);
        var targetValue = Clamp0360(GetWindDirectionEuler(false) + newIncrement) * Mathf.Deg2Rad;
        for (float t = 0; t < 1.0f; t += Time.deltaTime / timeInSeconds)
        {
            float time = windRotationCurve.Evaluate(t);

            /* 
             * Note, a bug can happen during the transition. It can never actually rotate between 359 degrees and 1 degree. 
             *  Ex: If The starting value is 45 degrees, and the target value is 315 degrees, it will rotate clockwise all the way around,
             * instead of taking the shortest path. This is what results in the janky sped-up animation during some transitions 
            */

            windDirection = Mathf.LerpAngle(startingValue, targetValue, time);
            yield return null;
        }
    }

    public Vector4 GetWindDirectionVector()
    {
        bool rotating = currentRotationSpeed < -0.0001f || currentRotationSpeed > 0.0001f;
        float directionCoefficient = rotating ? (windVectorBaseCoefficient - (Mathf.Pow(Mathf.Abs(currentRotationSpeed), 2))) : windVectorBaseCoefficient; // hacky, need a more accurate correllation between rotation speed and how much to subtract from the coefficient

        Debug.Log("Current coefficient: " + directionCoefficient + ", Current rotation speed: " + currentRotationSpeed + ", rotating?: " + rotating);
        Vector4 shaderWindFrequency = new Vector4(Mathf.Cos(windDirection), Mathf.Sin(windDirection), 0, 0) * directionCoefficient;
        return shaderWindFrequency;
    }

    public float GetWindDirectionEuler(bool forShader = true)
    {
        var trueRadian = forShader ? (2 * Mathf.PI) - windDirection : windDirection; // must subtract this from 2pi because it's actually mirrored in the shader
        return trueRadian * Mathf.Rad2Deg;
    }

    private float AddDegreeToAngle(float currentAngle, float degreesToAdd)
    {
        float newangle = currentAngle;
        if (currentAngle + degreesToAdd > 0 && currentAngle + degreesToAdd < 360)
        {
            newangle = currentAngle + degreesToAdd;
        }
        else
        {
            newangle = 360 + (currentAngle + degreesToAdd);
        }

        if (currentAngle + degreesToAdd > 360)
        {
            newangle = 360 - (currentAngle + degreesToAdd);
        }

        return newangle;
    }

    private static float Clamp0360(float eulerAngles)
    {
        float result = eulerAngles - Mathf.CeilToInt(eulerAngles / 360f) * 360f;
        if (result < 0)
        {
            result += 360f;
        }
        return result;
    }

    private static float InvertRadian(float angle)
    {
        return (angle + Mathf.PI) % (2 * Mathf.PI);
    }
}
