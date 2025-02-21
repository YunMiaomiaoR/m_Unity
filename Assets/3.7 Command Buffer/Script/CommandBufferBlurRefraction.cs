using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// 在UnityEditor模式下也能运行
[ExecuteInEditMode]
public class CommandBufferBlurRefraction : MonoBehaviour
{
    // 用于模糊的shader
    public Shader m_BlurShader;
    // 用于模糊的材质球
    private Material m_Material;
    private Camera m_Cam;

    // 用于存储Camera 和 对应 CommandBuffer 的键值对
    private Dictionary<Camera, CommandBuffer> m_Cameras = new Dictionary<Camera, CommandBuffer>();


    // 移除之前为所有相机添加的Command Buffer
    private void Cleanup()
    {
        foreach (var cam in m_Cameras)
        {
            if (cam.Key)
            {
                // 移除在指定的CameraEvent添加的指定的Command Buffer
                cam.Key.RemoveCommandBuffer (CameraEvent.AfterSkybox, cam.Value);
            }
        }
        m_Cameras.Clear(); //清空字典
        Object.DestroyImmediate(m_Material); //立即删除m_Material 材质球
    }
    // 启用组件的时候清空一次
    public void OnEnable()
    {
        Cleanup();
    }

    // 禁用组件时候清空一次
    public void OnDisable()
    {
        Cleanup();
    }

    // 当任何摄像机要渲染该对象的时候，为这个摄像机添加一个Command Buffer
    public void OnWillRenderObject()
    {
        // 如果当前挂脚本的物体没有激活，或者当前脚本没有激活，则直接返回
        var act = gameObject.activeInHierarchy && enabled;
        if (!act)
        {
            Cleanup();
            return;
        }

        // 如果当前没有摄像机渲染，也直接返回
        var cam = Camera.current;
        if (!cam)
            return;

        CommandBuffer buf = null;
        // 如果已经将当前摄像机加入字典，说明已经添加过Command Buffer，这里什么都不做
        if (m_Cameras.ContainsKey(cam))
            return;

        // 如果m_Material为空，则创建一个材质球 使用m_BlurShader这个shader
        if (!m_Material)
        {
            m_Material = new Material(m_BlurShader);
            // 设置材质球的隐藏标签为HideAndDontSave，隐藏并且不保存
            m_Material.hideFlags = HideFlags.HideAndDontSave;
        }

        // 创建一个Command Buffer，命名为“Grab screen and blur”
        // 并且与当前摄像机cam组成键值对，添加到字典中
        buf = new CommandBuffer();
        buf.name = "Grab screen and blur";
        m_Cameras[cam] = buf;   //这种写法等价于 m_Cameras.Add(cam. buf);

        // 复制屏幕到一个临时的Render Texture 上
        int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");   // 根据Shader变量名获取一个独一无二的ID
        /* 拓展：使用属性ID，在调用材质球的属性函数的时候会更高效
         * 例如：经常使用Material.SetColor或使用MaterialPropertyBlock
         * 在不同的游戏程序和不同硬件上 属性ID是不同的，所以不要试图 存储或者通过网络发送它
         */
        buf.GetTemporaryRT (screenCopyID, -1, -1, 0, FilterMode.Bilinear);   // 添加一个临时RenderTexture
        /* GetTemporaryRT 创建一个临时的RenderTexture，并根据 属性ID 将它设置为全局的Shader参数
         * 所有临时的RenderTexture如果未调用 ReleaseTemporaryRT显式释放，
         * 将会在相机渲染完成 或者Graphics.ExecuteCommandBuffer执行完成后 被移除
         * -1, -1: 是贴图的像素高宽。-1是使用摄像机的宽高；设为-x是摄像机宽高/x;
         * FilterMode.Bilinear：使用双线性过滤模式，对纹理进行平滑缩放。
         */

        // 复制当前激活的RT 到上面创建的临时RT，功能和使用类似Graphics.Blit();
        buf.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);

        // 获取两个小RT
        int blurredID = Shader.PropertyToID("_Temp1");
        int blurredID2 = Shader.PropertyToID("_Temp2");
        buf.GetTemporaryRT(blurredID, -3, -3, 0, FilterMode.Bilinear);
        buf.GetTemporaryRT(blurredID2, -3, -3, 0, FilterMode.Bilinear);

        // 降采样 将临时RT 复制到 上面申请的更小的RT中，释放临时RT
        buf.Blit(screenCopyID, blurredID);
        buf.ReleaseTemporaryRT(screenCopyID);

        // 高斯模糊，用于动态模糊程度调整的场景
        // 水平模糊，两个像素的模糊半径
        buf.SetGlobalVector("offsets", new Vector4(2.0f/Screen.width, 0, 0, 0));
        buf.Blit (blurredID, blurredID2, m_Material);   //将 blurredID 中的内容渲染到 blurredID2，同时通过材质 m_Material 应用模糊效果。
        // 垂直二分模糊，两个像素的模糊半径
        buf.SetGlobalVector("offsets", new Vector4(0, 2.0f/Screen.height, 0, 0));
        buf.Blit (blurredID, blurredID, m_Material);   //将 blurredID 中的内容渲染到 blurredID2，同时通过材质 m_Material 应用模糊效果。
        // 水平模糊，四个像素的模糊半径
        buf.SetGlobalVector("offsets", new Vector4(4.0f/Screen.width, 0, 0, 0));
        buf.Blit (blurredID, blurredID2, m_Material);   //将 blurredID 中的内容渲染到 blurredID2，同时通过材质 m_Material 应用模糊效果。
        // 垂直模糊，四个像素的模糊半径
        buf.SetGlobalVector("offsets", new Vector4(0, 4.0f/Screen.height, 0, 0));
        buf.Blit (blurredID, blurredID, m_Material);   //将 blurredID 中的内容渲染到 blurredID2，同时通过材质 m_Material 应用模糊效果。

        buf.SetGlobalTexture("_GrabBlurTexture", blurredID);    //输出模糊结果

        // 在摄像机事件AfterSkybox中添加CommandBuffer
        // 即，渲染完不透明物体和天空盒之后执行这个CommandBuffer
        cam.AddCommandBuffer (CameraEvent.AfterSkybox, buf);
    }

}
