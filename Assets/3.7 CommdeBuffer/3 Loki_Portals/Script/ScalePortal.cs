using UnityEngine;
using System.Collections;

public class ScalePortal : MonoBehaviour
{   
    // �����������׶δ�С
    public Vector3 phaseOriginalScale ;
    public Vector3 phaseWidthScale;
    public Vector3 phaseHeightScale;
    
    // Lerp�ٶ�
    public float phaseOriginalSpeed;
    public float phaseWidthSpeed;
    public float phaseHeightSpeed;

    // �����׶�
    private bool phaseOriginal  = true;
    private bool phaseWidth     = false;
    private bool phaseHeight    = false;

    private void Start()
    {
        // ��ʼ�����ű���
        transform.localScale = Vector3.zero;
    }

    void Update()
    {
        Appear();
    }

    void Appear()
    {
        if (phaseOriginal)
        {
            transform.localScale = Vector3.Lerp(transform.localScale, phaseOriginalScale, phaseOriginalSpeed * Time.deltaTime);

            // ���ŵ� ��Ŀ�������ľ��� <= 0.05 �������һ������
            if (Vector3.Distance(transform.localScale, phaseOriginalScale) <= 0.05f)
            {
                phaseOriginal = false;
                phaseWidth = true;
            }
        }

        if (phaseWidth)
        {
            transform.localScale = Vector3.Lerp(transform.localScale, phaseWidthScale, phaseWidthSpeed * Time.deltaTime);

            if (Vector3.Distance(transform.localScale, phaseWidthScale) <= 0.05f)
            {
                phaseWidth = false;
                phaseHeight = true;
            }
        }

        if (phaseHeight)
        {
            transform.localScale = Vector3.Lerp(transform.localScale, phaseHeightScale, phaseHeightSpeed * Time.deltaTime);

            if (Vector3.Distance(transform.localScale, phaseHeightScale) <= 0.05f)
            {
                phaseHeight = false;
            }
        }
    }
}
