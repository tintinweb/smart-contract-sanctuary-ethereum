// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './ToColor.sol';
import './HexStrings.sol';

library MandalaMetadata {

  using Strings for uint256;
  using Strings for uint8;
  using ToColor for bytes3;
  using HexStrings for uint160;

  function tokenURI(uint256 id, address owner, bool claimed, string memory svg) public pure returns (string memory) {
      string memory name = string(abi.encodePacked('Mandala Merge #',id.toString()));
      string memory description = string(abi.encodePacked('Random on-chain Mandala Merge animated SVG NFT'));
      string memory image = Base64.encode(bytes(svg));
      string memory claimedBoolean = 'false';
      if (claimed) {
        claimedBoolean = 'true';
      }

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://mandalamerge.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "claimed", "value": ',
                              claimedBoolean,
                              '}], "owner":"',
                              uint160(owner).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function renderMandalaById(bytes32 genes) public pure returns (string memory) {

    string memory render = string.concat('<defs><g id="svg-group">');

    for (uint i = 0; i < 5; i++) {
      render = string.concat(
        render,
        '<circle cx="', uint8(genes[(i*6)+3]).toString(), '" cy="', uint8(genes[(i*6)+4]).toString(), '" r="', uint8(genes[(i*6)+5]).toString(), '" stroke="#', (bytes2(genes[(i*6)+0]) | (bytes2(genes[(i*6)+1]) >> 8) | (bytes3(genes[(i*6)+2]) >> 16)).toColor(), '" fill-opacity="0">',
        '<animate attributeName="r" begin="0s" dur="5s" repeatCount="indefinite" values="', uint8(genes[(i*6)+5]).toString(), ';', uint8(genes[(i*6)+5]) > 10 ? (uint8(genes[(i*6)+5]) - 10).toString() : '0', ';', uint8(genes[(i*6)+5]) > 20 ? (uint8(genes[(i*6)+5]) - 20).toString() : '0', ';', uint8(genes[(i*6)+5]) > 10 ? (uint8(genes[(i*6)+5]) - 10).toString() : '0', ';', uint8(genes[(i*6)+5]).toString(), '"/>',
        '</circle>'
      );
    }

    render = string.concat(
      render,
      '</g></defs>',
      '<g id="svg-mandala" transform="translate(600, 600)"><g id="svg-layer">'
    );

    for (uint i = 0; i < 72; i++) {
      render = string.concat(render, '<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#svg-group" transform="rotate(',(i*5).toString(),')"/>');
    }

    render = string.concat(render, '</g></g>');

    return render;
  }

  function renderUnclaimedMandalaById(bytes32 genes) public pure returns (string memory) {

    string memory render = string.concat('<defs><g id="svg-group">');

    render = string.concat(
      render,
      '<circle cx="', uint8(genes[3]).toString(), '" cy="', uint8(genes[4]).toString(), '" r="', uint8(genes[5]).toString(), '" stroke="#', (bytes2(genes[0]) | (bytes2(genes[1]) >> 8) | (bytes3(genes[2]) >> 16)).toColor(), '" fill-opacity="0">',
      '<animate attributeName="r" begin="0s" dur="5s" repeatCount="indefinite" values="', uint8(genes[5]).toString(), ';', uint8(genes[5]) > 10 ? (uint8(genes[5]) - 10).toString() : '0', ';', uint8(genes[5]) > 20 ? (uint8(genes[5]) - 20).toString() : '0', ';', uint8(genes[5]) > 10 ? (uint8(genes[5]) - 10).toString() : '0', ';', uint8(genes[5]).toString(), '"/>',
      '</circle>'
    );

    render = string.concat(
      render,
      '</g></defs>',
      '<g id="svg-mandala" transform="translate(600, 600)"><g id="svg-layer">'
    );

    for (uint i = 0; i < 72; i++) {
      render = string.concat(render, '<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#svg-group" transform="rotate(',(i*5).toString(),')"/>');
    }

    render = string.concat(render, '</g></g>');

    return render;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToColor {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) internal pure returns (string memory) {
      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(buffer);
    }
}