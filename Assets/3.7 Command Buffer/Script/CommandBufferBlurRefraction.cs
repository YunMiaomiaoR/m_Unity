using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// ��UnityEditorģʽ��Ҳ������
[ExecuteInEditMode]
public class CommandBufferBlurRefraction : MonoBehaviour
{
    // ����ģ����shader
    public Shader m_BlurShader;
    // ����ģ���Ĳ�����
    private Material m_Material;
    private Camera m_Cam;

    // ���ڴ洢Camera �� ��Ӧ CommandBuffer �ļ�ֵ��
    private Dictionary<Camera, CommandBuffer> m_Cameras = new Dictionary<Camera, CommandBuffer>();


    // �Ƴ�֮ǰΪ���������ӵ�Command Buffer
    private void Cleanup()
    {
        foreach (var cam in m_Cameras)
        {
            if (cam.Key)
            {
                // �Ƴ���ָ����CameraEvent��ӵ�ָ����Command Buffer
                cam.Key.RemoveCommandBuffer (CameraEvent.AfterSkybox, cam.Value);
            }
        }
        m_Cameras.Clear(); //����ֵ�
        Object.DestroyImmediate(m_Material); //����ɾ��m_Material ������
    }
    // ���������ʱ�����һ��
    public void OnEnable()
    {
        Cleanup();
    }

    // �������ʱ�����һ��
    public void OnDisable()
    {
        Cleanup();
    }

    // ���κ������Ҫ��Ⱦ�ö����ʱ��Ϊ�����������һ��Command Buffer
    public void OnWillRenderObject()
    {
        // �����ǰ�ҽű�������û�м�����ߵ�ǰ�ű�û�м����ֱ�ӷ���
        var act = gameObject.activeInHierarchy && enabled;
        if (!act)
        {
            Cleanup();
            return;
        }

        // �����ǰû���������Ⱦ��Ҳֱ�ӷ���
        var cam = Camera.current;
        if (!cam)
            return;

        CommandBuffer buf = null;
        // ����Ѿ�����ǰ����������ֵ䣬˵���Ѿ���ӹ�Command Buffer������ʲô������
        if (m_Cameras.ContainsKey(cam))
            return;

        // ���m_MaterialΪ�գ��򴴽�һ�������� ʹ��m_BlurShader���shader
        if (!m_Material)
        {
            m_Material = new Material(m_BlurShader);
            // ���ò���������ر�ǩΪHideAndDontSave�����ز��Ҳ�����
            m_Material.hideFlags = HideFlags.HideAndDontSave;
        }

        // ����һ��Command Buffer������Ϊ��Grab screen and blur��
        // �����뵱ǰ�����cam��ɼ�ֵ�ԣ���ӵ��ֵ���
        buf = new CommandBuffer();
        buf.name = "Grab screen and blur";
        m_Cameras[cam] = buf;   //����д���ȼ��� m_Cameras.Add(cam. buf);

        // ������Ļ��һ����ʱ��Render Texture ��
        int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");   // ����Shader��������ȡһ����һ�޶���ID
        /* ��չ��ʹ������ID���ڵ��ò���������Ժ�����ʱ������Ч
         * ���磺����ʹ��Material.SetColor��ʹ��MaterialPropertyBlock
         * �ڲ�ͬ����Ϸ����Ͳ�ͬӲ���� ����ID�ǲ�ͬ�ģ����Բ�Ҫ��ͼ �洢����ͨ�����緢����
         */
        buf.GetTemporaryRT (screenCopyID, -1, -1, 0, FilterMode.Bilinear);   // ���һ����ʱRenderTexture
        /* GetTemporaryRT ����һ����ʱ��RenderTexture�������� ����ID ��������Ϊȫ�ֵ�Shader����
         * ������ʱ��RenderTexture���δ���� ReleaseTemporaryRT��ʽ�ͷţ�
         * �����������Ⱦ��� ����Graphics.ExecuteCommandBufferִ����ɺ� ���Ƴ�
         * -1, -1: ����ͼ�����ظ߿�-1��ʹ��������Ŀ�ߣ���Ϊ-x����������/x;
         * FilterMode.Bilinear��ʹ��˫���Թ���ģʽ�����������ƽ�����š�
         */

        // ���Ƶ�ǰ�����RT �����洴������ʱRT�����ܺ�ʹ������Graphics.Blit();
        buf.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);

        // ��ȡ����СRT
        int blurredID = Shader.PropertyToID("_Temp1");
        int blurredID2 = Shader.PropertyToID("_Temp2");
        buf.GetTemporaryRT(blurredID, -3, -3, 0, FilterMode.Bilinear);
        buf.GetTemporaryRT(blurredID2, -3, -3, 0, FilterMode.Bilinear);

        // ������ ����ʱRT ���Ƶ� ��������ĸ�С��RT�У��ͷ���ʱRT
        buf.Blit(screenCopyID, blurredID);
        buf.ReleaseTemporaryRT(screenCopyID);

        // ��˹ģ�������ڶ�̬ģ���̶ȵ����ĳ���
        // ˮƽģ�����������ص�ģ���뾶
        buf.SetGlobalVector("offsets", new Vector4(2.0f/Screen.width, 0, 0, 0));
        buf.Blit (blurredID, blurredID2, m_Material);   //�� blurredID �е�������Ⱦ�� blurredID2��ͬʱͨ������ m_Material Ӧ��ģ��Ч����
        // ��ֱ����ģ�����������ص�ģ���뾶
        buf.SetGlobalVector("offsets", new Vector4(0, 2.0f/Screen.height, 0, 0));
        buf.Blit (blurredID, blurredID, m_Material);   //�� blurredID �е�������Ⱦ�� blurredID2��ͬʱͨ������ m_Material Ӧ��ģ��Ч����
        // ˮƽģ�����ĸ����ص�ģ���뾶
        buf.SetGlobalVector("offsets", new Vector4(4.0f/Screen.width, 0, 0, 0));
        buf.Blit (blurredID, blurredID2, m_Material);   //�� blurredID �е�������Ⱦ�� blurredID2��ͬʱͨ������ m_Material Ӧ��ģ��Ч����
        // ��ֱģ�����ĸ����ص�ģ���뾶
        buf.SetGlobalVector("offsets", new Vector4(0, 4.0f/Screen.height, 0, 0));
        buf.Blit (blurredID, blurredID, m_Material);   //�� blurredID �е�������Ⱦ�� blurredID2��ͬʱͨ������ m_Material Ӧ��ģ��Ч����

        buf.SetGlobalTexture("_GrabBlurTexture", blurredID);    //���ģ�����

        // ��������¼�AfterSkybox�����CommandBuffer
        // ������Ⱦ�겻͸���������պ�֮��ִ�����CommandBuffer
        cam.AddCommandBuffer (CameraEvent.AfterSkybox, buf);
    }

}
