using UnityEngine;
using UnityEngine.Rendering;


[ExecuteInEditMode]
public class CommendBufferTest : MonoBehaviour
{
    public Shader shader;
    private void OnEnable()
    {
        CommandBuffer buf = new CommandBuffer();
        // �Լ�����Ⱦ
        buf.DrawRenderer(GetComponent<Renderer>(), new Material(shader));
        // ��͸��������Ⱦ���ִ��
        Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, buf);
    }
}
