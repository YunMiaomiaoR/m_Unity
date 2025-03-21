using System;
using System.Collections.Generic;
using UnityEngine;

public class AlphaBakedOrder : MonoBehaviour
{
    /// <summary>
    /// 内部类IndiceData,用于存储三角形的三个顶点索引（a、b、c）以及该三角形的得分（score）
    /// 该类实现了IComparable<IndiceData>接口，重写了CompareTo方法，用于比较两个IndiceData对象的得分，实现降序排序。
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

    public int[][] indicesDir;  //二维数组，用于存储不同方向的三角形索引顺序
    private int lastIndex;      //记录上一次使用的索引方向
    private int[] originIndices;//存储原始三角形索引
    Mesh mesh;
    Vector3 centerPt;

    void Awake()
    {
        // 判断是否有子对象
        if (transform.childCount > 0)
        {
            centerPt = transform.GetChild(0).localPosition; // 使用局部坐标
        }
        else
        {
            centerPt = transform.localPosition; // 直接使用自身局部坐标
            Debug.LogWarning("The game object has no child objects. Using default local position.");
        }

        // 获取当前游戏对象的网格组件、其三角形索引、顶点。
        mesh = GetComponent<MeshFilter>().mesh;
        var indices = originIndices = mesh.GetIndices(0);
        var vertices = mesh.vertices;

        // 将所有顶点从局部坐标转换为世界坐标。
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = transform.localToWorldMatrix.MultiplyPoint(vertices[i]);
        }

        // 初始化indicesDir数组, 这里以4个方向为例
        indicesDir = new int[4][];
        // 计算基于 X 轴（左右）和 Y 轴（上下）的排序索引
        calculateDirIndices(out indicesDir[0], out indicesDir[2], indices, vertices, 0);
        calculateDirIndices(out indicesDir[1], out indicesDir[3], indices, vertices, 2);
    }

    // 计算指定方向的正序和逆序三角形索引
    private void calculateDirIndices(out int[] v1, out int[] v2, int[] indices, Vector3[] vertices, int dirCheck)
    {
        // 遍历所有三角形，为每个三角形创建一个IndiceData对象，计算其得分（三个顶点在指定方向上的坐标之和），并添加到orderList中
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
        // 对orderList降序排序，生成新的三角形索引，存储在v1中。
        orderlist.Sort();
        v1 = new int[indices.Length];
        for (int i = 0; i < indices.Length; i += 3)
        {
            v1[i] = orderlist[i / 3].a;
            v1[i + 1] = orderlist[i / 3].b;
            v1[i + 2] = orderlist[i / 3].c;
        }
        // 反转orderList，得到逆序的三角形索引，存储在v2中。
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
        // 将网格的三角形索引恢复为原始索引, 将lastIndex重置为 -1。
        mesh.SetIndices(originIndices, MeshTopology.Triangles, 0);
        lastIndex = -1;
    }

    private void Update()
    {
        if (Camera.main == null) return;
        // 计算相机相对于物体中心点的归一化方向向量。
        var checkPos = Vector3.Normalize(Camera.main.transform.position - transform.localToWorldMatrix.MultiplyPoint3x4(centerPt));
        // 计算 checkPos 在局部坐标系 X/Y 轴上的投影（点乘）
        var dotX = Vector3.Dot(transform.right, checkPos);
        var dotY = Vector3.Dot(transform.up, checkPos);

        // 如果 dotX 绝对值大于 dotY，则说明摄像机主要在水平方向：dotX > 0 时选择 indicesDir[2]，否则选择 indicesDir[0]
        // 否则，摄像机主要在垂直方向：dotY > 0 时选择 indicesDir[1]，否则选择 indicesDir[3]
        var index = 0;
        if (Mathf.Abs(dotY) < Mathf.Abs(dotX))
        {
            index = dotX > 0 ? 2 : 0;
        }
        else
        {
            index = dotY > 0 ? 1 : 3;
        }

        // 如果当前选择的索引方向与上一次不同，则更新网格的三角形索引，并记录当前索引方向。
        if (lastIndex != index)
        {
            mesh.SetIndices(indicesDir[index], MeshTopology.Triangles, 0);
            lastIndex = index;
            print(index);
        }
    }
}
