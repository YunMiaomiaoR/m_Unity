using UnityEngine;
using System.Collections;

public class ScalePortal : MonoBehaviour
{   
    // 传送门三个阶段大小
    public Vector3 phaseOriginalScale ;
    public Vector3 phaseWidthScale;
    public Vector3 phaseHeightScale;
    
    // Lerp速度
    public float phaseOriginalSpeed;
    public float phaseWidthSpeed;
    public float phaseHeightSpeed;

    // 三个阶段
    private bool phaseOriginal  = true;
    private bool phaseWidth     = false;
    private bool phaseHeight    = false;

    private void Start()
    {
        // 初始化缩放比例
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

            // 缩放到 和目标比例间的距离 <= 0.05 则进行下一段缩放
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
