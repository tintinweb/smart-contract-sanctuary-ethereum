// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {

    struct SimpleStruct {
        string stringVar;
        bytes bytesVar;
    }

    struct ComplexStruct {
        SimpleStruct structVar;
        SimpleStruct[] structArrayVar;
    }

    SimpleStruct public simpleStruct;
    SimpleStruct[] public simpleStructArray;
    ComplexStruct public complexStruct;
    address public someAddress;
    address[] public addressArray;
    uint256 public number0;
    int16 public number1;
    bool public flag;
    bytes32 public rs;
    string public text;

    constructor() {
        
        simpleStruct = SimpleStruct("asdfasdf", msg.data);

        simpleStructArray.push(simpleStruct);

        complexStruct.structVar = simpleStruct;
        complexStruct.structArrayVar.push(simpleStruct);
        complexStruct.structArrayVar.push(simpleStruct);

        addressArray.push(msg.sender);
        addressArray.push(address(0x1337));
    }

    function setVaras(
        uint256 a,
        int16 b,
        bool c,
        address[] memory d,
        bytes32 e,
        string memory f,
        address g
    ) external returns (
        uint256,
        int16,
        bool,
        address[] memory,
        bytes32,
        string memory,
        address
    ) {
        number0 = a;
        number1 = b;
        flag = c;
        addressArray = d;
        rs = e;
        text = f;
        someAddress = g;
        return (a,b,c,d,e,f,g);
    }

    function setSimpleStruct(string memory _stringVar, bytes memory _bytesVar) external returns (SimpleStruct memory previous) {
        previous = simpleStruct;
        simpleStruct.stringVar = _stringVar;
        simpleStruct.bytesVar = _bytesVar;
    }

    function setSimpleStructWithStruct(SimpleStruct memory _simpleStruct) external returns (SimpleStruct memory previous) {
        previous = simpleStruct;
        simpleStruct = _simpleStruct;
    }

    function setComplexStruct(SimpleStruct memory _structVar, SimpleStruct[] memory _structArrayVar) external returns (ComplexStruct memory previous) {
        previous = complexStruct;
        complexStruct.structVar.stringVar = _structVar.stringVar;
        complexStruct.structVar.bytesVar = _structVar.bytesVar;
        delete complexStruct.structArrayVar;
        for (uint256 i = 0; i < _structArrayVar.length; i++) {
            complexStruct.structArrayVar.push(_structArrayVar[i]);
        }
    }

    function setComplextStructWithStruct(ComplexStruct memory _complexStruct) external returns (ComplexStruct memory previous) {
        previous = complexStruct;
        complexStruct.structVar.stringVar = _complexStruct.structVar.stringVar;
        complexStruct.structVar.bytesVar = _complexStruct.structVar.bytesVar;
        delete complexStruct.structArrayVar;
        for (uint256 i = 0; i < _complexStruct.structArrayVar.length; i++) {
            complexStruct.structArrayVar.push(_complexStruct.structArrayVar[i]);
        }
    }

}