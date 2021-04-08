Shader "Custom/PointCloud" {
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            StructuredBuffer<float3> colBuffer;
            StructuredBuffer<float3> posBuffer;
            float _Size;
            float _Radius;
            float3 _WorldPos;

            struct v2f {
                float4 pos: POSITION;
                fixed4 col: COLOR;
                float size: PSIZE;
                float4 center: TEXCOORD0;
                float dist: TEXCOORD1;
            };

            v2f vert (uint id : SV_VertexID) {
                v2f o;

                float4 pos = float4(posBuffer[id] + _WorldPos, 1);

                o.col = fixed4(colBuffer[id] / 255, 1);

                float dist = length(_WorldSpaceCameraPos - pos);

                pos.y += sin(length(pos.xz - _WorldSpaceCameraPos.xz)) * 0.5;

                o.pos = UnityObjectToClipPos(pos);

                float4 center = ComputeScreenPos(o.pos);
                center.xy /= center.w;
                center.x *= _ScreenParams.x;
                center.y *= _ScreenParams.y;                
                o.center = center;

                o.dist = dist;
                o.size = _Size / dist;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                if (length(i.pos.xy - i.center.xy) > _Radius / i.dist) {
                    discard;
                }
                return i.col;
            }
            ENDCG
        }
    }
}

