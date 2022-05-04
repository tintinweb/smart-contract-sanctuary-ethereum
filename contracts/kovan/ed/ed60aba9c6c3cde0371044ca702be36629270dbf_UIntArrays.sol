/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library UIntArrays {
  function sum(uint256[] memory _array) public pure returns (uint256 result) {
    result = 0;
    for (uint256 i = 0; i < _array.length; i++) {
      result += _array[i];
    }
  }

  function randomIndexFromWeightedArray(
    uint256[] memory _weightedArray,
    uint256 _randomNumber
  ) public pure returns (uint256) {
    uint256 totalSumWeight = sum(_weightedArray);
    require(totalSumWeight > 0, "Array has no weight");
    uint256 randomSumWeight = _randomNumber % totalSumWeight;
    uint256 currentSumWeight = 0;

    for (uint256 i = 0; i < _weightedArray.length; i++) {
      currentSumWeight += _weightedArray[i];
      if (randomSumWeight < currentSumWeight) {
        return i;
      }
    }

    return _weightedArray.length - 1;
  }

  function hash(uint256[] memory _array, uint256 _endIndex)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded;
    for (uint256 i = 0; i < _endIndex; i++) {
      encoded = abi.encode(encoded, _array[i]);
    }

    return keccak256(encoded);
  }

  function arrayFromPackedUint(uint256 _packed, uint256 _size)
    public
    pure
    returns (uint256[] memory)
  {
    uint256[] memory array = new uint256[](_size);

    for (uint256 i = 0; i < _size; i++) {
      array[i] = uint256(uint16(_packed >> (i * 16)));
    }

    return array;
  }

  function packedUintFromArray(uint256[] memory _array)
    public
    pure
    returns (uint256 _packed)
  {
    require(_array.length < 17, "pack array > 16");
    for (uint256 i = 0; i < _array.length; i++) {
      _packed |= _array[i] << (i * 16);
    }
  }

  function elementFromPackedUint(uint256 _packed, uint256 _index)
    public
    pure
    returns (uint256)
  {
    return uint256(uint16(_packed >> (_index * 16)));
  }

  function decrementPackedUint(
    uint256 _packed,
    uint256 _index,
    uint256 _number
  ) public pure returns (uint256 result) {
    result = _packed & ~(((1 << 16) - 1) << (_index * 16));
    result |=
      (elementFromPackedUint(_packed, _index) - _number) <<
      (_index * 16);
  }

  function incrementPackedUint(
    uint256 _packed,
    uint256 _index,
    uint256 _number
  ) public pure returns (uint256 result) {
    result = _packed & ~(((1 << 16) - 1) << (_index * 16));
    result |=
      (elementFromPackedUint(_packed, _index) + _number) <<
      (_index * 16);
  }

  function mergeArrays(
    uint256[] memory _array1,
    uint256[] memory _array2,
    bool _isPositive
  ) public pure returns (uint256[] memory) {
    for (uint256 i = 0; i < _array1.length; i++) {
      if (_isPositive) {
        _array1[i] += _array2[i];
      } else {
        _array1[i] -= _array2[i];
      }
    }
    return _array1;
  }
}