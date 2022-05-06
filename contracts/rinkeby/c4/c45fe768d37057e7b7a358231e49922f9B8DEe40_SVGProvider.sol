//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Params } from "./Params.sol";
import { NFTSVG } from "./NFTSVG.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract SVGProvider {
  Params.Character[] public CHARACTERS_T;

  Params.Character[] public CHARACTERS_R;

  Params.Character[] public CHARACTERS_U;

  Params.Character[] public CHARACTERS_H;

  Params.Character[] public CHARACTERS_DOT;

  Params.Character[] public CHARACTERS_A;

  Params.Character[] public CHARACTERS_F;

  constructor() {
    CHARACTERS_T.push(Params.Character({ path: "M0,48H48V64H32v96H16V64H0Z", width: 48 }));
    CHARACTERS_T.push(Params.Character({ path: "M56,128v16H48v16H24V144H16V96H0V80H16V48H32V80H48V96H32v48h8V128Z", width: 56 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80v32H40v48H24V112H0V80H24V32H40V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M40,80v32H16v48H0V32H16V80Z", width: 40 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,48H8V32H40V48h8V64H32V48H16V64H0Zm32,96H16V64H32Z", width: 48 }));
    CHARACTERS_T.push(Params.Character({ path: "M8,48H24V80h8V96H24v48H56v16H8V112H0V96H8Z", width: 56 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,96V80H16V48H32V80H48V96H32v32H16V96Z", width: 48 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80H0V64H64ZM24,160H16V128H0V112H24Zm40-32H48v32H40V112H64Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M16,64V32h8V80H0V64Zm8,96H16V128H0V112H24ZM64,80H40V32h8V64H64Zm0,48H48v32H40V112H64Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80v32H40v48H24V112H0V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80v32H40v48H24V112H0V80H24V32H40V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80V96H40v16H64v16H40v32H24V128H0V112H24V96H0V80H24V32H40V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,96V80H64V96Zm0,32V112H64v16H40v32H24V128Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,160V32H32V64H64V96H32v32H64v32Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,32H64V160H0ZM56,96V80H40V48H24V80H8V96H24v32H40V96Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,32H64V160H0Zm56,96H40V80H56V64H40V48H24V64H8V80H24v48h8v16H56Z", width: 64 }));

    CHARACTERS_R.push(Params.Character({ path: "M0,48H40V64h8V96H40v16H32v16h8v16h8v16H32V144H24V128H16v32H0ZM32,64H16V96H32Z", width: 48 }));
    CHARACTERS_R.push(Params.Character({ path: "M0,160V80H40V96h8v16H32V96H16v64Z", width: 48 }));
    CHARACTERS_R.push(Params.Character({ path: "M0,32H64V96H32V64H0Zm0,96V96H32v32Zm64,32H32V128H64Z", width: 64 }));
    CHARACTERS_R.push(Params.Character({ path: "M48,64V80H8v80H0V64Zm0,64H32v32H24V112H48Z", width: 48 }));
    CHARACTERS_R.push(Params.Character({ path: "M0,160V96H64v32H32v32Z", width: 64 }));
    CHARACTERS_R.push(Params.Character({ path: "M40,80H16v32H8v16H32v16h8v16H16V144H8v16H0V64H8V48h8V32H40Z", width: 40 }));
    CHARACTERS_R.push(Params.Character({ path: "M8,64v48H0V64Zm8-16V64H8V48ZM8,128V112h8v16ZM40,32V48H16V32ZM32,96H24v16H16V64H40V80H32Zm8,32v16H16V128Zm0-32v16H32V96Zm8-32H40V48h8Zm0,48v16H40V112Zm8,0H48V64h8Z", width: 56 }));
    CHARACTERS_R.push(Params.Character({ path: "M40,80v32H16v48H0V80Z", width: 40 }));

    CHARACTERS_U.push(Params.Character({ path: "M0,48H16v80H32V48H48v80H40v16H32v16H16V144H8V128H0Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M48,144H40v16H8V144H0V80H16v64H32V80H48Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M0,32H64V160H0ZM8,48V80h8v32h8v32H40V112h8V80h8V48Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M40,80H32V64H8V80H0V48H40ZM8,80h8v32H8Zm16,64H16V112h8Zm8-32H24V80h8Z", width: 40 }));
    CHARACTERS_U.push(Params.Character({ path: "M56,112v16H48v16H40v16H24V144H16V128H8V112H0V80H8V64h8V48h8V32H40V64H32V80H24v32H40V96h8V80H64v32Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M56,112v16H48v16H40v16H24V144H16V128H8V112H0V80H16V96h8v16H40V80H32V64H24V32H40V48h8V64h8V80h8v32Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M56,112v16H48v16H40v16H24V144H16V128H8V112H0V80H16V96h8v16H40V96h8V80H64v32Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M48,128H40v16H32v16H16V144H8V128H0V80H16v48H32V80H48Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M0,48H16v80H32V48H48v80H40v16H32v16H16V144H8V128H0Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M48,160H8V144H0V80H16v64H32V80H48Z", width: 48 }));

    CHARACTERS_H.push(Params.Character({ path: "M48,48V160H32V112H16v48H0V48H16V96H32V48Z", width: 48 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,48H16V80H40V96h8v64H32V96H16v64H0Z", width: 48 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,48H16V64H32V48H48V160H32V144H16v16H0ZM16,96H32V80H16Zm0,16v16H32V112Z", width: 48 }));
    CHARACTERS_H.push(Params.Character({ path: "M8,48H24V80H40V48H56V80h8V96H56v16h8v16H56v32H40V128H24v32H8V128H0V112H8V96H0V80H8Zm16,64H40V96H24Z", width: 64 }));
    CHARACTERS_H.push(Params.Character({ path: "M8,32V48h8V64h8V80H40V64h8V48h8V32h8V160H56V144H48V128H40V112H24v16H16v16H8v16H0V32Z", width: 64 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,32H8V160H0ZM23.88,80V32h-8V160h8V112H37.25v16H61.12v32h8V112H39.79V96H69.08V32h-8V80M77,32V160h8V32Z", width: 85 }));
    CHARACTERS_H.push(Params.Character({ path: "M23.94,128v32H16V112H59v48h-8V128M0,160H8V32H0ZM59,96V32h-8V80H23.94V32H16V96M67,32V160h8V32Z", width: 75 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,32H15.93V160H0Zm56.07,0V80H32.18v32H56.07v48H72V32Z", width: 72 }));

    CHARACTERS_DOT.push(Params.Character({ path: "M16,160H0V128H16Z", width: 16 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M16,144H0V112H16Z", width: 16 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M48,110H0V94H48Z", width: 48 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M0,64H16V80H0Zm16,66H0V114H16Z", width: 16 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M8,48H24V64H40V48H56V64H48V80H64V96H48v16h8v16H40V112H24v16H8V112h8V96H0V80H16V64H8Z", width: 64 }));

    CHARACTERS_A.push(Params.Character({ path: "M0,160V80H8V64h8V48H32V64h8V80h8v80H32V112H16v48ZM16,96H32V80H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M8,80H40V96h8v64H8V144H0V128H8V112H32V96H8Zm8,64H32V128H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M8,144H24V96H40v48H56V64H48V48H40V32H64V160H0V32H24V48H16V64H8ZM24,80V64H40V80Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,160H32V144H16v16H0V64H8V48h8V32H32V48h8V64h8ZM16,80v32H32V80Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V128H8V112h8V80H8V64h8V48h8V32H40V48h8V64h8V80H48v32h8v16h8v16H48V128H40V112H24v16H16v16ZM24,80H40V64H24Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,48H8V32H40V48h8V96H24V64h8V48H16v80H40v16H8V128H0Zm48,64v16H40V112Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,32H64V160H0ZM16,64V80H40V96H16v16H8v16h8v16H56V80H48V64Zm8,64V112H40v16Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,32H8V48H0ZM8,64h8V48H32V64h8V80h8v64H32V112H16v32H0V80H8Zm8,32H32V80H16ZM40,32h8V48H40Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,112H8V96H0V80H8V64H32V48H8V32H40V48h8ZM16,80V96H32V80Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V80H8V48h8V64H32V48h8V80h8v64H32V112H16v32ZM32,48H16V32H32ZM16,80V96H32V80Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,80v64H8V128H0V112H8V96H32V80H8V48h8V32H40V48h8V64H40V80ZM16,128H32V112H16ZM32,48H24V64h8Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M64,80v32H40v16H64v16H8V128H0V112H8V96H24V80H8V64H56V80ZM16,128h8V112H16ZM48,96V80H40V96Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M8,64h8V48H8V32H24V48h8V64h8V80h8v64H8V128H0V112H8V96H32V80H8Zm8,64H32V112H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,48H8V32H40V48h8V64H40V80h8v64H32V112H16v32H0V80H8V64H0Zm32,0H16V64H32ZM16,96H32V80H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,96H32V80H16V96H0V80H8V64h8V48H32V64h8V80h8Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,128h8v32H0V128H8V96h8V64h8V32h8V64h8V96h8Z", width: 56 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,112H32v16h8v16h8v16H32V144H16v16H0V144H8V128h8V112H0V96H8V80h8V64H32V80h8V96h8ZM8,64V48h8V64ZM32,32V48H16V32Zm0,16h8V64H32Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,128h8v32H0V128H8v16H48Zm-32,0H8V96h8Zm8-64V96H16V64Zm0-32h8V64H24ZM40,96H32V64h8Zm8,0v32H40V96Z", width: 56 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V128H8V112h8v16h8v16Zm56-16h8v16H32V128h8V112H16V96h8V80h8V96h8V80H32V64h8V48h8V32h8Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V64H8V48h8V32H48V48H40V80h8V96H40v32h8v16H24V96H16v48ZM16,80h8V64H16Z", width: 48 }));

    CHARACTERS_F.push(Params.Character({ path: "M0,48H48V64H16V96H32v16H16v48H0Z", width: 48 }));
    CHARACTERS_F.push(Params.Character({ path: "M8,160V112H0V96H8V64h8V48H40V64h8V80H32V64H24V96h8v16H24v48Z", width: 48 }));
    CHARACTERS_F.push(Params.Character({ path: "M40,80V96H8v64H0V80Zm0,48H24v32H16V112H40Z", width: 40 }));
    CHARACTERS_F.push(Params.Character({ path: "M40,80V96H16v16H40v16H16v32H0V80Z", width: 40 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,160V64H32V96H64v32H32v32ZM64,64H32V32H64Z", width: 64 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,32H64V160H0ZM56,96V80H40V64H56V48H32V64H24V80H16V96h8v48H40V96Z", width: 64 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,48H8V32H40V48h8V64H32V48H16V80h8V96h8v16H16V96H8V80H0Zm32,96H16V128H32Z", width: 48 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,144V128H8V112h8V96H8V80h8V64h8V48h8V80H48V96H32v16H24v16H48v16ZM48,48H32V32H48Zm8,16H48V48h8Zm0,48v16H48V112Z", width: 56 }));
  }

  function generateSVG(Params.SVGParams memory _params, bool _isFull) public view returns (string memory) {
    Params.Character[][8] memory characters;
    characters[0] = CHARACTERS_T;
    characters[1] = CHARACTERS_R;
    characters[2] = CHARACTERS_U;
    characters[3] = CHARACTERS_T;
    characters[4] = CHARACTERS_H;
    characters[5] = CHARACTERS_DOT;
    characters[6] = CHARACTERS_A;
    characters[7] = CHARACTERS_F;

    if (_isFull) {
      return
        string(
          abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
              NFTSVG.generateFullSVG(
                //
                characters,
                _params
              )
            )
          )
        );
    }

    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(
            NFTSVG.generateCoreSVG(
              //
              characters,
              _params
            )
          )
        )
      );
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Params {
  struct Character {
    bytes path;
    uint8 width;
  }

  struct FilterNoiseParams {
    bytes frequency;
    uint16 seed;
    uint8 duration;
    uint8 offset;
  }

  struct Color {
    uint8 scheme; // 1- 8
    uint8 palette;
    uint16 hue;
  }

  struct SVGParams {
    uint8 pattern_id;
    uint8[3] pixelate_id;
    Color color;
    FilterNoiseParams noise;
    uint8[8] character_ids;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Params } from "./Params.sol";
import { Combine } from "./Combine.sol";

library NFTSVG {
  function generateFullSVG(Params.Character[][8] memory _characters, Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">',
        bytes.concat(
          "<defs>", //
          generateStyles(),
          generateFilterDefs(_params),
          generateFilterNoise(_params), //
          "</defs>"
        ),
        bytes.concat(
          generateBackground(_params),
          generateFolder(_characters, _params.character_ids), //
          generateScreen(),
          generateTitle(_characters, _params.character_ids)
        ),
        "</svg>"
      );
  }

  function generateCoreSVG(Params.Character[][8] memory _characters, Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">',
        bytes.concat(
          "<defs>", //
          generateStyles(),
          generateFilterDefs(_params),
          "</defs>"
        ),
        bytes.concat(
          generateBackground(_params),
          generateFolder(_characters, _params.character_ids), //
          generateScreen(),
          generateTitle(_characters, _params.character_ids)
        ),
        "</svg>"
      );
  }

  function generateFilterDefs(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        generatePattern(_params),
        generateFilterPixelate(), // 
        generateExtractRGB(),
        generateFilterDSA(),
        generateFilterDSB(),
        generateFilterGrey(_params),
        generateFilterOverlay(_params)
      );
  }

  // updated
  function generateStyles() internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<style type="text/css">',
        bytes.concat(".colR{fill:#FF0000;}"), //
        bytes.concat(".colG{fill:#00FF00;}"), //
        bytes.concat(".colB{fill:#0000FF;}"), //
        "</style>"
      );
  }

  // updated
  function generatePattern(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    uint8 _id = _params.pattern_id % 12;
    string[12] memory path = [
      '<path d="M0 0h16v16H0zM32 0h16v16H32zM16 16h16v16H16zM48 16h16v16H48zM0 32h16v16H0zM32 32h16v16H32zM16 48h16v16H16zM48 48h16v16H48z"/>', //
      '<path d="M0 16h64v16H0zM0 48h64v16H0z"/><path d="M0 16h64v16H0zM0 48h64v16H0z"/><path d="M0 0h16v32H0zM32 16h16v48H32z"/>',
      '<path d="M16 0h16v64H16zM48 0h16v64H48z"/><path d="M0 32h64v16H0z"/>',
      '<path d="M0 0h16v16H0zM32 0h32v16H32zM16 16h16v16H16zM0 32h16v32H0zM32 32h32v32H32z"/>',
      '<path d="M0 0h16v16H0zM16 16h32v16H16z"/><path d="M16 16h16v32H16zM48 0h16v16H48zM0 48h16v16H0z"/>',
      '<path d="M16 16h32v32H16zM48 0h16v16H48zM0 48h16v16H0z"/>',
      '<path d="M0 16h32v16H0zM48 0h16v16H48zM0 48h16v16H0zM32 32h32v16H32z"/>',
      '<path d="M0 16h32v16H0zM32 0h16v48H32z"/><path d="M0 16h16v48H0zM32 32h32v16H32z"/>',
      '<path d="M0 0h64v16H0z"/><path d="M48 0h16v64H48zM16 32h16v16H16z"/>',
      '<path d="M0 0h16v16H0zM0 16h32v16H0zM0 32h48v16H0zM0 48h64v16H0z"/>',
      '<path d="M0 0h16v32H0zM32 0h16v64H32zM0 48h16v16H0zM48 0h16v16H48z"/>',
      '<path d="M0 0h16v16H0zM16 16h16v16H16zM0 48h16v16H0zM48 16h16v48H48z"/><path d="M32 48h32v16H32z"/>'
    ];

    return
      bytes.concat(
        bytes.concat('<pattern id="pattern" patternUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'), //
        '<g class="colG">',
        bytes(path[_id]),
        "</g>",
        "</pattern>"
      );
  }

  // updated
  function generateFilterPixelate() internal pure returns (bytes memory) {
    string[5][3] memory options = [
      ["7.5", "7.5", "15", "15", "7.5"], //
      ["15.5", "15.5", "31", "31", "15.5"],
      ["31", "31", "63", "63", "31"]
    ];
    bytes memory result;
    for (uint8 i = 0; i < 3; i++) {
      result = bytes.concat(
        result,
        bytes.concat('<filter id="FPL-', bytes(Strings.toString(i)), '" x="0" y="0">'),
        bytes.concat('<feFlood x="', bytes(options[i][0]), '" y="', bytes(options[i][1]), '" height="1" width="1"/>'), // dynamic
        bytes.concat('<feComposite height="', bytes(options[i][2]), '" width="', bytes(options[i][3]), '"/>'), // dynamic
        '<feTile result="a"/><feComposite in="SourceGraphic" in2="a" operator="in"/>',
        bytes.concat('<feMorphology operator="dilate" radius="', bytes(options[i][4]), '"/>'), // dynamic
        "</filter>"
      );
    }
    return result;
  }

  // updated
  function generateFilterNoise(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        bytes.concat('<filter id="FN" x="0" y="0" width="100%" height="100%">'),
        bytes.concat('<feTurbulence type="fractalNoise" baseFrequency="', _params.noise.frequency, '" seed="', bytes(Strings.toString(_params.noise.seed)), '" numOctaves="3"/>'), // dynamic
        '<feColorMatrix type="hueRotate" values="0">',
        bytes.concat('<animate attributeName="values" from="0" to="360" dur="', bytes(Strings.toString(_params.noise.duration)), '" repeatCount="indefinite"/>'), // dynamic
        "</feColorMatrix>",
        '<feComponentTransfer><feFuncR type="discrete" tableValues="0 1"/><feFuncG type="discrete" tableValues="0 0 1"/><feFuncB type="discrete" tableValues="0 1"/></feComponentTransfer>',
        bytes.concat('<feColorMatrix values="1 0 0 0 0 -1 1 0 0 0 -1 -1 1 0 0 1 1 1 0 0"/>'), //
        "</filter>"
      );
  }

  // updated
  function generateExtractRGB() internal pure returns (bytes memory) {
    bytes[3] memory ids = [bytes("R"), "G", "B"];
    bytes[3] memory colors = [bytes("1 0 0"), "0 1 0", "0 0 1"];
    bytes memory result;
    for (uint8 i = 0; i < 3; i++) {
      result = bytes.concat(
        result,
        bytes.concat('<filter id="FE-', ids[i], '" x="0" y="0" width="100%" height="100%">'), //
        bytes.concat('<feColorMatrix values="1 0 0 0 0 -1 1 0 0 0 -1 -1 1 0 0 ', colors[i], ' 0 0"/>'),
        "</filter>"
      );
    }
    return result;
  }

  // updated
  function generateFilterGrey(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    bytes memory values = Combine.getMatrixByPaletteAndOffset(_params.color.palette, _params.noise.offset);
    return
      bytes.concat(
        bytes.concat('<filter id="FG">'), //
        bytes.concat('<feColorMatrix values="', values, '"/>'),
        "</filter>"
      );
  }

  // updated
  function generateFilterOverlay(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    uint16[4] memory hues = Combine.getHuesByScheme(_params.color.scheme, _params.color.hue);
    uint8 palette = _params.color.palette % 3;
    bytes[3] memory sats = [bytes("40%"), "50%", "60%"];
    bytes[3] memory lits = [bytes("70%"), "70%", "60%"];
    bytes memory result;
    bytes memory hsl;

    for (uint8 i = 0; i < 4; i++) {
      hsl = bytes.concat("hsl(", bytes(Strings.toString(hues[i])), ",", sats[palette], ",", lits[palette], ")");
      result = bytes.concat(
        result,
        bytes.concat('<filter id="FCS-', bytes(Strings.toString(i + 1)), '" x="-20%" y="-20%" width="140%" height="140%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse">'), //
        bytes.concat('<feFlood flood-color="', hsl, '" flood-opacity="1" x="0%" y="0%" width="100%" height="100%" result="flood" />'),
        '<feBlend mode="color" x="0%" y="0%" width="100%" height="100%" in="flood" in2="SourceGraphic" result="blend" />',
        '<feComposite in="blend" in2="SourceAlpha" operator="in" x="0%" y="0%" width="100%" height="100%" result="composite" />'
        "</filter>"
      );
    }
    return result;
  }

  // updated
  function generateFilterDSA() internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<filter id="FDSA" x="0%" y="0%" width="140%" height="140%">', //
        bytes.concat(
          '<feDropShadow stdDeviation="0" dx="2" dy="0" flood-color="hsl(0,0%,60%)"/>'
          '<feDropShadow stdDeviation="0" dx="0" dy="2" flood-color="hsl(0,0%,60%)"/>',
          '<feDropShadow stdDeviation="0" dx="2" dy="0" flood-color="hsl(0,0%,40%)"/>',
          '<feDropShadow stdDeviation="0" dx="0" dy="2" flood-color="hsl(0,0%,40%)"/>',
          '<feDropShadow stdDeviation="0" dx="4" dy="0" flood-color="hsl(0,0%,20%)"/>',
          '<feDropShadow stdDeviation="0" dx="0" dy="4" flood-color="hsl(0,0%,20%)"/>',
          '<feDropShadow stdDeviation="0" dx="-2" dy="0" flood-color="hsl(0,0%,20%)"/>',
          '<feDropShadow stdDeviation="0" dx="0" dy="-2" flood-color="hsl(0,0%,20%)" result="dsOUT"/>'
        ),
        bytes.concat(
          '<feOffset dx="2" dy="2" height="100%" in="SourceGraphic" result="offset1"/>'
          '<feComposite in="SourceGraphic" in2="offset1" operator="out" width="100%" height="100%" result="composite1"/>'
          '<feColorMatrix type="matrix" values="1 0 0 0 0.791 0 1 0 0 0.791 0 0 1 0 0.791 0 0 0 1 0" in="composite1" result="colormatrix1"/>'
        ),
        '<feMerge result="merge1"><feMergeNode in="dsOUT" /><feMergeNode in="colormatrix1" /></feMerge></filter>'
      );
  }

  // updated
  function generateFilterDSB() internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<filter id="FDSB" x="-20%" y="-20%" width="140%" height="140%">'
        '<feDropShadow stdDeviation="0" dx="2" dy="0" flood-color="hsl(0,0%,60%)"/>',
        '<feDropShadow stdDeviation="0" dx="0" dy="2" flood-color="hsl(0,0%,60%)"/>',
        '<feDropShadow stdDeviation="0" dx="-2" dy="0" flood-color="hsl(0,0%,40%)"/>',
        '<feDropShadow stdDeviation="0" dx="0" dy="-2" flood-color="hsl(0,0%,40%)"/>',
        '<feDropShadow stdDeviation="0" dx="2" dy="0" flood-color="hsl(0,0%,80%)"/>',
        '<feDropShadow stdDeviation="0" dx="0" dy="2" flood-color="hsl(0,0%,80%)"/>',
        '<feDropShadow stdDeviation="0" dx="-2" dy="0" flood-color="hsl(0,0%,20%)"/>',
        '<feDropShadow stdDeviation="0" dx="0" dy="-2" flood-color="hsl(0,0%,20%)"/>',
        "</filter>"
      );
  }

  // updated
  function generateBackground(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    bytes memory tmp;
    {
      bytes[3] memory rgb = [bytes("R"), "G", "B"];
      for (uint8 i = 0; i < 3; i++) {
        tmp = bytes.concat(
          tmp, //
          bytes.concat('<g filter="url(#FDSA)">'),
          bytes.concat('<g filter="url(#FPL-', bytes(Strings.toString(_params.pixelate_id[i] % 3)), ')">'),
          bytes.concat('<g filter="url(#FE-', rgb[i], ')">'), // filter pixelate for bg
          bytes.concat('<rect x="0" y="0" width="100%" height="100%" filter="url(#FN)"/>'),
          "</g>",
          "</g>",
          "</g>"
        );
      }
    }

    return
      bytes.concat(
        bytes.concat('<g filter="url(#FCS-1)">'), //
        bytes.concat('<g filter="url(#FG)">'),
        bytes.concat('<rect width="100%" height="100%" class="colR"/>'),
        bytes.concat('<g filter="url(#FDSA)">'),
        bytes.concat('<rect width="100%" height="100%" fill="url(#pattern)" />'),
        "</g>",
        "</g>",
        '<g filter="url(#FG)">',
        tmp,
        "</g>",
        "</g>"
      );
  }

  // updated
  function generateFolder(Params.Character[][8] memory _characters, uint8[8] memory _charactersIds) internal pure returns (bytes memory) {
    uint8 pad = 47;
    uint8 gap = 12;
    uint16 translateX = 208;
    for (uint8 i = 0; i < 8; i++) {
      translateX += _characters[i][_charactersIds[i]].width + gap;
    }
    uint16 x3 = translateX + pad - gap;
    uint16 x2 = x3 - 16;
    uint16 x1 = x2 - 16;
    bytes memory corner = bytes.concat(
      //
      bytes(Strings.toString(x3)),
      " 320 ",
      bytes(Strings.toString(x3)),
      " 192 ",
      bytes(Strings.toString(x2)),
      " 192 ",
      bytes(Strings.toString(x2)),
      " 176 ",
      bytes(Strings.toString(x1)),
      " 176 ",
      bytes(Strings.toString(x1))
    );
    return
      bytes.concat(
        bytes.concat('<g filter="url(#FCS-2)">'), //
        '<g filter="url(#FG)">',
        '<g class="colG" filter="url(#FDSA)">',
        bytes.concat(
          '<polygon points="192 160 192 176 176 176 176 192 160 192 160 832 176 832 176 848 192 848 192 864 832 864 832 848 848 848 848 832 864 832 864 336 848 336 848 320 ', //
          corner,
          ' 160 192 160"/>'
        ),
        "</g>",
        "</g>",
        "</g>"
      );
  }

  // updated
  function generateScreen() internal pure returns (bytes memory) {
    return
      bytes.concat(
        bytes.concat('<g filter="url(#FCS-3)">'), //
        '<g filter="url(#FG)">',
        '<g class="colR" filter="url(#FDSB)">'
        '<rect x="208" y="368" width="608" height="448"/>',
        "</g>",
        "</g>",
        "</g>"
      );
  }

  // updated
  function generateTitle(Params.Character[][8] memory _characters, uint8[8] memory _charactersIds) internal pure returns (bytes memory) {
    uint8 gap = 12;
    uint16 translateX = 208;
    bytes memory truth;
    for (uint8 i = 0; i < 8; i++) {
      if (i > 0) {
        translateX += _characters[i - 1][_charactersIds[i - 1]].width + gap;
      }
      if (i == 7) {
        translateX -= gap;
      }
      truth = bytes.concat(truth, bytes.concat("<path", ' transform="translate(', bytes(Strings.toString(translateX)), ',183)" d="', _characters[i][_charactersIds[i]].path, '"/>'));
    }
    return
      bytes.concat(
        bytes.concat('<g filter="url(#FCS-4)">'), //
        '<g filter="url(#FG)">',
        '<g class="colB" filter="url(#FDSA)">',
        truth,
        "</g>",
        "</g>",
        "</g>"
      );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Combine {
  /**
  _scheme 1 - 8
  _baseHue 0 - 360
   */
  function getHuesByScheme(uint8 _scheme, uint16 _baseHue) internal pure returns (uint16[4] memory hues) {
    _scheme = (_scheme % 8) + 1;
    _baseHue = _baseHue % 361;
    if (_scheme == 1) {
      // Mono
      hues[0] = _baseHue;
      hues[1] = _baseHue;
      hues[2] = _baseHue;
      hues[3] = _baseHue;
    } else if (_scheme == 2) {
      // Duo Analogous
      hues[0] = _baseHue;
      hues[1] = _baseHue + 50;
      hues[2] = _baseHue;
      hues[3] = _baseHue;
    } else if (_scheme == 3) {
      // Duo Complimentary
      hues[0] = _baseHue;
      hues[1] = _baseHue + 180;
      hues[2] = _baseHue;
      hues[3] = _baseHue;
    } else if (_scheme == 4) {
      // Trio Analogous
      hues[0] = _baseHue;
      hues[1] = _baseHue + 50;
      hues[2] = _baseHue + 100;
      hues[3] = _baseHue + 100;
    } else if (_scheme == 5) {
      // Trio Triadic
      hues[0] = _baseHue;
      hues[1] = _baseHue + 120;
      hues[2] = _baseHue + 240;
      hues[3] = _baseHue + 240;
    } else if (_scheme == 6) {
      // Quad Analogous
      hues[0] = _baseHue;
      hues[1] = _baseHue + 50;
      hues[2] = _baseHue + 100;
      hues[3] = _baseHue + 150;
    } else if (_scheme == 7) {
      // Quad Complimentary
      hues[0] = _baseHue;
      hues[1] = _baseHue + 30;
      hues[2] = _baseHue + 180;
      hues[3] = _baseHue + 210;
    } else if (_scheme == 8) {
      // Quad Tetadic
      hues[0] = _baseHue;
      hues[1] = _baseHue + 60;
      hues[2] = _baseHue + 180;
      hues[3] = _baseHue + 240;
    }
  }

  /**
  _palete 1 - 3
  _offset 1 - 3
   */
  function getMatrixByPaletteAndOffset(uint8 _palette, uint8 _offset) internal pure returns (bytes memory) {
    _palette = _palette % 3;
    _offset = (_offset % 3) + 1;
    bytes memory row;

    bytes[3] memory red = [bytes("0.3"), "0.053", "0.004"];
    bytes[3] memory green = [bytes("0.45"), "0.215", "0.074"];
    bytes[3] memory blue = [bytes("0.791"), "0.603", "0.262"];

    if (_offset == 1) {
      row = bytes.concat(red[_palette], " ", green[_palette], " ", blue[_palette], " 0 0 ");
      return bytes.concat(row, row, row, "0 0 0 1 0");
    }
    if (_offset == 2) {
      row = bytes.concat(blue[_palette], " ", red[_palette], " ", green[_palette], " 0 0 ");
      return bytes.concat(row, row, row, "0 0 0 1 0");
    }
    row = bytes.concat(green[_palette], " ", blue[_palette], " ", red[_palette], " 0 0 ");
    return bytes.concat(row, row, row, "0 0 0 1 0");
  }
}