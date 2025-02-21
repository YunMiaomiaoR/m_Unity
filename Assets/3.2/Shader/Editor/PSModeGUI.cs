using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class PSModeGUI : ShaderGUI
{
    private Material mat;
    // 1.定义枚举类型：BlendModeChoose
    // enum里无法直接绘制分隔线
    enum BlendModeChoose
    {
        正常_Normal,
        透明混合_Alphablend,
        // Darken Blending Mode Category 叠加后整体图片变暗
        变暗_Darken,
        正片叠底_Multiply,
        颜色加深_ColorBurn,
        线性加深_LinearBurn,
        深色_DarkerColor,
        // Lighten Blending Mode Category 叠加后整体图片变亮
        变亮_Lighten,
        滤色_Screen,
        颜色减淡_ColorDodge,
        线性减淡_LinearDodge,
        浅色_LighterColor,
        // Contrast Blending Mode Category 
        叠加_Overlay,
        柔光_SoftLight,
        强光_HardLight,
        亮光_VividLight,
        线性光_LinearLight,
        点光_PinLight,
        实色混合_HardMix,
        // Inversion Blending Mode Category 
        差值_Difference,
        排除_Exclusion,
        减去_Subtract,
        划分_Divide,
        // Component Blending Mode Category 
        色相_Hue,
        饱和度_Saturation,
        颜色_Color,
        明度_Luminosity
    }

    // 2.定义材质属性和下拉菜单选项
    private MaterialProperty ModeID;
    private MaterialProperty ModeChooseProps;
    // 将 BlendModeChoose 枚举中的所有选项转换为字符串数组，以用于显示在下拉菜单中。
    string[] MaterialChoosenames = System.Enum.GetNames(typeof(BlendModeChoose));

    private MaterialProperty DstColorProps;
    private MaterialProperty DstTextureProps;
    private MaterialProperty SrcColorProps;
    private MaterialProperty SrcTextureProps;

    // 3.重写ShaderGUI的OnGUI方法，（虚方法，从父类继承而来，可以被子类重写）
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);
        // 控制混合模式选择的布局和交互
        // 垂直布局区域；创建一个 GUIStyle 样式；"U2D.createRect" 是 Unity 内置的样式，给区域添加一个边框或矩形效果
        EditorGUILayout.BeginVertical(new GUIStyle("U2D.createRect"));
        EditorGUILayout.Space(10);

        // 3.1.查找材质属性并显示下拉菜单
        // 查找数组：FindProperty方法用于在材质属性数组中 查找一个特定的属性;_IDChoose 是在 Shader 中定义的材质属性。
        ModeChooseProps = FindProperty("_IDChoose", properties);
        ModeID = FindProperty("_ModeID", properties);
        // 显示下拉菜单：EditorGUILayout.Popup();
        // (int)ModeChooseProps.floatValue：转换为整数;
        // MateritalChoosenames：将枚举 BlendModeChoose 的所有值转换为字符串数组
        ModeChooseProps.floatValue = EditorGUILayout.Popup(
            "BlendModeChoose", (int)ModeChooseProps.floatValue,
            MaterialChoosenames);

        // 3.2.根据用户选择设置 ModeID 值
        switch (ModeChooseProps.floatValue) 
        { 
            case 0:
                ModeID.floatValue = 0; break;
            case 1:
                ModeID.floatValue = 1; break;
            case 2:
                ModeID.floatValue = 2; break;
            case 3:
                ModeID.floatValue = 3; break;
            case 4:
                ModeID.floatValue = 4; break;
            case 5:
                ModeID.floatValue = 5; break;
            case 6:
                ModeID.floatValue = 6; break;
            case 7:
                ModeID.floatValue = 7; break;
            case 8:
                ModeID.floatValue = 8; break;
            case 9:
                ModeID.floatValue = 9; break;
            case 10:
                ModeID.floatValue = 10; break;
            case 11:
                ModeID.floatValue = 11; break;
            case 12:
                ModeID.floatValue = 12; break;
            case 13:
                ModeID.floatValue = 13; break;
            case 14:
                ModeID.floatValue = 14; break;
            case 15:
                ModeID.floatValue = 15; break;
            case 16:
                ModeID.floatValue = 16; break;
            case 17:
                ModeID.floatValue = 17; break;
            case 18:
                ModeID.floatValue = 18; break;
            case 19:
                ModeID.floatValue = 19; break;
            case 20:
                ModeID.floatValue = 20; break;
            case 21:
                ModeID.floatValue = 21; break;
            case 22:
                ModeID.floatValue = 22; break;
            case 23:
                ModeID.floatValue = 23; break;
            case 24:
                ModeID.floatValue = 24; break;
            case 25:
                ModeID.floatValue = 25; break;
            case 26:
                ModeID.floatValue = 26; break;
        }

        EditorGUILayout.Space(10);
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(30);
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        EditorGUILayout.Space(10);

        // 3.3设置材质的颜色和纹理
        DstColorProps = FindProperty("_Color1", properties);
        materialEditor.ColorProperty(DstColorProps, "DstColor");
        DstTextureProps = FindProperty("_MainTex1", properties);
        materialEditor.TextureProperty(DstTextureProps, "DstTexture");
        EditorGUILayout.Space(20);
        SrcColorProps = FindProperty("_Color2", properties);
        materialEditor.ColorProperty(SrcColorProps, "SrcColor");
        SrcTextureProps = FindProperty("_MainTex2", properties);
        materialEditor.TextureProperty(SrcTextureProps, "SrcTexture");
        EditorGUILayout.Space(10);
        EditorGUILayout.EndVertical();
    }
}
