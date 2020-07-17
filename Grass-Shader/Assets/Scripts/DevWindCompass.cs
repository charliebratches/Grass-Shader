using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DevWindCompass : MonoBehaviour
{
    public GameObject windManagerObject;
    WindManager windManager;

    // Start is called before the first frame update
    void Start()
    {
        windManager = windManagerObject.GetComponent<WindManager>();
    }

    // Update is called once per frame
    void Update()
    {
        //windManager.windDirection = -transform.rotation.eulerAngles.y * Mathf.Deg2Rad;
        var windDirectionEuler = windManager.GetWindDirectionEuler();
        transform.rotation = Quaternion.Euler(transform.rotation.eulerAngles.x, windDirectionEuler, transform.rotation.eulerAngles.z);
        //gameObject.transform.eulerAngles = new Vector3(
        //    transform.eulerAngles.x,
        //    (windManager.windDirection*180/Mathf.PI),
        //    transform.eulerAngles.z
        //);
    }
}
