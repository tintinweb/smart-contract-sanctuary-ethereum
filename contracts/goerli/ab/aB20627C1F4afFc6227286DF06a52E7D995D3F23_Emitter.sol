// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Emitter {
    event Int(int256 value);
    event IntArray(int256[] value);
    event Uint(uint256 value);
    event UintArrayFixed(uint256[3] value);
    event Bool(bool value);
    event BoolArrayFixed(bool[2] value);
    event Address(address value);
    event AddressArray(address[] value);
    event String(string value);
    event StringArray(string[] value);
    event Mixed(int256 _int, uint256 _uint, bool _bool, string _string, address _address);
    event MixedArray(int256[] _int, uint256[] _uint, bool[] _bool, string[] _string, address[] _address);

    function emitInt(int256 value) public {
        emit Int(value);
    }
    function emitIntArray(int256[] calldata value) public {
        emit IntArray(value);
    }

    function emitUint(uint256 value) public {
        emit Uint(value);
    }
    function emitUintArrayFixed(uint256[3] calldata value) public {
        emit UintArrayFixed(value);
    }

    function emitBool(bool value) public {
        emit Bool(value);
    }
    function emitBoolArrayFixed(bool[2] calldata value) public {
        emit BoolArrayFixed(value);
    }

    function emitAddress(address value) public {
        emit Address(value);
    }
    function emitAddressArray(address[] calldata value) public {
        emit AddressArray(value);
    }

    function emitString(string calldata value) public {
        emit String(value);
    }
    function emitStringArray(string[] calldata value) public {
        emit StringArray(value);
    }

    function emitMixed(int256 _int, uint256 _uint, bool _bool, string calldata _string, address _address) public {
        emit Mixed(_int, _uint, _bool, _string, _address);
    }
    function emitMixedArray(int256[] calldata _int, uint256[] calldata _uint, bool[] calldata _bool, string[] calldata _string, address[] calldata _address) public {
        emit MixedArray(_int, _uint, _bool, _string, _address);
    }
}