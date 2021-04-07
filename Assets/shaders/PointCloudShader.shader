﻿Shader "Custom/PointCloud" {
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // C#から受け渡されるバッファとパラメータの受け取り
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

                // 連番で渡ってくる頂点IDを利用して、描画する頂点の座標を取り出し
                float4 pos = float4(posBuffer[id] + _WorldPos, 1);

                // 同様に色の取り出し
                // Ptsファイルで255段階で保存されている色ので0-1の階調に変換
                o.col = fixed4(colBuffer[id] / 255, 1);

                // 点群のサイズの補正のためカメラと点群の距離を計算
                float dist = length(_WorldSpaceCameraPos - pos);

                pos.y += sin(length(pos.xz - _WorldSpaceCameraPos.xz)) * 0.5;

                o.pos = UnityObjectToClipPos(pos);

                // 四角形の中央のスクリーン座標も渡すようにする
                // 自分でプロジェクション座標変換する必要がある

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
                // i.pos はPOSITIONセマンティックスを使っているため、
                // 1点が複数のピクセルに自動的にラスタライズされる際に、
                // ピクセルごとに異なるスクリーン座標が渡されてくる。
                // いっぽうi.centerは自前で座標変換しているため、 
                // vert -> fragで自動の変換などが発生せず
                // 同じ四角形の中では必ず同じ座標（四角形の中心）が渡されてくる。

                // 円を描画するため、描画するピクセルのスクリーン座標と、
                // ピクセルが属する四角形の中心のスクリーン座標の距離を計算

                if (length(i.pos.xy - i.center.xy) > _Radius / i.dist) {
                    discard;
                }
                return i.col;
            }
            ENDCG
        }
    }
}

