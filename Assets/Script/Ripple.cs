using System.Runtime.CompilerServices;
using UnityEngine;

public class Ripple : MonoBehaviour
{
    public Shader drawShader;
    public Shader rippleShader;     // ��������shader
    private RenderTexture preRT;    // ��һ֡RT
    private RenderTexture currentRT;// ��ǰ֡RT
    private Material drawMat, rippleMat;
    private Material floorMat;
    public GameObject Wave;
    public Transform obj;
    RaycastHit groundHit;

    [Range(0, 10)]
    public float footSize = 5;
    [Range(0, 1)]
    public float footStrength = 1;
    [Range(1, 5)]
    public float dispPow = 2;

    void Start()
    {
        drawMat = new Material(drawShader);
        rippleMat = new Material(rippleShader);
        floorMat = Wave.GetComponent<MeshRenderer>().material;
        preRT = CreateRT();
        currentRT = CreateRT();

        floorMat.SetTexture("_MaskTex", currentRT);
    }

    public RenderTexture CreateRT()
    {
        RenderTexture rt = new RenderTexture(512, 512, 0, RenderTextureFormat.RFloat);
        rt.Create();
        return rt;
    }

    private Vector2 lastTexCoord;
    private Vector3 lastPosition;
    void Update()
    {
        // ��������
        if (Vector3.Distance(obj.position, lastPosition) > 0.01f)
        {
            if (Physics.Raycast(obj.position, -Vector3.up, out groundHit))
            {
                lastTexCoord = groundHit.textureCoord;
                drawMat.SetVector("_Coordinate", new Vector4(groundHit.textureCoord.x, groundHit.textureCoord.y, 0, 0));
                drawMat.SetFloat("_Strength", footStrength);
                drawMat.SetFloat("_Size", footSize);
                RenderTexture temp = RenderTexture.GetTemporary(currentRT.width, currentRT.height, 0, RenderTextureFormat.ARGBFloat);
                Graphics.Blit(currentRT, temp);
                Graphics.Blit(temp, currentRT, drawMat);
                RenderTexture.ReleaseTemporary(temp);
            }
            lastPosition = obj.position;
        }

        // ��������
        rippleMat.SetTexture("_PreRT",preRT);
        rippleMat.SetTexture("_CurrentRT",currentRT);
        //rippleMat.SetFloat("_DispPow", dispPow);
        RenderTexture temp1 = RenderTexture.GetTemporary(currentRT.width, currentRT.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(null, temp1, rippleMat);
        // ��������currentRTΪ����֡
        Graphics.Blit (temp1, preRT);   
        RenderTexture rt = preRT;
        preRT = currentRT;
        currentRT = rt;
        RenderTexture.ReleaseTemporary(temp1);
    }
}
