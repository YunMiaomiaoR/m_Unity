// 头文件防护符，确保文件不会被重复包含，避免重复定义的错误
#ifndef PSBLENDMODE_INCLUDE
#define PSBLENDMODE_INCLUDE

// 正常
float3 Normal(float3 Src, float3 Dst)
{
	Dst = 0;
	return Src.rgb + Dst.rgb;
}

float3 Alphablend(float4 Src, float4 Dst)
{
	float4 C = Src.a * Src + (1.0 - Src.a) * Dst;
	return C.rgb;
}

// Darken Blending Mode Category 叠加后整体图片变暗
// 变暗
float3 Darken(float3 Src, float3 Dst)
{
	return min(Src, Dst);
}

// 正片叠底
float3 Multiply(float3 Src, float3 Dst)
{
	return Src * Dst;
}

// 颜色加深
float3 ColorBurn(float3 Src, float3 Dst)
{
	return 1.0 - (1.0 -Dst) / Src;
}

// 线性加深
float3 LinearBurn(float3 Src, float3 Dst)
{
	return Src + Dst - 1.0;
}

// 深色：rgb颜色分量总和的比较
float3 DarkerColor(float3 Src, float3 Dst)
{
	return (Src.x + Src.y + Src.z < Dst.x + Dst.y + Dst.z) ? Src : Dst;
}

// Lighten Blending Mode Category 叠加后整体图片变亮
// 变亮
float3 Lighten(float3 Src, float3 Dst)
{
	return max(Src, Dst);
}

// 滤色
float3 Screen(float3 Src, float3 Dst)
{
	return Src + Dst - Src * Dst;
}

// 颜色减淡
float3 ColorDodge(float3 Src, float3 Dst)
{
	return Dst / (1.0 - Src);
}

// 线性减淡
float3 LinearDodge(float3 Src, float3 Dst)
{
	return Src + Dst;
}

// 浅色
float3 LighterColor(float3 Src, float3 Dst)
{
	return (Src.x + Src.y + Src.z > Dst.x + Dst.y + Dst.z) ? Src : Dst;
}

// Contrast Blending Mode Category 
// 叠加（基于Dst图像）
float overlay(float Src, float Dst)
{
	// Dst < 0.5, 用正片叠底效果，使图像变暗
	// Dst >= 0.5, 用滤色效果，使图像变亮
	return (Dst < 0.5) ? 2.0 * Src * Dst : 1.0 - 2.0 * (1.0 - Src) * (1.0 - Dst);
}
float3 Overlay(float3 Src, float3 Dst)
{
	float3 C;
	C.x = overlay(Src.x, Dst.x);
	C.y = overlay(Src.y, Dst.y);
	C.z = overlay(Src.z, Dst.z);
	return C;
}

// 柔光
float softLight(float Src, float Dst)
{
	// Src < 0.5 ：较暗，减少目标像素亮度，产生阴影效果
	// Src = 0.5 且 Dst < 0.25 : 目标像素非常暗，强化非常暗的像素
	// Src >= 0.5 且 Dst >= 0.25: 目标像素较亮，计算目标像素的平方根来增加亮度
	return(Src < 0.5) ? Dst - (1.0 - 2.0 * Src) * Dst * (1.0 - Dst) :
		  (Dst < 0.25) ? Dst + (2.0 * Src - 1.0) * Dst *((16.0 * Dst - 12.0) * Dst + 3.0) :
		  Dst + (2.0 * Src - 1.0) * (sqrt(Dst) - Dst);
}
float3 SoftLight(float3 Src, float3 Dst)
{
	float3 C;
	C.x = softLight(Src.x, Dst.x);
	C.y = softLight(Src.y, Dst.y);
	C.z = softLight(Src.z, Dst.z);
	return C;
}

// 强光（基于Src图像）
float hardLight(float Src, float Dst)
{
	// Src < 0.5, 像素较暗，正片叠底，更加阴影化（较小的Src会减弱Dst）
	// Src >= 0.5, 像素较亮，滤色，使高亮部分更为突出
	return (Src < 0.5) ? 2.0 * Src * Dst : 1.0 - 2.0 * (1.0 - Src) * (1.0 - Dst);
}
float3 HardLight(float3 Src, float3 Dst)
{
	float3 C;
	C.x = hardLight(Src.x, Dst.x);
	C.y = hardLight(Src.y, Dst.y);
	C.z = hardLight(Src.z, Dst.z);
	return C;
}

// 亮光
float vividLight(float Src, float Dst)
{
	// Src < 0.5, 加深
	// Src >= 0.5, 减淡
	return (Src < 0.5) ? 1.0 - (1.0 - Dst) / (2.0 * Src) : Dst / (2.0 * (1.0 - Src));
}
float3 VividLight(float3 Src, float3 Dst)
{
	float3 C;
	C.x = vividLight(Src.x, Dst.x);
	C.y = vividLight(Src.y, Dst.y);
	C.z = vividLight(Src.z, Dst.z);
	return C;
}

// 线性光
float3 LinearLight(float Src, float Dst)
{
	return 2.0 * Src + Dst - 1.0;
}

// 点光
float pinLight(float Src, float Dst)
{
	// 2.0 * Src - 1.0 > Dst 源像素较亮，直接替换为源像素 亮度值
	// Src < 0.5 * Dst 源像素较暗，放大Src使暗部更明显
	// 不满足以上两种 —— 源像素亮度不明显，保留目标像素原始值
	return (2.0 * Src - 1.0 > Dst) ? 2.0 * Src - 1.0 :
		   (Src < 0.5 * Dst) ? 2.0 * Src : Dst;
}
float3 PinLight(float3 Src, float3 Dst)
{
	float3 C;
	C.x = pinLight(Src.x, Dst.x);
	C.y = pinLight(Src.y, Dst.y);
	C.z = pinLight(Src.z, Dst.z);
	return C;
}

// 实色混合
float3 HardMix(float3 Src, float3 Dst)
{
	return floor(Src + Dst);
}

// Inversion Blending Mode Category 
// 差值
float3 Difference(float3 Src, float3 Dst)
{
	return abs(Dst - Src);
}

// 排除
float3 Exclusion(float3 Src, float3 Dst)
{
	return Src + Dst - 2.0 * Src * Dst;
}

// 减去
float3 Subtract(float3 Src, float3 Dst)
{
	return Src - Dst;
}

// 划分
float3 Divide(float3 Src, float3 Dst)
{
	return Src / Dst;
}

// Component Blending Mode Category 
// RGB转HSV
float3 RGB2HSV(float3 C)
{
	// K是常量，用于颜色之间的比较和位置映射
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	// 比较 C.b 和 C.g，将较大值移动到第一位
	float4 p = lerp(float4(C.bg, K.wz), float4(C.gb, K.xy), step(C.b, C.g));
	// 进一步比较并将最大值放到第一位
	float4 q = lerp(float4(p.xyz, C.r), float4(C.r, p.xyz), step(p.x, C.r));
	// 计算最大值和最小值之间的差异
	float Dst = q.x - min(q.w, q.y);
	// 极小值限制1.0 × 10^(-10)(科学计数法不能有空格)
	float e = 1.0e-10;
	// 色相, 饱和度, 明度
	return float3(abs(q.z + (q.w - q.y) / (6.0 * Dst + e)), Dst / (q.x + e), q.x);
}

// HSV转RGB
float3 HSV2RGB(float3 C)
{
	float3 rgb;
	// fmod()计算浮点数，确保色相值在0-6之间循环，clamp()将值限制在[0.0, 1.0]之间
	rgb = clamp(abs(fmod(C.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return C.z * lerp(1.0, rgb, C.y);
}

// 色相
float3 Hue(float3 Src, float3 Dst)
{
	// 将目标图层颜色转换为 HSV
	Dst = RGB2HSV(Dst);
	// 将源图层的色相赋值给目标图层
	Dst.x = RGB2HSV(Src).x;
	// 将修改后的 HSV 颜色转换回 RGB
	return HSV2RGB(Dst);
}

// 饱和度
float3 Saturation(float3 Src, float3 Dst)
{
	Dst = RGB2HSV(Dst);
	Dst.y = RGB2HSV(Src).y;
	return HSV2RGB(Dst);
}

// 颜色混合（保持目标图层明暗效果）
float3 Color(float3 Src, float3 Dst)
{
	Src = RGB2HSV(Src);
	Src.z = RGB2HSV(Dst).z;
	return HSV2RGB(Src);
}

// 明度
float3 Luminosity(float3 Src, float3 Dst)
{
	// 加权系数 (0.3, 0.59, 0.11) 是基于人眼对 RGB 三个颜色的感知敏感度得出的
	// 目标图层明度
	float dLum = dot(Dst, float3(0.3, 0.59, 0.11));
	// 源图层明度
	float sLum = dot(Src, float3(0.3, 0.59, 0.11));
	float lum = sLum - dLum;
	// 应用到目标图层
	float3 C = Dst + lum;
	// 颜色最大值和最小值（用于限制颜色范围）
	float minC = min(min(C.x, C.y), C.z);
	float maxC = max(max(C.x, C.y), C.z);
	// 颜色校正，确保在[0, 1]之间
	if (minC < 0.0)
		return sLum + ((C - sLum) * sLum) / (sLum - minC);
	else if (maxC > 1.0)
		return sLum + ((C - sLum) * (1.0 - sLum)) / (maxC - sLum);
	else
		return C;
}

float3 OutPutMode(float4 Src, float4 Dst, float ID)
{
	if (ID == 0)
		return Normal(Src, Dst);
	if (ID == 1)
		return Alphablend(Src, Dst);
	if (ID == 2)
		return Darken(Src, Dst);
	if (ID == 3)
		return Multiply(Src, Dst);
	if (ID == 4)
		return ColorBurn(Src, Dst);
	if (ID == 5)
		return LinearBurn(Src, Dst);
	if (ID == 6)
		return DarkerColor(Src, Dst);
	if (ID == 7)
		return Lighten(Src, Dst);
	if (ID == 8)
		return Screen(Src, Dst);
	if (ID == 9)
		return ColorDodge(Src, Dst);
	if (ID == 10)
		return LinearDodge(Src, Dst);
	if (ID == 11)
		return LighterColor(Src, Dst);
	if (ID == 12)
		return Overlay(Src, Dst);
	if (ID == 13)
		return SoftLight(Src, Dst);
	if (ID == 14)
		return HardLight(Src, Dst);
	if (ID == 15)
		return VividLight(Src, Dst);
	if (ID == 16)
		return LinearLight(Src, Dst);
	if (ID == 17)
		return PinLight(Src, Dst);
	if (ID == 18)
		return HardMix(Src, Dst);
	if (ID == 19)
		return Difference(Src, Dst);
	if (ID == 20)
		return Exclusion(Src, Dst);
	if (ID == 21)
		return Subtract(Src, Dst);
	if (ID == 22)
		return Divide(Src, Dst);
	if (ID == 23)
		return Hue(Src, Dst);
	if (ID == 24)
		return Saturation(Src, Dst);
	if (ID == 25)
		return Color(Src, Dst);
	if (ID == 26)
		return Luminosity(Src, Dst);

	return float3(0.0, 0.0, 0.0);
}

#endif