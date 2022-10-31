Shader "Instanced/InstancedSurfaceShader" 
{
    Properties
    {
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
            Tags { "RenderType" = "Opaque" }
            LOD 200

            CGPROGRAM
            // Physically based Standard lighting model
            #pragma surface surf Standard addshadow fullforwardshadows
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup 
            #pragma vertex vert

            sampler2D _MainTex;

            struct Input {
                float2 uv_MainTex;
                float3 worldNormal;
                float3 worldPos;
                INTERNAL_DATA
            };

        #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
            StructuredBuffer<float4> positionBuffer;
        #endif

            void rotate2D(inout float2 v, float r)
            {
                float s, c;
                sincos(r, s, c);
                v = float2(v.x * c - v.y * s, v.x * s + v.y * c);
            }

            float4x4 inverse(float4x4 input)
            {
#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))

                float4x4 cofactors = float4x4(
                    minor(_22_23_24, _32_33_34, _42_43_44),
                    -minor(_21_23_24, _31_33_34, _41_43_44),
                    minor(_21_22_24, _31_32_34, _41_42_44),
                    -minor(_21_22_23, _31_32_33, _41_42_43),

                    -minor(_12_13_14, _32_33_34, _42_43_44),
                    minor(_11_13_14, _31_33_34, _41_43_44),
                    -minor(_11_12_14, _31_32_34, _41_42_44),
                    minor(_11_12_13, _31_32_33, _41_42_43),

                    minor(_12_13_14, _22_23_24, _42_43_44),
                    -minor(_11_13_14, _21_23_24, _41_43_44),
                    minor(_11_12_14, _21_22_24, _41_42_44),
                    -minor(_11_12_13, _21_22_23, _41_42_43),

                    -minor(_12_13_14, _22_23_24, _32_33_34),
                    minor(_11_13_14, _21_23_24, _31_33_34),
                    -minor(_11_12_14, _21_22_24, _31_32_34),
                    minor(_11_12_13, _21_22_23, _31_32_33)
                    );
#undef minor
                return transpose(cofactors) / determinant(input);
            }

            void setup()
            {
            #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                float4 data = positionBuffer[unity_InstanceID];
                float rot = data.w; // data.w* _Time.y * 0.2f; ; // data.w;
                float size = 1;
                float rotation = data.w * data.w * _Time.y * 0;

                //rotate2D(data.xz, rotation);

                unity_ObjectToWorld._11_21_31_41 = float4(size, 0, 0, 0);
                unity_ObjectToWorld._12_22_32_42 = float4(0, size, 0, 0);
                unity_ObjectToWorld._13_23_33_43 = float4(0, 0, size, 0);
                unity_ObjectToWorld._14_24_34_44 = float4(data.xyz, 1);

                float s, c;
                sincos(rot, s, c);
                float4x4 rotateX = float4x4(
                    1, 0, 0, 0,
                    0, c, -s, 0,
                    0, s, c, 0,
                    0, 0, 0, 1
                    );
                unity_ObjectToWorld = mul(unity_ObjectToWorld, rotateX); // this line
                

                unity_WorldToObject = unity_ObjectToWorld;
                // unity_WorldToObject._14_24_34 *= -1;
                // unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;

                unity_WorldToObject = inverse(unity_ObjectToWorld); //this line
            #endif
            }

            void vert(inout appdata_full v, out Input data) {
                UNITY_INITIALIZE_OUTPUT(Input, data);

                // worldPosition(?)
                data.worldPos = v.vertex;

                
            }

            half _Glossiness;
            half _Metallic;

            void surf(Input IN, inout SurfaceOutputStandard o) {

                float3 wn = UnityObjectToWorldNormal(o.Normal); // IN.worldNormal;

                fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
                
                float3 posddx = ddx(IN.worldPos.xyz);
                float3 posddy = ddy(IN.worldPos.xyz);
                float3 derivedNormal = cross(normalize(posddx), normalize(posddy));

                // Add in lighting, somehow

                half4 c2 = (0.0, 0.0, 0.0, 0.3);
                c2.rgb = derivedNormal;
               // c = c2;

                //
           /*     c.r = wn.x;
                c.g = wn.y;
                c.b = wn.z;*/

                o.Albedo = c.rgb;
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = c.a;
            }
            ENDCG
        }
        FallBack "Diffuse"
}