pragma solidity ^0.8.13;

contract StorageToMemory{
    uint120 a = 233;
    function test1() public  returns (uint) {
        uint b = a;
        return b;
    }
    function test2() public  returns (uint120) {
        uint120 b = a;
        return b;
    }
}