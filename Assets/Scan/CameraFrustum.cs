using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class CameraFrustum : MonoBehaviour
{
    public  Shader scanShader;
    private Material scanMat;

    public Color scanCol = Color.red;
    private float scanDistance;
    [Range(0, 5)]
    public float scanSpeed = 1f;
    [Range(0, 5)]
    public float scanRange = 2f;
    [Range(0, 1)]
    public float opacity = 0.8f;

    // Start is called before the first frame update
    void Start()
    {
        scanMat = new Material(scanShader);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        float speed = scanSpeed;
        if (scanMat != null)
        {
            scanDistance = Mathf.Lerp(scanDistance, 1, Time.deltaTime * speed);
            if (scanDistance > 0.9f)
                scanDistance = 0;
            scanMat.SetFloat("_ScanDistance", scanDistance);
            scanMat.SetFloat("_ScanRange", scanRange);
            //scanMat.SetFloat("_Opacity", opacity);
            scanMat.SetColor("_ScanCol", scanCol);
            Graphics.Blit(source, destination, scanMat);
        }
        else
            Graphics.Blit(source, destination);
    }
}
