/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SafesnapExample {
    struct MyTuple {
        bool myBool;
        uint256 myUint256;
        address myAddress;
    }

    struct myNestedTuple {
        bool myBool;
        bytes someBytes;
        uint256 largePositiveInt;
        MyTuple subTuple;
    }

    struct TupleA {
        uint256 largeNumA;
    }

    struct TupleB {
        uint256 largeNumB;
        TupleA a;
    }

    struct TupleC {
        uint256 largeNumC;
        TupleB b;
    }

    struct TupleD {
        uint256 largeNumD;
        TupleC c;
    }

    struct TupleE {
        uint256 largeNumE;
        TupleD d;
    }

    struct TupleF {
        uint256 largeNumF;
        TupleE e;
    }

    struct TupleG {
        uint256 largeNumG;
        TupleF f;
    }

    struct TupleH {
        uint256 largeNumH;
        TupleG g;
    }

    struct TupleI {
        uint256 largeNumI;
        TupleH h;
    }

    struct TupleJ {
        uint256 largeNumJ;
        TupleI i;
    }

    myNestedTuple public nestedTupleValue;
    TupleJ public veryNestedTuple;
    bytes[][] public bytesArrayOfArrays;
    TupleA[] public tupleArrayOfArrays;

    address public addressValue;
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
    MyTuple public myTupleValue;
    bool[] public boolArray;
    MyTuple[] public myTupleArray;

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
        MyTuple calldata _myTupleValue,
        bool[] calldata _boolArray,
        MyTuple[] calldata _myTupleArray
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

    function setAddressValue(address _addressValue) public {
        addressValue = _addressValue;
    }

    function setNestedTuple(myNestedTuple calldata _tuple) public {
        nestedTupleValue = _tuple;
    }

    function setVeryNestedTuple(TupleJ calldata _tupleJ) public {
        veryNestedTuple = _tupleJ;
    }

    function setBytesArrayOfArrays(bytes[][] calldata _arr) public {
        for (uint256 i = 0; i < _arr.length; i++) {
            for (uint256 j = 0; j < _arr[i].length; j++) {
                bytesArrayOfArrays[i][j] = _arr[i][j];
            }
        }
    }

    function setTupleArrayOfArrays(TupleA[][] calldata _arr) public {
        for (uint256 i = 0; i < _arr.length; i++) {
            for (uint256 j = 0; j < _arr[i].length; j++) {
                uint256Value = _arr[i][j].largeNumA;
            }
        }
    }
}