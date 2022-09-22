/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SafesnapExample {
    struct myTuple {
        bool myBool;
        uint256 myUint256;
    }

    bool boolValue;
    int256 int256Value;
    uint256 uint256Value;
    bytes bytesValue;
    bytes1 bytes1Value;
    bytes2 bytes2Value;
    bytes3 bytes3Value;
    bytes4 bytes4Value;
    bytes5 bytes5Value;
    bytes32 bytes32Value;
    string stringValue;
    myTuple myTupleValue;
    bool[] boolArray;
    myTuple[] myTupleArray;

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
}