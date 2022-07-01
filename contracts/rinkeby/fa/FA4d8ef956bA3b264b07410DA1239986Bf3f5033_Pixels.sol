// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IPixels.sol";

contract Pixels is IPixels {
  // Color Palettes (Index => Hex Colors)
  string[] public palette;

  Trait[] public traits;

  // pixels (RLE)
  mapping(string => Part[]) public pixels;

  // TO DO: Only owner
  function addColorsToPalette(string[] calldata newColors) external {
    for (uint256 i = 0; i < newColors.length; i++) {
      palette.push(newColors[i]);
    }
  }

  function addPixels(Part[] calldata _parts) external {
    for (uint256 i = 0; i < _parts.length; i++) {
      pixels[_parts[i].trait].push(_parts[i]);
    }
  }

  function addTraits(Trait[] calldata _traits) external {
    for (uint256 i = 0; i < _traits.length; i++) {
      traits.push(_traits[i]);
    }
  }

  function getByTrait(string memory trait) external view returns (Part[] memory) {
    return pixels[trait];
  }

  function getPixels() external view returns (Part[][11] memory parts) {
    parts[0] = pixels["background"];
    parts[1] = pixels["body"];
    parts[2] = pixels["eyes"];
    parts[3] = pixels["ears"];
    parts[4] = pixels["head"];
    parts[5] = pixels["face"];
    parts[6] = pixels["fashion"];
    parts[7] = pixels["food"];
    parts[8] = pixels["frens"];
    parts[9] = pixels["mschf"];
    parts[10] = pixels["special"];
    return parts;
  }

  function getPalette() external view returns (string[] memory) {
    return palette;
  }

  function getTraits() external view returns (Trait[] memory) {
    return traits;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IPixels {
  struct Part {
    string trait;
    string name;
    bytes data;
    bool nothing;
    uint128 weight;
  }

  struct Trait {
    string name;
    uint128 weights;
  }

  // TO DO: Only owner
  function addColorsToPalette(string[] calldata newColors) external;

  // TO DO: Only owner
  function addPixels(Part[] calldata _parts) external;

  // TO DO: Only owner
  function addTraits(Trait[] calldata _traits) external;

  function getByTrait(string memory trait) external view returns (Part[] memory);

  function getPixels() external view returns (Part[][11] memory parts);

  function getPalette() external view returns (string[] memory);

  function getTraits() external view returns (Trait[] memory);
}