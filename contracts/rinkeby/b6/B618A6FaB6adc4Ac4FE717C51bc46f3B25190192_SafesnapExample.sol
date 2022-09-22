/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SafesnapExample {
    struct myTuple {
        bool myBool;
        uint256 myUint256;
    }

    bool public boolValue;
    int8 public int8Value;
    int24 public int24Value;
    int256 public int256Value;
    uint8 public uint8Value;
    uint40 public uint40Value;
    uint256 public uint256Value;
    bytes public bytesValue;
    bytes1 public bytes1Value;
    bytes2 public bytes2Value;
    bytes3 public bytes3Value;
    bytes4 public bytes4Value;
    bytes5 public bytes5Value;
    bytes32 public bytes32Value;
    string public stringValue;
    myTuple public myTupleValue;
    bool[] public boolArray;
    myTuple[] public myTupleArray;

    function setSomeValues(
        bool _boolValue,
        int256 _int256Value,
        uint256 _uint256Value,
        bytes calldata _bytesValue,
        bytes32 _bytes32Value
    ) public {
        boolValue = _boolValue;
        int256Value = _int256Value;
        uint256Value = _uint256Value;
        bytesValue = _bytesValue;
        bytes32Value = _bytes32Value;
    }

    function setSomeOtherValues(
        myTuple calldata _myTupleValue,
        bool[] calldata _boolArray,
        myTuple[] calldata _myTupleArray
    ) public {
        myTupleValue = _myTupleValue;
        boolArray = _boolArray;

        for (uint256 i = 0; i < _myTupleArray.length; i++) {
            myTupleArray.push(_myTupleArray[i]);
        }
    }

    function setBytes3Value(bytes3 _bytes3Value) public {
        bytes3Value = _bytes3Value;
    }

    function setInt24Value(int24 _int24Value) public {
        int24Value = _int24Value;
    }
    
    function setUint40Value(uint40 _uint40Value) public {
        uint40Value = _uint40Value;
    }

    function setInt8Value(int8 _int8Value) public {
        int8Value = _int8Value;
    }
    
    function setUint8Value(uint8 _uint8Value) public {
        uint8Value = _uint8Value;
    }
}