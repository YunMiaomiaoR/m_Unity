// ͷ�ļ���������ȷ���ļ����ᱻ�ظ������������ظ�����Ĵ���
#ifndef PSBLENDMODE_INCLUDE
#define PSBLENDMODE_INCLUDE

// ����
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

// Darken Blending Mode Category ���Ӻ�����ͼƬ�䰵
// �䰵
float3 Darken(float3 Src, float3 Dst)
{
	return min(Src, Dst);
}

// ��Ƭ����
float3 Multiply(float3 Src, float3 Dst)
{
	return Src * Dst;
}

// ��ɫ����
float3 ColorBurn(float3 Src, float3 Dst)
{
	return 1.0 - (1.0 -Dst) / Src;
}

// ���Լ���
float3 LinearBurn(float3 Src, float3 Dst)
{
	return Src + Dst - 1.0;
}

// ��ɫ��rgb��ɫ�����ܺ͵ıȽ�
float3 DarkerColor(float3 Src, float3 Dst)
{
	return (Src.x + Src.y + Src.z < Dst.x + Dst.y + Dst.z) ? Src : Dst;
}

// Lighten Blending Mode Category ���Ӻ�����ͼƬ����
// ����
float3 Lighten(float3 Src, float3 Dst)
{
	return max(Src, Dst);
}

// ��ɫ
float3 Screen(float3 Src, float3 Dst)
{
	return Src + Dst - Src * Dst;
}

// ��ɫ����
float3 ColorDodge(float3 Src, float3 Dst)
{
	return Dst / (1.0 - Src);
}

// ���Լ���
float3 LinearDodge(float3 Src, float3 Dst)
{
	return Src + Dst;
}

// ǳɫ
float3 LighterColor(float3 Src, float3 Dst)
{
	return (Src.x + Src.y + Src.z > Dst.x + Dst.y + Dst.z) ? Src : Dst;
}

// Contrast Blending Mode Category 
// ���ӣ�����Dstͼ��
float overlay(float Src, float Dst)
{
	// Dst < 0.5, ����Ƭ����Ч����ʹͼ��䰵
	// Dst >= 0.5, ����ɫЧ����ʹͼ�����
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

// ���
float softLight(float Src, float Dst)
{
	// Src < 0.5 ���ϰ�������Ŀ���������ȣ�������ӰЧ��
	// Src = 0.5 �� Dst < 0.25 : Ŀ�����طǳ�����ǿ���ǳ���������
	// Src >= 0.5 �� Dst >= 0.25: Ŀ�����ؽ���������Ŀ�����ص�ƽ��������������
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

// ǿ�⣨����Srcͼ��
float hardLight(float Src, float Dst)
{
	// Src < 0.5, ���ؽϰ�����Ƭ���ף�������Ӱ������С��Src�����Dst��
	// Src >= 0.5, ���ؽ�������ɫ��ʹ�������ָ�Ϊͻ��
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

// ����
float vividLight(float Src, float Dst)
{
	// Src < 0.5, ����
	// Src >= 0.5, ����
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

// ���Թ�
float3 LinearLight(float Src, float Dst)
{
	return 2.0 * Src + Dst - 1.0;
}

// ���
float pinLight(float Src, float Dst)
{
	// 2.0 * Src - 1.0 > Dst Դ���ؽ�����ֱ���滻ΪԴ���� ����ֵ
	// Src < 0.5 * Dst Դ���ؽϰ����Ŵ�Srcʹ����������
	// �������������� ���� Դ�������Ȳ����ԣ�����Ŀ������ԭʼֵ
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

// ʵɫ���
float3 HardMix(float3 Src, float3 Dst)
{
	return floor(Src + Dst);
}

// Inversion Blending Mode Category 
// ��ֵ
float3 Difference(float3 Src, float3 Dst)
{
	return abs(Dst - Src);
}

// �ų�
float3 Exclusion(float3 Src, float3 Dst)
{
	return Src + Dst - 2.0 * Src * Dst;
}

// ��ȥ
float3 Subtract(float3 Src, float3 Dst)
{
	return Src - Dst;
}

// ����
float3 Divide(float3 Src, float3 Dst)
{
	return Src / Dst;
}

// Component Blending Mode Category 
// RGBתHSV
float3 RGB2HSV(float3 C)
{
	// K�ǳ�����������ɫ֮��ıȽϺ�λ��ӳ��
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	// �Ƚ� C.b �� C.g�����ϴ�ֵ�ƶ�����һλ
	float4 p = lerp(float4(C.bg, K.wz), float4(C.gb, K.xy), step(C.b, C.g));
	// ��һ���Ƚϲ������ֵ�ŵ���һλ
	float4 q = lerp(float4(p.xyz, C.r), float4(C.r, p.xyz), step(p.x, C.r));
	// �������ֵ����Сֵ֮��Ĳ���
	float Dst = q.x - min(q.w, q.y);
	// ��Сֵ����1.0 �� 10^(-10)(��ѧ�����������пո�)
	float e = 1.0e-10;
	// ɫ��, ���Ͷ�, ����
	return float3(abs(q.z + (q.w - q.y) / (6.0 * Dst + e)), Dst / (q.x + e), q.x);
}

// HSVתRGB
float3 HSV2RGB(float3 C)
{
	float3 rgb;
	// fmod()���㸡������ȷ��ɫ��ֵ��0-6֮��ѭ����clamp()��ֵ������[0.0, 1.0]֮��
	rgb = clamp(abs(fmod(C.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return C.z * lerp(1.0, rgb, C.y);
}

// ɫ��
float3 Hue(float3 Src, float3 Dst)
{
	// ��Ŀ��ͼ����ɫת��Ϊ HSV
	Dst = RGB2HSV(Dst);
	// ��Դͼ���ɫ�ำֵ��Ŀ��ͼ��
	Dst.x = RGB2HSV(Src).x;
	// ���޸ĺ�� HSV ��ɫת���� RGB
	return HSV2RGB(Dst);
}

// ���Ͷ�
float3 Saturation(float3 Src, float3 Dst)
{
	Dst = RGB2HSV(Dst);
	Dst.y = RGB2HSV(Src).y;
	return HSV2RGB(Dst);
}

// ��ɫ��ϣ�����Ŀ��ͼ������Ч����
float3 Color(float3 Src, float3 Dst)
{
	Src = RGB2HSV(Src);
	Src.z = RGB2HSV(Dst).z;
	return HSV2RGB(Src);
}

// ����
float3 Luminosity(float3 Src, float3 Dst)
{
	// ��Ȩϵ�� (0.3, 0.59, 0.11) �ǻ������۶� RGB ������ɫ�ĸ�֪���жȵó���
	// Ŀ��ͼ������
	float dLum = dot(Dst, float3(0.3, 0.59, 0.11));
	// Դͼ������
	float sLum = dot(Src, float3(0.3, 0.59, 0.11));
	float lum = sLum - dLum;
	// Ӧ�õ�Ŀ��ͼ��
	float3 C = Dst + lum;
	// ��ɫ���ֵ����Сֵ������������ɫ��Χ��
	float minC = min(min(C.x, C.y), C.z);
	float maxC = max(max(C.x, C.y), C.z);
	// ��ɫУ����ȷ����[0, 1]֮��
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