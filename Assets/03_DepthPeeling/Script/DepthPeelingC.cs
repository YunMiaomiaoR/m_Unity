using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SocialPlatforms;

[RequireComponent(typeof(Camera))]
public class DepthPeelingC : MonoBehaviour
{
    // ö��
    public enum RT
    {
        Depth = 0,
        Color = 1,
    }

    [Range(1, 6)]
    public int depthMax = 3;
    public RT rt;
    public Shader MRTShader;
    public Shader finalClipsShader;

    private Camera sourceCamera;    //�������
    private Camera tempCamera;      //��ʱ����Ⱦ�������

    public RenderTexture[] rts;     //�洢������RT����Ⱥ���ɫ
    public RenderTexture rtTemp;    //��ʱRT
    private RenderBuffer[] colorBuffers;    //��ɫ������
    private RenderTexture depthBuffer;      //��Ȼ�����
    public RenderTexture finalClips;        //�洢�����Ȱ������ݡ�// �����Դ�ռ�ñȽϴ� ���Ҫ�Ż� ���Կ��� ��ǰ������� ��һ��rt�����ۻ�  �����㷨��˵����
    public bool showFinal;
    private Material finalClipMat;

    void Start()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
        // ��ʼ������ RenderTexture
        this.sourceCamera = this.GetComponent<Camera>();
        tempCamera = new GameObject().AddComponent<Camera>();
        tempCamera.enabled = false;

        finalClipMat = new Material(finalClipsShader);
        // rts �������ڴ洢������ȾĿ��
        this.rts = new RenderTexture[2]
        {
            new RenderTexture(sourceCamera.pixelWidth, sourceCamera.pixelHeight, 0, RenderTextureFormat.RFloat),    //��ȣ�Rͨ��������
            new RenderTexture(sourceCamera.pixelWidth, sourceCamera.pixelHeight, 0, RenderTextureFormat.Default),   //��ɫ
        };

        rts[0].Create();
        rts[1].Create();
        finalClips = new RenderTexture(sourceCamera.pixelWidth, sourceCamera.pixelHeight, 0, RenderTextureFormat.Default);

        finalClips.dimension = TextureDimension.Tex2DArray;
        finalClips.volumeDepth = 6;     //������������
        finalClips.Create();

        Shader.SetGlobalTexture("FinalClips", finalClips);
        rtTemp = new RenderTexture(sourceCamera.pixelWidth, sourceCamera.pixelHeight, 0, RenderTextureFormat.RFloat);
        rtTemp.Create();

        Shader.SetGlobalTexture("DepthRendered", rtTemp);
        colorBuffers = new RenderBuffer[2] { rts[0].colorBuffer, rts[1].colorBuffer };  //rts[0] �� rts[1] ����ɫ������

        depthBuffer = new RenderTexture(sourceCamera.pixelWidth, sourceCamera.pixelHeight, 16, RenderTextureFormat.Depth);
        depthBuffer.Create();
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        tempCamera.CopyFrom(sourceCamera);  //�����������������
        tempCamera.clearFlags = CameraClearFlags.SolidColor;   //�������Ϊ��һ��ɫ����Ⱥ�������Ϣ�������
        tempCamera.backgroundColor = Color.clear;               //��������Ϊ͸��
        tempCamera.SetTargetBuffers(colorBuffers, depthBuffer.depthBuffer); //�������ȾĿ��
        tempCamera.cullingMask = 1 << LayerMask.NameToLayer("clipRender");  //cullingMask �����������Ⱦ��Щͼ�㡣λ�����㷵�ص�ͼ������ ��clipRenderͼ������Ϊ������Ŀɼ�ͼ�㣨����Ⱦ clipRender ͼ���е����壩

        // ����Ⱦ������ӵ� finalClips
        for (int i = 0; i < depthMax; i++)
        {
            Graphics.Blit(rts[0], rtTemp); //��Ҫ���Ƴ��� ����ֱ����rts��0�� �����ǲ���ͬʱ��д
            Shader.SetGlobalInt("DepthRenderedIndex", i);
            tempCamera.RenderWithShader(MRTShader, "");     //��ʹ�������ǩ��ʹ��Ĭ��Pass
            Graphics.CopyTexture(rts[1], 0, 0, finalClips, i, 0);
        }

        if (showFinal == false)
        {
            Graphics.Blit(rts[rt.GetHashCode()], dest); //��ֱ�ӽ� rts[rt.GetHashCode()] �е�����������Ⱦ��Ŀ�� 
        }
        else
        {
            Graphics.Blit(null, dest, finalClipMat);    //ʹ�� finalClips ����������Ⱦ
        }
    }

    void OnDestroy()
    {
        rts[0].Release();
        rts[1].Release();
        finalClips.Release();
        rtTemp.Release();
        depthBuffer.Release();
    }
}
