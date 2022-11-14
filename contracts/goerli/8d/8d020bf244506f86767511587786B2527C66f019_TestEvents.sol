pragma solidity ^0.8.0;

contract TestEvents {

    struct ComplicatedStruct {
        uint256 a0;
        uint256 a1;
    }

    event SimpleEvent(uint arg0, uint arg1, bool arg2);
    event BiggerEvent(uint arg0, uint arg1, bool arg2, string arg3Str);
    event SlightBiggerEvent(uint arg0, uint arg1, bool arg2, string arg3Str, uint[] arg4Arr);
    event BiggestEvent(uint arg0, uint arg1, bool arg2, string arg3Str, ComplicatedStruct arg4Strct);
    
    function testEvent(uint arg0, uint arg1, bool arg2, string memory arg3Str, uint arg4a0, uint arg4a1) public {
        emit SimpleEvent(arg0, arg1, arg2);
        emit BiggerEvent(arg0, arg1, arg2, arg3Str);
        uint[] memory arg4Arr = new uint[](2);
        arg4Arr[0] = arg4a0;
        arg4Arr[1] = arg4a1;
        emit SlightBiggerEvent(arg0, arg1, arg2, arg3Str, arg4Arr);
        ComplicatedStruct memory arg4 = ComplicatedStruct(arg4a0, arg4a1);
        emit BiggestEvent(arg0, arg1, arg2, arg3Str, arg4);
    }

}