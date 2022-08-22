// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "./interfaces/Types.sol";
import "./interfaces/IConjuror.sol";
import "./Cauldron.sol";
import "./Incantation.sol";
import "base64-sol/base64.sol";

contract Conjuror is IConjuror {
  function generateWandURI(Wand memory wand, address owner)
    external
    pure
    override
    returns (string memory)
  {
    string memory name = Incantation.generate(wand.tokenId);

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name": "',
                name,
                '", "description":"A unique Wand, designed and built on-chain", "image": "data:image/svg+xml;base64,', // TODO: edit description
                Base64.encode(bytes(generateSVG(wand, name, owner))),
                '", "attributes": [',
                generateAttributes(wand),
                "]}"
              )
            )
          )
        )
      );
  }

  function generateAttributes(Wand memory wand)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type": "Level", "value": ',
          SolidMustacheHelpers.uintToString(wand.level, 0),
          '},{"trait_type": "Evolution", "value": ',
          SolidMustacheHelpers.uintToString(wand.xp, 0),
          '},{"trait_type": "Birth", "display_type": "date", "value": ',
          SolidMustacheHelpers.uintToString(wand.birth, 0),
          "}"
        )
      );
  }

  function generateSVG(
    Wand memory wand,
    string memory name,
    address owner
  ) internal pure returns (string memory svg) {
    // TODO should xpCap be pulled from the forge?
    uint32 xpCap = 10000;
    return
      Cauldron.render(
        Cauldron.__Input({
          background: wand.background,
          seed: uint16(uint256(keccak256(abi.encodePacked(owner)))), // use a 16-bit hash of the owner address,
          planets: scalePlanets(wand.planets),
          aspects: scaleAspects(wand.aspects),
          handle: wand.handle,
          xp: Cauldron.Xp({
            cap: xpCap,
            amount: wand.xp,
            crown: wand.xp >= xpCap
          }),
          stone: interpolateStone(wand.stone),
          halo: wand.halo,
          frame: generateFrame(wand, name),
          sparkles: generateSparkles(wand.tokenId),
          filterLayers: generateFilterLayers()
        })
      );
  }

  function generateFrame(Wand memory wand, string memory name)
    internal
    pure
    returns (Cauldron.Frame memory)
  {
    return
      Cauldron.Frame({
        level1: wand.level == 0,
        level2: wand.level == 1,
        level3: wand.level == 2,
        level4: wand.level == 3,
        level5: wand.level == 4,
        title: name
      });
  }

  function generateFilterLayers()
    internal
    pure
    returns (Cauldron.FilterLayer[3] memory)
  {
    return [
      Cauldron.FilterLayer({
        blurX: 19,
        blurY: 17,
        dispScale: 77,
        lightColor: Cauldron.Color({hue: 0, saturation: 0, lightness: 100}),
        opacity: 20,
        pointX: -493,
        pointY: 514,
        pointZ: 104,
        specConstant: 819,
        specExponent: 4,
        surfaceScale: -7,
        turbBlur: 54,
        turbFreqX: 17,
        turbFreqY: 17,
        turbOct: 1,
        fractalNoise: true
      }),
      Cauldron.FilterLayer({
        blurX: 19,
        blurY: 17,
        dispScale: 90,
        lightColor: Cauldron.Color({hue: 0, saturation: 0, lightness: 100}),
        opacity: 25,
        pointX: -139,
        pointY: 514,
        pointZ: 104,
        specConstant: 762,
        specExponent: 4,
        surfaceScale: -11,
        turbBlur: 76,
        turbFreqX: 1,
        turbFreqY: 9,
        turbOct: 1,
        fractalNoise: true
      }),
      Cauldron.FilterLayer({
        blurX: 19,
        blurY: 17,
        dispScale: 88,
        lightColor: Cauldron.Color({hue: 58, saturation: 100, lightness: 94}),
        opacity: 34,
        pointX: -493,
        pointY: 514,
        pointZ: 104,
        specConstant: 359,
        specExponent: 3,
        surfaceScale: 157,
        turbBlur: 73,
        turbFreqX: 19,
        turbFreqY: 19,
        turbOct: 1,
        fractalNoise: true
      })
    ];
  }

  function generateSparkles(uint256 tokenId)
    internal
    pure
    returns (Cauldron.Sparkle[] memory result)
  {
    uint256 seed = uint256(keccak256(abi.encodePacked(tokenId)));
    uint256 sparkleCount = 4 + (seed % 4);
    result = new Cauldron.Sparkle[](sparkleCount);
    for (uint256 i = 0; i < sparkleCount; i++) {
      result[i] = Cauldron.Sparkle({
        tx: uint16(
          1820 - (uint256(keccak256(abi.encodePacked(seed + 3 * i + 0))) % 1640)
        ),
        ty: uint16(
          1880 - (uint256(keccak256(abi.encodePacked(seed + 3 * i + 1))) % 1640)
        ),
        scale: uint8(
          30 + (uint256(keccak256(abi.encodePacked(seed + 3 * i + 2))) % 70)
        )
      });
    }
    return result;
  }

  function scalePlanets(Planet[8] memory planets)
    internal
    pure
    returns (Cauldron.Planet[8] memory result)
  {
    for (uint256 i = 0; i < 8; i++) {
      result[i].visible = planets[i].visible;
      result[i].x = int16((int256(planets[i].x) * 520) / 127);
      result[i].y = int16((int256(planets[i].y) * 520) / 127);
    }
  }

  function scaleAspects(Aspect[8] memory aspects)
    internal
    pure
    returns (Cauldron.Aspect[8] memory result)
  {
    for (uint256 i = 0; i < 8; i++) {
      result[i].x1 = int16((int256(aspects[i].x1) * 260) / 127);
      result[i].y1 = int16((int256(aspects[i].y1) * 260) / 127);
      result[i].x2 = int16((int256(aspects[i].x2) * 260) / 127);
      result[i].y2 = int16((int256(aspects[i].y2) * 260) / 127);
    }
  }

  function interpolateStone(uint16 stoneId)
    internal
    pure
    returns (Cauldron.Stone memory)
  {
    (uint8 from, uint8 to, uint8 progress) = interpolationParams(stoneId);
    Cauldron.Stone memory fromStone = stoneList()[from];
    Cauldron.Stone memory toStone = stoneList()[to];
    return
      Cauldron.Stone({
        turbFreqX: interpolateUInt8Value(
          fromStone.turbFreqX,
          toStone.turbFreqX,
          progress
        ),
        turbFreqY: interpolateUInt8Value(
          fromStone.turbFreqY,
          toStone.turbFreqY,
          progress
        ),
        turbOct: interpolateUInt8Value(
          fromStone.turbOct,
          toStone.turbOct,
          progress
        ),
        redAmp: interpolateInt8Value(
          fromStone.redAmp,
          toStone.redAmp,
          progress
        ),
        redExp: interpolateInt8Value(
          fromStone.redExp,
          toStone.redExp,
          progress
        ),
        redOff: interpolateInt8Value(
          fromStone.redOff,
          toStone.redOff,
          progress
        ),
        greenAmp: interpolateInt8Value(
          fromStone.greenAmp,
          toStone.greenAmp,
          progress
        ),
        greenExp: interpolateInt8Value(
          fromStone.greenExp,
          toStone.greenExp,
          progress
        ),
        greenOff: interpolateInt8Value(
          fromStone.greenOff,
          toStone.greenOff,
          progress
        ),
        blueAmp: interpolateInt8Value(
          fromStone.blueAmp,
          toStone.blueAmp,
          progress
        ),
        blueExp: interpolateInt8Value(
          fromStone.blueExp,
          toStone.blueExp,
          progress
        ),
        blueOff: interpolateInt8Value(
          fromStone.blueOff,
          toStone.blueOff,
          progress
        ),
        fractalNoise: progress < 50
          ? fromStone.fractalNoise
          : toStone.fractalNoise,
        rotation: interpolateUInt16Value(
          fromStone.rotation,
          toStone.rotation,
          progress
        )
      });
  }

  function interpolationParams(uint16 stone)
    internal
    pure
    returns (
      uint8 from,
      uint8 to,
      uint8 progress
    )
  {
    uint256 angle = uint256(stone) * 1000;
    uint256 step = (3600 * 1000) / stoneList().length;
    from = uint8(angle / step);
    uint256 midway = step * from + step / 2;

    if (angle < midway) {
      // going left
      to = prevStone(from);
      progress = uint8(round1(((midway - angle) * 1000) / step));
    } else {
      // going right
      to = nextStone(from);
      progress = uint8(round1(((angle - midway) * 1000) / step));
    }
  }

  function prevStone(uint8 index) private pure returns (uint8) {
    return (index > 0 ? index - 1 : uint8(stoneList().length - 1));
  }

  function nextStone(uint8 index) private pure returns (uint8) {
    return (index + 1) % uint8(stoneList().length);
  }

  function round1(uint256 number) internal pure returns (uint256) {
    return number / 10 + ((number % 10) >= 5 ? 1 : 0);
  }

  function interpolateUInt8Value(
    uint8 from,
    uint8 to,
    uint8 progress
  ) internal pure returns (uint8) {
    return
      uint8(uint256(interpolateValue(int8(from), int8(to), int8(progress))));
  }

  function interpolateUInt16Value(
    uint16 from,
    uint16 to,
    uint8 progress
  ) internal pure returns (uint16) {
    return
      uint16(uint256(interpolateValue(int16(from), int16(to), int8(progress))));
  }

  function interpolateInt8Value(
    int8 from,
    int8 to,
    uint8 progress
  ) internal pure returns (int8) {
    return int8(interpolateValue(from, to, int8(progress)));
  }

  function interpolateValue(
    int256 from,
    int256 to,
    int256 progress
  ) internal pure returns (int256) {
    if (from > to) {
      return from - ((from - to) * progress) / 100;
    } else {
      return from + ((to - from) * progress) / 100;
    }
  }

  function stoneList() internal pure returns (Cauldron.Stone[29] memory) {
    return [
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 2,
        turbFreqY: 1,
        turbOct: 3,
        redAmp: 90,
        redExp: 15,
        redOff: -69,
        greenAmp: 66,
        greenExp: -24,
        greenOff: -23,
        blueAmp: 11,
        blueExp: -85,
        blueOff: -16,
        rotation: 218
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 2,
        turbFreqY: 2,
        turbOct: 3,
        redAmp: 12,
        redExp: 30,
        redOff: 9,
        greenAmp: -16,
        greenExp: -88,
        greenOff: 71,
        blueAmp: 58,
        blueExp: -39,
        blueOff: 76,
        rotation: 216
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 2,
        turbFreqY: 4,
        turbOct: 3,
        redAmp: 30,
        redExp: -74,
        redOff: -56,
        greenAmp: 62,
        greenExp: -52,
        greenOff: -68,
        blueAmp: 12,
        blueExp: -32,
        blueOff: -6,
        rotation: 21
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 8,
        turbFreqY: 7,
        turbOct: 3,
        redAmp: 60,
        redExp: -56,
        redOff: -48,
        greenAmp: 74,
        greenExp: -52,
        greenOff: -36,
        blueAmp: 78,
        blueExp: 48,
        blueOff: 46,
        rotation: 43
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 6,
        turbFreqY: 3,
        turbOct: 3,
        redAmp: -32,
        redExp: -39,
        redOff: -48,
        greenAmp: 42,
        greenExp: -36,
        greenOff: -19,
        blueAmp: 39,
        blueExp: 18,
        blueOff: 12,
        rotation: 43
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 6,
        turbFreqY: 3,
        turbOct: 3,
        redAmp: 14,
        redExp: -70,
        redOff: -12,
        greenAmp: 29,
        greenExp: -92,
        greenOff: -38,
        blueAmp: 79,
        blueExp: -72,
        blueOff: -63,
        rotation: 310
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 2,
        turbFreqY: 2,
        turbOct: 3,
        redAmp: 72,
        redExp: -92,
        redOff: -34,
        greenAmp: -43,
        greenExp: -30,
        greenOff: 78,
        blueAmp: -75,
        blueExp: -39,
        blueOff: 76,
        rotation: 114
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 0,
        turbFreqY: 4,
        turbOct: 3,
        redAmp: 9,
        redExp: -100,
        redOff: 30,
        greenAmp: 5,
        greenExp: -98,
        greenOff: 64,
        blueAmp: 41,
        blueExp: -65,
        blueOff: -79,
        rotation: 56
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 5,
        turbFreqY: 3,
        turbOct: 1,
        redAmp: 79,
        redExp: -51,
        redOff: -61,
        greenAmp: -12,
        greenExp: -77,
        greenOff: 51,
        blueAmp: 45,
        blueExp: 100,
        blueOff: 14,
        rotation: 86
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 2,
        turbFreqY: 2,
        turbOct: 1,
        redAmp: 33,
        redExp: -51,
        redOff: -90,
        greenAmp: -23,
        greenExp: -96,
        greenOff: 35,
        blueAmp: 47,
        blueExp: -51,
        blueOff: 82,
        rotation: 43
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 7,
        turbFreqY: 2,
        turbOct: 2,
        redAmp: 8,
        redExp: 14,
        redOff: 3,
        greenAmp: 64,
        greenExp: -42,
        greenOff: -68,
        blueAmp: 99,
        blueExp: 100,
        blueOff: 17,
        rotation: 69
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 3,
        turbFreqY: 3,
        turbOct: 6,
        redAmp: 48,
        redExp: -71,
        redOff: -90,
        greenAmp: 26,
        greenExp: -60,
        greenOff: -31,
        blueAmp: -87,
        blueExp: -87,
        blueOff: -89,
        rotation: 43
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 1,
        turbFreqY: 4,
        turbOct: 4,
        redAmp: 77,
        redExp: -100,
        redOff: 55,
        greenAmp: 9,
        greenExp: -97,
        greenOff: -4,
        blueAmp: -10,
        blueExp: -65,
        blueOff: -81,
        rotation: 244
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 3,
        turbFreqY: 9,
        turbOct: 2,
        redAmp: 100,
        redExp: 1,
        redOff: -11,
        greenAmp: 41,
        greenExp: -93,
        greenOff: -96,
        blueAmp: 33,
        blueExp: -88,
        blueOff: -100,
        rotation: 43
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 4,
        turbFreqY: 7,
        turbOct: 2,
        redAmp: 69,
        redExp: -43,
        redOff: 16,
        greenAmp: 61,
        greenExp: -66,
        greenOff: -63,
        blueAmp: 58,
        blueExp: 1,
        blueOff: -15,
        rotation: 306
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 16,
        turbFreqY: 9,
        turbOct: 3,
        redAmp: -44,
        redExp: 78,
        redOff: -22,
        greenAmp: 54,
        greenExp: 72,
        greenOff: 5,
        blueAmp: 57,
        blueExp: 71,
        blueOff: -4,
        rotation: 329
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 7,
        turbFreqY: 6,
        turbOct: 1,
        redAmp: 4,
        redExp: -57,
        redOff: -9,
        greenAmp: -51,
        greenExp: -12,
        greenOff: 51,
        blueAmp: 24,
        blueExp: -83,
        blueOff: -80,
        rotation: 31
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 4,
        turbFreqY: 0,
        turbOct: 3,
        redAmp: -2,
        redExp: -94,
        redOff: -22,
        greenAmp: 19,
        greenExp: -79,
        greenOff: 18,
        blueAmp: 42,
        blueExp: -61,
        blueOff: -70,
        rotation: 56
      }),
      Cauldron.Stone({
        fractalNoise: false,
        turbFreqX: 1,
        turbFreqY: 4,
        turbOct: 4,
        redAmp: 46,
        redExp: -98,
        redOff: -87,
        greenAmp: 39,
        greenExp: -61,
        greenOff: -39,
        blueAmp: -30,
        blueExp: -32,
        blueOff: -6,
        rotation: 48
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 34,
        turbFreqY: 6,
        turbOct: 3,
        redAmp: 17,
        redExp: -18,
        redOff: 91,
        greenAmp: 50,
        greenExp: -44,
        greenOff: -21,
        blueAmp: 58,
        blueExp: -82,
        blueOff: -36,
        rotation: 75
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 8,
        turbFreqY: 2,
        turbOct: 1,
        redAmp: 34,
        redExp: -31,
        redOff: 29,
        greenAmp: 56,
        greenExp: -57,
        greenOff: -82,
        blueAmp: 68,
        blueExp: 51,
        blueOff: -80,
        rotation: 295
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 6,
        turbFreqY: 2,
        turbOct: 3,
        redAmp: 43,
        redExp: -66,
        redOff: 12,
        greenAmp: 100,
        greenExp: 93,
        greenOff: -33,
        blueAmp: 100,
        blueExp: 86,
        blueOff: -26,
        rotation: 304
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 3,
        turbFreqY: 5,
        turbOct: 5,
        redAmp: -2,
        redExp: -76,
        redOff: 31,
        greenAmp: 72,
        greenExp: 80,
        greenOff: -32,
        blueAmp: 92,
        blueExp: 79,
        blueOff: 67,
        rotation: 37
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 2,
        turbFreqY: 6,
        turbOct: 5,
        redAmp: 0,
        redExp: -76,
        redOff: 47,
        greenAmp: 81,
        greenExp: 30,
        greenOff: -54,
        blueAmp: -60,
        blueExp: 79,
        blueOff: 36,
        rotation: 147
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 7,
        turbFreqY: 5,
        turbOct: 3,
        redAmp: 66,
        redExp: 86,
        redOff: -28,
        greenAmp: -9,
        greenExp: -77,
        greenOff: -4,
        blueAmp: 30,
        blueExp: 5,
        blueOff: -16,
        rotation: 35
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 5,
        turbFreqY: 4,
        turbOct: 4,
        redAmp: 40,
        redExp: -51,
        redOff: -61,
        greenAmp: -19,
        greenExp: -77,
        greenOff: 42,
        blueAmp: -64,
        blueExp: 6,
        blueOff: 76,
        rotation: 242
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 17,
        turbFreqY: 9,
        turbOct: 3,
        redAmp: 64,
        redExp: -76,
        redOff: -10,
        greenAmp: -13,
        greenExp: -88,
        greenOff: 63,
        blueAmp: 57,
        blueExp: -99,
        blueOff: 1,
        rotation: 190
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 4,
        turbFreqY: 4,
        turbOct: 7,
        redAmp: 39,
        redExp: -100,
        redOff: -39,
        greenAmp: 38,
        greenExp: -52,
        greenOff: -53,
        blueAmp: 32,
        blueExp: -93,
        blueOff: 48,
        rotation: 2
      }),
      Cauldron.Stone({
        fractalNoise: true,
        turbFreqX: 4,
        turbFreqY: 9,
        turbOct: 3,
        redAmp: -59,
        redExp: -76,
        redOff: -10,
        greenAmp: 18,
        greenExp: -88,
        greenOff: 4,
        blueAmp: 66,
        blueExp: -99,
        blueOff: -52,
        rotation: 111
      })
    ];
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "../Cauldron.sol";

struct Aspect {
  int8 x1;
  int8 y1;
  int8 x2;
  int8 y2;
}

struct Planet {
  bool visible;
  int8 x;
  int8 y;
}

struct Wand {
  uint256 tokenId;
  uint64 birth;
  uint16 stone;
  Cauldron.Halo halo;
  Cauldron.Handle handle;
  Cauldron.Background background;
  Planet[8] planets;
  Aspect[8] aspects;
  uint32 xp;
  uint32 level;
}

struct PackedWand {
  // order matters !!
  uint64 background;
  uint64 birth;
  uint128 planets;
  uint256 aspects;
  // background
  uint16 stone;
  uint16 halo;
  uint8 visibility;
  uint8 handle;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./Types.sol";

interface IConjuror {
  function generateWandURI(Wand memory wand, address owner)
    external
    view
    returns (string memory);
}

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

library Incantation {
  function generate(uint256 seed) public pure returns (string memory) {
    string[83] memory actions = [
      "ANIMATE",
      "WINGING",
      "INCREASING",
      "SPIRALING",
      "SPROUTING",
      "EMERGING",
      "SUBSIDING",
      "FLAPPING",
      "PLUMED",
      "GESTURING",
      "SWELLING",
      "COLLAPSING",
      "SPREADING",
      "DESCENDING",
      "FREE",
      "SHIFTING",
      "LIGHT",
      "DIMINISHING",
      "EBBING",
      "THRIVING",
      "BUDDING",
      "VIABLE",
      "CRESCENT",
      "ROAMING",
      "TUMBLING",
      "ADRIFT",
      "MIGRATING",
      "GLIDING",
      "STEPPING",
      "SINKING",
      "AERIAL",
      "HOVERING",
      "LIVING",
      "EXPRESS",
      "WANING",
      "LOWERING",
      "AUGMENTING",
      "GROWING",
      "SAILING",
      "SOARING",
      "DRIFTING",
      "WAVING",
      "HOLLOW",
      "SURGING",
      "SLIDING",
      "SWIMMING",
      "MUSHROOMING",
      "FLYING",
      "EXPANDING",
      "BURGEONING",
      "DECREASING",
      "CLIMBING",
      "FLUTTERING",
      "LOOSE",
      "INFLATED",
      "STREAMING",
      "ASCENDING",
      "VOYAGING",
      "ADVANCING",
      "VOLATILE",
      "LOFTY",
      "FLOATING",
      "SETTLING",
      "TOTTERING",
      "ASCENDING",
      "SWOOPING",
      "ZOOMING",
      "AMPLIFYING",
      "TOWERING",
      "PLUNGING",
      "STIRRING",
      "FLOURISHING",
      "ELEVATED",
      "STRETCHING",
      "FLEET",
      "CHANGING",
      "MOBILE",
      "WAFTING",
      "MATURING",
      "DEVELOPING",
      "SLIPPING",
      "ENLARGING",
      "WAXING"
    ];
    string[84] memory adjectives = [
      "INFLAMED",
      "BURNISHED",
      "GLEAMING",
      "ILLUMINATED",
      "VAPOROUS",
      "VIVID",
      "SUNLIT",
      "BLAZING",
      "CLOUDED",
      "OPAQUE",
      "SPIRITED",
      "ENVELOPED",
      "GLOWING",
      "FIERCE",
      "MARSHY",
      "FLAMING",
      "ALIGHT",
      "NATURAL",
      "LEADEN",
      "FEVERISH",
      "PHOSPHORESCENT",
      "SHIMMERING",
      "FLASHING",
      "IGNEOUS",
      "ROUGH",
      "OBSCURE",
      "OVERCAST",
      "SHROUDED",
      "NUBILOUS",
      "SUNNY",
      "COARSE",
      "EMULSIFIED",
      "HEATED",
      "FULGENT",
      "AQUEOUS",
      "NEBULOUS",
      "RADIANT",
      "INCANDESCENT",
      "TWINKLING",
      "MOONLIT",
      "SILVERY",
      "BEAMING",
      "ABLAZE",
      "GOLDEN",
      "SPARKLING",
      "ROBUST",
      "POLISHED",
      "BURNING",
      "MIRRORLIKE",
      "LUSTROUS",
      "SULLEN",
      "FLARING",
      "BRILLIANT",
      "LIGHTED",
      "FOGGY",
      "FEBRILE",
      "INDEFINITE",
      "GLITTERING",
      "GLOOMY",
      "DENSE",
      "MUCKY",
      "DUSKY",
      "SUNLESS",
      "HEAVY",
      "FERVID",
      "CLOUDY",
      "DAZZLING",
      "BLURRED",
      "MURKY",
      "RESPLENDENT",
      "GLOSSY",
      "SOMBER",
      "FIERY",
      "GLISTENING",
      "DAMP",
      "GLARING",
      "AGLOW",
      "MISTY",
      "FUZZY",
      "INTENSE",
      "AURORAL",
      "LUMINOUS",
      "BLEARY",
      "HAZY"
    ];
    string[85] memory nouns = [
      "HOOP",
      "BOWL",
      "SCUD",
      "EARTH",
      "HEAVENS",
      "CIRCUIT",
      "ROUND",
      "AZURE",
      "HAZE",
      "VEIL",
      "GATEWAY",
      "FROST",
      "EMPYREAN",
      "MIST",
      "STAR",
      "DISK",
      "COSMOS",
      "PERIPHERY",
      "PRESSURE",
      "SMOKE",
      "POTHER",
      "WORLD",
      "COLURE",
      "ORB",
      "EQUATOR",
      "STEAM",
      "CORONA",
      "SMOG",
      "REVOLUTION",
      "OPENING",
      "NEBULA",
      "TERRENE",
      "MURK",
      "HAZINESS",
      "CREATION",
      "COIL",
      "FILM",
      "ECLIPTIC",
      "ORBIT",
      "PUFF",
      "CLOUD",
      "UNIVERSE",
      "COMPASS",
      "OBSCURITY",
      "SKY",
      "BAND",
      "ASTEROID",
      "GLOBE",
      "GLOOM",
      "HEAVENS",
      "ETHER",
      "ENCLOSURE",
      "DARKNESS",
      "HOROSCOPE",
      "AUREOLE",
      "DISC",
      "LID",
      "FOGGINESS",
      "DIMNESS",
      "BELT",
      "ASTROMETRY",
      "GALAXY",
      "ENTRY",
      "WHEEL",
      "HALO",
      "CIRQUE",
      "OVERCAST",
      "MERIDIAN",
      "HORIZON",
      "VAPOR",
      "MACROCOSM",
      "RING",
      "NATURE",
      "BILLOW",
      "DOORWAY",
      "SPHERE",
      "PERIMETER",
      "GATE",
      "ENTRANCE",
      "CIRCLET",
      "CROWN",
      "FOG",
      "MICROCOSM",
      "CYCLE",
      "VAULT"
    ];
    string memory action = actions[seed % actions.length];
    string memory adjective = adjectives[seed % adjectives.length];
    string memory noun = nouns[seed % nouns.length];

    return string(abi.encodePacked(action, " ", adjective, " ", noun));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}