// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  
  @notice
  Utilities to decode an IPFS hash.

  @dev
  This is fairly gas intensive, due to multiple nested loops, onchain 
  IPFS hash decoding is therefore not advised (storing them as a string,
  in that use-case, *might* be more efficient).

*/
library JBIpfsDecoder {
  //*********************************************************************//
  // ------------------- internal constant properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Just a kind reminder to our readers

    @dev
    Used in base58ToString
  */
  bytes internal constant _ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function decode(string memory _baseUri, bytes32 _hexString)
    external
    pure
    returns (string memory)
  {
    // Concatenate the hex string with the fixed IPFS hash part (0x12 and 0x20)
    bytes memory completeHexString = abi.encodePacked(bytes2(0x1220), _hexString);

    // Convert the hex string to a hash
    string memory ipfsHash = _toBase58(completeHexString);

    // Concatenate with the base URI
    return string(abi.encodePacked(_baseUri, ipfsHash));
  }

  /**
    @notice
    Convert a hex string to base58

    @notice 
    Written by Martin Ludfall - Licence: MIT
  */
  function _toBase58(bytes memory _source) private pure returns (string memory) {
    if (_source.length == 0) return new string(0);

    uint8[] memory digits = new uint8[](46); // hash size with the prefix

    digits[0] = 0;

    uint8 digitlength = 1;
    uint256 _sourceLength = _source.length;

    for (uint256 i; i < _sourceLength; ) {
      uint256 carry = uint8(_source[i]);

      for (uint256 j; j < digitlength; ) {
        carry += uint256(digits[j]) << 8; // mul 256
        digits[j] = uint8(carry % 58);
        carry = carry / 58;

        unchecked {
          ++j;
        }
      }

      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        unchecked {
          ++digitlength;
        }
        carry = carry / 58;
      }

      unchecked {
        ++i;
      }
    }
    return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
  }

  function _truncate(uint8[] memory _array, uint8 _length) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_length);
    for (uint256 i; i < _length; ) {
      output[i] = _array[i];

      unchecked {
        ++i;
      }
    }
    return output;
  }

  function _reverse(uint8[] memory _input) private pure returns (uint8[] memory) {
    uint256 _inputLength = _input.length;
    uint8[] memory output = new uint8[](_inputLength);
    for (uint256 i; i < _inputLength; ) {
      unchecked {
        output[i] = _input[_input.length - 1 - i];
        ++i;
      }
    }
    return output;
  }

  function _toAlphabet(uint8[] memory _indices) private pure returns (bytes memory) {
    uint256 _indicesLength = _indices.length;
    bytes memory output = new bytes(_indicesLength);
    for (uint256 i; i < _indicesLength; ) {
      output[i] = _ALPHABET[_indices[i]];

      unchecked {
        ++i;
      }
    }
    return output;
  }
}