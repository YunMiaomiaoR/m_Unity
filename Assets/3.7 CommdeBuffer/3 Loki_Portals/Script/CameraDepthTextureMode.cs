using UnityEngine;

public class CameraDepthTextureMode : MonoBehaviour
{
    // ���л�˽���ֶ�
    [SerializeField]
    DepthTextureMode m_DepthTextureMode;

    private void OnValidate()
    {
        SetCameraDepthTextureMode();
    }

    private void Awake()
    {
        SetCameraDepthTextureMode();
    }

    private void SetCameraDepthTextureMode()
    {
        GetComponent<Camera>().depthTextureMode = m_DepthTextureMode;
    }
}
