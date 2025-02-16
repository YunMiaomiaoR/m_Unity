using UnityEngine;
using UnityEngine.Rendering;

// �ýű��ڱ༭ģʽ��Ҳ��ִ�У��������ڳ�����ͼ��ʹ��ͼ��Ч����
// ͬʱ��Ҫ�󸽼Ӹýű��Ķ����ϱ�����һ��Camera�����
[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class CommandBufferBlur : MonoBehaviour
{
    private Shader _Shader;
    private Material _Material = null;
    private Camera _Camera = null;

    private CommandBuffer _CommandBuffer = null;
    private RenderTextureFormat _TextureFormat = RenderTextureFormat.ARGB32;  // �洢��Ⱦ�����ʽ��Ĭ������ΪARGB32
    private Vector2 _ScreenResolution = Vector2.zero;  // ������Ļ�ֱ���

    public void Cleanup()
    {
        // û��ʼ����ֱ�ӷ���
        if(!Initialized)
            return;
        
        // �����������Ⱦʱ�����Ƴ��������
        _Camera.RemoveCommandBuffer(CameraEvent.BeforeForwardAlpha, _CommandBuffer);
        // ���������������Ϊnull
        _CommandBuffer = null;
        // ���ٲ���
        Object.DestroyImmediate(_Material);
    }

    // �ű�����ʱ���ã� �������³�ʼ��
    public void OnEnable()
    {
        Cleanup();
        Initialize();
    }

    // �ű�����ʱ���ã� ��������
    public void OnDisable()
    {
        Cleanup();
    }

    // �����������Ƿ��Ѿ���ʼ��
    public bool Initialized
    {
        get { return _CommandBuffer != null; }
    }

    // ��ʼ������������Shader���������ʺ��������
    void Initialize()
    {
        if (Initialized)
            return;

        // Shader�쳣���
        if (!_Shader)
        {
            _Shader = Shader.Find("Shader/SeparableBlur"); //ģ����shader

            if (!_Shader)
                throw new MissingReferenceException("Unable to find required shader \"Shader/SeparableBlur\"");
        }

        if (!_Material)
        {
            _Material = new Material(_Shader);
            _Material.hideFlags = HideFlags.HideAndDontSave; 
        }

        _Camera = GetComponent<Camera>();

        // �����������HDR���ú�ϵͳ֧�����ȷ��ʹ�õ������ʽ
        if (_Camera.allowHDR && SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.DefaultHDR))
            _TextureFormat = RenderTextureFormat.DefaultHDR;

        _CommandBuffer = new CommandBuffer();
        _CommandBuffer.name = "Blur screen";

        int numInterations = 4; // ��������ģ���ĵ�������

        Vector2[] sizes =
        {
            new Vector2(Screen.width, Screen.height),
            new Vector2(Screen.width / 2, Screen.height / 2),   // ���ͷֱ��ʣ�������ܺ�ģ��Ч��
            new Vector2(Screen.width / 4, Screen.height / 4),
            new Vector2(Screen.width / 8, Screen.height / 8),
        };

        // ���ж�ν�������ģ������
        for (int i = 0; i < numInterations; ++i)
        {
            // ����һ����ʱRT���ڴ洢��Ļ����
            int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
            // width in pixels, or -1 for "camera pixel width"
            _CommandBuffer.GetTemporaryRT(screenCopyID, -1, -1, 0, FilterMode.Bilinear, _TextureFormat);    // ����������ֱ��ʴ�С��RT
            _CommandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);  // ���������ǰ��RT���Ƹ�screenCopyID

            // ����������ʱRT����ģ������
            int blurredID = Shader.PropertyToID("_Grab" + i + "_Temp1");
            int blurredID2 = Shader.PropertyToID("_Grab" + i + "_Temp2");
            _CommandBuffer.GetTemporaryRT(blurredID, (int)sizes[i].x, (int) sizes[i].y, 0, FilterMode.Bilinear, _TextureFormat);    // ������ʱ��RT1��RT2��������ģ��Ч��
            _CommandBuffer.GetTemporaryRT(blurredID2, (int)sizes[i].x, (int) sizes[i].y, 0, FilterMode.Bilinear, _TextureFormat);

            // ����Ļ���ݸ��Ƶ���һ����ʱRT
            _CommandBuffer.Blit(screenCopyID, blurredID);
            _CommandBuffer.ReleaseTemporaryRT(screenCopyID);    // �ͷ�screenCopyID��RT

            // �Ե�һ����ʱRT����ģ��
            _CommandBuffer.SetGlobalVector("offsets", new Vector4(2.0f / sizes[i].x, 0, 0, 0)); // ����ģ��
            _CommandBuffer.Blit(blurredID, blurredID2,_Material);
            _CommandBuffer.SetGlobalVector("offsets", new Vector4(0, 2.0f / sizes[i].y, 0, 0)); // ����ģ��
            _CommandBuffer.Blit(blurredID2, blurredID, _Material);

            _CommandBuffer.SetGlobalTexture("_GrabBlurTexture_" + i, blurredID); // ģ��Ч����ɺ󣬽������õ� ȫ������_GrabBlurTexture_1234, ������FrostedGlass.shader�п���ֱ�ӷ���
        }

        _Camera.AddCommandBuffer(CameraEvent.BeforeForwardAlpha, _CommandBuffer);   // ����ȾTransparent����֮ǰִ�У�ȷ����ȾFrostedGlass(Transparent)��ʱ�����ʹ��_GrabBlurTexture_1234

        _ScreenResolution = new Vector2(Screen.width, Screen.height);    // ������Ļ�ֱ���
    }

    // �����Ⱦǰ �ص�OnPreRender�������ű�Ҫ���ص�����ϣ�
    // ��ÿ����Ⱦ֮ǰ���ã������Ļ�ֱ��ʷ����仯�������³�ʼ��
    void OnPreRender()
    {
        if (_ScreenResolution != new Vector2(Screen.width, Screen.height))
            Cleanup();

        Initialize();
    }
}
