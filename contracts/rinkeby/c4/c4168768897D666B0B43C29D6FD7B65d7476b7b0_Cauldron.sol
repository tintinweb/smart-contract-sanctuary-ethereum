// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

library Cauldron {
  struct __Input {
    Handle handle;
    Background background;
    Xp xp;
    Stone stone;
    uint256 seed;
    Halo halo;
    Planet[8] planets;
    Aspect[8] aspects;
    FilterLayer[3] filterLayers;
    Frame frame;
    Sparkle[] sparkles;
  }

  struct FilterLayer {
    bool fractalNoise;
    uint8 turbFreqX;
    uint8 turbFreqY;
    uint8 turbOct;
    uint8 turbBlur;
    uint8 dispScale;
    uint8 blurX;
    uint8 blurY;
    uint8 specExponent;
    uint8 opacity;
    int16 surfaceScale;
    uint16 specConstant;
    int16 pointX;
    int16 pointY;
    int16 pointZ;
    Color lightColor;
  }

  struct Color {
    uint8 saturation;
    uint8 lightness;
    uint16 hue;
  }

  struct LightColor {
    uint8 saturation;
    uint8 lightness;
    uint16 hue;
  }

  struct Background {
    bool radial;
    bool dark;
    Color color;
  }

  struct Xp {
    bool crown;
    uint32 amount;
    uint32 cap;
  }

  struct Stone {
    bool fractalNoise;
    uint8 turbFreqX;
    uint8 turbFreqY;
    uint8 turbOct;
    int8 redAmp;
    int8 redExp;
    int8 redOff;
    int8 greenAmp;
    int8 greenExp;
    int8 greenOff;
    int8 blueAmp;
    int8 blueExp;
    int8 blueOff;
    uint16 rotation;
  }

  struct Frame {
    bool level1;
    bool level2;
    bool level3;
    bool level4;
    bool level5;
    string title;
  }

  struct Halo {
    bool halo0;
    bool halo1;
    bool halo2;
    bool halo3;
    bool halo4;
    bool halo5;
    uint16 hue;
    bool[24] rhythm;
  }

  struct Handle {
    bool handle0;
    bool handle1;
    bool handle2;
    bool handle3;
  }

  struct Aspect {
    int16 x1;
    int16 y1;
    int16 x2;
    int16 y2;
  }

  struct Planet {
    bool visible;
    int16 x;
    int16 y;
  }

  struct Sparkle {
    uint8 scale;
    uint16 tx;
    uint16 ty;
  }
  function render(__Input memory __input)
    public
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 3000" shape-rendering="geometricPrecision" > <style type="text/css"> .bc{fill:none;stroke:#8BA0A5;} </style>',
        BackgroundLayer.filter(__input),
        halo(__input.halo),
        "</svg>"
      )
    );
  }

  function halo(Halo memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <g id="halo" filter="url(#ge)"> <path d="',
        __input.halo0
          ? "m0 0 114 425c-40-153-6-231 93-231 100 0 134 78 93 231L414 0c-31 116-103 174-207 174C104 174 32 116 0 0Z"
          : "",
        __input.halo1
          ? "M211 0q-29 217-106 215Q29 217 0 0l55 420q-21-164 50-165 72 1 50 165Z"
          : "",
        __input.halo2
          ? "M171 0q0 115 171 162l-10 39q-161-39-161 219 0-258-160-219L1 162Q171 115 171 0Z"
          : "",
        __input.halo3
          ? "M193 0c0 25-96 52-192 79l10 39c90-21 182-7 182 42 0-49 93-63 183-42l10-39C290 52 193 25 193 0Z"
          : "",
        __input.halo4
          ? "m1 244 23 76c73-22 154-25 228-8L323 0q-48 209-206 222A521 521 0 0 0 1 244Z"
          : "",
        __input.halo5
          ? "M157 46Q136 199 50 201c-16 0-33 2-49 4l10 79a442 442 0 0 1 115 0Z"
          : "",
        '" fill="hsl(',
        SolidMustacheHelpers.uintToString(__input.hue, 0),
        ', 10%, 64%)" style="transform: translateX(-50%); transform-box: fill-box;" /> '
      )
    );
    if (__input.halo4) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <circle fill="hsl(',
          SolidMustacheHelpers.uintToString(__input.hue, 0),
          ', 10%, 64%)" cx="0" cy="80" r="40"/> '
        )
      );
    }
    __result = string(abi.encodePacked(__result, " "));
    if (__input.halo5) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <circle fill="hsl(',
          SolidMustacheHelpers.uintToString(__input.hue, 0),
          ', 10%, 64%)" cx="0" cy="60" r="40"/> '
        )
      );
    }
    __result = string(
      abi.encodePacked(
        __result,
        " </g> </defs> ",
        ' <g transform="translate(1000 1060)"> '
      )
    );
    for (uint256 __i; __i < __input.rhythm.length; __i++) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.rhythm[__i]) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <g style="transform: rotate(calc(',
            SolidMustacheHelpers.uintToString(__i, 0),
            " * 15deg)) translateY(",
            __input.halo0 ? "-770px" : "",
            __input.halo1 ? "-800px" : "",
            __input.halo2 ? "-800px" : "",
            __input.halo3 ? "-800px" : "",
            __input.halo4 ? "-740px" : "",
            __input.halo5 ? "-720px" : "",
            ');" ><use href="#halo"/></g> '
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(abi.encodePacked(__result, " </g>"));
  }
}

library BackgroundLayer {
  function filter(Cauldron.__Input memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <filter color-interpolation-filters="sRGB" id="ge" width="250%" height="250%" x="-75%" y="-55%" > <feGaussianBlur in="SourceAlpha" result="alphablur" stdDeviation="8" /> ',
        ' <feGaussianBlur in="SourceAlpha" stdDeviation="30" result="fg" /> <feColorMatrix in="fg" result="bgg" type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0 " /> ',
        " "
      )
    );
    for (uint256 __i; __i < __input.filterLayers.length; __i++) {
      __result = string(
        abi.encodePacked(
          __result,
          " <feTurbulence ",
          __input.filterLayers[__i].fractalNoise ? 'type="fractalNoise"' : "",
          ' baseFrequency="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbFreqX,
            3
          ),
          " ",
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbFreqY,
            3
          ),
          '" numOctaves="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbOct,
            0
          ),
          '" seed="',
          SolidMustacheHelpers.uintToString(__input.seed, 0),
          '" result="t',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feGaussianBlur stdDeviation="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbBlur,
            1
          ),
          '" in="SourceAlpha" result="tb',
          SolidMustacheHelpers.uintToString(__i, 0)
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '" /> <feDisplacementMap scale="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].dispScale,
            0
          ),
          '" in="tb',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" in2="t',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="dt',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feColorMatrix type="matrix" values="0 0 0 0 0, 0 0 0 0 0, 0 0 0 0 0, 0 0 0 1 0" in="dt',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="cm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feGaussianBlur stdDeviation="',
          SolidMustacheHelpers.uintToString(__input.filterLayers[__i].blurX, 1),
          " ",
          SolidMustacheHelpers.uintToString(__input.filterLayers[__i].blurY, 1)
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '" in="cm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="bcm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feSpecularLighting surfaceScale="',
          SolidMustacheHelpers.intToString(
            __input.filterLayers[__i].surfaceScale,
            0
          ),
          '" specularConstant="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].specConstant,
            2
          ),
          '" specularExponent="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].specExponent,
            0
          ),
          '" lighting-color="hsl(',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].lightColor.hue,
            0
          ),
          ", ",
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].lightColor.saturation,
            0
          ),
          "%, ",
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].lightColor.lightness,
            0
          )
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '%)" in="bcm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="l',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" > <fePointLight x="',
          SolidMustacheHelpers.intToString(__input.filterLayers[__i].pointX, 0),
          '" y="',
          SolidMustacheHelpers.intToString(__input.filterLayers[__i].pointY, 0),
          '" z="',
          SolidMustacheHelpers.intToString(__input.filterLayers[__i].pointZ, 0),
          '"/> </feSpecularLighting> <feComposite operator="in" in="l',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" in2="cm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="cl1',
          SolidMustacheHelpers.uintToString(__i, 0)
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '" /> <feComposite operator="arithmetic" k1="0" k2="0" k3="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].opacity,
            2
          ),
          '" k4="0" in="dt',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" in2="cl1',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="cl2',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feComposite operator="in" in2="SourceAlpha" in="cl2',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="clf',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> '
        )
      );
    }
    __result = string(
      abi.encodePacked(
        __result,
        ' <feMerge> <feMergeNode in="bgg"/> <feMergeNode in="SourceGraphic"/> '
      )
    );
    for (uint256 __i2; __i2 < __input.filterLayers.length; __i2++) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <feMergeNode in="clf',
          SolidMustacheHelpers.uintToString(__i2, 0),
          '"/> '
        )
      );
    }
    __result = string(
      abi.encodePacked(
        __result,
        ' </feMerge> </filter> <filter id="bb"> <feGaussianBlur in="SourceGraphic" stdDeviation="2"/> </filter> </defs>'
      )
    );
  }
}

library SolidMustacheHelpers {
  function intToString(int256 i, uint256 decimals)
    internal
    pure
    returns (string memory)
  {
    if (i >= 0) {
      return uintToString(uint256(i), decimals);
    }
    return string(abi.encodePacked("-", uintToString(uint256(-i), decimals)));
  }

  function uintToString(uint256 i, uint256 decimals)
    internal
    pure
    returns (string memory)
  {
    if (i == 0) {
      return "0";
    }
    uint256 j = i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    uint256 strLen = decimals >= len
      ? decimals + 2
      : (decimals > 0 ? len + 1 : len);

    bytes memory bstr = new bytes(strLen);
    uint256 k = strLen;
    while (k > 0) {
      k -= 1;
      uint8 temp = (48 + uint8(i - (i / 10) * 10));
      i /= 10;
      bstr[k] = bytes1(temp);
      if (decimals > 0 && strLen - k == decimals) {
        k -= 1;
        bstr[k] = ".";
      }
    }
    return string(bstr);
  }
}