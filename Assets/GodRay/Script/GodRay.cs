using UnityEngine;

public class GodRay : PostEffectsBase
{
    public Shader godRayShader;
    private Material godRayMaterial = null;
    public Material material
    {
        get
        {
            godRayMaterial = CheckShaderAndCreateMaterial(godRayShader, godRayMaterial);
            return godRayMaterial;
        }
    }

    // ����������ȡ��ֵ
    public Color colorThreshold = Color.gray;
    // ����ɫ
    public Color lightColor = Color.white;
    // ��ǿ��
    [Range(0.0f, 20.0f)] public float lightFactor = 0.5f;
    // ����ģ��uv����ƫ��ֵ
    [Range(0.0f, 10.0f)] public float samplerScale = 1;
    // ��������
    [Range(1, 5)]        public int blurInt = 2;
    // �ֱ�������ϵ��(������)
    [Range(1, 5)]        public int downSample = 2;
    // ��Դλ��
    public Transform lightTransform;
    // ��Դ��Χ
    [Range(0.0f, 5.0f)]  public float lightRadius = 2.0f;
    // ��ȡ�������powϵ���������ʵ�������ɫ���������
    [Range(1.0f, 4.0f)]  public float lightPowFactor = 3.0f;

    private Camera targetCamera = null;

    void Awake()
    {
        targetCamera = GetComponent<Camera>();
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material && targetCamera)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);

            // �����Դλ�� ������ռ�ת�����ӿڿռ�
            Vector3 viewPortLightPos = lightTransform == null ? new Vector3(.5f, .5f, 0) : targetCamera.WorldToViewportPoint(lightTransform.position);

            // ������������
            material.SetVector("_ColorThreshold", colorThreshold);
            material.SetVector("_ViewProtLightPos", new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
            material.SetFloat("_LightRadius", lightRadius);
            material.SetFloat("_PowFactor", lightPowFactor);
            Graphics.Blit(source, buffer0, material, 0);    //������ֵ��ȡ�������֣�ʹ��Pass0����Bloom��һ�� �����Դ�����޳���Դ��Χ��Ĳ���

            // ����ģ���Ĳ���uvƫ��ֵ
            float samplerOffset = samplerScale / source.width;

            // ͨ��ѭ����������ģ��
            for (int i = 0; i < blurInt; i++)
            {
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
                float offset = samplerOffset * (i * 2 + 1);
                material.SetVector("_offsets", new Vector4(offset, offset, 0, 0));
                Graphics.Blit (buffer0, buffer1, material, 1);

                offset = samplerOffset * (i * 2 + 2);
                material.SetVector("_offsets", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(buffer1 , buffer0, material, 1);
                RenderTexture.ReleaseTemporary(buffer1);
            }

            // ģ���Ľ�����ݸ������е�����
            material.SetTexture("_BlurTex", buffer0);
            material.SetVector("_LightColor", lightColor);
            material.SetFloat("_LightFactor", lightFactor);

            // ������ģ�������ԭͼ���л��
            Graphics.Blit(source, destination, material, 2);

            // ����ͷ���ʱ����
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
