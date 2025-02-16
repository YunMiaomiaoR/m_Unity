using UnityEngine;
using UnityEngine.Rendering;


[ExecuteInEditMode]
public class CommendBufferTest : MonoBehaviour
{
    public Shader shader;
    private void OnEnable()
    {
        CommandBuffer buf = new CommandBuffer();
        // 自己的渲染
        buf.DrawRenderer(GetComponent<Renderer>(), new Material(shader));
        // 不透明物体渲染完后执行
        Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, buf);
    }
}
