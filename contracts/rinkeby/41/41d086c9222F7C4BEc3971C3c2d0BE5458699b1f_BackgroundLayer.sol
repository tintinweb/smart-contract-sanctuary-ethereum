// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

string constant __constant0 = '%, 0)"/> </radialGradient> <circle style="fill:url(#grad0)" cx="1000" cy="1925" r="1133"/> <circle style="fill:url(#grad0)" cx="1000" cy="372" r="1133"/> ';

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
        BackgroundLayer.background(__input.background),
        BackgroundLayer.xpBar(__input.xp),
        BackgroundLayer.stars(__input),
        stone(__input),
        FrameLayer.frame(__input.frame),
        halo(__input.halo),
        HandleLayer.handles(__input.handle),
        birthchart(__input),
        sparkle(__input),
        "</svg>"
      )
    );
  }

  function stone(__Input memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<filter id="s"> <feTurbulence ',
        __input.stone.fractalNoise ? 'type="fractalNoise"' : "",
        ' baseFrequency="',
        SolidMustacheHelpers.uintToString(__input.stone.turbFreqX, 3),
        " ",
        SolidMustacheHelpers.uintToString(__input.stone.turbFreqY, 3),
        '" numOctaves="',
        SolidMustacheHelpers.uintToString(__input.stone.turbOct, 0),
        '" seed="',
        SolidMustacheHelpers.uintToString(__input.seed, 0),
        '" /> <feComponentTransfer> <feFuncR type="gamma" amplitude="',
        SolidMustacheHelpers.intToString(__input.stone.redAmp, 2),
        '" exponent="',
        SolidMustacheHelpers.intToString(__input.stone.redExp, 2),
        '" offset="',
        SolidMustacheHelpers.intToString(__input.stone.redOff, 2)
      )
    );
    __result = string(
      abi.encodePacked(
        __result,
        '" /> <feFuncG type="gamma" amplitude="',
        SolidMustacheHelpers.intToString(__input.stone.greenAmp, 2),
        '" exponent="',
        SolidMustacheHelpers.intToString(__input.stone.greenExp, 2),
        '" offset="',
        SolidMustacheHelpers.intToString(__input.stone.greenOff, 2),
        '" /> <feFuncB type="gamma" amplitude="',
        SolidMustacheHelpers.intToString(__input.stone.blueAmp, 2),
        '" exponent="',
        SolidMustacheHelpers.intToString(__input.stone.blueExp, 2),
        '" offset="',
        SolidMustacheHelpers.intToString(__input.stone.blueOff, 2),
        '" /> <feFuncA type="discrete" tableValues="1"/> </feComponentTransfer> <feComposite operator="in" in2="SourceGraphic" result="tex" /> ',
        ' <feGaussianBlur in="SourceAlpha" stdDeviation="30" result="glow" /> <feColorMatrix in="glow" result="bgg" type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 .8 0 " /> <feMerge> <feMergeNode in="bgg"/> <feMergeNode in="tex"/> </feMerge> </filter> <radialGradient id="ss"> <stop offset="0%" stop-color="hsla(0, 0%, 0%, 0)"/> <stop offset="90%" stop-color="hsla(0, 0%, 0%, .8)"/> </radialGradient> <defs> ',
        ' <clipPath id="sc"> <circle cx="1000" cy="1060" r="260"/> </clipPath> </defs> ',
        ' <circle transform="rotate('
      )
    );
    __result = string(
      abi.encodePacked(
        __result,
        SolidMustacheHelpers.uintToString(__input.stone.rotation, 0),
        ', 1000, 1060)" cx="1000" cy="1060" r="260" filter="url(#s)" /> ',
        ' <circle cx="1200" cy="1060" r="520" fill="url(#ss)" clip-path="url(#sc)" /> <defs> <radialGradient id="sf" cx="606.78" cy="1003.98" fx="606.78" fy="1003.98" r="2" gradientTransform="translate(-187630.67 -88769.1) rotate(-33.42) scale(178.04 178.05)" gradientUnits="userSpaceOnUse" > <stop offset=".05" stop-color="#fff" stop-opacity=".7"/> <stop offset=".26" stop-color="#ececec" stop-opacity=".5"/> <stop offset=".45" stop-color="#c4c4c4" stop-opacity=".5"/> <stop offset=".63" stop-color="#929292" stop-opacity=".5"/> <stop offset=".83" stop-color="#7b7b7b" stop-opacity=".5"/> <stop offset="1" stop-color="#cbcbca" stop-opacity=".5"/> </radialGradient> <radialGradient id="sh" cx="1149" cy="2660" fx="1149" fy="2660" r="76" gradientTransform="translate(312 2546) rotate(-20) scale(1 -.5)" gradientUnits="userSpaceOnUse" > <stop offset="0" stop-color="#fff" stop-opacity=".7"/> <stop offset="1" stop-color="#fff" stop-opacity="0"/> </radialGradient> </defs> <path fill="url(#sf)" d="M1184 876a260 260 0 1 1-368 368 260 260 0 0 1 368-368Z"/> <path fill="url(#sh)" d="M919 857c49-20 96-15 107 11 10 26-21 62-70 82s-97 14-107-12c-10-25 21-62 70-81Z"/>'
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

  function birthchart(__Input memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<g transform="translate(1000 1060)"> <defs> <radialGradient id="ag" cx="0" cy="0" r="1" gradientTransform="translate(.5 .5)" > <stop stop-color="#FFFCFC" stop-opacity=".7"/> <stop offset="1" stop-color="#534E41" stop-opacity=".6"/> </radialGradient> <clipPath id="ac"><circle cx="0" cy="0" r="260"/></clipPath> <filter id="pb"><feGaussianBlur stdDeviation="4"/></filter> <style> .p0 { fill: #FFF6F2 } .p1 { fill: #FFFCF0 } .p2 { fill: #FFEDED } .p3 { fill: #FFEEF4 } .p4 { fill: #FFF3E9 } .p5 { fill: #ECFDFF } .p6 { fill: #EEF7FF } .p7 { fill: #F8F0FF } </style> </defs> '
      )
    );
    for (uint256 __i; __i < __input.aspects.length; __i++) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <path d="M',
          SolidMustacheHelpers.intToString(__input.aspects[__i].x1, 0),
          ",",
          SolidMustacheHelpers.intToString(__input.aspects[__i].y1, 0),
          " L",
          SolidMustacheHelpers.intToString(__input.aspects[__i].x2, 0),
          ",",
          SolidMustacheHelpers.intToString(__input.aspects[__i].y2, 0),
          ' m25,25" stroke="url(#ag)" stroke-width="8" clip-path="url(#ac)" /> '
        )
      );
    }
    __result = string(abi.encodePacked(__result, ' <g filter="url(#pb)"> '));
    for (uint256 __i2; __i2 < __input.planets.length; __i2++) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.planets[__i2].visible) {
        __result = string(
          abi.encodePacked(
            __result,
            '<circle cx="',
            SolidMustacheHelpers.intToString(__input.planets[__i2].x, 0),
            '" cy="',
            SolidMustacheHelpers.intToString(__input.planets[__i2].y, 0),
            '" class="p',
            SolidMustacheHelpers.uintToString(__i2, 0),
            '" r="11"/>'
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(abi.encodePacked(__result, " </g> </g>"));
  }

  function sparkle(__Input memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <style type="text/css"> .sp { fill: white } </style> <symbol id="sp" viewBox="0 0 250 377"> <path class="sp" d="m4 41 121 146 125 2-122 2 118 146-121-146-125-2 122-2L4 41Z"/> <path class="sp" d="m105 0 21 185 86-83-86 88 18 187-20-185-87 84 87-88L105 0Z"/> </symbol> </defs> <g filter="url(#bb)" style="opacity: .6"> '
      )
    );
    for (uint256 __i; __i < __input.sparkles.length; __i++) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <use width="250" height="377" transform="translate(',
          SolidMustacheHelpers.uintToString(__input.sparkles[__i].tx, 0),
          " ",
          SolidMustacheHelpers.uintToString(__input.sparkles[__i].ty, 0),
          ") scale(",
          SolidMustacheHelpers.uintToString(__input.sparkles[__i].scale, 2),
          ')" href="#sp" /> '
        )
      );
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

  function background(Cauldron.Background memory __input)
    external
    pure
    returns (string memory __result)
  {
    if (__input.radial) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <path style="fill:hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ', 30%, 7%)" d="M0 0h2000v3000H0z"/> <radialGradient id="grad0"> <stop offset="0" style="stop-color: hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)"/> <stop offset="1" style="stop-color: hsla(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            __constant0
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
      if (!__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <path style="fill:hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)" d="M0 0h2000v3000H0z"/> <radialGradient id="grad0"> <stop offset="0" style="stop-color:hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ', 100%, 95%)"/> <stop offset="1" style="stop-color:hsla(55, 66%, 83',
            __constant0
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(abi.encodePacked(__result, " "));
    if (!__input.radial) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <linearGradient id="l0" gradientTransform="rotate(90)"> <stop offset="0%" stop-color="hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ', 30%, 7%)"/> <stop offset="100%" stop-color="hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)"/> </linearGradient> <rect style="fill:url(#l0)" width="2000" height="3000"/> '
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
      if (!__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <linearGradient id="l0" gradientTransform="rotate(90)"> <stop offset="0%" stop-color="hsl(55, 66%, 83%)"/> <stop offset="100%" stop-color="hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)"/> </linearGradient> <rect style="fill:url(#l0)" width="2000" height="3000"/> '
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(
      abi.encodePacked(
        __result,
        ' <path filter="url(#bb)" style="opacity: .5" d="m1000 2435-199 334 195-335-573 212 570-214-892-20 889 18-1123-339 1121 335-1244-713 1243 709-1242-1106L988 2418-133 938 990 2415 101 616l892 1796L423 382l573 2028L801 260l199 2149 199-2149-195 2150 573-2028-569 2030 891-1796-889 1799L2133 938 1012 2418l1244-1102-1243 1106 1243-709-1244 713 1121-335-1123 338 889-17-892 20 570 214-573-212 195 335-199-334z" fill="white" />'
      )
    );
  }

  function xpBar(Cauldron.Xp memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <style> .xpc { fill: none; stroke-width: 1; stroke: #FAFFC0; opacity: 0.7; } .hilt path { fill: url(#hg); } </style> <linearGradient id="xpg" x1="80%" x2="20%" y1="200%" y2="-400%"> <stop offset="0"/> <stop offset=".4" stop-color="#90ee90" stop-opacity="0"/> </linearGradient> <linearGradient id="hg" x1="80%" x2="20%" y1="200%" y2="-400%"> <stop offset="0"/> <stop offset=".4" stop-color="#90ee90"/> </linearGradient> </defs> <circle class="xpc" cx="1000" cy="1060" r="320"/> <circle class="xpc" cx="1000" cy="1060" r="290"/> <path id="xpb" d="M1000 1365a1 1 0 0 0 0-610" stroke-linecap="round" style="stroke-dasharray:calc(',
        SolidMustacheHelpers.uintToString(__input.amount, 0),
        " / ",
        SolidMustacheHelpers.uintToString(__input.cap, 0),
        ' * 37.2%) 100%;fill:none;stroke-width:28;stroke:url(#xpg);opacity:1;mix-blend-mode:plus-lighter"/> <use href="#xpb" transform="matrix(-1 0 0 1 2000 0)"/> <g class="hilt" filter="url(#ge)" id="xph"> <path transform="rotate(45 1000 1365)" d="M980 1345h40v40h-40z"/> <path d="M980 1345h40v40h-40z"/> </g> ',
        __input.crown
          ? ' <use href="#xph" transform="translate(0,-610)"/> '
          : ""
      )
    );
  }

  function stars(Cauldron.__Input memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <filter id="st"> <feTurbulence baseFrequency=".1" seed="',
        SolidMustacheHelpers.uintToString(__input.seed, 0),
        '"/> <feColorMatrix values="0 0 0 7 -4 0 0 0 7 -4 0 0 0 7 -4 0 0 0 0 1" /> </filter> </defs> <clipPath id="stc"> <circle cx="1000" cy="1060" r="520"/> </clipPath> <mask id="stm"> <g filter="url(#st)" transform="scale(2)"> <rect width="100%" height="100%"/> </g> </mask> <circle class="bc" cx="1000" cy="1060" r="260"/> <circle class="bc" cx="1000" cy="1060" r="360"/> <circle class="bc" cx="1000" cy="1060" r="440"/> <circle class="bc" cx="1000" cy="1060" r="520"/> <line class="bc" x1="740" y1="610" x2="1260" y2="1510"/> <line class="bc" x1="1260" y1="610" x2="740" y2="1510"/> <line class="bc" x1="1450" y1="800" x2="550" y2="1320"/> <line class="bc" x1="1450" y1="1320" x2="550" y2="800"/> <g style="filter: blur(2px);"> <rect width="100%" height="100%" fill="white" mask="url(#stm)" clip-path="url(#stc)" /> </g>'
      )
    );
  }
}

library FrameLayer {
  function frame(Cauldron.Frame memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <linearGradient id="gradient-fill"> <stop offset="0" stop-color="black"></stop> <stop offset="0.5" stop-color="rgba(255,255,255,0.5)"></stop> <stop offset="1" stop-color="rgba(255,255,255,0.8)"></stop> </linearGradient> <style type="text/css"> .title {font: 45px serif; fill: #ffffffbb; letter-spacing: 7px} .frame-line { fill: none; stroke: url(#gradient-fill); stroke-miterlimit: 10; stroke-width: 2px; mix-blend-mode: plus-lighter; } .frame-circ { fill: url(#gradient-fill); mix-blend-mode: plus-lighter; } </style> </defs>',
        __input.level1
          ? ' <g> <g id="half1"> <polyline class="frame-line" points="999.95 170.85 1383.84 170.85 1862.82 137.14 1862.82 1863.5 1759.46 2478.5 1481.46 2794.5 999.98 2794.5" ></polyline> <polyline class="frame-line" points="1000 69 1931.46 68.5 1931.39 2930.43 1569.96 2931 1480.96 2828 999.99 2828" ></polyline> </g> <use href="#half1" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        __input.level2
          ? ' <g> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> <g id="half2"> <polyline class="frame-line" points="1000 69 1931.46 68.5 1931.39 2930.43 1569.96 2931 1480.96 2828 1000 2828" ></polyline> <polyline class="frame-line" points="1897.11 102.86 1383.84 137.14 1000 137.14" ></polyline> <polyline class="frame-line" points="1897.17 102.86 1897.46 2896.5 1710.57 2897.5 1607.57 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1607.57 2794.5 1759.46 2478.5 1862.46 1898 1862.82 711.53 1357.29 206 1000 205.71" ></polyline> <line class="frame-line" x1="1607.57" y1="2794.5" x2="1000" y2="2794.5" ></line> <line class="frame-line" x1="1371.92" y1="172" x2="1000" y2="172"></line> <polyline class="frame-line" points="1371.92 172 1862.82 661.72 1862.82 137.14 1371.92 172" ></polyline> <line class="frame-line" x1="999.41" y1="240.85" x2="998.82" y2="240.85" ></line> <line class="frame-line" x1="999.41" y1="240.85" x2="1000" y2="240.85" ></line> <polyline class="frame-line" points="1000 2773.5 1481.46 2773.5 1573.01 1924.59 1827.75 1412.39 1827.75 725.62 1342.13 240 1000 240.84" ></polyline> <line class="frame-line" x1="999.41" y1="240.85" x2="1000" y2="240.84" ></line> </g> <use href="#half2" transform="scale(-1,1) translate(-2000,0)"></use> </g>'
          : "",
        __input.level3
          ? ' <g> <g id="half3"> <polyline class="frame-line" points="1000 69 1931.5 68.5 1931.43 2930.43 1570 2931 1481 2828 1000 2828" ></polyline> <polyline class="frame-line" points="1529.47 205.71 1494.75 170.99 1434.52 170.99 1366.78 102.65 1000.15 102.51" ></polyline> <polyline class="frame-line" points="1897.15 697.11 1827.43 627.96 1827.43 503.65 1759.61 435.84 1759.65 239.65 1563.41 239.65 1529.47 205.71" ></polyline> <polyline class="frame-line" points="1794.28 470.49 1794.32 205.71 1529.47 205.71" ></polyline> <polyline class="frame-line" points="1505.26 2630.76 1505.26 2329.59 1827.78 1797.3 1827.78 1091.27" ></polyline> <polyline class="frame-line" points="1505.26 2630.76 1505.26 2741.32 1474.99 2773.5 1000.04 2773.5 1000 2773.5" ></polyline> <polyline class="frame-line" points="1827.78 1091.27 1827.78 725.62 1342.17 240 1000 240.84" ></polyline> <line class="frame-line" x1="1000" y1="240.84" x2="998.85" y2="240.85" ></line> <polyline class="frame-line" points="1897.2 697.11 1897.5 2896.5 1710.61 2897.5 1607.61 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1000 205.71 1357.32 206 1862.86 711.53 1862.5 1898 1759.5 2478.5 1481.5 2794.5 1000 2794.5" ></polyline> <line class="frame-line" x1="1827.78" y1="1091.27" x2="1827.82" y2="1091.1" ></line> <polyline class="frame-line" points="1505.26 2630.76 1367.45 2554.29 1367.45 2220.5 1792.75 1724.22 1792.75 1248.5 1827.78 1091.27" ></polyline> <line class="frame-line" x1="1523.72" y1="2641" x2="1505.26" y2="2630.76" ></line> <polygon class="frame-line" points="1516.66 2779.74 1533.6 2794.5 1754.59 2794.5 1854.26 2880.53 1879.75 2880.53 1879.75 2016.03 1854.5 2050.86 1773.41 2487.85 1516.66 2779.74" ></polygon> <polygon class="frame-line" points="1827.82 2003.62 1827.78 1827.65 1541.42 2300.27 1541.42 2701.3 1745.92 2465.88 1827.82 2003.62" ></polygon> <path class="frame-circ" d="M1523.72,2437.57c-19.52,0-17.5-108.68-17.5-108.68v303.83l17.5,8.28v-203.43Z" ></path> </g> <use href="#half3" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        __input.level4
          ? ' <g> <g id="half4"> <polyline class="frame-line" points="1000 69 1931.5 68.5 1931.43 2930.43 1570 2931 1481 2828 1000 2828" ></polyline> <line class="frame-line" x1="1897.28" y1="863.04" x2="1897.5" y2="2880.53" ></line> <polyline class="frame-line" points="1897.28 863.04 1897.2 102.86 1000 102.86" ></polyline> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2896.5 1710.61 2897.5 1607.61 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2880.53 1897.5 862.02 1897.28 863.04" ></polyline> <polyline class="frame-line" points="1897.28 863.04 1880.5 941.98 1880.5 2482.5 1668.74 2606.83 1516.66 2779.74 1533.6 2794.5 1754.59 2794.5 1854.26 2880.53 1897.5 2880.53" ></polyline> <polygon class="frame-line" points="1810.37 1957.47 1584.83 2627.74 1598.53 2636.23 1743.99 2466.19 1833.34 1957.47 1810.37 1957.47" ></polygon> <polygon class="frame-line" points="1792.74 1887.34 1521.19 2335.31 1519.33 2728.41 1540.01 2703.32 1792.74 1957.47 1792.74 1887.34" ></polygon> <line class="frame-line" x1="1760.57" y1="1061.26" x2="1760.57" y2="1185.5" ></line> <line class="frame-line" x1="1760.57" y1="1061.26" x2="1760.57" y2="658.41" ></line> <polyline class="frame-line" points="1367.38 2457.75 1314.63 2424.63 1314.7 2083.5 1743.57 1676.44" ></polyline> <polyline class="frame-line" points="1743.57 1676.44 1760.57 1660.31 1760.57 1185.5" ></polyline> <polygon class="frame-line" points="1385.01 2220.72 1421.7 2503.81 1475.28 2593.06 1489.95 2601.39 1489.95 2324.67 1792.75 1830.71 1792.75 1742.41 1385.01 2220.72" ></polygon> <polyline class="frame-line" points="1743.57 1676.44 1743.57 1265.46 1760.57 1185.5" ></polyline> <polyline class="frame-line" points="1810.78 1825.36 1810.78 1265.44 1827.78 1185.47" ></polyline> <polyline class="frame-line" points="1760.57 1061.26 1725.5 1218.65 1725.5 1592.76 1268.07 1931.48 1268.07 2424.5 1367.45 2484.94" ></polyline> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2220.5 1792.75 1724.22 1792.75 1218.65 1827.78 1061.42" ></polyline> <line class="frame-line" x1="1827.82" y1="1061.26" x2="1827.78" y2="1061.42" ></line> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2554.29 1490.09 2622.34 1490.09 2734.78 1468.95 2756.5 1390.92 2756.5 1310.95 2773.5" ></polyline> <polygon class="frame-line" points="1390.64 240 1827.78 677.14 1827.78 346.02 1504.22 240 1390.64 240" ></polygon> <polygon class="frame-line" points="1827.78 240 1582.82 240 1827.78 315.28 1827.78 240" ></polygon> <line class="frame-line" x1="1827.78" y1="1061.42" x2="1827.78" y2="1185.47" ></line> <polyline class="frame-line" points="1310.95 2773.5 1001.4 2773.5 1000.22 2773.5 1000.04 2773.5 1000 2773.5" ></polyline> <polyline class="frame-line" points="1827.78 1185.47 1827.78 1797.3 1505.26 2329.59 1505.26 2741.32 1474.99 2773.5 1310.95 2773.5" ></polyline> <polyline class="frame-line" points="1827.78 1061.42 1827.78 725.62 1342.17 240 1000 240" ></polyline> <polyline class="frame-line" points="1000 205.71 1383.88 205.71 1862.86 137.14 1862.86 1863.5 1759.5 2478.5 1481.5 2794.5 1000 2794.5" ></polyline> <circle class="frame-circ" cx="1811.14" cy="191.9" r="16.65"></circle> <circle class="frame-circ" cx="1811.14" cy="2745.05" r="16.65"></circle> </g> <use href="#half4" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        __input.level5
          ? ' <g> <g id="half5"> <circle class="frame-circ" cx="1730.45" cy="2846.73" r="16.65"></circle> <path class="frame-circ" d="M1373.87,2812.06c0-19.52,108.68-17.5,108.68-17.5h-482.63l.2,17.5h373.75Z" ></path> <path class="frame-circ" d="M1373.87,2826.85c0-19.52,108.68-17.5,108.68-17.5h-482.63l.2,17.5h373.75Z" ></path> <polyline class="frame-line" points="1000 137.11 1131.57 137.04 1178.34 68.9 1931.5 68.5 1931.43 2930.43 1570 2931 1481 2828 1000 2828" ></polyline> <polyline class="frame-line" points="1897.28 863.04 1897.2 102.86 1210.67 102.86 1165.79 170.24 1000 170.31" ></polyline> <line class="frame-line" x1="1897.28" y1="863.04" x2="1897.5" y2="2880.53" ></line> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2896.5 1710.61 2897.5 1607.61 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1897.28 863.04 1880.5 941.98 1880.5 2482.5 1668.74 2606.83 1516.66 2779.74 1533.6 2794.5 1754.59 2794.5 1854.26 2880.53 1897.5 2880.53" ></polyline> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2880.53 1897.5 862.02 1897.28 863.04" ></polyline> <polyline class="frame-line" points="1827.78 1192.28 1827.78 1797.3 1505.26 2329.59 1505.26 2741.32 1474.99 2773.5 1108.16 2773.5" ></polyline> <polyline class="frame-line" points="1108.16 2773.5 1001.4 2773.5 1000.22 2773.5 1000.04 2773.5 1000 2773.5" ></polyline> <polyline class="frame-line" points="1795.65 693.48 1342.17 240 1000 240" ></polyline> <line class="frame-line" x1="1827.78" y1="1192.28" x2="1827.78" y2="1061.42" ></line> <polyline class="frame-line" points="1827.78 1061.42 1827.78 725.62 1795.65 693.48" ></polyline> <polyline class="frame-line" points="1000 205.71 1343.14 205.71 1387.55 137.14 1637.33 137.14 1862.86 724.46 1862.86 1863.5 1759.5 2478.5 1481.5 2794.5 1000 2794.5" ></polyline> <polygon class="frame-line" points="1391.12 258.56 1749.43 619.82 1802.81 619.82 1623.32 160.77 1403.75 160.77 1391.12 258.56" ></polygon> <polyline class="frame-line" points="1743.58 1781.6 1792.75 1724.22 1792.75 1218.65 1827.78 1061.42" ></polyline> <line class="frame-line" x1="1827.82" y1="1061.26" x2="1827.78" y2="1061.42" ></line> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2554.29 1433.9 2622.34 1433.9 2734.78 1412.76 2756.5 1188.13 2756.5 1108.16 2773.5" ></polyline> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2220.5 1743.58 1781.6" ></polyline> <polyline class="frame-line" points="1367.45 2484.94 1268.07 2424.5 1268.07 1931.48 1725.5 1592.76 1725.5 1218.65 1760.57 1061.26 1760.57 658.41" ></polyline> <polyline class="frame-line" points="1760.57 1761.76 1760.57 1218.65 1795.65 1061.26 1795.65 972.9" ></polyline> <line class="frame-line" x1="1795.65" y1="693.48" x2="1795.65" y2="972.9" ></line> <polygon class="frame-line" points="1354.28 1995.11 1516.66 1871.28 1516.66 1822.34 1608.69 1751.67 1608.69 1697.46 1281.35 1941.68 1281.35 2416.1 1354.28 2461.09 1354.28 1995.11" ></polygon> <polygon class="frame-line" points="1367.48 2197.71 1728.39 1776.02 1725.8 1612.05 1621.83 1687.86 1621.83 1758.95 1528.89 1828.67 1528.89 1882.83 1367.48 2003.92 1367.48 2197.71" ></polygon> <polygon class="frame-line" points="1504.51 2079.27 1504.51 2307.23 1795.65 1826.17 1795.65 1741.8 1504.51 2079.27" ></polygon> <polygon class="frame-line" points="1379.42 2225.53 1379.42 2544.67 1447.81 2613.04 1488.39 2613.04 1488.39 2097.65 1379.42 2225.53" ></polygon> <polygon class="frame-line" points="1810.37 1957.47 1584.83 2627.74 1598.53 2636.23 1743.99 2466.19 1833.34 1957.47 1810.37 1957.47" ></polygon> <polygon class="frame-line" points="1792.74 1887.34 1521.19 2335.31 1519.33 2728.41 1540.01 2703.32 1792.74 1957.47 1792.74 1887.34" ></polygon> <polyline class="frame-line" points="1827.78 1192.28 1810.78 1272.24 1810.78 1825.36" ></polyline> <polyline class="frame-line" points="1743.58 1781.6 1743.58 1217.84 1795.65 972.9" ></polyline> <polygon class="frame-line" points="1880.5 2511.85 1862.86 2511.85 1681.48 2620.12 1580.39 2737.19 1618.59 2777.12 1759.78 2776.27 1859.09 2863.38 1880.17 2863.38 1880.5 2511.85" ></polygon> </g> <use href="#half5" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        '<path opacity="0.4" d="M 529.085 2844.789 L 454.584 2930.999 L 1545.417 2930.989 L 1470.942 2844.789 L 529.085 2844.789 Z" fill="#00000055" stroke="white" stroke-width="3.75" ></path> <clipPath id="tc"> <path d="M 529.085 2844.789 L 454.584 2930.999 L 1545.417 2930.989 L 1470.942 2844.789 L 529.085 2844.789 Z" fill="black" ></path> </clipPath> <text x="1000" y="2904" text-anchor="middle" class="title" clip-path="url(#tc)"> ',
        __input.title,
        " </text>"
      )
    );
  }
}

library HandleLayer {
  function handles(Cauldron.Handle memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <style> .a, .d { fill: none; } .a, .b, .c, .d, .e, .f, .g, .h, .i, .k { stroke: #000; stroke-width: .25px; } .b, .c, .e, .g { fill: #fff; } .pf { fill: #584975; } .red { --wedge-color: #e0727f; } .rf { fill: #ed2d2e; } .nf { fill: #053c5b; } .gr { --wedge-color: #8a9fa4; } .bf{ fill: #1b1925; } .lb { fill: #425288; } .gf { fill: #aad37e; } .bl { --wedge-color: #425288; } .ef { fill: #8a9fa4; } .lgf { fill: #c3cdd7; } .lbf { fill: #8cb3db; } .db { --wedge-color: #3a4757; } </style> <symbol id="wa" viewBox="0 0 111 111"> <style>.cw { fill: var(--wedge-color) }</style> <path class="c" d="M12 111a226 226 0 0 0 99-99l-7-3a226 226 0 0 1-95 95Z"/> <path class="c cw" d="M9 104a226 226 0 0 0 95-95L87 0 75 21c-15 21-32 22-53 1 22 21 20 38-1 53A204 204 0 0 1 0 87Z"/> </symbol> <symbol id="wb" viewBox="0 0 114 65"> <path class="a cw" d="M3 4 0 32s57-14 57 33c0-47 56-33 56-33l-3-28C87-1 30-1 3 4Z"/> <path class="b" d="M0 32s25-6 42 3c-9-5-33-2-33-2l-9-1m113 0s-25-6-41 3c8-5 33-2 33-2l9-1"/> </symbol> <symbol id="c" viewBox="0 0 211 420"> <path class="ef" d="M211 0q-29 217-106 215Q29 217 0 0l55 420q-21-164 50-165 72 1 50 165Z"/> </symbol> <symbol id="g" viewBox="0 0 346 148"> <path class="lbf" d="M173 0c1 20 10 60 173 88-168-21-172 36-173 60-1-24-6-81-173-60C163 60 171 20 173 0Z"/> </symbol> <symbol id="h" viewBox="0 0 48 90"> <path class="b" d="M24 90c0-14 16-34 24-42 0-12-24-30-24-48C24 18 0 36 0 48c8 8 24 28 24 42Z"/> <path class="c" d="M45 40a72 72 0 0 0-21 29C20 58 13 49 3 40 9 29 24 14 24 0c0 14 15 29 21 40Z"/> <path class="b" d="M24 69v21"/> </symbol> </defs> <g filter="url(#ge)" style="opacity: 1; mix-blend-mode: luminosity">',
        __input.handle0
          ? '<path class="pf" d="M1073 2313c-13-13-18-24-25-81-27-194-2-683 34-778l-32-40H950l-32 40c36 95 61 584 34 778-7 57-12 68-25 80Z"/> <rect class="c" x="941" y="1407" width="119" height="7" rx="4"/> <rect class="c" x="941" y="1593" width="119" height="7" rx="4"/> <rect class="c" x="944" y="1631" width="111" height="7" rx="4"/> <rect class="c" x="948" y="1669" width="104" height="7" rx="4"/> <rect class="c" x="951" y="1707" width="98" height="7" rx="4"/> <rect class="c" x="953" y="1745" width="94" height="7" rx="4"/> <rect class="c" x="955" y="1783" width="90" height="7" rx="4"/> <rect class="c" x="957" y="1821" width="87" height="7" rx="4"/> <rect class="c" x="958" y="1859" width="84" height="7" rx="4"/> <rect class="c" x="959" y="1897" width="82" height="7" rx="4"/> <rect class="c" x="960" y="1935" width="81" height="7" rx="4"/> <rect class="c" x="960" y="1973" width="80" height="7" rx="4"/> <rect class="c" x="960" y="2011" width="80" height="7" rx="4"/> <rect class="c" x="960" y="2049" width="80" height="7" rx="4"/> <rect class="c" x="959" y="2087" width="81" height="7" rx="4"/> <rect class="c" x="958" y="2125" width="85" height="7" rx="4"/> <rect class="c" x="955" y="2163" width="90" height="7" rx="4"/> <path class="b" d="M1000 1553a231 231 0 0 1-103-25l5-10a220 220 0 0 0 196-1l6 11a231 231 0 0 1-104 25Z"/> <use class="red" width="111" height="111" transform="translate(1091 1426)" href="#wa"/> <use class="red" width="111" height="111" transform="rotate(90 -258 1168)" href="#wa"/> <use class="red" width="114" height="65" transform="translate(943 2199)" href="#wb"/> <use class="red" width="114" height="65" transform="matrix(-1.25 0 0 -1 1071 1558)" href="#wb"/> <path class="pf" d="M918 1454h164"/> <path class="b" d="M928 2384c10-5 9 15 9 15s-11 4-7 22c0 0-12-32-2-37Zm144 0c-10-5-9 15-9 15s11 4 7 22c0 0 12-32 2-37Z"/> <circle cx="1000" cy="2350" r="80" fill="#ad93c5"/> <path class="b" d="M1000 2351s102 4 68-52l-4 4c29 43-64 42-64 42s-93 1-64-42l-4-4c-34 56 68 52 68 52Zm-51 136 11 63c16-33 64-33 80 0l11-63c-31 38-72 38-102 0Zm89 50a51 51 0 0 0-76 0l-6-35c28 24 60 24 88 0Z"/> <path class="a" d="m949 2487 7 15m6 35-3 13m79-13 2 13m11-63-7 15"/> <path d="M1068 2299c35 56-68 52-68 52s-103 4-68-52a80 80 0 0 0-17 52c5 85 36 217 52 318-20-125 16-133 33-133s53 8 33 133c16-101 47-233 52-318 2-16-5-39-17-52Zm-28 251a46 46 0 0 0-80 0l-11-63c30 38 71 38 102 0Zm33-146c-7 57-43 100-73 100s-66-43-73-100c-1-5-9-48 73-47 82-1 74 42 73 47Z" fill="#e0727f"/>'
          : "",
        __input.handle1
          ? '<rect class="c" x="947" y="1407" width="106" height="7" rx="4"/> <circle cx="1000" cy="2020" r="130" fill="#fff" stroke="#000" stroke-width=".3"/> <circle cx="1000" cy="2020" r="126" fill="#8a9fa4"/> <circle cx="1000" cy="2020" r="118" fill="#efc981"/> <path d="M1000 2001a124 124 0 0 0-109 65 118 118 0 0 0 218 0 124 124 0 0 0-109-65Z" fill="#f5cc14"/> <path class="rf" d="M963 1414h74l42 899H921l42-899z"/> <rect class="c" x="952" y="1567" width="97" height="7" rx="4"/> <rect class="c" x="950" y="1605" width="100" height="7" rx="4"/> <rect class="c" x="949" y="1642" width="103" height="7" rx="4"/> <rect class="c" x="947" y="1679" width="106" height="7" rx="4"/> <rect class="c" x="945" y="1717" width="111" height="7" rx="4"/> <rect class="c" x="944" y="1754" width="113" height="7" rx="4"/> <rect class="c" x="942" y="1791" width="117" height="7" rx="4"/> <rect class="c" x="940" y="1829" width="119" height="7" rx="4"/> <rect class="c" x="939" y="1866" width="123" height="7" rx="4"/> <rect class="c" x="937" y="1903" width="127" height="7" rx="4"/> <rect class="c" x="935" y="1941" width="132" height="7" rx="4"/> <path class="rf" d="m824 2337 168 232c-99-138-17-152-6-157l-38-17c-12 5-53 21-124-58Z"/> <path class="c" d="M896 2411c34 10 66-5 66-5a60 60 0 0 0-33 50Z"/> <path class="rf" d="m909 2419 16 23c6-17 12-23 12-23s-16 2-28 0Z"/> <path class="d" d="m896 2411 13 8m16 23 4 15m8-38a271 271 0 0 1 25-13"/> <path class="rf" d="m1176 2337-168 232c99-138 17-152 6-157l38-17c12 5 53 21 124-58Z"/> <path class="c" d="M1104 2411c-34 10-66-5-66-5a60 60 0 0 1 33 51Z"/> <path class="rf" d="m1091 2419-16 23c-6-17-12-23-12-23s16 2 28 0Z"/> <path class="d" d="m1104 2411-13 8m-16 23-4 15m-8-38a271 271 0 0 0-25-13"/> <circle class="c" cx="1000" cy="2334" r="82"/> <circle class="nf" cx="1000" cy="2334" r="75"/> <rect class="c" x="993" y="2252" width="15" height="164" rx="7"/> <use class="bl" width="114" height="65" transform="matrix(.91 0 0 1.82 948 1487)" href="#wb"/> <path class="b" d="M1000 2163a231 231 0 0 1-103-25l5-10a220 220 0 0 0 196-1l5 11a231 231 0 0 1-103 25Z"/> <path class="nf" d="m1078 2186-10-197c-34-10-106-10-135 0l-11 196Z"/> <use class="gr" width="114" height="65" transform="matrix(-1.5 0 0 -1.77 1085 2239)" href="#wb"/> <use class="gr" width="111" height="111" transform="rotate(90 -563 1474)" href="#wa"/> <use class="gr" width="111" height="111" transform="translate(1089 2036)" href="#wa"/>'
          : "",
        __input.handle2
          ? '<rect class="c" x="932" y="1407" width="135" height="7" rx="4"/> <path class="bf" d="M1060 1415c-56 187-41 540-3 673 34 118 28 165 3 225H940c-25-60-31-107 3-225 38-133 53-486-3-673Z"/> <rect class="c" x="968" y="1873" width="64" height="7" rx="4"/> <rect class="c" x="965" y="1910" width="70" height="7" rx="4"/> <rect class="c" x="962" y="1948" width="7" height="7" rx="4"/> <rect class="c" x="958" y="1985" width="85" height="7" rx="4"/> <rect class="c" x="952" y="2023" width="95" height="7" rx="4"/> <path class="b" d="M1042 1824a234 234 0 0 1-84 0l1-12a222 222 0 0 0 82 0Z"/> <path class="lb" d="M916 1755c-16 41 11 48 46 51l-4 26c-31-28-59-38-77 5 17-41-2-55-50-58l17-20c13 9 47 46 68-4Zm168 0c16 41-11 48-46 51l4 26c31-28 59-38 77 5-17-41 2-55 50-58l-17-20c-13 9-47 46-68-4Z"/> <circle class="bf" cx="1000" cy="2394.6" r="65.5"/> <path class="lb" d="M1000 2342c32 0 16-30 140-16-87-14-140-37-140-71 0 34-53 57-140 71 124-14 108 16 140 16Z"/> <rect class="lb" x="915" y="2375" width="170.5" height="38.3" rx="19.2"/> <path class="lb" d="M1000 2763c0-116 66-174 148-202l-18-56c-110 20-98-63-130-63s-20 83-130 63l-18 56c82 28 148 86 148 202Z"/> <path class="b" d="M1000 2662c4-8 27-73 124-113l-7-22c-34 5-92-5-117-66-25 61-83 71-117 66l-7 22c97 40 120 105 124 113Z"/> <path class="gf" d="M1000 2645c11-22 44-70 114-100l-3-10c-58 7-99-31-111-56-12 25-53 63-111 56l-3 10c71 30 103 78 114 100Zm-117-118 6 8m-13 14 10-4m114 100v18m111-128 6-8m-3 18 10 4m-124-88v18"/> <path class="b" d="M1000 2328s8-9 24-15c-16-8-24-16-24-16s-8 8-24 16c16 6 24 15 24 15Z"/> <path class="gf" d="m1000 2318 7-6-7-5-7 5 7 6z"/> <path class="a" d="M1000 2297v10m-7 5-17 1m24 5v10m7-16 17 1"/> <use class="bl" width="114" height="65" transform="matrix(-.6 0 0 -1.46 1034 1845)" href="#wb"/> <use class="bl" width="114" height="65" transform="matrix(1.2 0 0 1.17 932 2064)" href="#wb"/>'
          : "",
        __input.handle3
          ? '<path class="lbf" d="m1021 2313 35-899H942l38 899h41z"/> <rect class="g" x="932" y="1407" width="135" height="7" rx="4"/> <rect class="g" x="952" y="1724" width="96" height="7" rx="4"/> <rect class="g" x="953" y="1762" width="94" height="7" rx="4"/> <rect class="g" x="955" y="1800" width="91" height="7" rx="4"/> <rect class="g" x="957" y="1837" width="87" height="7" rx="4"/> <rect class="g" x="958" y="1875" width="84" height="7" rx="4"/> <rect class="g" x="960" y="1912" width="81" height="7" rx="4"/> <rect class="g" x="961" y="1950" width="78" height="7" rx="4"/> <rect class="g" x="963" y="1988" width="74" height="7" rx="4"/> <path class="g" d="M1108 2075a212 212 0 0 0-216 0l-4-8a221 221 0 0 1 225 1Z"/> <use class="db" width="114" height="65" transform="matrix(.7 0 0 1.46 961 2021)" href="#wb"/> <use class="db" width="114" height="65" transform="matrix(-1.01 0 0 -1 1058 1696)" href="#wb"/> <use width="211" height="420" transform="matrix(.2 .06 -.08 .26 1060 1982)" href="#c"/> <use width="211" height="420" transform="matrix(.18 .09 -.12 .25 1108 1997)" href="#c"/> <use width="211" height="420" transform="matrix(.2 -.06 .08 .26 900 1994)" href="#c"/> <use width="211" height="420" transform="matrix(.18 -.09 .12 .25 854 2016)" href="#c"/> <circle class="lbf" cx="1000" cy="2257" r="81"/> <path class="ef" d="M1000 2434c133 0 226-73 226-73l-87-120c45 63 21 99-39 118-60 20-100-3-100-56 0 53-39 76-100 56-59-19-84-55-39-118l-87 120s93 73 226 73Z"/> <path d="m825 2318-28 39s58 41 142 55c26-12 45-23 45-42-55 34-145-8-159-52Zm350 0 28 39s-58 41-141 55c-27-12-45-23-46-42 56 34 145-8 159-52Z" fill="#c3cdd7"/> <use width="346" height="148" transform="translate(827 2370)" href="#g"/> <path class="b" d="M1000 2471s14-19 51-28c-37-15-51-33-51-33s-13 18-51 33c37 9 51 28 51 28Z"/> <path d="M1000 2462c11-11 25-17 33-20a143 143 0 0 1-33-23 143 143 0 0 1-33 23c8 3 22 9 33 20Z" fill="#3a4757"/> <path class="b" d="m967 2442-18 1m51-24v-9m33 32 18 1m-51 19v10"/> <use width="48" height="90" transform="translate(976 2167)" href="#h"/> <use width="48" height="90" transform="rotate(90 -572 1662)" href="#h"/> <use width="48" height="90" transform="rotate(-90 1596 686)" href="#h"/> <use width="48" height="90" transform="rotate(180 512 1174)" href="#h"/>'
          : "",
        "</g>"
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