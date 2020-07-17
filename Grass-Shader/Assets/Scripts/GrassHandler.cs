using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassHandler : MonoBehaviour
{
    Material grassMaterial;
    public GameObject windManagerObject;
    WindManager windManager;

    public bool findWindManagerInScene;
    // Start is called before the first frame update
    public bool grassIsFirstMaterial;
    void Start()
    {
        grassMaterial = GetComponent<Renderer>().sharedMaterials[grassIsFirstMaterial ? 0 : 1]; // *ASSUMES GRASS IS THE SECOND MATERIAL IF grassIsFirstMaterial IS FALSE
        if (findWindManagerInScene)
        {
            var windManagerGameObject = GameObject.FindGameObjectWithTag("WindManager");
            if (windManagerGameObject != null)
            {
                windManager = windManagerGameObject.GetComponent<WindManager>();
            }
        }
        else
        {
            windManager = windManagerObject.GetComponent<WindManager>();
        }
    }

    // Update is called once per frame
    public void Update()
    {
        grassMaterial.SetVector("_WindFrequency", windManager.GetWindDirectionVector());
    }
}
