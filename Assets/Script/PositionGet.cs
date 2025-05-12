using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PositionGet : MonoBehaviour
{
    public GameObject obj;
    private Material material;
    // Start is called before the first frame update
    void Start()
    {
        material = obj.GetComponent<MeshRenderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        material.SetVector("_ObjectCenter", transform.position);
    }
}