using UnityEngine;

public class FootTouch : MonoBehaviour
{
    public Shader drawShader;
    private RenderTexture splitmap;
    private Material snowMaterial, drawMaterial;
    public GameObject terrain;
    public Transform[] foot;    // ���foot��������
    RaycastHit groundHit;
    int layerMask;

    [Range(0, 20)]
    public float footSize;
    [Range(0, 1)]
    public float footStrength;

    void Start()
    {
        layerMask = LayerMask.GetMask("terrain");
        drawMaterial = new Material(drawShader);
        snowMaterial = terrain.GetComponent<MeshRenderer>().material;
        splitmap = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
        snowMaterial.SetTexture("_MaskTex", splitmap);
    }

    private void Update()
    {
        for (int i = 0; i < foot.Length; i++)
        {
            // ��������: ����ʼλ�� - ���·������ߣ���ֵ��- ������ײ��Ϣ
            if (Physics.Raycast(foot[i].position, -Vector3.up, out groundHit))
            {
                drawMaterial.SetVector("_Coordinate", new Vector4(groundHit.textureCoord.x, groundHit.textureCoord.y, 0, 0));
                //print(foot[i].position);

                drawMaterial.SetFloat("_Strength", footStrength);
                drawMaterial.SetFloat("_Size", footSize);
                RenderTexture temp = RenderTexture.GetTemporary(splitmap.width, splitmap.height, 0, RenderTextureFormat.ARGBFloat);
                Graphics.Blit(splitmap, temp);
                Graphics.Blit(temp, splitmap, drawMaterial);
                RenderTexture.ReleaseTemporary(temp);
            }
        }
    }
}
