using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// PostEffectsBase基类
public class DS_Bloom : PostEffectsBase
{
    public Shader bloomShader;
    private Material bloomMaterial = null;

    public  Material material
    {
        get
        {
            // 调用PostEffectsBase基类中的函数，检查shader并创建材质
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]       public int interations = 3; //高斯模糊迭代次数
    [Range(0.2f, 3.0f)] public float blurSpread; //高斯模糊范围
    [Range(1, 8)]       public int downSample = 2; //降采样 缩放系数
    [Range(0.0f, 1.0f)] public float luminanceThreshold = 0.6f; //阈值

    // 调用OnRenderImage函数来实现Bloom
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold); // 传入阈值

            // src.width 和 height 代表屏幕图像的宽度和高度
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            // 创建一块分辨率小于原屏幕的缓冲区：buffer0
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear; //滤波模式为双线性

            // 用Blit方法调用shader中的第一个pass，提取图像中较亮的区域
            Graphics.Blit(source, buffer0, material, 0); //结果存在buffer0

            // 迭代进行高斯模糊
            for (int i = 0; i < interations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread); //传入模糊半径

                // 定义第二个缓冲区：buffer1
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 用Blit方法调用Shader中的第二个pass，进行竖直方向的高斯模糊
                Graphics.Blit(buffer0, buffer1, material, 1);

                // 释放缓冲区buffer0, 将buffer1的值赋给buffer0，并重新分配buffer1
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 调用Shader第三个pass，进行水平方向模糊
                Graphics.Blit (buffer0, buffer1, material, 2);

                // 释放
                RenderTexture.ReleaseTemporary (buffer0);
                buffer0 = buffer1;

                // 迭代完成后，buffer0就是高斯模糊后的结果
            }

            // 将完成高斯模糊后的结果buffer0传给材质中的_Bloom纹理
            material.SetTexture("_Bloom", buffer0);

            // 调用shader中的第四个pass，完成混合
            Graphics.Blit(source, destination, material, 3);

            // 释放临时缓冲区
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            // 当源纹理不为空时，将源纹理复制到目标渲染纹理上
            Graphics.Blit(source, destination);
        }
    }
}
