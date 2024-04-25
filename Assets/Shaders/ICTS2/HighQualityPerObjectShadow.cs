using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace iMix
{
    [ExecuteInEditMode]
    public class HighQualityPerObjectShadow : MonoBehaviour
    {
        // Start is called before the first frame update
        Bounds bounds = new Bounds();
        //可以升级为很多个transform
        public Transform shadowCaster;
        public Light mainLight;
        public float shadowClipDistance = 10;
        private Matrix4x4 viewMatrix, projMatrix;

        private List<Vector3> vertexPositions = new List<Vector3>();
        private List<MeshRenderer> vertexRenderer = new List<MeshRenderer>();
        private SkinnedMeshRenderer[] skinmeshes;
        private int boundsCount;

        void Start()
        {


            skinmeshes = shadowCaster.GetComponentsInChildren<SkinnedMeshRenderer>();

            Debug.Log(skinmeshes.Length + "  Length");

            for (int i = 0; i < skinmeshes.Length; i++)
            {

                CalculateAABB(boundsCount, skinmeshes[i]);
                boundsCount += 1;
            }

            float x = bounds.extents.x;                                       //范围这里是三维向量，分别取得X Y Z
            float y = bounds.extents.y;
            float z = bounds.extents.z;

            vertexPositions.Add(new Vector3(x, y, z));
            vertexPositions.Add(new Vector3(x, -y, z));
            vertexPositions.Add(new Vector3(x, y, -z));
            vertexPositions.Add(new Vector3(x, -y, -z));
            vertexPositions.Add(new Vector3(-x, y, z));
            vertexPositions.Add(new Vector3(-x, -y, z));
            vertexPositions.Add(new Vector3(-x, y, -z));
            vertexPositions.Add(new Vector3(-x, -y, -z));


            for (int i = 0; i < vertexPositions.Count; i++)
            {

                vertexRenderer.Add(GameObject.CreatePrimitive(PrimitiveType.Sphere).GetComponent<MeshRenderer>());

                vertexRenderer[i].transform.position = vertexPositions[i] + bounds.center;
                vertexRenderer[i].material.SetColor("_BaseColor", Color.red);
                vertexRenderer[i].transform.localScale = new Vector3(0.1f, 0.1f, 0.1f);
            }



        }

        // Update is called once per frame
        void Update()
        {

            // Debug.Log("ViewMatrix2:" + UniversalRenderPipeline.viewMatrix);
            UpdateAABB();

            fitToScene();



        }

        void CalculateAABB(int boundsCount, SkinnedMeshRenderer skinmeshRender)
        {
            if (boundsCount != 0)
            {

                bounds.Encapsulate(skinmeshRender.bounds);


            }
            else
            {
                bounds = skinmeshRender.bounds;

            }

            Debug.Log(skinmeshRender.name + " is being encapsulate");
            Debug.Log(boundsCount);
        }

        public void UpdateAABB()
        {
         

            int boundscount = 0;

            foreach (var skinmesh in skinmeshes)
            {
                //if(skinmesh.sharedMesh.name == "UpperBody")
                //{
                CalculateAABB(boundscount, skinmesh);
                boundscount += 1;
                // }

            }


            float x = bounds.extents.x;                                       //范围这里是三维向量，分别取得X Y Z
            float y = bounds.extents.y;
            float z = bounds.extents.z;



            vertexPositions[0] = (new Vector3(x, y, z));
            vertexPositions[1] = (new Vector3(x, -y, z));
            vertexPositions[2] = (new Vector3(x, y, -z));
            vertexPositions[3] = (new Vector3(x, -y, -z));
            vertexPositions[4] = (new Vector3(-x, y, z));
            vertexPositions[5] = (new Vector3(-x, -y, z));
            vertexPositions[6] = (new Vector3(-x, y, -z));
            vertexPositions[7] = (new Vector3(-x, -y, -z));


            for (int i = 0; i < vertexPositions.Count; i++)
            {

                //  vertexRenderer.Add(GameObject.CreatePrimitive(PrimitiveType.Sphere).GetComponent<MeshRenderer>());
                vertexRenderer[i].transform.position = vertexPositions[i] + bounds.center;
                vertexRenderer[i].material.SetColor("_BaseColor", Color.cyan);
                vertexRenderer[i].transform.localScale = new Vector3(0.1f, 0.1f, 0.1f);
                vertexPositions[i] = vertexRenderer[i].transform.position;
            }
        }
        public void fitToScene()
        {

            float xmin = float.MaxValue, xmax = float.MinValue;
            float ymin = float.MaxValue, ymax = float.MinValue;
            float zmin = float.MaxValue, zmax = float.MinValue;


            foreach (var vertex in vertexPositions)
            {

                Vector3 vertexLS = mainLight.transform.worldToLocalMatrix.MultiplyPoint(vertex);
                xmin = Mathf.Min(xmin, vertexLS.x);
                xmax = Mathf.Max(xmax, vertexLS.x);
                ymin = Mathf.Min(ymin, vertexLS.y);
                ymax = Mathf.Max(ymax, vertexLS.y);
                zmin = Mathf.Min(zmin, vertexLS.z);
                zmax = Mathf.Max(zmax, vertexLS.z);

            }

            viewMatrix = mainLight.transform.worldToLocalMatrix;


            if (SystemInfo.usesReversedZBuffer)
            {
                viewMatrix.m20 = -viewMatrix.m20;
                viewMatrix.m21 = -viewMatrix.m21;
                viewMatrix.m22 = -viewMatrix.m22;
                viewMatrix.m23 = -viewMatrix.m23;
            }


            UniversalRenderPipeline.viewMatrix = viewMatrix;
            

            zmax += shadowClipDistance * shadowCaster.localScale.x;

            Vector4 row0 = new Vector4(2 / (xmax - xmin), 0, 0, -(xmax + xmin) / (xmax - xmin));
            Vector4 row1 = new Vector4(0, 2 / (ymax - ymin), 0, -(ymax + ymin) / (ymax - ymin));
            Vector4 row2 = new Vector4(0, 0, -2 / (zmax - zmin), -(zmax + zmin) / (zmax - zmin));
            Vector4 row3 = new Vector4(0, 0, 0, 1);

            projMatrix.SetRow(0, row0);
            projMatrix.SetRow(1, row1);
            projMatrix.SetRow(2, row2);
            projMatrix.SetRow(3, row3);

            UniversalRenderPipeline.proMatrix = projMatrix;

        }

        public void OnDestroy()
        {
            //foreach (var sphere in vertexRenderer)
            //{
            //    vertexRenderer.Remove(sphere);
            //}
        }
    }
}


