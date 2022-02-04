pragma solidity ^0.8.0;

contract Test {

    bytes32 public test;
    bytes public btest;

    constructor() {

    }

    function stringToBytes32(string memory source) public returns (bytes32) {
        bytes memory tempEmptyStringTest = bytes(source);
        btest = tempEmptyStringTest;
        bytes32 aa;
        // if (tempEmptyStringTest.length == 0) {
        //     return 0x0;
        // }

        assembly {
            aa := mload(source)
        }
        test = aa;
    }
}