using UnityEngine;

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
    public Camera MainCamera = null;
    public Camera reflectionCamera = null;
    public RenderTexture reflectionRT = null;
    private bool isReflectionCameraRendering = false;
    private Material reflectionMaterial = null;

    private void OnWillRenderObject()
    {
        if (isReflectionCameraRendering)
            return;

        isReflectionCameraRendering = true;

        if (reflectionCamera == null)
        {
            var go = new GameObject("Reflection Camera");
            reflectionCamera = go.AddComponent<Camera>();
            reflectionCamera.CopyFrom(MainCamera);
        }
        if (reflectionRT == null)
        {
            reflectionRT = RenderTexture.GetTemporary(1024, 1024, 24);
        }
        //��Ҫʵʱͬ������Ĳ���������༭���¹������֣�Editor�����Զ���ü���ͻ�仯
        UpdateCamearaParams(MainCamera, reflectionCamera);
        reflectionCamera.targetTexture = reflectionRT;
        reflectionCamera.enabled = false;

        var reflectM = CaculateReflectMatrix();
        reflectionCamera.worldToCameraMatrix = MainCamera.worldToCameraMatrix * reflectM;

        var normal = transform.up;
        var d = -Vector3.Dot(normal, transform.position);
        var plane = new Vector4(normal.x, normal.y, normal.z, d);
        //����ת�þ���ƽ�������ռ�任����������ռ�
        var viewSpacePlane = reflectionCamera.worldToCameraMatrix.inverse.transpose * plane;
        var clipMatrix = reflectionCamera.CalculateObliqueMatrix(viewSpacePlane);
        reflectionCamera.projectionMatrix = clipMatrix;

        GL.invertCulling = true;
        reflectionCamera.Render();
        GL.invertCulling = false;

        if (reflectionMaterial == null)
        {
            var renderer = GetComponent<Renderer>();
            reflectionMaterial = renderer.sharedMaterial;
        }
        reflectionMaterial.SetTexture("_ReflectionTex", reflectionRT);

        isReflectionCameraRendering = false;
    }

    Matrix4x4 CaculateReflectMatrix()
    {
        var normal = transform.up;
        var d = -Vector3.Dot(normal, transform.position);
        var reflectM = new Matrix4x4();
        reflectM.m00 = 1 - 2 * normal.x * normal.x;
        reflectM.m01 = -2 * normal.x * normal.y;
        reflectM.m02 = -2 * normal.x * normal.z;
        reflectM.m03 = -2 * d * normal.x;

        reflectM.m10 = -2 * normal.x * normal.y;
        reflectM.m11 = 1 - 2 * normal.y * normal.y;
        reflectM.m12 = -2 * normal.y * normal.z;
        reflectM.m13 = -2 * d * normal.y;

        reflectM.m20 = -2 * normal.x * normal.z;
        reflectM.m21 = -2 * normal.y * normal.z;
        reflectM.m22 = 1 - 2 * normal.z * normal.z;
        reflectM.m23 = -2 * d * normal.z;

        reflectM.m30 = 0;
        reflectM.m31 = 0;
        reflectM.m32 = 0;
        reflectM.m33 = 1;
        return reflectM;
    }

    private void UpdateCamearaParams(Camera srcCamera, Camera destCamera)
    {
        if (destCamera == null || srcCamera == null)
            return;

        destCamera.clearFlags = srcCamera.clearFlags;
        destCamera.backgroundColor = srcCamera.backgroundColor;
        destCamera.farClipPlane = srcCamera.farClipPlane;
        destCamera.nearClipPlane = srcCamera.nearClipPlane;
        destCamera.orthographic = srcCamera.orthographic;
        destCamera.fieldOfView = srcCamera.fieldOfView;
        destCamera.aspect = srcCamera.aspect;
        destCamera.orthographicSize = srcCamera.orthographicSize;
    }
}