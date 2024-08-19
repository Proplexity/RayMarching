using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Scripting;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RayMarchCamera : SceneViewFilter
{
    [SerializeField] 
    private Shader _shader;

    public Material _rayMarchMaterial
    {
        get
        {
            if (!_rayMarchMat && _shader)
            {
                _rayMarchMat = new Material(_shader);
                _rayMarchMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return _rayMarchMat;
        }
    }

    private Material _rayMarchMat;

    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }
            return _cam;
        }
    }

    private Camera _cam;

    public Transform _directionalLight;

    public float _maxDistance;
    public Color _mainColor;
    public Vector3 modInterval;
    public Vector2 _shadowDistance;
    public float _shadowIntensity;
    public Color _lightCol;
    public float _lightIntensity;
    [Range(1, 128)] public float _shadowPenumbra;


    [Header("Shapes")]  
    public Vector4 _sphere1;
    public Vector4 _box1;
    public Vector4 _sdBoxFrame;
    public float _boxFrameModifier;
    public Vector4 _rBox1;
    public float _rBoxModifier;
    public Vector4 _sdCone;
    public Vector3 _sdConeModifiers;
    public Vector4 _sdTorus;
    public Vector2 _sdTorusModifier;
    public Vector4 _sdPlane;
    public float _planeModifier;
    public float _boxSphereSmooth;
    public float _sphereIntersectionSmooth;
    public Vector4 _sphere2;
    







    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!_rayMarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        _rayMarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        _rayMarchMaterial.SetMatrix("_CamToWorld", _camera.cameraToWorldMatrix);
        _rayMarchMaterial.SetFloat("_maxDistance", _maxDistance);
        _rayMarchMaterial.SetVector("_sphere1", _sphere1);
        _rayMarchMaterial.SetVector("_box1", _box1);
        _rayMarchMaterial.SetVector("_directionalLight", _directionalLight ? _directionalLight.forward : Vector3.down);
        _rayMarchMaterial.SetColor("_mainColor", _mainColor);
        _rayMarchMaterial.SetVector("_modInterval", modInterval);
        _rayMarchMaterial.SetVector("_rBox1", _rBox1);
        _rayMarchMaterial.SetFloat("_rBoxModifier", _rBoxModifier);
        _rayMarchMaterial.SetVector("_sdBoxFrame", _sdBoxFrame);
        _rayMarchMaterial.SetFloat("_boxFraeModifier", _boxFrameModifier);
        _rayMarchMaterial.SetVector("_sdConeModifiers", _sdConeModifiers);
        _rayMarchMaterial.SetVector("_sdCone", _sdCone); 
        _rayMarchMaterial.SetVector("_sdTorus", _sdTorus); 
        _rayMarchMaterial.SetVector("_sdTorusModifier", _sdTorusModifier);
        _rayMarchMaterial.SetVector("_sdPlane", _sdPlane);
        _rayMarchMaterial.SetFloat("_planeModifier", _planeModifier);
        _rayMarchMaterial.SetFloat("_boxSphereSmooth", _boxSphereSmooth);
        _rayMarchMaterial.SetFloat("_sphereIntersectionSmooth", _sphereIntersectionSmooth);
        _rayMarchMaterial.SetVector("_sphere2", _sphere2);
        _rayMarchMaterial.SetVector("_shadowDistance", _shadowDistance);
        _rayMarchMaterial.SetFloat("_shadowIntensity", _shadowIntensity);
        _rayMarchMaterial.SetColor("_lightCol", _lightCol);
        _rayMarchMaterial.SetFloat("_lightIntensity", _lightIntensity);
        _rayMarchMaterial.SetFloat("_shadowPenumbra", _shadowPenumbra);

        RenderTexture.active = destination;
        _rayMarchMaterial.SetTexture("_MainTex", source);
        GL.PushMatrix();
        GL.LoadOrtho();
        _rayMarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 2.0f);
        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 3.0f);
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();

    }


    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);



        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BL);
        frustum.SetRow(3, BR);

        return frustum;
    }





}
