using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class CommandBufferBlurRefraction : MonoBehaviour
{
    public Shader m_BlurShader;
    private Material m_Material;

    private Camera m_Cam;

    // We'll want to add a command buffer on any camera that renders us,
    // so have a dictionary of them.
    private Dictionary<Camera, CommandBuffer> m_Cameras = new Dictionary<Camera, CommandBuffer>();

    // Remove command buffers from all cameras we added into
    private void Cleanup()
    {
        foreach (var cam in m_Cameras)
        {
            if (cam.Key)
            {
                cam.Key.RemoveCommandBuffer(CameraEvent.AfterSkybox, cam.Value);
            }
        }
        m_Cameras.Clear();
        Object.DestroyImmediate(m_Material);
    }

    public void OnEnable()
    {
        Cleanup();
    }

    public void OnDisable()
    {
        Cleanup();
    }

    // Whenever any camera will render us, add a command buffer to do the work on it
    public void OnWillRenderObject()
    {
        var act = gameObject.activeInHierarchy && enabled;
        if (!act)
        {
            Cleanup();
            return;
        }

        var cam = Camera.current;
        if (!cam)
            return;

        CommandBuffer buf = null;
        // Did we already add the command buffer on this camera? Nothing to do then.
        if (m_Cameras.ContainsKey(cam))
            return;

        if (!m_Material)
        {
            m_Material = new Material(m_BlurShader);
            m_Material.hideFlags = HideFlags.HideAndDontSave;
        }

        buf = new CommandBuffer();
        buf.name = "Grab screen and blur";
        m_Cameras[cam] = buf;

        // copy screen into temporary RT
        //获取渲染纹理ID
        int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
        //用screenCopyID标识，获取一个模板纹理。
        buf.GetTemporaryRT(screenCopyID, -1, -1, 0, FilterMode.Bilinear);
        //BuiltinRenderTextureType.CurrentActive也就是当前屏幕的纹理标识，将其赋值进screenCopyID标识的纹理。
        buf.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);

        // get two smaller RTs
        //获取2个模板纹理，后面将它们2的效果轮流混合。
        int blurredID = Shader.PropertyToID("_Temp1");
        int blurredID2 = Shader.PropertyToID("_Temp2");
        buf.GetTemporaryRT(blurredID, -2, -2, 0, FilterMode.Bilinear);
        buf.GetTemporaryRT(blurredID2, -2, -2, 0, FilterMode.Bilinear);

        // downsample screen copy into smaller RT, release screen RT
        //将抓屏纹理_ScreenCopyTexture采样填充到_Temp1后释放。
        buf.Blit(screenCopyID, blurredID);
        buf.ReleaseTemporaryRT(screenCopyID);

        // horizontal blur
        //修改SeparableBlur.shader的全局参数offsets，使其产生各个方向的模糊效果来叠加增强效果。
        //（如果着色器不在 Properties模块中暴露某个参数，将使用全局属性）
        buf.SetGlobalVector("offsets", new Vector4(2.0f / Screen.width, 0, 0, 0));
        //使用m_Material渲染blurredID结果赋值给blurredID2。
        buf.Blit(blurredID, blurredID2, m_Material);
        // vertical blur
        buf.SetGlobalVector("offsets", new Vector4(0, 2.0f / Screen.height, 0, 0));
        buf.Blit(blurredID2, blurredID, m_Material);
        // horizontal blur
        buf.SetGlobalVector("offsets", new Vector4(4.0f / Screen.width, 0, 0, 0));
        buf.Blit(blurredID, blurredID2, m_Material);
        // vertical blur
        buf.SetGlobalVector("offsets", new Vector4(0, 4.0f / Screen.height, 0, 0));
        buf.Blit(blurredID2, blurredID, m_Material);

        //得到透明效果纹理后，赋值给GlassWithoutGrab.shader的_GrabBlurTexture混合得出模糊透明。
        buf.SetGlobalTexture("_GrabBlurTexture", blurredID);

        cam.AddCommandBuffer(CameraEvent.AfterSkybox, buf);
    }
}

