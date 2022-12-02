// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import { Attribute, Royalty } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';
import { Metadata as MetadataV1 } from '../structs/DynamicMetadataStructs.sol';

library DynamicMetadata {
  using Strings for uint16;

  // Returns a copy of the concated attributes
  function concatDynamicAttributes(Attribute[] calldata baseAttributes, Attribute[] calldata dynamicAttributes)
    public
    pure
    returns (Attribute[] memory)
  {
    uint256 countOfAttributes = baseAttributes.length + dynamicAttributes.length;
    Attribute[] memory allAttributes = new Attribute[](countOfAttributes);
    for (uint256 i = 0; i < baseAttributes.length; i++) {
      allAttributes[i] = baseAttributes[i];
    }

    for (uint256 i = 0; i < dynamicAttributes.length; i++) {
      allAttributes[baseAttributes.length + i] = dynamicAttributes[i];
    }

    return allAttributes;
  }

  //
  function appendBaseAttributes(Attribute[] storage baseAttributes, Attribute[] calldata newBaseAttributes) public {
    for (uint256 i = 0; i < newBaseAttributes.length; i++) {
      baseAttributes.push(newBaseAttributes[i]);
    }
  }

  function toBytes(Attribute memory attribute) public pure returns (bytes memory) {
    bytes memory attributesInByte = '{';
    if (bytes(attribute.displayType).length > 0) {
      attributesInByte = bytes.concat(
        attributesInByte,
        abi.encodePacked('"display_type":"', attribute.displayType, '",')
      );
    }

    attributesInByte = bytes.concat(
      attributesInByte,
      //TODO: ver como hacemos con el manejo de las comillas para los numeros
      abi.encodePacked('"trait_type":"', attribute.traitType, '",', '"value":"', attribute.value, '"')
    );

    return bytes.concat(attributesInByte, '}');
  }

  //INFO: This method assumes that attributesToMap has a length greather than 0
  function mapToBytes(Attribute[] calldata attributesToMap) public pure returns (bytes memory) {
    bytes memory attributesInBytes = '"attributes":[';

    for (uint32 i = 0; i < attributesToMap.length - 1; i++) {
      attributesInBytes = bytes.concat(attributesInBytes, toBytes(attributesToMap[i]), ',');
    }
    attributesInBytes = bytes.concat(attributesInBytes, toBytes(attributesToMap[attributesToMap.length - 1]), ']');

    return attributesInBytes;
  }

  //INFO: This method assumes that metadata.attributes has a length greather than 0
  function toBase64URI(MetadataV1 calldata metadata) public pure returns (string memory) {
    bytes memory descriptionInBytes = keyValueToJsonInBytes('description', metadata.description);
    bytes memory imageInBytes = keyValueToJsonInBytes('image', metadata.image);
    bytes memory nameInBytes = keyValueToJsonInBytes('name', metadata.name);
    bytes memory attributesInBytes = mapToBytes(metadata.attributes);
    bytes memory jsonInBytes = bytes.concat(
      '{',
      descriptionInBytes,
      ',',
      imageInBytes,
      ',',
      nameInBytes,
      ',',
      attributesInBytes
    );
    // INFO: If has royalties set
    if (metadata.royalty.feePercentage != 0) {
      bytes memory royaltyFeeInBytes = keyValueToJsonInBytes(
        'seller_fee_basis_points', // INFO: Open see key for royalties
        metadata.royalty.feePercentage.toString()
      );
      bytes memory royaltyRecipientInBytes = keyValueToJsonInBytes(
        'fee_recipient', // INFO: Open see key for royalties
        Strings.toHexString(uint256(uint160(metadata.royalty.recipientAddress)), 20)
      );
      jsonInBytes = bytes.concat(jsonInBytes, ',', royaltyFeeInBytes, ',', royaltyRecipientInBytes);
    }

    jsonInBytes = bytes.concat(jsonInBytes, '}');

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(jsonInBytes)));
  }

  function keyValueToJsonInBytes(string memory key, string memory value) public pure returns (bytes memory) {
    return bytes.concat('"', bytes(key), '":"', bytes(value), '"');
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
struct Attribute {
  string displayType;
  string traitType;
  string value;
}

struct Royalty {
  address recipientAddress;
  uint16 feePercentage; // INFO: Use two decimal => 100 = 1%
}

struct Metadata {
  string description;
  string name;
  Tuple[] additionalProperties;
  Attribute[] attributes;
}

struct Tuple {
  string key;
  string value;
}

struct SCBehavior {
  function(uint256) internal view returns (string memory) getTokenURI;
  function(address, address, uint256) internal view returns (bool) canTokenBeTransferred;
  function(address, uint256) internal transferBlockedToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Attribute, Royalty, SCBehavior } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';

struct Metadata {
  string description;
  string image;
  string name;
  Attribute[] attributes;
  Royalty royalty;
}