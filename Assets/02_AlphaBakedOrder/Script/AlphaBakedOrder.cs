using System;
using System.Collections.Generic;
using UnityEngine;

public class AlphaBakedOrder : MonoBehaviour
{
    /// <summary>
    /// �ڲ���IndiceData,���ڴ洢�����ε���������������a��b��c���Լ��������εĵ÷֣�score��
    /// ����ʵ����IComparable<IndiceData>�ӿڣ���д��CompareTo���������ڱȽ�����IndiceData����ĵ÷֣�ʵ�ֽ�������
    /// </summary>
    class IndiceData : IComparable<IndiceData>
    {
        public int a;
        public int b;
        public int c;
        public float score;
        public int CompareTo(IndiceData other)
        {
            return (int)((other.score - score) * 10000);
        }
    }

    public int[][] indicesDir;  //��ά���飬���ڴ洢��ͬ���������������˳��
    private int lastIndex;      //��¼��һ��ʹ�õ���������
    private int[] originIndices;//�洢ԭʼ����������
    Mesh mesh;
    Vector3 centerPt;

    void Awake()
    {
        // �ж��Ƿ����Ӷ���
        if (transform.childCount > 0)
        {
            centerPt = transform.GetChild(0).localPosition; // ʹ�þֲ�����
        }
        else
        {
            centerPt = transform.localPosition; // ֱ��ʹ������ֲ�����
            Debug.LogWarning("The game object has no child objects. Using default local position.");
        }

        // ��ȡ��ǰ��Ϸ�������������������������������㡣
        mesh = GetComponent<MeshFilter>().mesh;
        var indices = originIndices = mesh.GetIndices(0);
        var vertices = mesh.vertices;

        // �����ж���Ӿֲ�����ת��Ϊ�������ꡣ
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = transform.localToWorldMatrix.MultiplyPoint(vertices[i]);
        }

        // ��ʼ��indicesDir����, ������4������Ϊ��
        indicesDir = new int[4][];
        // ������� X �ᣨ���ң��� Y �ᣨ���£�����������
        calculateDirIndices(out indicesDir[0], out indicesDir[2], indices, vertices, 0);
        calculateDirIndices(out indicesDir[1], out indicesDir[3], indices, vertices, 2);
    }

    // ����ָ��������������������������
    private void calculateDirIndices(out int[] v1, out int[] v2, int[] indices, Vector3[] vertices, int dirCheck)
    {
        // �������������Σ�Ϊÿ�������δ���һ��IndiceData���󣬼�����÷֣�����������ָ�������ϵ�����֮�ͣ�������ӵ�orderList��
        List<IndiceData> orderlist = new List<IndiceData>();
        for (int i = 0; i < indices.Length; i += 3)
        {
            IndiceData data = new IndiceData();
            data.a = indices[i];
            data.b = indices[i + 1];
            data.c = indices[i + 2];
            data.score = (vertices[data.a][dirCheck] + vertices[data.b][dirCheck] + vertices[data.c][dirCheck]);

            orderlist.Add(data);
        }
        // ��orderList�������������µ��������������洢��v1�С�
        orderlist.Sort();
        v1 = new int[indices.Length];
        for (int i = 0; i < indices.Length; i += 3)
        {
            v1[i] = orderlist[i / 3].a;
            v1[i + 1] = orderlist[i / 3].b;
            v1[i + 2] = orderlist[i / 3].c;
        }
        // ��תorderList���õ�������������������洢��v2�С�
        orderlist.Reverse();
        v2 = new int[indices.Length];
        for (int i = 0; i < indices.Length; i += 3)
        {
            v2[i] = orderlist[i / 3].a;
            v2[i + 1] = orderlist[i / 3].b;
            v2[i + 2] = orderlist[i / 3].c;
        }
    }

    private void OnDisable()
    {
        // ������������������ָ�Ϊԭʼ����, ��lastIndex����Ϊ -1��
        mesh.SetIndices(originIndices, MeshTopology.Triangles, 0);
        lastIndex = -1;
    }

    private void Update()
    {
        if (Camera.main == null) return;
        // �������������������ĵ�Ĺ�һ������������
        var checkPos = Vector3.Normalize(Camera.main.transform.position - transform.localToWorldMatrix.MultiplyPoint3x4(centerPt));
        // ���� checkPos �ھֲ�����ϵ X/Y ���ϵ�ͶӰ����ˣ�
        var dotX = Vector3.Dot(transform.right, checkPos);
        var dotY = Vector3.Dot(transform.up, checkPos);

        // ��� dotX ����ֵ���� dotY����˵���������Ҫ��ˮƽ����dotX > 0 ʱѡ�� indicesDir[2]������ѡ�� indicesDir[0]
        // �����������Ҫ�ڴ�ֱ����dotY > 0 ʱѡ�� indicesDir[1]������ѡ�� indicesDir[3]
        var index = 0;
        if (Mathf.Abs(dotY) < Mathf.Abs(dotX))
        {
            index = dotX > 0 ? 2 : 0;
        }
        else
        {
            index = dotY > 0 ? 1 : 3;
        }

        // �����ǰѡ���������������һ�β�ͬ����������������������������¼��ǰ��������
        if (lastIndex != index)
        {
            mesh.SetIndices(indicesDir[index], MeshTopology.Triangles, 0);
            lastIndex = index;
            print(index);
        }
    }
}
