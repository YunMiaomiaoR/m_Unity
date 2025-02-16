using UnityEngine;
using UnityEngine.Rendering;

// 该脚本在编辑模式下也能执行，并允许在场景视图中使用图像效果。
// 同时，要求附加该脚本的对象上必须有一个Camera组件。
[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class CommandBufferBlur : MonoBehaviour
{
    private Shader _Shader;
    private Material _Material = null;
    private Camera _Camera = null;

    private CommandBuffer _CommandBuffer = null;
    private RenderTextureFormat _TextureFormat = RenderTextureFormat.ARGB32;  // 存储渲染纹理格式，默认设置为ARGB32
    private Vector2 _ScreenResolution = Vector2.zero;  // 保存屏幕分辨率

    public void Cleanup()
    {
        // 没初始化就直接返回
        if(!Initialized)
            return;
        
        // 从摄像机的渲染时间中移除命令缓冲区
        _Camera.RemoveCommandBuffer(CameraEvent.BeforeForwardAlpha, _CommandBuffer);
        // 将命令缓冲区引用设为null
        _CommandBuffer = null;
        // 销毁材质
        Object.DestroyImmediate(_Material);
    }

    // 脚本启用时调用， 清理并重新初始化
    public void OnEnable()
    {
        Cleanup();
        Initialize();
    }

    // 脚本禁用时调用， 进行清理
    public void OnDisable()
    {
        Cleanup();
    }

    // 检查命令缓冲区是否已经初始化
    public bool Initialized
    {
        get { return _CommandBuffer != null; }
    }

    // 初始化方法，加载Shader、创建材质和命令缓冲区
    void Initialize()
    {
        if (Initialized)
            return;

        // Shader异常检测
        if (!_Shader)
        {
            _Shader = Shader.Find("Shader/SeparableBlur"); //模糊的shader

            if (!_Shader)
                throw new MissingReferenceException("Unable to find required shader \"Shader/SeparableBlur\"");
        }

        if (!_Material)
        {
            _Material = new Material(_Shader);
            _Material.hideFlags = HideFlags.HideAndDontSave; 
        }

        _Camera = GetComponent<Camera>();

        // 根据摄像机的HDR设置和系统支持情况确定使用的纹理格式
        if (_Camera.allowHDR && SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.DefaultHDR))
            _TextureFormat = RenderTextureFormat.DefaultHDR;

        _CommandBuffer = new CommandBuffer();
        _CommandBuffer.name = "Blur screen";

        int numInterations = 4; // 降采样和模糊的迭代次数

        Vector2[] sizes =
        {
            new Vector2(Screen.width, Screen.height),
            new Vector2(Screen.width / 2, Screen.height / 2),   // 降低分辨率，提高性能和模糊效果
            new Vector2(Screen.width / 4, Screen.height / 4),
            new Vector2(Screen.width / 8, Screen.height / 8),
        };

        // 进行多次降采样和模糊操作
        for (int i = 0; i < numInterations; ++i)
        {
            // 创建一个临时RT用于存储屏幕内容
            int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
            // width in pixels, or -1 for "camera pixel width"
            _CommandBuffer.GetTemporaryRT(screenCopyID, -1, -1, 0, FilterMode.Bilinear, _TextureFormat);    // 申请摄像机分辨率大小的RT
            _CommandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);  // 将摄像机当前的RT复制给screenCopyID

            // 创建两个临时RT用于模糊处理
            int blurredID = Shader.PropertyToID("_Grab" + i + "_Temp1");
            int blurredID2 = Shader.PropertyToID("_Grab" + i + "_Temp2");
            _CommandBuffer.GetTemporaryRT(blurredID, (int)sizes[i].x, (int) sizes[i].y, 0, FilterMode.Bilinear, _TextureFormat);    // 申请临时的RT1，RT2，用来做模糊效果
            _CommandBuffer.GetTemporaryRT(blurredID2, (int)sizes[i].x, (int) sizes[i].y, 0, FilterMode.Bilinear, _TextureFormat);

            // 将屏幕内容复制到第一个临时RT
            _CommandBuffer.Blit(screenCopyID, blurredID);
            _CommandBuffer.ReleaseTemporaryRT(screenCopyID);    // 释放screenCopyID的RT

            // 对第一个临时RT进行模糊
            _CommandBuffer.SetGlobalVector("offsets", new Vector4(2.0f / sizes[i].x, 0, 0, 0)); // 横向模糊
            _CommandBuffer.Blit(blurredID, blurredID2,_Material);
            _CommandBuffer.SetGlobalVector("offsets", new Vector4(0, 2.0f / sizes[i].y, 0, 0)); // 纵向模糊
            _CommandBuffer.Blit(blurredID2, blurredID, _Material);

            _CommandBuffer.SetGlobalTexture("_GrabBlurTexture_" + i, blurredID); // 模糊效果完成后，将其设置到 全局纹理_GrabBlurTexture_1234, 其他的FrostedGlass.shader中可以直接访问
        }

        _Camera.AddCommandBuffer(CameraEvent.BeforeForwardAlpha, _CommandBuffer);   // 在渲染Transparent队列之前执行，确保渲染FrostedGlass(Transparent)的时候可以使用_GrabBlurTexture_1234

        _ScreenResolution = new Vector2(Screen.width, Screen.height);    // 更新屏幕分辨率
    }

    // 相机渲染前 回调OnPreRender函数（脚本要挂载到相机上）
    // 在每次渲染之前调用，如果屏幕分辨率发生变化，则重新初始化
    void OnPreRender()
    {
        if (_ScreenResolution != new Vector2(Screen.width, Screen.height))
            Cleanup();

        Initialize();
    }
}
