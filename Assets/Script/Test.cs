using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;

public class Test : MonoBehaviour
{
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
    public int[][] indicesDir;
    private int lastIndex;
    private int[] originIndices;

    bool isReverse;
    Mesh mesh;
    Vector3 centerPt;
    void Awake()
    {
        if (transform.childCount > 0)
        {
            centerPt = transform.GetChild(0).localPosition;
        }
        else
        {
            centerPt = Vector3.zero;
            UnityEngine.Debug.LogWarning("The game object has no child objects. Using default center point (0, 0, 0).");
        }

        mesh = GetComponent<MeshFilter>().mesh;
        var indices = originIndices = mesh.GetIndices(0);
        var vertices = mesh.vertices;
        for (int i = 0; i < vertices.Length; i++)
        {

            vertices[i] = transform.localToWorldMatrix.MultiplyPoint(vertices[i]);

        }

        indicesDir = new int[4][];

        calculateDirIndices(out indicesDir[0], out indicesDir[2], indices, vertices, 0);
        calculateDirIndices(out indicesDir[1], out indicesDir[3], indices, vertices, 2);

    }

    private void calculateDirIndices(out int[] v1, out int[] v2, int[] indices, Vector3[] vertices, int dirCheck)
    {

        List<IndiceData> orderList = new List<IndiceData>();
        for (int i = 0; i < indices.Length; i += 3)
        {
            IndiceData data = new IndiceData();
            data.a = indices[i];
            data.b = indices[i + 1];
            data.c = indices[i + 2];
            data.score = (vertices[data.a][dirCheck] + vertices[data.b][dirCheck] + vertices[data.c][dirCheck]);

            orderList.Add(data);
        }
        orderList.Sort();
        v1 = new int[indices.Length];
        for (int i = 0; i < indices.Length; i += 3)
        {
            v1[i] = orderList[i / 3].a;
            v1[i + 1] = orderList[i / 3].b;
            v1[i + 2] = orderList[i / 3].c;
        }
        orderList.Reverse();
        v2 = new int[indices.Length];
        for (int i = 0; i < indices.Length; i += 3)
        {
            v2[i] = orderList[i / 3].a;
            v2[i + 1] = orderList[i / 3].b;
            v2[i + 2] = orderList[i / 3].c;
        }

    }
    private void OnDisable()
    {
        mesh.SetIndices(originIndices, MeshTopology.Triangles, 0);
        lastIndex = -1;
    }

    void Update()
    {
        if (Camera.main == null) return;
        var checkPos = Vector3.Normalize(Camera.main.transform.position - transform.localToWorldMatrix.MultiplyPoint3x4(centerPt));
        var dotX = Vector3.Dot(transform.right, checkPos);
        var dotY = Vector3.Dot(transform.up, checkPos);
        //  print(dotX + "," + dotY);

        var index = 0;
        if (Mathf.Abs(dotY) < Mathf.Abs(dotX))
        {
            index = dotX > 0 ? 2 : 0;

        }
        else
        {
            index = dotY > 0 ? 1 : 3;

        }

        if (lastIndex != index)
        {
            mesh.SetIndices(indicesDir[index], MeshTopology.Triangles, 0);
            lastIndex = index;
            print(index);
        }


    }
}