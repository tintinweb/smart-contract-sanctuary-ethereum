// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Layer.sol";

contract LayerHead is Layer {
  constructor(){
    layerName = "Head";

    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-0</text>',
      value: 'Head-Value-zero',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-1</text>',
      value: 'Head-Value-first',
      defaultColor1Hex: 'green',
      defaultColor2Hex: 'green'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-2</text>',
      value: 'Head-Value-second',
      defaultColor1Hex: 'blue',
      defaultColor2Hex: 'blue'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-3</text>',
      value: 'Head-Value-third',
      defaultColor1Hex: 'red',
      defaultColor2Hex: 'red'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-4</text>',
      value: 'Head-Value-fourth',
      defaultColor1Hex: 'yellow',
      defaultColor2Hex: 'yellow'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-5</text>',
      value: 'Head-Value-fifth',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-6</text>',
      value: 'Head-Value-sixth',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-7</text>',
      value: 'Head-Value-seventh',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-8</text>',
      value: 'Head-Value-eighth',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-9</text>',
      value: 'Head-Value-ninth',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-10</text>',
      value: 'Head-Value-10nth',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-11</text>',
      value: 'Head-Value-11nth',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-12</text>',
      value: 'Head-Value-12th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-13</text>',
      value: 'Head-Value-13th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-14</text>',
      value: 'Head-Value-14th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-15</text>',
      value: 'Head-Value-15th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-16</text>',
      value: 'Head-Value-16th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-17</text>',
      value: 'Head-Value-17th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
    layerOptions.push(Option({
      svg: '<text x="20" y="35" class="small" fill="currentColor">Head-18</text>',
      value: 'Head-Value-18th',
      defaultColor1Hex: '#000',
      defaultColor2Hex: '#000'
    }));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

struct OptionSelection {
  uint256 optionNumber;
  string color1Hex;
  string color2Hex;
}

struct Option {
  string svg;
  string value;
  string defaultColor1Hex;
  string defaultColor2Hex;
}

abstract contract Layer {
  Option[] public layerOptions;
  string layerName;
  
  function getOptionsLength() external virtual view returns (uint256) {
    return layerOptions.length;
  }
  
  function getOptionDefaultColorById (
    uint256 id
  )
    external
    virtual
    view
    returns (string memory)
  {
    // return layerOptions[id].defaultColor1Hex;
    return layerOptions[id].defaultColor1Hex;
  }

  // change to metadata
  function getOptionMetaById (
    uint256 id
  )
    external
    virtual
    view
    returns (string memory)
  {
    return string.concat(
      '{ "trait_type": "',
      layerName,
      '", "value": "',
      layerOptions[id].value,
      '" }'
    );
  }

  function renderOptionById(
    uint256 id,
    string memory color1Hex,
    string memory color2Hex
  ) external virtual view returns (string memory){
    return string(abi.encodePacked(
      '<g color="',
      color1Hex,
      '">',
      layerOptions[id].svg,
      '</g>'
      ));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}