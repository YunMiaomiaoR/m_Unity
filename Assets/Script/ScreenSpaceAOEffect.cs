using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ScreenSpaceAOEffect : MonoBehaviour
{
    // private����
    private Material ssaoMaterial = null;
    private Camera cam = null;
    private List<Vector4> sampleKernelList = new List<Vector4>();
    public Texture2D noiseTexture;

    // ������
    // AO
    [Range(4, 32)] 
    public int sampleKernelCount = 32;
    [Range(0.010f, 1.0f)]
    public float SampleKernelRadius = 1.0f;
    [Range(0, 2)]
    public int DownSample = 0;
    [Range(0, 0.002f)]
    public float DepthBiasValue = 0.002f;
    [Range(0, 5.0f)]
    public float AOStrength = 1.0f;
    // Blur
    [Range(0, 0.2f)]
    public float BilaterFilterStrength = 0.2f;
    [Range(1, 4)]
    public int BlurRadius = 1;

    // AO��Ͽ���
    public bool OnlyShowAO = false;

    public enum SSAOPassName
    {
        GenerateAO = 0,
        BilateralFilter = 1,
        Composite = 2,
    }

    // ����shader��������ssaoMaterial
    private void Awake()
    {
        var shader = Shader.Find("AO/ScreenSpaceAOEffect");
        ssaoMaterial = new Material(shader);
        cam = GetComponent<Camera>();
    }

    // �ű�����ʱ��ȡ��Ⱥͷ�����Ϣ
    private void OnEnable()
    {
        cam.depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    private void OnDisable()
    {
        cam.depthTextureMode &= ~DepthTextureMode.DepthNormals;
    }

    // ��Ⱦ��ͼ����
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        GenerateAOSampleKernel();

        //ssaoMaterial.SetTexture("_MainTex", source);
        ssaoMaterial.SetTexture("_NoiseTex", noiseTexture);

        // AO
        var aoRT = RenderTexture.GetTemporary(source.width >> DownSample, source.height >> DownSample, 0);
        ssaoMaterial.SetMatrix      ("_InverseProjectionMatrix", cam.projectionMatrix.inverse);
        ssaoMaterial.SetFloat       ("_DepthBiasValue", DepthBiasValue);
        ssaoMaterial.SetFloat       ("_AOStrength", AOStrength);
        ssaoMaterial.SetVectorArray ("_SampleKernelArray", sampleKernelList.ToArray());
        ssaoMaterial.SetFloat       ("_SampleKernelCount", sampleKernelList.Count);
        ssaoMaterial.SetFloat       ("_SampleKernelRadius", SampleKernelRadius);
        Graphics.Blit(source, aoRT, ssaoMaterial, (int)SSAOPassName.GenerateAO);
        
        // ģ��������ģ����
        var blurRT = RenderTexture.GetTemporary(source.width >> DownSample, source.height >> DownSample, 0);
        ssaoMaterial.SetFloat("_BilaterFilterFactor", 1.0f - BilaterFilterStrength);
        ssaoMaterial.SetVector("_BlurRadius", new Vector4(BlurRadius, 0, 0, 0));
        Graphics.Blit(aoRT, blurRT, ssaoMaterial, (int)SSAOPassName.BilateralFilter);

        ssaoMaterial.SetVector("_BlurRadius", new Vector4(0, BlurRadius, 0, 0));
        // ֻ��AO
        if (OnlyShowAO)
        {
            Graphics.Blit(blurRT, destination, ssaoMaterial, (int)SSAOPassName.BilateralFilter);
        }
        // AO��ԭʼ�����ϳ�
        else
        {
            Graphics.Blit(blurRT, aoRT, ssaoMaterial, (int)SSAOPassName.BilateralFilter);
            ssaoMaterial.SetTexture("_AOTex", aoRT);
            Graphics.Blit(source, destination, ssaoMaterial, (int)SSAOPassName.Composite);
        }

        RenderTexture.ReleaseTemporary(aoRT);
        RenderTexture.ReleaseTemporary(blurRT);
    }

    private void GenerateAOSampleKernel()
    {
        if (sampleKernelCount == sampleKernelList.Count)
        {
            return; //listΪ���򷵻�
        }
        sampleKernelList.Clear();
        for (int i = 0; i < sampleKernelCount; i++)
        {
            Vector4 vec = new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), Random.Range(0, 1.0f), 1.0f);
            // ��ʼ���������
            vec.Normalize();
            float scale = (float)i / sampleKernelCount;
            scale = Mathf.Lerp(0.01f, 1.0f, scale * scale); //i��0-63��Ӧ0-1�Ķ��η�������
            vec *= scale;
            sampleKernelList.Add(vec);
        }
    }
}
