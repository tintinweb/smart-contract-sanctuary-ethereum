// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import {RickRollInterface} from './interfaces/RickRollInterface.sol';
import {Base64} from './libraries/Base64.sol';

contract RickRoll is RickRollInterface {
  string public name;
  uint256[] public arrayBuffer;
  uint256 public bufferLength;
  uint256 public noOfBytes;

  constructor(uint256 _maxBufferLength, uint256 _noOfBytes) {
    arrayBuffer = new uint256[](_maxBufferLength);
    noOfBytes = _noOfBytes;
  }

  function append(uint256[] memory buffer) public override {
    for (uint256 i = 0; i < buffer.length; i++) {
      arrayBuffer[bufferLength + i] = buffer[i];
    }
    bufferLength += buffer.length;
  }

  function getRickRoll() public view override returns (string memory) {
    bytes memory _bytes = new bytes(noOfBytes);
    for (uint256 i = 0; i < arrayBuffer.length; i++) {
      uint256 num = arrayBuffer[i];
      for (uint256 j = 0; num > 0 && j < 32 && (i * 32 + j) < noOfBytes; j++) {
        uint8 remainder = uint8(num % 0x100);
        _bytes[i * 32 + j] = bytes1(uint8(remainder));
        num = num / 0x100;
      }
    }
    return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(_bytes)));
  }

  function setName(string memory _name) public override {
    name = _name;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface RickRollInterface {
  function append(uint256[] memory buffer) external;
  function getRickRoll() external view returns (string memory);
  function setName(string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

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