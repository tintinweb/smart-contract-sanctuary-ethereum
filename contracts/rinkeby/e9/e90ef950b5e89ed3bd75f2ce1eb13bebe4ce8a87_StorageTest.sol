pragma solidity ^0.8.13;
contract StorageTest {
    struct test {
        uint256 i;
        uint256 j;
    }
    test public k;
    function func(uint256 a) public {
        k.i=a;
        k.j=a;
    }
}