//TODO ：https://zhuanlan.zhihu.com/p/351390737
//结合这个就能做了，新增render data以及forward renderer用于人物头顶的正交相机

// using UnityEngine;
// using UnityEngine.Rendering;
// using UnityEngine.Rendering.Universal;
// using System.Collections.Generic;
// using System.Collections;
// using System;
// using UnityEditor;
// using Unity.IO.LowLevel.Unsafe;

// public class HighQualityCharacterShadowFeature : ScriptableRendererFeature
// {
//     class HighQualityCharacterShadowPass : ScriptableRenderPass
//     {
//         public int HighQualityHeroLayer = 9;
//         public GameObject directionLightObj = GameObject.Find("Directional Light");
//         private Bounds bounds = new Bounds();
//         private List<Vector3> boundsVertexList = new List<Vector3>();
//         public Camera lightCam = null;
//         public float CameraSize = 1;
//         private Shader captureDepthShader = null;
//         private RenderTextureDescriptor descriptor;
//         public RTHandle rtHandle;
//         private int renderTextureWidth = 1024;
//         private int renderTextureHeight = 1024;

//         private Light directionalLight = null;
//         private Matrix4x4 m_LightVP;
//         public HighQualityCharacterShadowPass()
//         {
//             descriptor = new RenderTextureDescriptor(renderTextureWidth, renderTextureHeight, RenderTextureFormat.Depth, 24);

//         }
//         // This method is called before executing the render pass.
//         // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
//         // When empty this render pass will render to the active camera render target.
//         // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
//         // The render pipeline will ensure target setup and clearing happens in a performant manner.
//         public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
//         {
//             captureDepthShader = Shader.Find("HighQualityHeroShadows/capture depth");
//             SkinnedMeshRenderer[] skinnedMeshRenderers = Resources.FindObjectsOfTypeAll(typeof(SkinnedMeshRenderer)) as SkinnedMeshRenderer[];
//             foreach (var renderer in skinnedMeshRenderers)
//             {
//                 if (renderer.gameObject.activeInHierarchy && renderer.gameObject.layer == HighQualityHeroLayer && renderer != null)
//                 {
//                     bounds.Encapsulate(renderer.bounds);
//                 }
//             }
//             float x = bounds.extents.x;
//             float y = bounds.extents.y;
//             float z = bounds.extents.z;
//             boundsVertexList.Add(new Vector3(x, y, z) + bounds.center);
//             boundsVertexList.Add(new Vector3(x, -y, z) + bounds.center);
//             boundsVertexList.Add(new Vector3(x, y, -z) + bounds.center);
//             boundsVertexList.Add(new Vector3(x, -y, -z) + bounds.center);
//             boundsVertexList.Add(new Vector3(-x, y, z) + bounds.center);
//             boundsVertexList.Add(new Vector3(-x, -y, z) + bounds.center);
//             boundsVertexList.Add(new Vector3(-x, y, -z) + bounds.center);
//             boundsVertexList.Add(new Vector3(-x, -y, -z) + bounds.center);

//             directionalLight = directionLightObj.GetComponent<Light>();
//             RenderingUtils.ReAllocateIfNeeded(ref rtHandle, descriptor);
            
            
//             ConfigureTarget(rtHandle); // == set render target step1
//             ConfigureClear(ClearFlag.All, Color.clear); // == set render target step2

//             Shader.SetGlobalTexture("_ShadowDepthTex", rtHandle);
//             if (lightCam == null)
//             {
//                 lightCam = InitLightCam(directionLightObj, rtHandle, cmd);
//             }  
//         }
//         //Step one, create light camera , and set culling layer.
//         public Camera InitLightCam(GameObject parentObj, RenderTexture rt, CommandBuffer cmd)
//         {
//             Debug.Log(111);
//             if (lightCam == null)
//             {
//                 GameObject lightCamObj = new GameObject("DepthCamera");
//                 lightCam = lightCamObj.AddComponent<Camera>();
//                 lightCamObj.transform.SetParent(parentObj.transform, false);

//                 lightCam.orthographic = true;
//                 lightCam.backgroundColor = Color.black;
//                 lightCam.clearFlags = CameraClearFlags.Color;
//                 lightCam.targetTexture = rt;
//                 lightCam.cullingMask = 1 << HighQualityHeroLayer;

//                 //     if(cmd == null){
//                 //     cmd = new CommandBuffer();
//                 //     cmd.name = "SetViewPort";
//                 // }
//                 // lightCam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmd);
//                 cmd.SetViewport(new Rect(1, 1, renderTextureWidth - 2, renderTextureHeight - 2)); //prevent 阴影拉扯
//             }
//             return lightCam;
//         }

//         // Here you can implement the rendering logic.
//         // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
//         // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
//         // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
//         public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
//         {
//             // Shader.EnableKeyword("_HIGH_QUALITY_SHADOW_REVEIVE");
//             CommandBuffer cmd = CommandBufferPool.Get();

//             SkinnedMeshRenderer[] skinnedMeshRenderers = Resources.FindObjectsOfTypeAll(typeof(SkinnedMeshRenderer)) as SkinnedMeshRenderer[];

//             bounds.size = Vector3.zero;
//             foreach (var renderer in skinnedMeshRenderers)
//             {
//                 if (renderer.gameObject.activeInHierarchy && renderer.gameObject.layer == HighQualityHeroLayer && renderer != null)
//                 {
//                     bounds.Encapsulate(renderer.bounds);
//                 }
//             }
//             float x = bounds.extents.x;
//             float y = bounds.extents.y;
//             float z = bounds.extents.z;
//             boundsVertexList[0] = (new Vector3(x, y, z) + bounds.center);
//             boundsVertexList[1] = (new Vector3(x, -y, z) + bounds.center);
//             boundsVertexList[2] = (new Vector3(x, y, -z) + bounds.center);
//             boundsVertexList[3] = (new Vector3(x, -y, -z) + bounds.center);
//             boundsVertexList[4] = (new Vector3(-x, y, z) + bounds.center);
//             boundsVertexList[5] = (new Vector3(-x, -y, z) + bounds.center);
//             boundsVertexList[6] = (new Vector3(-x, y, -z) + bounds.center);
//             boundsVertexList[7] = (new Vector3(-x, -y, -z) + bounds.center);

//             ConfigureTarget(rtHandle);
//             ConfigureClear(ClearFlag.All, Color.clear);

//             // UpdateLightCam(lightCam, directionalLight, bounds);

//             UpdateShaderVP();

//             context.ExecuteCommandBuffer(cmd);
//             CommandBufferPool.Release(cmd);

//             DrawingSettings drawSettings = CreateDrawingSettings(  // == lightCam.RenderWithShader(captureDepthShader, "RenderType");
//         new ShaderTagId("RenderType"),
//         ref renderingData,
//         SortingCriteria.CommonOpaque
//     );

//             drawSettings.overrideMaterial = new Material(captureDepthShader); // Use the shader
//             FilteringSettings filterSettings = new FilteringSettings(RenderQueueRange.all, 1 << HighQualityHeroLayer);

//             context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filterSettings);
//         }

//         // Cleanup any allocated resources that were created during the execution of this render pass.
//         public override void OnCameraCleanup(CommandBuffer cmd)
//         {
//         }

//         void UpdateLightCam(Camera lightCam, Light light, Bounds bounds)
//         {
//             Vector3 pos = new Vector3();
//             Vector3 lightDir = light.transform.forward;
//             Vector3 maxDistance = new Vector3(bounds.extents.x, bounds.extents.y, bounds.extents.z);
//             float length = maxDistance.magnitude;
//             pos = bounds.center - lightDir * length;
//             lightCam.transform.position = pos;


//             Vector2 xMinMax = new Vector2(float.MinValue, float.MaxValue);
//             Vector2 yMinMax = new Vector2(float.MinValue, float.MaxValue);
//             Vector2 zMinMax = new Vector2(float.MinValue, float.MaxValue);

//             Matrix4x4 world2LightMatrix = lightCam.transform.worldToLocalMatrix;
//             for (int i = 0; i < boundsVertexList.Count; i++)
//             {
//                 Vector4 pointLS = world2LightMatrix * boundsVertexList[i];

//                 if (pointLS.x > xMinMax.x)
//                     xMinMax.x = pointLS.x;
//                 if (pointLS.x < xMinMax.y)
//                     xMinMax.y = pointLS.x;

//                 if (pointLS.y > yMinMax.x)
//                     yMinMax.x = pointLS.y;
//                 if (pointLS.y < yMinMax.y)
//                     yMinMax.y = pointLS.y;

//                 if (pointLS.z > zMinMax.x)
//                     zMinMax.x = pointLS.z;
//                 if (pointLS.z < zMinMax.y)
//                     zMinMax.y = pointLS.z;
//             }

//             lightCam.nearClipPlane = 0;
//             lightCam.farClipPlane = zMinMax.x - zMinMax.y;
//             lightCam.orthographicSize = CameraSize * (yMinMax.x - yMinMax.y) / 2;//宽高中的高度
//             lightCam.aspect = (xMinMax.x - xMinMax.y) / (yMinMax.x - yMinMax.y);
//         }

//         void UpdateShaderVP()
//         {
//             Matrix4x4 world2View = lightCam.worldToCameraMatrix;
//             Matrix4x4 projection = GL.GetGPUProjectionMatrix(lightCam.projectionMatrix, false);
//             m_LightVP = projection * world2View;

//             Shader.SetGlobalMatrix("_LightVP", m_LightVP);
//         }
//     }

//     HighQualityCharacterShadowPass m_HighQualityCharacterShadowPass;
//     public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;

//     /// <inheritdoc/>
//     public override void Create()
//     {
//         m_HighQualityCharacterShadowPass = new HighQualityCharacterShadowPass();

//         // Configures where the render pass should be injected.
//         m_HighQualityCharacterShadowPass.renderPassEvent = renderPassEvent;
//     }

//     // Here you can inject one or multiple render passes in the renderer.
//     // This method is called when setting up the renderer once per-camera.
//     public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
//     {
//         renderer.EnqueuePass(m_HighQualityCharacterShadowPass);
//     }
// }


