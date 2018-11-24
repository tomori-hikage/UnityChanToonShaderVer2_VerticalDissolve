//UCTS_Outline_VerticalDissolve.cginc
//Unitychan Toon Shader ver.2.0
//v.2.0.5
//nobuyuki@unity3d.com
//https://github.com/unity3d-jp/UnityChanToonShaderVer2_Project
//(C)Unity Technologies Japan/UCL
// 2018/08/23 N.Kobayashi (Unity Technologies Japan)
// カメラオフセット付きアウトライン（BaseColorライトカラー反映修正版）
// 2017/06/05 PS4対応版
// Ver.2.0.4.3
// 2018/02/05 Outline Tex対応版
// #pragma multi_compile _IS_OUTLINE_CLIPPING_NO _IS_OUTLINE_CLIPPING_YES 
// _IS_OUTLINE_CLIPPING_YESは、Clippigマスクを使用するシェーダーでのみ使用できる. OutlineのブレンドモードにBlend SrcAlpha OneMinusSrcAlphaを追加すること.
//
            uniform float4 _LightColor0;
            uniform float4 _BaseColor;
            //v.2.0.5
            uniform float4 _Color;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _Outline_Width;
            uniform float _Farthest_Distance;
            uniform float _Nearest_Distance;
            uniform sampler2D _Outline_Sampler; uniform float4 _Outline_Sampler_ST;
            uniform float4 _Outline_Color;
            uniform fixed _Is_BlendBaseColor;
            uniform fixed _Is_LightColor_Base;
            uniform float _Offset_Z;
            //v2.0.4
            uniform sampler2D _OutlineTex; uniform float4 _OutlineTex_ST;
            uniform fixed _Is_OutlineTex;
            //Baked Normal Texture for Outline
            uniform sampler2D _BakedNormal; uniform float4 _BakedNormal_ST;
            uniform fixed _Is_BakedNormal;
            
            //VerticalDissolve
            uniform float _FillAmount;
		    uniform float _InvertMask;
		    uniform float _Is_WorldCoordinates;
		    uniform float _BorderWidth;
		    uniform float _NoiseScale;
		    uniform float3 _NoiseSpeed;
		    uniform float _LayerNoise;
		    uniform float _Wave1_Amplitude;
            uniform float _Wave1_Frequency;
		    uniform float _Wave1_Offset;
		    uniform float _Wave2_Amplitude;
		    uniform float _Wave2_Frequency;
		    uniform float _Wave2_Offset;
//v.2.0.4
#ifdef _IS_OUTLINE_CLIPPING_YES
            uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
            uniform float _Clipping_Level;
            uniform fixed _Inverse_Clipping;
            uniform fixed _IsBaseMapAlphaAsClippingMask;
#endif
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                float3 tangentDir : TEXCOORD2;
                float3 bitangentDir : TEXCOORD3;

                //VerticalDissolve
                float4 posWorld : TEXCOORD4;
            };

            //VerticalDissolve
            float3 mod289(float3 x) { return x - floor(x / 289.0) * 289.0; }
		    float4 mod289(float4 x) { return x - floor(x / 289.0) * 289.0; }
		    float4 permute(float4 x) { return mod289((x * 34.0 + 1.0) * x); }
		    float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - r * 0.85373472095314; }

		    float snoise(float3 v)
		    {
		    	const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
		    	float3 i = floor(v + dot(v, C.yyy));
		    	float3 x0 = v - i + dot(i, C.xxx);
		    	float3 g = step(x0.yzx, x0.xyz);
		    	float3 l = 1.0 - g;
		    	float3 i1 = min(g.xyz, l.zxy);
		    	float3 i2 = max(g.xyz, l.zxy);
		    	float3 x1 = x0 - i1 + C.xxx;
		    	float3 x2 = x0 - i2 + C.yyy;
		    	float3 x3 = x0 - 0.5;
		    	i = mod289(i);
		    	float4 p = permute(permute(permute(
                i.z + float4(0.0, i1.z, i2.z, 1.0)) +
                i.y + float4(0.0, i1.y, i2.y, 1.0)) +
                i.x + float4(0.0, i1.x, i2.x, 1.0));
		    	float4 j = p - 49.0 * floor(p / 49.0);
		    	float4 x_ = floor(j / 7.0);
		    	float4 y_ = floor(j - 7.0 * x_);
		    	float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
		    	float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;
		    	float4 h = 1.0 - abs(x) - abs(y);
		    	float4 b0 = float4(x.xy, y.xy);
		    	float4 b1 = float4(x.zw, y.zw);
		    	float4 s0 = floor(b0) * 2.0 + 1.0;
		    	float4 s1 = floor(b1) * 2.0 + 1.0;
		    	float4 sh = -step(h, 0.0);
		    	float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
		    	float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
		    	float3 g0 = float3(a0.xy, h.x);
		    	float3 g1 = float3(a0.zw, h.y);
		    	float3 g2 = float3(a1.xy, h.z);
		    	float3 g3 = float3(a1.zw, h.w);
		    	float4 norm = taylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
		    	g0 *= norm.x;
		    	g1 *= norm.y;
		    	g2 *= norm.z;
		    	g3 *= norm.w;
		    	float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
		    	m = m * m;
		    	m = m * m;
		    	float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
		    	return 42.0 * dot(m, px);
		    }

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
                //float3 lightColor = _LightColor0.rgb;
                float2 Set_UV0 = o.uv0;
                float4 _Outline_Sampler_var = tex2Dlod(_Outline_Sampler,float4(TRANSFORM_TEX(Set_UV0, _Outline_Sampler),0.0,0));
                //v.2.0.4.3 baked Normal Texture for Outline
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                
                //VerticalDissolve
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

                float3x3 tangentTransform = float3x3( o.tangentDir, o.bitangentDir, o.normalDir);
                //UnpackNormal()が使えないので、以下で展開。使うテクスチャはBump指定をしないこと.
                float4 _BakedNormal_var = (tex2Dlod(_BakedNormal,float4(TRANSFORM_TEX(Set_UV0, _BakedNormal),0.0,0)) * 2 - 1);
                float3 _BakedNormalDir = normalize(mul(_BakedNormal_var.rgb, tangentTransform));
                //ここまで.
                float Set_Outline_Width = (_Outline_Width*0.001*smoothstep( _Farthest_Distance, _Nearest_Distance, distance(objPos.rgb,_WorldSpaceCameraPos) )*_Outline_Sampler_var.rgb).r;
                //v.2.0.4.2 for VRChat mirror object without normalize()
                float3 viewDirection = _WorldSpaceCameraPos.xyz - o.pos.xyz;
                float4 viewDirectionVP = mul(UNITY_MATRIX_VP, float4(viewDirection.xyz, 1));
                //v.2.0.4.2
                _Offset_Z = _Offset_Z * -0.01;
//v2.0.4
#ifdef _OUTLINE_NML
                //v.2.0.4.3 baked Normal Texture for Outline                
                o.pos = UnityObjectToClipPos(lerp(float4(v.vertex.xyz + v.normal*Set_Outline_Width,1), float4(v.vertex.xyz + _BakedNormalDir*Set_Outline_Width,1),_Is_BakedNormal));
#elif _OUTLINE_POS
                Set_Outline_Width = Set_Outline_Width*2;
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + normalize(v.vertex)*Set_Outline_Width,1) );
#endif
                o.pos.z = o.pos.z + _Offset_Z*viewDirectionVP.z;
                return o;
            }
            float4 frag(VertexOutput i) : SV_Target{
                //VerticalDissolve Noise
			    float3 vertex3Pos = mul(unity_WorldToObject, float4(i.posWorld));//
			    float3 position = lerp(vertex3Pos, i.posWorld, _Is_WorldCoordinates);
			    float noise = snoise((_NoiseScale * (_NoiseSpeed * _Time.y + position)));

                //VerticalDissolve Generate Mask
                float layer = noise * _LayerNoise;
                float wave1 = _Wave1_Amplitude * sin(noise + ((layer + position.x) * _Wave1_Frequency + _Wave1_Offset));
                float wave2 = _Wave2_Amplitude * sin(noise + ((layer + position.z) * _Wave2_Frequency + _Wave2_Offset));
			    float wave = wave1 + wave2 + position.y;
			    float mask1 = step(wave, (_FillAmount * 2.0) - 1.0);
			    float mask2 = step(max(0.0, _BorderWidth) * 0.1 + wave, (_FillAmount * 2.0) - 1.0);
                float opacityMask = mask1 * (1.0 - _InvertMask) + _InvertMask * (1.0 - mask2);
			    clip(opacityMask - 0.5);

                //v.2.0.5
                _Color = _BaseColor;
                float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
                //float3 lightColor = _LightColor0.rgb;
                float2 Set_UV0 = i.uv0;
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(Set_UV0, _MainTex));
                float3 _BaseColorMap_var = (_BaseColor.rgb*_MainTex_var.rgb);
                //v.2.0.5
                float3 Set_BaseColor = lerp( _BaseColorMap_var, (_BaseColorMap_var*saturate(_LightColor0.rgb)), _Is_LightColor_Base );
                //v.2.0.4
                float3 _Is_BlendBaseColor_var = lerp( _Outline_Color.rgb, (_Outline_Color.rgb*Set_BaseColor*Set_BaseColor), _Is_BlendBaseColor );
                float3 _OutlineTex_var = tex2D(_OutlineTex,TRANSFORM_TEX(Set_UV0, _OutlineTex));
//v.2.0.4
#ifdef _IS_OUTLINE_CLIPPING_NO
                float3 Set_Outline_Color = lerp(_Is_BlendBaseColor_var, _OutlineTex_var.rgb*_Is_BlendBaseColor_var, _Is_OutlineTex );
                return fixed4(Set_Outline_Color,1.0);
#elif _IS_OUTLINE_CLIPPING_YES
                float4 _ClippingMask_var = tex2D(_ClippingMask,TRANSFORM_TEX(Set_UV0, _ClippingMask));
                float Set_MainTexAlpha = _MainTex_var.a;
                float _IsBaseMapAlphaAsClippingMask_var = lerp( _ClippingMask_var.r, Set_MainTexAlpha, _IsBaseMapAlphaAsClippingMask );
                float _Inverse_Clipping_var = lerp( _IsBaseMapAlphaAsClippingMask_var, (1.0 - _IsBaseMapAlphaAsClippingMask_var), _Inverse_Clipping );
                float Set_Clipping = saturate((_Inverse_Clipping_var+_Clipping_Level));
                clip(Set_Clipping - 0.5);
                float4 Set_Outline_Color = lerp( float4(_Is_BlendBaseColor_var,Set_Clipping), float4((_OutlineTex_var.rgb*_Is_BlendBaseColor_var),Set_Clipping), _Is_OutlineTex );
                return Set_Outline_Color;
#endif
            }
// UCTS_Outline_VerticalDissolve.cginc ここまで.
