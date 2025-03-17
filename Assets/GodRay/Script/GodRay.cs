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

    // 高亮部分提取阈值
    public Color colorThreshold = Color.gray;
    // 光颜色
    public Color lightColor = Color.white;
    // 光强度
    [Range(0.0f, 20.0f)] public float lightFactor = 0.5f;
    // 径向模糊uv采样偏移值
    [Range(0.0f, 10.0f)] public float samplerScale = 1;
    // 迭代次数
    [Range(1, 5)]        public int blurInt = 2;
    // 分辨率缩放系数(降采样)
    [Range(1, 5)]        public int downSample = 2;
    // 光源位置
    public Transform lightTransform;
    // 光源范围
    [Range(0.0f, 5.0f)]  public float lightRadius = 2.0f;
    // 提取高亮结果pow系数，用于适当降低颜色过亮的情况
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

            // 计算光源位置 从世界空间转化到视口空间
            Vector3 viewPortLightPos = lightTransform == null ? new Vector3(.5f, .5f, 0) : targetCamera.WorldToViewportPoint(lightTransform.position);

            // 参数传给材质
            material.SetVector("_ColorThreshold", colorThreshold);
            material.SetVector("_ViewProtLightPos", new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
            material.SetFloat("_LightRadius", lightRadius);
            material.SetFloat("_PowFactor", lightPowFactor);
            Graphics.Blit(source, buffer0, material, 0);    //根据阈值提取高亮部分，使用Pass0，比Bloom多一步 计算光源距离剔除光源范围外的部分

            // 镜像模糊的采样uv偏移值
            float samplerOffset = samplerScale / source.width;

            // 通过循环迭代径向模糊
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

            // 模糊的结果传递给材质中的属性
            material.SetTexture("_BlurTex", buffer0);
            material.SetVector("_LightColor", lightColor);
            material.SetFloat("_LightFactor", lightFactor);

            // 将镜像模糊结果与原图进行混合
            Graphics.Blit(source, destination, material, 2);

            // 最后释放临时缓冲
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
