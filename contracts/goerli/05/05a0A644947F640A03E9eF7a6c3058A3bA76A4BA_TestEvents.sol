pragma solidity ^0.8.0;

contract TestEvents {

    struct ComplicatedStruct {
        uint256 a0;
        uint256 a1;
    }

    event SimpleEvent(uint arg0, uint arg1, bool arg2);
    event BiggerEvent(uint arg0, uint arg1, bool arg2, string arg3Str);
    event SlightBiggerEvent(uint arg0, uint arg1, bool arg2, string arg3Str, uint[2][2] arg4Arr);
    event BiggestEvent(uint arg0, uint arg1, bool arg2, string arg3Str, ComplicatedStruct arg4Strct);
    
    function testEvent(uint arg0, uint arg1, bool arg2, string memory arg3Str, uint arg4a0, uint arg4a1) public {
        emit SimpleEvent(arg0, arg1, arg2);
        emit BiggerEvent(arg0, arg1, arg2, arg3Str);
        uint[2][2] memory arg4Arr1;
        arg4Arr1[0][0] = arg4a0;
        arg4Arr1[1][0] = arg4a1;
        arg4Arr1[0][1] = arg4a0;
        arg4Arr1[1][1] = arg4a1;
        emit SlightBiggerEvent(arg0, arg1, arg2, arg3Str, arg4Arr1);
        ComplicatedStruct memory arg4 = ComplicatedStruct(arg4a0, arg4a1);
        emit BiggestEvent(arg0, arg1, arg2, arg3Str, arg4);
    }

}