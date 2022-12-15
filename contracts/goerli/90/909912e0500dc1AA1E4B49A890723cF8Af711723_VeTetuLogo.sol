// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../lib/Base64.sol";

/// @title Library for storing SVG image of veNFT.
/// @author belbix
library VeTetuLogo {

  /// @dev Return SVG logo of veTETU.
  function tokenURI(uint _tokenId, uint _balanceOf, uint untilEnd, uint _value) public pure returns (string memory output) {
    output = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 900"><style>.base{font-size:40px;}</style><rect fill="#193180" width="600" height="900"/><path fill="#4899F8" d="M0,900h600V522.2C454.4,517.2,107.4,456.8,60.2,0H0V900z"/><circle fill="#1B184E" cx="385" cy="212" r="180"/><circle fill="#04A8F0" cx="385" cy="142" r="42"/><path fill-rule="evenodd" clip-rule="evenodd" fill="#686DF1" d="M385.6,208.8c43.1,0,78-34.9,78-78c-1.8-21.1,16.2-21.1,21.1-15.4c0.4,0.3,0.7,0.7,1.1,1.2c16.7,21.5,26.6,48.4,26.6,77.7c0,25.8-24.4,42.2-50.2,42.2H309c-25.8,0-50.2-16.4-50.2-42.2c0-29.3,9.9-56.3,26.6-77.7c0.3-0.4,0.7-0.8,1.1-1.2c4.9-5.7,22.9-5.7,21.1,15.4l0,0C307.6,173.9,342.5,208.8,385.6,208.8z"/><path fill="#04A8F0" d="M372.3,335.9l-35.5-51.2c-7.5-10.8,0.2-25.5,13.3-25.5h35.5h35.5c13.1,0,20.8,14.7,13.3,25.5l-35.5,51.2C392.5,345.2,378.7,345.2,372.3,335.9z"/>';
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 464)" fill="#EAECFE" class="base">ID:</text><text transform="matrix(1 0 0 1 50 506)" fill="#97D0FF" class="base">', _toString(_tokenId), '</text>'));
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 579)" fill="#EAECFE" class="base">Balance:</text><text transform="matrix(1 0 0 1 50 621)" fill="#97D0FF" class="base">', _toString(_balanceOf / 1e18), '</text>'));
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 695)" fill="#EAECFE" class="base">Until unlock:</text><text transform="matrix(1 0 0 1 50 737)" fill="#97D0FF" class="base">', _toString(untilEnd / 60 / 60 / 24), ' days</text>'));
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 811)" fill="#EAECFE" class="base">Power:</text><text transform="matrix(1 0 0 1 50 853)" fill="#97D0FF" class="base">', _toString(_value / 1e18), '</text></svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "veTETU #', _toString(_tokenId), '", "description": "Locked TETU tokens", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));
  }

  /// @dev Inspired by OraclizeAPI's implementation - MIT license
  ///      https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function _toString(uint value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}