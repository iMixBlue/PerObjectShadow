using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class HeadTorwards : MonoBehaviour
{
    public Transform HeadBoneTransform;
    public Transform HeadForwardTransform;
    public Transform HeadRightTransform;

    private Renderer[] allRenderers;

    private int HeadForwardID = Shader.PropertyToID("_HeadForward");
    private int HeadRightID = Shader.PropertyToID("_HeadRight");

#if UNITY_EDITIOR
   void OnValidate()
   {
   LateUpdate();
   }
#endif

    private void Update()
    {
        if(allRenderers == null)
        {
            allRenderers = GetComponentsInChildren<Renderer>(true);
        }

        for (int i = 0; i<allRenderers.Length; i++)
        {
            Renderer r = allRenderers[i];
            foreach (Material mat in r.sharedMaterials)
            {
                if(mat.shader)
                {
                    // if(mat.shader.name == "Custom/iMixToonLitURP")
                    // {
                        mat.SetVector(HeadForwardID, HeadForwardTransform.position - HeadBoneTransform.position);
                        mat.SetVector(HeadRightID, HeadRightTransform.position - HeadBoneTransform.position);
                    // }
                }
            }
        }
    }
}
