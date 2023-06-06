pragma solidity ^0.8.13;

contract StorageToMemory{
    uint120 a = 233;
    function test1() public  {
        uint b = a;
    }
    function test2() public  {
        uint120 b = a;
       
    }
}