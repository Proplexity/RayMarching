Shader "PeerPlay/RayMarchingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            sampler2D _MainTex;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform float _maxDistance, _lightIntensity, _shadowIntensity, _shadowPenumbra;
            uniform float4 _sphere1, _box1, _sdPlane, _sdCone, _sdTorus, _sdBoxFrame, _rBox1, _sphere2;
            uniform float2 _sdTorusModifier, _shadowDistance;
            uniform float3 _sdConeModifiers, _modInterval;
            uniform float3 _directionalLight, _lightCol;
            uniform fixed4 _mainColor;
            uniform float _rBoxModifier, _boxFraeModifier, _planeModifier, _boxSphereSmooth, _sphereIntersectionSmooth;
            uniform sampler2D _CameraDepthTexture;
            
           


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);

                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }

            float boxSphere(float3 p)
            {
                 float sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                 float roundBox = sdRoundBox(p - _rBox1.xyz, _rBox1.www, _rBoxModifier);
                 float combine1 = opSmoothSubtraction(sphere1, roundBox, _boxSphereSmooth);
                 float sphere2 = sdSphere(p - _sphere2.xyz, _sphere2.w);
                 float combine2 = opSmoothIntersection(sphere2, combine1, _sphereIntersectionSmooth);
                 

                 return combine2;
            }

            float distancefield(float3 p)
            {
                float modX = pMod1(p.x, _modInterval);
                float modY = pMod1(p.y, _modInterval);
                float modZ = pMod1(p.z, _modInterval); 
               
               float BoxSphere = boxSphere(p);
                float plane = sdPlane(p - _sdPlane.xyz, _sdPlane.xyz, _planeModifier);
                //float roundBox = sdRoundBox(p - _rBox1.xyz, _rBox1.www, _rBoxModifier);
                float boxFrame = sdBoxFrame(p - _sdBoxFrame.xyz, _sdBoxFrame.www, _boxFraeModifier);
                float torus = sdTorus(p - _sdTorus.xyz,_sdTorusModifier.xy);
                float cone = sdCone(p - _sdCone.xyz, _sdConeModifiers.xy, _sdConeModifiers.z);
                
                
                return BoxSphere; 
            }

            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0);
                float3 n = float3(
                    distancefield(p + offset.xyy) - distancefield(p - offset.xyy), 
                    distancefield(p + offset.yxy) - distancefield(p - offset.yxy), 
                    distancefield(p + offset.yyx) - distancefield(p - offset.yyx)
                );
                return normalize(n);
            }

            float hardShadow(float3 ro, float3 rd, float minT, float maxT)
            {
                for (float t = minT; t < maxT; )
                {
                    float h = distancefield(ro+rd*t);
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    t += h;
                }
                return 1.0;
            }

             float softShadow(float3 ro, float3 rd, float minT, float maxT, float k)
            {
                float result = 1.0;
                for (float t = minT; t < maxT; )
                {
                    float h = distancefield(ro+rd*t);
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    result = min(result, k*h/t);
                    t += h;
                }
                return result;
            }

            float3 shading(float3 p, float3 n)
            {
                // directional light
                float result = (_lightCol * dot(-_directionalLight, n) * 0.5 + 0.5) * _lightIntensity;
                //shadows
                float shadow = softShadow(p, -_directionalLight, _shadowDistance.x,_shadowDistance.y, _shadowPenumbra) * 0.5 + 0.5;
                shadow = max(0.0,  pow(shadow, _shadowIntensity));
                result *= shadow;
                return result;
            }

            fixed4 raymarching(float3 ro, float3 rd, float depth)
            {
                fixed4 result = fixed4(1,1,1,1);
                const int max_iteration = 164;
                float t = 0; //distance traveled along ray dir

                for (int i = 0; i < max_iteration; i++)
                {
                    if (t > _maxDistance || t >= depth)
                    {
                        //enviorenment
                        result = fixed4(rd, 0);
                        break;
                    }

                    float3 p = ro + rd * t;
                    //check for hit in distance field
                    float d = distancefield(p);
                    if (d < 0.01) // we have hit something
                    {
                        //shading
                        float3 n = getNormal(p);
                        float3 s = shading(p, n);


                        result = fixed4(_mainColor.rgb * s, 1);
                        break;
                    }
                    t += d;
                }

                return result;
            }




            fixed4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                fixed3 col = tex2D(_MainTex, i.uv);
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w , 1.0);
                // return result;
            }
            ENDCG
        }
    }
}
