//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './Base64.sol';

library Metadata {
  using Strings for uint256;
  using Strings for uint32;
  using Base64 for *;

  function compileMetadata(
    uint256 tokenId,
    string memory baseURI,
    string memory faction,
    string memory name,
    string[] memory attrNames,
    uint32[] memory attributeValues
  ) public pure returns (string memory) {
    string memory attrData;

    if (attrNames.length == 0) {
      attrData = '{}';
    } else {
      attrData = compileAttributes(attrNames, attributeValues);
    }

    bytes memory tempEmptyStringTest = bytes(name);
    if (tempEmptyStringTest.length == 0) {
      name = string(abi.encodePacked('Bot #', tokenId.toString()));
    }

    string memory metadata = string(
      abi.encodePacked(
        '{"name": "',
        name,
        '", "description": "The robot uprising is smaller than you think.", ',
        '"image": "',
        baseURI,
        tokenId.toString(),
        '", ',
        '"faction": "',
        faction,
        '", ',
        '"attributes": ',
        attrData,
        '}'
      )
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.base64(bytes(metadata))
        )
      );
  }

  function compileAttributes(
    string[] memory attrNames,
    uint32[] memory attributeValues
  ) public pure returns (string memory) {
    require(
      attrNames.length == attributeValues.length,
      'Metadata: attrNames/attributeValues length mismatch'
    );

    string memory attrs;

    for (uint8 i = 0; i < attrNames.length; i++) {
      if (i == attrNames.length - 1) {
        attrs = string(
          abi.encodePacked(
            attrs,
            string(
              abi.encodePacked(
                '"',
                attrNames[i],
                '": ',
                attributeValues[i].toString()
              )
            )
          )
        );
      } else {
        attrs = string(
          abi.encodePacked(
            attrs,
            string(
              abi.encodePacked(
                '"',
                attrNames[i],
                '": ',
                attributeValues[i].toString()
              )
            ),
            ','
          )
        );
      }
    }

    return string(abi.encodePacked('{', attrs, '}'));
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

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

/** BASE 64 - Written by Brech Devos */
library Base64 {
  string internal constant TABLE =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) public pure returns (string memory) {
    if (data.length == 0) return '';

    // load the table into memory
    string memory table = TABLE;

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
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}