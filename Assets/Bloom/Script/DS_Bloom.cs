using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// PostEffectsBase����
public class DS_Bloom : PostEffectsBase
{
    public Shader bloomShader;
    private Material bloomMaterial = null;

    public  Material material
    {
        get
        {
            // ����PostEffectsBase�����еĺ��������shader����������
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]       public int interations = 3; //��˹ģ����������
    [Range(0.2f, 3.0f)] public float blurSpread; //��˹ģ����Χ
    [Range(1, 8)]       public int downSample = 2; //������ ����ϵ��
    [Range(0.0f, 1.0f)] public float luminanceThreshold = 0.6f; //��ֵ

    // ����OnRenderImage������ʵ��Bloom
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold); // ������ֵ

            // src.width �� height ������Ļͼ��Ŀ�Ⱥ͸߶�
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            // ����һ��ֱ���С��ԭ��Ļ�Ļ�������buffer0
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear; //�˲�ģʽΪ˫����

            // ��Blit��������shader�еĵ�һ��pass����ȡͼ���н���������
            Graphics.Blit(source, buffer0, material, 0); //�������buffer0

            // �������и�˹ģ��
            for (int i = 0; i < interations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread); //����ģ���뾶

                // ����ڶ�����������buffer1
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // ��Blit��������Shader�еĵڶ���pass��������ֱ����ĸ�˹ģ��
                Graphics.Blit(buffer0, buffer1, material, 1);

                // �ͷŻ�����buffer0, ��buffer1��ֵ����buffer0�������·���buffer1
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // ����Shader������pass������ˮƽ����ģ��
                Graphics.Blit (buffer0, buffer1, material, 2);

                // �ͷ�
                RenderTexture.ReleaseTemporary (buffer0);
                buffer0 = buffer1;

                // ������ɺ�buffer0���Ǹ�˹ģ����Ľ��
            }

            // ����ɸ�˹ģ����Ľ��buffer0���������е�_Bloom����
            material.SetTexture("_Bloom", buffer0);

            // ����shader�еĵ��ĸ�pass����ɻ��
            Graphics.Blit(source, destination, material, 3);

            // �ͷ���ʱ������
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            // ��Դ����Ϊ��ʱ����Դ�����Ƶ�Ŀ����Ⱦ������
            Graphics.Blit(source, destination);
        }
    }
}
