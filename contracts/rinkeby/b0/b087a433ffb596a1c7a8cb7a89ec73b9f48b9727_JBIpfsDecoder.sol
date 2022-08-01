// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @notice
  Utilities to decode an IPFS hash.
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

    // Convert the hex string to an hash
    string memory ipfsHash = _toBase58(completeHexString);

    // Concatenate with the base URI
    return string(abi.encodePacked(_baseUri, ipfsHash));
  }

  /**
    @notice
    Convert an hex string to base58

    @notice 
    Written by Martin Ludfall - Licence: MIT
  */
  function _toBase58(bytes memory _source) private pure returns (string memory) {
    if (_source.length == 0) return new string(0);
    uint8[] memory digits = new uint8[](46); // hash size with the prefix
    digits[0] = 0;
    uint8 digitlength = 1;
    for (uint256 i = 0; i < _source.length; ++i) {
      uint256 carry = uint8(_source[i]);
      for (uint256 j = 0; j < digitlength; ++j) {
        carry += uint256(digits[j]) * 256;
        digits[j] = uint8(carry % 58);
        carry = carry / 58;
      }

      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        digitlength++;
        carry = carry / 58;
      }
    }
    return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
  }

  function _truncate(uint8[] memory _array, uint8 _length) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_length);
    for (uint256 i = 0; i < _length; i++) {
      output[i] = _array[i];
    }
    return output;
  }

  function _reverse(uint8[] memory _input) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_input.length);
    for (uint256 i = 0; i < _input.length; i++) {
      output[i] = _input[_input.length - 1 - i];
    }
    return output;
  }

  function _toAlphabet(uint8[] memory _indices) private pure returns (bytes memory) {
    bytes memory output = new bytes(_indices.length);
    for (uint256 i = 0; i < _indices.length; i++) {
      output[i] = _ALPHABET[_indices[i]];
    }
    return output;
  }
}