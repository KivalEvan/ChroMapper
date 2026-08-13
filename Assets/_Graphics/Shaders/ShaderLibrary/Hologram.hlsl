#ifndef CHROMAPPER_HOLOGRAM_INCLUDED
#define CHROMAPPER_HOLOGRAM_INCLUDED

// Hologram inputs are passed in as arguments; the library does not read
// uniforms the consumer shader must declare (instanced props included).

inline float ResolveHologramTime(float4 timeValue, float4 timeHelperOffset)
{
    return timeHelperOffset.w + timeValue.w;
}

inline float3 ResolveGridHologram(
    float3 worldPosition, float3 objectPosition, float4 timeValue,
    float4 timeHelperOffset, float gridSize, float scanDistance,
    float haltScan, float stripeSpeed, float phaseOffset, float fill,
    float holoIntensity, float3 hologramColor)
{
    float time = ResolveHologramTime(timeValue, timeHelperOffset);
    time = haltScan > 0.5 ? 0.0 : time;

    float3 gridPhase = time * float3(0.0, stripeSpeed, stripeSpeed * 0.5);
    float cameraDistance = length(worldPosition - _WorldSpaceCameraPos);
    float distanceFactor = saturate(cameraDistance * 0.1333333);
    distanceFactor = 1.0 - (1.0 - distanceFactor) * (1.0 - distanceFactor);
    float resolvedGridSize = gridSize - distanceFactor * 10.0;
    float colorScale = 1.0 - distanceFactor * 0.6;

    float3 gridPosition = float3(abs(objectPosition.x), objectPosition.yz);
    float3 gridWave = cos(frac(-gridPosition * resolvedGridSize - gridPhase) +
        fill);
    float grid = gridWave.x * gridWave.y * gridWave.z;

    float scanPosition = (worldPosition.y - unity_ObjectToWorld._m13 +
        phaseOffset * scanDistance) / scanDistance;
    float scan = frac(-time * stripeSpeed + scanPosition);
    float leadingInput = max((0.02499998 - scan) * 40.00004, 0.0);
    float trailingInput = max((0.975 - scan) * -40.0, 0.0);
    float leading = 1.0 - leadingInput * leadingInput *
        (3.0 - 2.0 * leadingInput);
    float trailing = trailingInput * trailingInput *
        (3.0 - 2.0 * trailingInput);
    float envelope = (leading + trailing) * 0.25 + 1.0;
    float scanGrid = saturate((1.0 - scan) * leading + grid);
    float hologram = envelope - scanGrid;

    return hologram * colorScale * holoIntensity * hologramColor;
}

inline float3 ResolveScanlineHologram(
    float3 worldPosition, float4 timeValue,
    float4 timeHelperOffset, float scanDistance,
    float haltScan, float stripeSpeed, float phaseOffset,
    float holoIntensity, float3 hologramColor)
{
    float time = ResolveHologramTime(timeValue, timeHelperOffset);
    float scanTime = haltScan > 0.5 ? -0.0 : -time * stripeSpeed;
    float scanPosition = (worldPosition.y - unity_ObjectToWorld._m13 +
        phaseOffset * scanDistance) / scanDistance;
    float scan = min((1.0 - frac(scanTime + scanPosition)) * 1.666667, 1.0);
    scan = 1.0 - scan * scan * (3.0 - 2.0 * scan);
    return scan * holoIntensity * hologramColor;
}

inline float3 ResolveLegacyHologram(
    float3 worldPosition, float4 timeValue,
    float4 timeHelperOffset, float gridSize, float3 hologramColor)
{
    float time = ResolveHologramTime(timeValue, timeHelperOffset);
    float4 relativePosition = worldPosition.yxyz -
        unity_ObjectToWorld._m13_m03_m13_m23;
    float4 scaledPosition = relativePosition * gridSize;

    float3 wavePosition = scaledPosition.yzw - time * float3(0.0, 1.0, 0.0);
    float3 waves = sin(frac(wavePosition) * 3.141593) * 1.2;
    float pulsePosition = frac((scaledPosition.x * 0.33 + time) * 0.2);
    pulsePosition = min(pulsePosition * 2.0, 1.0);
    float pulseEdge = min(pulsePosition * 20.0, 1.0);
    pulseEdge = pulseEdge * pulseEdge * (3.0 - 2.0 * pulseEdge);
    float pulse = pulseEdge * (1.0 - pulsePosition);

    float modulation = cos(time * 2.0 + relativePosition.y +
        relativePosition.z - relativePosition.w * 7.0) * 0.4 + 0.8;
    float hologram = (waves.x * waves.y * waves.z * modulation + pulse) * pulse;
    return hologram * hologramColor;
}

inline float4 ApplyHologram(
    float4 result, float3 worldPosition, float3 objectPosition, float4 timeValue,
    float4 timeHelperOffset, float gridSize, float scanDistance,
    float holoIntensity, float haltScan, float stripeSpeed, float phaseOffset,
    float fill, float3 hologramColor)
{
    #if defined(_HOLOGRAM_GRID)
    result.rgb += ResolveGridHologram(
        worldPosition, objectPosition, timeValue, timeHelperOffset, gridSize,
        scanDistance, haltScan, stripeSpeed, phaseOffset, fill,
        holoIntensity, hologramColor);
    #elif defined(_HOLOGRAM_SCANLINE)
    result.rgb += ResolveScanlineHologram(
        worldPosition, timeValue, timeHelperOffset, scanDistance,
        haltScan, stripeSpeed, phaseOffset, holoIntensity, hologramColor);
    result.a = 0.0;
    #elif defined(_HOLOGRAM_LEGACY)
    result.rgb += ResolveLegacyHologram(
        worldPosition, timeValue, timeHelperOffset, gridSize, hologramColor);
    #endif
    return result;
}

#endif