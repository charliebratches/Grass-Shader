using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//this script is used for creating a radial bending effect for a grass shader. It inputs an array of positions to the shader, each of which are coordinates for the radial bend effect.
public class InteractionHolder : MonoBehaviour
{
    [SerializeField]

    //for bending grass, i.e. when the player walks thrrough
    public List<GameObject> bendObjects;
    Vector4[] bendPositions = new Vector4[100];

    //for cutting grass
    public List<GameObject> cutObjects;
    Vector4[] cutPositions = new Vector4[10000];

    public Material grassMaterial;

    // Update is called once per frame
    void Update()
    {

        for (int i = 0; i < bendObjects.Count; i++)
        {
            bendPositions[i] = bendObjects[i].transform.position;
        }

        for (int i = 0; i < cutObjects.Count; i++)
        {
            cutPositions[i] = cutObjects[i].transform.position;
        }

        grassMaterial.SetFloat("_PositionArray", bendObjects.Count);
        grassMaterial.SetVectorArray("_Positions", bendPositions);

        grassMaterial.SetFloat("_CutPositionArray", cutObjects.Count);
        grassMaterial.SetVectorArray("_CutPositions", cutPositions);

    }

    public void AddCutObject(GameObject go)
    {
        cutObjects.Add(go);

        for (int i = 0; i < cutObjects.Count; i++)
        {
            cutPositions[i] = cutObjects[i].transform.position;
        }

        grassMaterial.SetFloat("_CutPositionArray", cutObjects.Count);
        grassMaterial.SetVectorArray("_CutPositions", cutPositions);
    }
}
