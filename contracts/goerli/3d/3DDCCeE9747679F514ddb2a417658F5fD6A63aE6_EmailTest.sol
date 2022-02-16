pragma solidity ^0.8;

contract EmailTest {
    function fail() public {
        revert("dupa");
    }
}