using UnityEngine;

public class ObjMove : MonoBehaviour
{
    // ���������յ�
    public Vector3 pointA = new Vector3(-0.2f, 3.0f, 4.0f);
    public Vector3 pointB = new Vector3(-0.2f, 3.0f, -1.0f);
    public Vector3 pointC = new Vector3(-0.2f, 3.0f, 2.0f);

    // �ƶ��ٶ�
    public float speed = 1.0f;

    // ���ڿ��������ƶ��Ľ׶�
    private bool isMovingAtoB = true;
    private bool isMovingBToC = false;

    void Start()
    {
        // �������ʼλ������Ϊ���
        transform.position = pointA;
    }

    void Update()
    {
        // ��������ӵ�ǰλ���ƶ����յ�Ĳ���
        float step = speed * Time.deltaTime;

        if (isMovingAtoB)
        {
            transform.position = Vector3.MoveTowards(transform.position, pointB, step);

            // ������嵽��B����A�˶�
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