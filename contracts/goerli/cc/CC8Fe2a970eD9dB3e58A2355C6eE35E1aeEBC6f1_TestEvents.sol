pragma solidity ^0.8.0;

contract TestEvents {

    struct ComplicatedStruct {
        uint256 a0;
        uint256 a1;
    }

    event SimpleEvent(uint arg0, uint arg1, bool arg2);
    event BiggerEvent(uint arg0, uint arg1, bool arg2, string arg3Str);
    event BiggestEvent(uint arg0, uint arg1, bool arg2, string arg3Str, ComplicatedStruct arg4Strct);
    
    function testEvent(uint arg0, uint arg1, bool arg2, string memory arg3Str, uint arg4a0, uint arg4a1) public {
        emit SimpleEvent(arg0, arg1, arg2);
        emit BiggerEvent(arg0, arg1, arg2, arg3Str);
        ComplicatedStruct memory arg4 = ComplicatedStruct(arg4a0, arg4a1);
        emit BiggestEvent(arg0, arg1, arg2, arg3Str, arg4);
    }

}