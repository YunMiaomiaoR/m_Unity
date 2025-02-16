using UnityEngine;

public class ObjMove : MonoBehaviour
{
    // 定义起点和终点
    public Vector3 pointA = new Vector3(-0.2f, 3.0f, 4.0f);
    public Vector3 pointB = new Vector3(-0.2f, 3.0f, -1.0f);
    public Vector3 pointC = new Vector3(-0.2f, 3.0f, 2.0f);

    // 移动速度
    public float speed = 1.0f;

    // 用于控制物体移动的阶段
    private bool isMovingAtoB = true;
    private bool isMovingBToC = false;

    void Start()
    {
        // 将物体初始位置设置为起点
        transform.position = pointA;
    }

    void Update()
    {
        // 计算物体从当前位置移动到终点的步进
        float step = speed * Time.deltaTime;

        if (isMovingAtoB)
        {
            transform.position = Vector3.MoveTowards(transform.position, pointB, step);

            // 如果物体到达B，向A运动
            if (Vector3.Distance(transform.position, pointB) < 0.001f)
            {
                isMovingAtoB = false;
                isMovingBToC = true;
            }
        }

        if (isMovingBToC)
        {
            transform.position = Vector3.MoveTowards(transform.position, pointC, step);
            
            if (Vector3.Distance(transform.position, pointC) < 0.001f)
            {
                isMovingBToC = false;
            }
        }
    }
}