/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

contract Float {
    mapping(address => PositionData) public position;

    struct PositionData {
        uint32 slot; // array number
        uint32 fraction; // first byte in the slot
    }

    mapping(uint128 => bytes32) public values;
    bool initDone;

    function addNumber(uint32 _slot, bytes32 _preparedNumber) public {
        values[_slot] = _preparedNumber;
    }

    function addNumbers(
        uint32[] memory _slots,
        bytes32[] memory _preparedNumbers
    ) public {
        require(
            _slots.length == _preparedNumbers.length,
            "arrays length mismatch"
        );
        for (uint i = 0; i < _slots.length; i++) {
            addNumber(_slots[i], _preparedNumbers[i]);
        }
    }

    function addToken(address _token, PositionData memory _position) public {
        position[_token] = _position;
    }

    function addTokens(
        address[] memory _token,
        PositionData[] memory _position
    ) public {
        for (uint i = 0; i < _token.length; i++) {
            addToken(_token[i], _position[i]);
        }
    }

    bytes32 public value;

    function _getValue(
        uint128 _slot,
        uint _firstBytePos
    ) public returns (bytes32) {
        // maybe input bit position to avoid multiplication to 8 ?
        value = (values[_slot] << (_firstBytePos * 8)) >> 240;
        return value;
    }

    // decode hex number to uint256
    // consider mantissa taking first 2 bits
    uint public num;
    uint256 public result;

    function _decodeValue(bytes32 _value) public returns (uint256) {
        num = uint256(_value);
        uint256 mantissa = uint256(_value) >> 14;
        uint256 body = (uint256(_value) << 242) >> 242;
        result = body * (10 ** (3 - mantissa)); // this is neede for remix test only!
        return body * (10 ** (3 - mantissa));
    }

    // look at an example
    // having bits 10_10011101110101 (2 and 10101 in dec)
    // we want to mean a float number 101.01
    // these bits are converted to a hex number
    // A775
    function getValueForToken(address _token) public returns (uint256) {
        PositionData memory pos = position[_token];
        value = _getValue(pos.slot, pos.fraction);
        return _decodeValue(value);
    }
}